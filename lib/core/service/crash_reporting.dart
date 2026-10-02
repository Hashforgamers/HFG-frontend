import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Wires Firebase Crashlytics and Performance Monitoring. Call once, right
/// after `Firebase.initializeApp`.
///
/// Both stay off in debug builds so local development doesn't pollute the
/// dashboards. Build with `--dart-define=FIREBASE_MONITORING_IN_DEBUG=true`
/// to test them from a debug build.
abstract final class CrashReporting {
  static const bool _forceInDebug = bool.fromEnvironment(
    'FIREBASE_MONITORING_IN_DEBUG',
  );

  static bool get enabled => !kDebugMode || _forceInDebug;

  static StreamSubscription<User?>? _authSub;

  static Future<void> init({required String flavor}) async {
    final crashlytics = FirebaseCrashlytics.instance;
    try {
      await crashlytics.setCrashlyticsCollectionEnabled(enabled);
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        enabled,
      );
      await crashlytics.setCustomKey('flavor', flavor);
    } catch (e) {
      // Monitoring must never stop the app from starting.
      debugPrint('[CrashReporting] init failed: $e');
      return;
    }

    // Errors thrown inside the Flutter framework (build, layout, paint...).
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      if (enabled) crashlytics.recordFlutterFatalError(details);
    };

    // Uncaught async errors that never reach the framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      if (enabled) crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    // Tag reports with the Firebase uid (never email/name) so a crash can be
    // matched to a support ticket. Cleared on sign-out.
    await _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      unawaited(crashlytics.setUserIdentifier(user?.uid ?? ''));
    });
  }

  /// Report a caught error that was handled but still worth knowing about.
  static void recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) {
    if (!enabled) return;
    unawaited(
      FirebaseCrashlytics.instance.recordError(error, stack, reason: reason),
    );
  }
}
