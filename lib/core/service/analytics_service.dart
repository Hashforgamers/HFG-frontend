import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

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
  AnalyticsService({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;
  final Set<String> _sessionDeduplicationKeys = <String>{};

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

    final safe = sanitizeParameters(parameters);
    debugPrint('[Analytics] $name $safe');
    await _analytics.logEvent(name: name, parameters: safe);
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
        if (trimmed.isNotEmpty) safe[entry.key] = trimmed;
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
