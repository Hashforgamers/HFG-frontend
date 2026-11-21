import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';

/// The funnel every arcade game shares (`arcade_game_*`), sent through
/// [AnalyticsService] so it reaches Firebase and Segment with identical names.
/// Game-specific funnels (LudoAnalytics, SuperOverAnalytics) sit on top of it.
///
/// - `arcade_game_opened`: the game's screen opened (one play session).
/// - `arcade_game_started`: a run / match / race began.
/// - `arcade_game_completed`: a run ended and its score was handed in.
/// - `arcade_game_closed`: the screen closed; `abandoned` says a run was left
///   unfinished.
///
/// Every event carries `game_id`, `source` and `session_id`, so games compare
/// on one set of names. Booleans go out as "true"/"false", as in
/// LudoAnalytics. Every call is fire-and-forget and can never break gameplay.
abstract final class ArcadeAnalytics {
  static const _defaultSource = 'home';
  static const _pendingSourceTtl = Duration(seconds: 10);

  static final Map<String, _Session> _sessions = {};
  static String? _pendingSource;
  static DateTime? _pendingSourceAt;

  static String _flag(bool v) => v ? 'true' : 'false';
  static String? _flagOrNull(bool? v) => v == null ? null : _flag(v);

  @visibleForTesting
  static void Function(String name, Map<String, Object?> params)? testSink;

  static void _log(String name, _Session s, Map<String, Object?> params) {
    final parameters = <String, Object?>{
      'game_id': s.gameId,
      'source': s.source,
      'session_id': s.id,
      ...params,
    };
    final sink = testSink;
    if (sink != null) return sink(name, parameters);
    try {
      unawaited(locator<AnalyticsService>().log(name, parameters: parameters));
    } catch (_) {
      // Analytics not registered (tests) or unavailable: ignore.
    }
  }

  /// Names where the next game is being opened from (leaderboard, chat, ...),
  /// for entry points that can't pass it to the screen. Call it right before
  /// navigating; it is used once and expires quickly.
  static void from(String source) {
    _pendingSource = source;
    _pendingSourceAt = DateTime.now();
  }

  static String? _takePendingSource() {
    final source = _pendingSource;
    final at = _pendingSourceAt;
    _pendingSource = null;
    _pendingSourceAt = null;
    if (source == null || at == null) return null;
    return DateTime.now().difference(at) > _pendingSourceTtl ? null : source;
  }

  // A run can start without the game's own screen having opened (a match
  // screen reached straight from an invite), so sessions are made on demand.
  static _Session _session(String gameId, {String? source}) =>
      _sessions[gameId] ??= _Session(
        gameId: gameId,
        source: _takePendingSource() ?? source ?? _defaultSource,
      );

  /// The game's screen opened.
  static void opened(String gameId, {String? source}) {
    _sessions.remove(gameId);
    _log('arcade_game_opened', _session(gameId, source: source), const {});
  }

  /// A run began. [mode] is `solo`, `online`, or the game's own mode name.
  /// With [ifIdle], a run that is already going is left alone - for games
  /// whose only start signal also fires on resume.
  static void started(
    String gameId, {
    String mode = 'solo',
    int? level,
    bool ifIdle = false,
  }) {
    final s = _session(gameId);
    if (ifIdle && s.runStartedAt != null) return;
    s
      ..runs += 1
      ..mode = mode
      ..runStartedAt = DateTime.now();
    _log('arcade_game_started', s, {
      'mode': mode,
      'run_no': s.runs,
      'level': level,
    });
  }

  /// A game page's `analytics` message, when it marks a run's start or end.
  ///
  /// - Start: `started` (Super Over) or `<game_id>_game_start` (Hash Rush). A
  ///   paid continue (`continued: true`) carries on the same run.
  /// - End: `<game_id>_level_failed`. A lost level hands in no score, so this
  ///   is its only end signal. Won levels and endless runs do hand one in and
  ///   are reported from there.
  static void fromWeb(String gameId, Object? payload) {
    if (payload is! Map) return;
    final event = payload['event'];
    final raw = payload['params'];
    final params = raw is Map ? raw : const {};
    final mode = params['mode'];
    if (event == 'started' || event == '${gameId}_game_start') {
      if (params['continued'] == true) return;
      final level = params['level'];
      started(
        gameId,
        mode: mode is String && mode.isNotEmpty ? mode : 'solo',
        level: level is num ? level.toInt() : null,
      );
    } else if (event == '${gameId}_level_failed' && mode != 'endless') {
      final score = params['score'];
      completed(gameId, score: score is num ? score.toInt() : 0);
    }
  }

  /// Whether [gameId] has a play session open.
  static bool isOpen(String gameId) => _sessions.containsKey(gameId);

  /// A run ended. [synced], [isNewBest] and [rank] are the leaderboard's
  /// answer, when the score was handed in.
  static void completed(
    String gameId, {
    required int score,
    bool? synced,
    bool? isNewBest,
    int? rank,
    Future<ArcadeScoreOutcome?>? outcome,
  }) {
    final s = _session(gameId);
    final startedAt = s.runStartedAt;
    final runNo = startedAt == null ? s.runs + 1 : s.runs;
    final mode = s.mode;
    final durationSec = startedAt == null
        ? null
        : DateTime.now().difference(startedAt).inSeconds;
    // Games with no start signal (most HTML games) still count their runs.
    if (startedAt == null) s.runs += 1;
    s
      ..completedRuns += 1
      ..runStartedAt = null;
    // The run is closed above, before any wait: [outcome] is for games whose
    // leaderboard answer arrives after the match ends (Ludo).
    void send(ArcadeScoreOutcome? o) => _log('arcade_game_completed', s, {
      'mode': mode,
      'run_no': runNo,
      'score': score,
      'duration_sec': durationSec,
      'synced': _flagOrNull(o?.synced ?? synced),
      'is_new_best': _flagOrNull(o?.isNewBest ?? isNewBest),
      'rank': o?.rank ?? rank,
    });
    if (outcome == null) return send(null);
    unawaited(
      outcome
          .timeout(const Duration(seconds: 10))
          .then<ArcadeScoreOutcome?>((o) => o, onError: (_) => null)
          .then(send),
    );
  }

  /// The game's screen closed.
  static void closed(String gameId) {
    final s = _sessions.remove(gameId);
    if (s == null) return;
    _log('arcade_game_closed', s, {
      'session_sec': DateTime.now().difference(s.openedAt).inSeconds,
      'runs': s.runs,
      'completed_runs': s.completedRuns,
      'abandoned': _flag(s.runStartedAt != null),
    });
  }

  @visibleForTesting
  static void resetForTest() {
    _sessions.clear();
    testSink = null;
    _pendingSource = null;
    _pendingSourceAt = null;
  }
}

/// The leaderboard's answer to a finished run.
typedef ArcadeScoreOutcome = ({bool synced, bool? isNewBest, int? rank});

class _Session {
  _Session({required this.gameId, required this.source});

  final String gameId;
  final String source;
  final String id = '${DateTime.now().microsecondsSinceEpoch}';
  final DateTime openedAt = DateTime.now();
  int runs = 0;
  int completedRuns = 0;
  String? mode;
  DateTime? runStartedAt;
}
