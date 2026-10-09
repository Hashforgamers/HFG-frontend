import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Wires Firebase Crashlytics and Performance Monitoring. Call [init] once,
/// right after `Firebase.initializeApp`, inside [runGuarded].
///
/// Both stay off in debug builds so local development doesn't pollute the
/// dashboards. Build with `--dart-define=FIREBASE_MONITORING_IN_DEBUG=true`
/// to test them from a debug build.
///
/// Every report carries custom keys `screen`, `auth_state`, `app_state` and
/// `game_mode` so a crash can be tied to where the user was.
abstract final class CrashReporting {
  static const bool _forceInDebug = bool.fromEnvironment(
    'FIREBASE_MONITORING_IN_DEBUG',
  );

  static bool get enabled => !kDebugMode || _forceInDebug;

  static bool _ready = false;
  static StreamSubscription<User?>? _authSub;
  static AppLifecycleListener? _lifecycle;

  /// Add to `navigatorObservers` to keep the `screen` key current.
  static final NavigatorObserver routeObserver = _ScreenKeyObserver();

  /// Runs [body] (the whole of `main`) in a zone whose uncaught errors are
  /// reported. `WidgetsFlutterBinding.ensureInitialized` and `runApp` must
  /// both run inside [body] so they share the zone.
  static void runGuarded(Future<void> Function() body) {
    runZonedGuarded(body, (error, stack) {
      _record(error, stack, fatal: !isExpectedFailure(error));
    });
  }

  static Future<void> init({required String flavor}) async {
    final crashlytics = FirebaseCrashlytics.instance;
    try {
      await crashlytics.setCrashlyticsCollectionEnabled(enabled);
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        enabled,
      );
      await crashlytics.setCustomKey('flavor', flavor);
      await crashlytics.setCustomKey('screen', 'launch');
      await crashlytics.setCustomKey('game_mode', 'none');
      await crashlytics.setCustomKey('app_state', 'resumed');
    } catch (e) {
      // Monitoring must never stop the app from starting.
      debugPrint('[CrashReporting] init failed: $e');
      return;
    }
    _ready = true;

    // Errors thrown inside the Flutter framework (build, layout, paint...).
    // Image and font loading failures surface here too; they're network
    // conditions, not defects, so they must not count against crash-free.
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      if (!enabled) return;
      if (isExpectedFailure(details.exception) ||
          details.library == 'image resource service') {
        unawaited(crashlytics.recordFlutterError(details));
      } else {
        unawaited(crashlytics.recordFlutterFatalError(details));
      }
    };

    // Uncaught async errors that never reach the framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      _record(error, stack, fatal: !isExpectedFailure(error));
      return true;
    };

    // Tag reports with the Firebase uid (never email/name) so a crash can be
    // matched to a support ticket. Cleared on sign-out.
    await _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      unawaited(crashlytics.setUserIdentifier(user?.uid ?? ''));
      setKey(
        'auth_state',
        user == null
            ? 'signed_out'
            : (user.isAnonymous ? 'anonymous' : 'signed_in'),
      );
    });

    _lifecycle?.dispose();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) => setKey('app_state', state.name),
    );
  }

  /// Network blips, failed image/font downloads and Firestore being briefly
  /// unreachable. Worth recording, never worth calling a crash.
  @visibleForTesting
  static bool isExpectedFailure(Object error) {
    if (error is SocketException ||
        error is HttpException ||
        error is HandshakeException ||
        error is TimeoutException) {
      return true;
    }
    if (error is FirebaseException) {
      return const {
        'unavailable',
        'network-request-failed',
        'deadline-exceeded',
      }.contains(error.code);
    }
    // package:http's ClientException and google_fonts' download failure,
    // matched by name so this file needs neither package.
    final type = error.runtimeType.toString();
    if (type == 'ClientException' || type == 'NetworkImageLoadException') {
      return true;
    }
    return error.toString().contains('Failed to load font');
  }

  /// Sets a Crashlytics custom key. Safe to call before [init] or in tests.
  static void setKey(String key, Object value) {
    if (!_ready || !enabled) return;
    unawaited(
      FirebaseCrashlytics.instance.setCustomKey(key, value).catchError((_) {}),
    );
  }

  /// Which game is on screen, e.g. `ludo_online_quick`; pass null on exit.
  static void setGameMode(String? mode) => setKey('game_mode', mode ?? 'none');

  /// Report a caught error that was handled but still worth knowing about.
  static void recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) {
    if (!_ready || !enabled) return;
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, reason: reason),
    );
  }

  static void _record(Object error, StackTrace stack, {required bool fatal}) {
    if (!_ready || !enabled) {
      debugPrint('[CrashReporting] uncaught: $error\n$stack');
      return;
    }
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal),
    );
  }
}

class _ScreenKeyObserver extends NavigatorObserver {
  void _set(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name != null && name.isNotEmpty) {
      CrashReporting.setKey('screen', name);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _set(newRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _set(previousRoute);
}
