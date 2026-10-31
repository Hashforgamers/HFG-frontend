import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';

/// Super Over's funnel events (`super_over_*`), sent through [AnalyticsService]
/// so they reach Firebase and Segment with identical snake_case names.
///
/// - Every event carries `game_id`, `source` and `session_id` (one per time the
///   game screen is opened). The user is identified by [AnalyticsService]'s
///   `setUserId`, so no `user_id` param is sent.
/// - Gameplay events (`started`, `ball_played`, `completed`, `replay_tapped`)
///   come from the game itself over the web view's `analytics` handler and are
///   whitelisted by [mapWebEvent].
/// - Bookings are attributed to Super Over when the player played it earlier
///   in this app session (or tapped its book CTA); otherwise they are ignored.
/// - Booleans go out as the strings "true"/"false", as in LudoAnalytics.
/// - Every call is fire-and-forget and can never break gameplay.
abstract final class SuperOverAnalytics {
  static const gameId = 'super_over';

  /// Where the game was opened from.
  static const sources = {
    'home',
    'notification',
    'mini_games',
    'leaderboard',
    'deep_link',
  };

  static String _source = 'mini_games';
  static String? _sessionId;
  static DateTime? _lastPlayedAt;
  static bool _ctaTapped = false;

  static String _flag(bool v) => v ? 'true' : 'false';

  static Map<String, Object?> _base() => {
    'game_id': gameId,
    'source': _source,
    'session_id': _sessionId,
  };

  static void _log(
    String name,
    Map<String, Object?> params, {
    String? dedupeKey,
  }) {
    try {
      unawaited(
        locator<AnalyticsService>().log(
          name,
          parameters: {..._base(), ...params},
          deduplicationKey: dedupeKey,
        ),
      );
    } catch (_) {
      // Analytics not registered (tests) or unavailable: ignore.
    }
  }

  /// The game screen opened: starts a new play session.
  static void opened({required String source}) {
    _source = sources.contains(source) ? source : 'mini_games';
    _sessionId = '${DateTime.now().microsecondsSinceEpoch}';
    _log(AnalyticsEvent.superOverOpened, const {});
  }

  /// Opened from a push notification or a deep link. Not wired yet: the app
  /// has no route that opens Super Over from either.
  static void deeplinkLanded({required String source}) {
    opened(source: source);
    _log(AnalyticsEvent.superOverDeeplinkLanded, const {});
  }

  /// An event posted by the game page: `{event, params}`.
  static void fromWeb(Object? payload) {
    final mapped = mapWebEvent(payload);
    if (mapped == null) return;
    if (mapped.name == AnalyticsEvent.superOverStarted) {
      _lastPlayedAt = DateTime.now();
    }
    _log(mapped.name, mapped.params);
  }

  static const _webEvents = {
    'started': AnalyticsEvent.superOverStarted,
    'ball_played': AnalyticsEvent.superOverBallPlayed,
    'completed': AnalyticsEvent.superOverCompleted,
    'replay_tapped': AnalyticsEvent.superOverReplayTapped,
  };

  static const _webParams = {
    'mode',
    'difficulty',
    'run_id',
    'is_replay',
    'role',
    'ball_no',
    'balls_played',
    'runs',
    'wickets',
    'outcome',
    'score',
    'target',
    'result',
    'is_special',
  };

  /// Whitelists what the web page may log: known events only, known params
  /// only, and only plain text, numbers or booleans. Anything else is dropped.
  @visibleForTesting
  static ({String name, Map<String, Object?> params})? mapWebEvent(
    Object? payload,
  ) {
    if (payload is! Map) return null;
    final name = _webEvents[payload['event']];
    if (name == null) return null;
    final raw = payload['params'];
    final params = <String, Object?>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || !_webParams.contains(key)) continue;
        if (value is bool) {
          params[key] = _flag(value);
        } else if (value is num && value.isFinite) {
          params[key] = value;
        } else if (value is String && value.isNotEmpty) {
          params[key] = value.length > 40 ? value.substring(0, 40) : value;
        }
      }
    }
    return (name: name, params: params);
  }

  static void scoreSubmitted({
    required String status,
    int? score,
    int? ballsPlayed,
    int? rank,
    int? previousBest,
    bool? isNewBest,
    String? runId,
  }) => _log(AnalyticsEvent.superOverScoreSubmitted, {
    'status': status,
    'score': score,
    'balls_played': ballsPlayed,
    'rank': rank,
    'previous_best': previousBest,
    'is_new_best': isNewBest == null ? null : _flag(isNewBest),
    'run_id': runId,
  }, dedupeKey: runId);

  static void leaderboardViewed({required String source}) =>
      _log(AnalyticsEvent.superOverLeaderboardViewed, {'source': source});

  /// For the book-a-console CTA once one exists in the Super Over flow.
  static void bookCtaViewed({required String placement}) =>
      _log(AnalyticsEvent.superOverBookCtaViewed, {'placement': placement});

  static void bookCtaTapped({required String placement}) {
    _ctaTapped = true;
    _log(AnalyticsEvent.superOverBookCtaTapped, {'placement': placement});
  }

  /// Null when this booking isn't attributable to Super Over.
  static Map<String, Object?>? _attribution() {
    final played = _lastPlayedAt;
    if (!_ctaTapped && played == null) return null;
    return {
      'attribution': _ctaTapped ? 'book_cta' : 'played_this_session',
      'minutes_since_play': played == null
          ? null
          : DateTime.now().difference(played).inMinutes,
    };
  }

  static void bookingStarted({
    required String bookingId,
    String? venueId,
    String? slotId,
  }) {
    final attribution = _attribution();
    if (attribution == null) return;
    _log(AnalyticsEvent.superOverBookingStarted, {
      ...attribution,
      'booking_id': bookingId,
      'venue_id': venueId,
      'slot_id': slotId,
    }, dedupeKey: bookingId);
  }

  static void bookingConfirmed({
    required String bookingId,
    String? venueId,
    String? slotId,
    num? value,
  }) {
    final attribution = _attribution();
    if (attribution == null) return;
    _log(AnalyticsEvent.superOverBookingConfirmed, {
      ...attribution,
      'booking_id': bookingId,
      'venue_id': venueId,
      'slot_id': slotId,
      'value': value,
      'currency': value == null ? null : 'INR',
    }, dedupeKey: bookingId);
  }

  @visibleForTesting
  static void resetForTest() {
    _source = 'mini_games';
    _sessionId = null;
    _lastPlayedAt = null;
    _ctaTapped = false;
  }

  @visibleForTesting
  static void markPlayedForTest() => _lastPlayedAt = DateTime.now();

  @visibleForTesting
  static Map<String, Object?>? attributionForTest() => _attribution();
}
