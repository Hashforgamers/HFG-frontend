import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../score/mini_game_score_service.dart';
import 'constants.dart';

/// Points are only available once this participant's placement is known.
int? ludoPlacementScore({
  required LudoPlayerType? seat,
  required List<LudoPlayerType> winners,
  required Set<LudoPlayerType> participants,
  required bool finished,
}) {
  if (seat == null || !participants.contains(seat) || participants.length < 2) {
    return null;
  }
  if (winners.toSet().length != winners.length ||
      !participants.containsAll(winners)) {
    return null;
  }
  final index = winners.indexOf(seat);
  if (index >= 0) return (4 - index) * 100;
  if (finished && winners.length == participants.length - 1) {
    return (5 - participants.length) * 100;
  }
  return null;
}

/// A per-account best-score outbox. Failed uploads stay on disk; submissions
/// are serialized so a slower upload cannot erase a newer, better result.
class LudoScoreService {
  LudoScoreService({
    required this.currentUid,
    required this.read,
    required this.write,
    required this.submit,
  });

  static final instance = LudoScoreService(
    currentUid: () => FirebaseAuth.instance.currentUser?.uid,
    read: (key) async =>
        (await SharedPreferences.getInstance()).getInt(key) ?? 0,
    write: (key, value) async {
      await (await SharedPreferences.getInstance()).setInt(key, value);
    },
    submit: (score) => MiniGameScoreService().recordScore('ludo', score),
  );

  final String? Function() currentUid;
  final Future<int> Function(String key) read;
  final Future<void> Function(String key, int value) write;
  final Future<bool> Function(int score) submit;
  Future<void> _tail = Future<void>.value();

  Future<bool> record(int score) => _enqueue(score);
  Future<bool> sync() => _enqueue(null);

  Future<bool> _enqueue(int? score) {
    final uid = currentUid();
    if (uid == null || uid.isEmpty) return Future.value(false);
    final operation = _tail
        .then((_) async {
          final bestKey = 'ludo_best_v1_$uid';
          final syncedKey = 'ludo_synced_v1_$uid';
          final best = max(await read(bestKey), score ?? 0);
          if (score != null) await write(bestKey, best);
          final synced = await read(syncedKey);
          if (best <= synced) return true;
          if (currentUid() != uid) return false;
          try {
            if (!await submit(best)) return false;
            await write(syncedKey, best);
            return true;
          } catch (_) {
            return false;
          }
        })
        .catchError((Object _) => false);
    _tail = operation.then<void>((_) {});
    return operation;
  }
}
