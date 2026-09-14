import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AnalyticsSink =
    Future<void> Function(String name, Map<String, dynamic> parameters);

abstract final class AnalyticsEvent {
  static const onboardingStarted = 'onboarding_started';
  static const gameSelected = 'game_selected';
  static const citySelected = 'city_selected';
  static const signUp = 'sign_up';
  static const login = 'login';
  static const tournamentListViewed = 'tournament_list_viewed';
  static const tournamentViewed = 'tournament_viewed';
  static const tournamentJoinStarted = 'tournament_join_started';
  static const teamCreated = 'team_created';
  static const freeAgentSelected = 'free_agent_selected';
  static const paymentStarted = 'payment_started';
  static const paymentSuccess = 'payment_success';
  static const paymentFailed = 'payment_failed';
  static const tournamentJoined = 'tournament_joined';
  static const matchCheckedIn = 'match_checked_in';
  static const resultViewed = 'result_viewed';
  static const hostVerificationStarted = 'host_verification_started';
  static const hostVerificationSubmitted = 'host_verification_submitted';
  static const tournamentCreated = 'tournament_created';
  static const tournamentPublished = 'tournament_published';
}

/// Firebase Analytics facade for HASH's product and tournament journey.
///
/// Call this service from controllers after an action is confirmed. Widget
/// `build` methods must never emit analytics events.
class AnalyticsService {
  AnalyticsService({
    FirebaseAnalytics? analytics,
    SharedPreferences? preferences,
    AnalyticsSink? segmentSink,
    AnalyticsSink? metaSink,
  }) : _analytics = analytics ?? FirebaseAnalytics.instance,
       _preferences = preferences,
       _segmentSink = segmentSink,
       _metaSink = metaSink;

  final FirebaseAnalytics _analytics;
  SharedPreferences? _preferences;
  PackageInfo? _packageInfo;
  final AnalyticsSink? _segmentSink;
  final AnalyticsSink? _metaSink;
  /// Regenerated on every cold start: this identifies one app session, and is
  /// deliberately never persisted. Use [_installId] for a stable device key.
  static final String _launchSessionId =
      '${DateTime.now().microsecondsSinceEpoch}';
  String? _installId;
  bool _migratedLegacySessionKey = false;
  String? _currentScreen;
  String? _previousScreen;
  final Set<String> _sessionDeduplicationKeys = <String>{};
  static const _metaConversionEvents = {
    'signup_completed',
    'tournament_registration_completed',
    'tournament_payment_completed',
    'tournament_joined',
    'booking_completed',
    'host_verification_submitted',
    'tournament_created',
  };

  /// Firebase Analytics caps events at 25 parameters, and string values at 100
  /// characters. Anything over either limit is dropped server-side without a
  /// warning, so trim locally where we can still choose what to keep.
  static const int _maxParameters = 25;
  static const int _maxParameterValueLength = 100;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  static const Set<String> _blockedParameterKeys = {
    'email',
    'phone',
    'phone_number',
    'mobile',
    'mobile_number',
    'name',
    'full_name',
    'government_id',
    'gov_id',
    'upi_id',
    'address',
  };

  Future<void> log(
    String name, {
    Map<String, Object?> parameters = const {},
    String? deduplicationKey,
  }) async {
    final dedupe = deduplicationKey == null ? null : '$name:$deduplicationKey';
    if (dedupe != null && !_sessionDeduplicationKeys.add(dedupe)) return;

    assert(
      RegExp(r'^[a-z][a-z0-9_]{0,39}$').hasMatch(name),
      'Analytics events must use lower_snake_case',
    );

    // Analytics is never allowed to break the flow that emitted it. Callers
    // await `log` from inside payment and registration paths, so every failure
    // below - SDK, network or plugin - is swallowed rather than rethrown.
    try {
      final safe = mergeParameters(
        caller: sanitizeParameters(parameters),
        standard: sanitizeParameters(await _standardParameters()),
      );
      debugPrint('[Analytics] $name $safe');
      await _analytics.logEvent(name: name, parameters: safe);
      _fanOutToProviders(name, safe);
    } catch (error, stackTrace) {
      debugPrint('[Analytics] failed to log $name: $error');
      debugPrint('$stackTrace');
    }
  }

  /// Forwards to Segment/Meta without blocking the caller. These are best
  /// effort: a slow or failing provider must not add latency to a checkout.
  void _fanOutToProviders(String name, Map<String, Object> safe) {
    final providerPayload = Map<String, dynamic>.from(safe);
    void send(AnalyticsSink? sink) {
      if (sink == null) return;
      unawaited(
        Future<void>(() => sink(name, providerPayload)).catchError((
          Object error,
        ) {
          debugPrint('[Analytics] provider rejected $name: $error');
        }),
      );
    }

    send(_segmentSink);
    if (_metaConversionEvents.contains(name)) send(_metaSink);
  }

