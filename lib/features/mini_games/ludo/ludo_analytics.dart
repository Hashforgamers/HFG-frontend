import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';

import 'online/ludo_match.dart';

/// Ludo's analytics events (`ludo_*`), sent through [AnalyticsService] so they
/// reach Firebase and Segment with identical snake_case names.
///
/// Spec notes:
/// - Booleans go out as the strings "true"/"false" (Firebase params accept
///   only text or numbers, and Segment's Firebase destination mangles bools).
/// - Spectators never send match start/end; they only send
///   `ludo_spectate_opened`.
/// - Every call is fire-and-forget and can never break gameplay.
abstract final class LudoAnalytics {
  static String _flag(bool v) => v ? 'true' : 'false';

  static void _log(
    String name,
    Map<String, Object?> params, {
    String? dedupeKey,
  }) {
    try {
      unawaited(
        locator<AnalyticsService>().log(
          name,
          parameters: params,
          deduplicationKey: dedupeKey,
        ),
      );
    } catch (_) {
      // Analytics not registered (tests) or unavailable: ignore.
    }
  }

  /// Online matches are `quick` or `friends`; local ones carry their own mode.
  static String onlineMode(LudoMatch m) => m.quick ? 'quick' : 'friends';

  static String errorCode(Object error) =>
      error is FirebaseException ? error.code : 'unknown';

  static void opened(String source) => _log('ludo_opened', {'source': source});

  static void modeSelected(String mode) =>
      _log('ludo_mode_selected', {'mode': mode});

  static void matchStart({
    required String matchId,
    required String mode,
    required int humans,
    required int bots,
    required bool quick,
  }) => _log('ludo_match_start', {
    'match_id': matchId,
    'mode': mode,
    'players': humans + bots,
    'humans': humans,
    'bots': bots,
    'quick': _flag(quick),
  }, dedupeKey: matchId);

  static void matchEnd({
    required String matchId,
    required String mode,
    String? result,
    int? position,
    int? points,
    required int humans,
    required int bots,
    required int durationSec,
    required int turns,
  }) => _log('ludo_match_end', {
    'match_id': matchId,
    'mode': mode,
    'result': result,
    'position': position,
    'points': points,
    'vs_bot': _flag(bots > 0),
    'humans': humans,
    'bots': bots,
    'duration_sec': durationSec,
    'turns': turns,
  }, dedupeKey: matchId);

  static void matchQuit({
    required String matchId,
    required String mode,
    required int turnNumber,
    required int durationSec,
    required String reason,
  }) => _log('ludo_match_quit', {
    'match_id': matchId,
    'mode': mode,
    'turn_number': turnNumber,
    'duration_sec': durationSec,
    'reason': reason,
  }, dedupeKey: matchId);

  static void botFilled({
    required String matchId,
    required String trigger,
    required int waitSec,
    required int bots,
  }) => _log('ludo_bot_filled', {
    'match_id': matchId,
    'trigger': trigger,
    'wait_sec': waitSec,
    'bots': bots,
  });

  static void roomCreated(String roomType) =>
      _log('ludo_room_created', {'room_type': roomType});

  static void roomCodeEntered({required bool found}) =>
      _log('ludo_room_code_entered', {'result': found ? 'found' : 'not_found'});

  static void inviteSent(String channel) =>
      _log('ludo_invite_sent', {'channel': channel});

  static void banner(String action, {required int waitSec, String? matchId}) =>
      _log(
        'ludo_banner_$action',
        {'wait_sec': waitSec},
        // One "shown" per waiting room, however often the banner rebuilds.
        dedupeKey: action == 'shown' ? matchId : null,
      );

  static void rematch({
    required bool requested,
    required bool vsBot,
    required int humans,
  }) => _log(requested ? 'ludo_rematch_requested' : 'ludo_rematch_joined', {
    'vs_bot': _flag(vsBot),
    'humans': humans,
  });

  static void resume(String source) => _log('ludo_resume', {'source': source});

  static void spectateOpened(String source) =>
      _log('ludo_spectate_opened', {'source': source});

  static void disconnect({
    required int turnNumber,
    required bool reconnected,
  }) => _log('ludo_disconnect', {
    'turn_number': turnNumber,
    'reconnected': _flag(reconnected),
  });

  static void syncFailed({
    required String stage,
    required Object error,
    int? attempt,
  }) => _log('ludo_sync_failed', {
    'error_code': errorCode(error),
    'stage': stage,
    if (attempt != null) 'attempt': attempt,
  });
}