  /// Caller parameters are the reason the event exists, so they claim the
  /// budget first; standard parameters fill whatever slots are left.
  @visibleForTesting
  static Map<String, Object> mergeParameters({
    required Map<String, Object> caller,
    required Map<String, Object> standard,
  }) {
    assert(
      caller.length <= _maxParameters,
      'Analytics events may carry at most $_maxParameters parameters',
    );
    final safe = <String, Object>{};
    for (final entry in caller.entries) {
      if (safe.length >= _maxParameters) break;
      safe[entry.key] = entry.value;
    }
    for (final entry in standard.entries) {
      if (safe.length >= _maxParameters) break;
      safe.putIfAbsent(entry.key, () => entry.value);
    }
    return safe;
  }

  Future<Map<String, Object?>> _standardParameters() async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    if (!_migratedLegacySessionKey) {
      _migratedLegacySessionKey = true;
      // Previously this key held a value that was persisted forever, making it
      // an install id under a session id's name. Drop the stale entry.
      await prefs.remove('hash_session_id');
    }
    _installId ??= prefs.getString('hash_install_id');
    if ((_installId ?? '').isEmpty) {
      _installId = '${DateTime.now().microsecondsSinceEpoch}';
      await prefs.setString('hash_install_id', _installId!);
    }
    return {
      'hash_session_id': _launchSessionId,
      'hash_install_id': _installId,
      'platform': defaultTargetPlatform.name,
      'app_version': _packageInfo!.version,
      'build_number': _packageInfo!.buildNumber,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'screen_name': _currentScreen,
      'previous_screen': _previousScreen,
      'is_logged_in': prefs.getBool('isLoggedIn') == true,
    };
  }

  Future<void> trackScreen(String screenName) async {
    final normalized = screenName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (normalized.isEmpty || normalized == _currentScreen) return;
    _previousScreen = _currentScreen;
    _currentScreen = normalized;
    try {
      await _analytics.logScreenView(screenName: normalized);
    } catch (error) {
      debugPrint('[Analytics] failed to log screen $normalized: $error');
    }
  }

  @visibleForTesting
  static Map<String, Object> sanitizeParameters(
    Map<String, Object?> parameters,
  ) {
    final safe = <String, Object>{};
    for (final entry in parameters.entries) {
      if (_blockedParameterKeys.contains(entry.key) || entry.value == null) {
        continue;
      }
      final value = entry.value;
      if (value is String) {
        final trimmed = value.trim();
        if (trimmed.isEmpty) continue;
        safe[entry.key] = trimmed.length > _maxParameterValueLength
            ? trimmed.substring(0, _maxParameterValueLength)
            : trimmed;
      } else if (value is num) {
        safe[entry.key] = value;
      } else if (value is bool) {
        safe[entry.key] = value ? 1 : 0;
      }
    }
    return safe;
  }

  Future<void> setAuthenticatedUser(String userId) async {
    final value = userId.trim();
    if (value.isEmpty) return;
    await _analytics.setUserId(id: value);
  }

  Future<void> clearAuthenticatedUser() => _analytics.setUserId(id: null);

  Future<void> setUserProperties({
    String? primaryGame,
    String? userRole,
    String? city,
    String? skillTier,
    String? appLanguage,
    String? acquisitionSource,
  }) async {
    final values = <String, String?>{
      'primary_game': primaryGame,
      'user_role': userRole,
      'city': city,
      'skill_tier': skillTier,
      'app_language': appLanguage,
      'acquisition_source': acquisitionSource,
    };
    for (final entry in values.entries) {
      final value = entry.value?.trim();
      if (value != null && value.isNotEmpty) {
        await _analytics.setUserProperty(name: entry.key, value: value);
      }
    }
  }

  static String normalizeFailureReason(Object? error) {
    final raw = error?.toString().toLowerCase() ?? '';
    if (raw.contains('cancel')) return 'user_cancelled';
    if (raw.contains('timeout')) return 'timeout';
    if (raw.contains('network') || raw.contains('socket')) {
      return 'network_error';
    }
    if (raw.contains('declin')) return 'payment_declined';
    if (raw.contains('insufficient')) return 'insufficient_funds';
    if (raw.contains('confirm')) return 'confirmation_failed';
    return 'unknown';
  }
}
