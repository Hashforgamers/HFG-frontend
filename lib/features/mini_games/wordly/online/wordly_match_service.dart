import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';

import 'wordly_match.dart';

/// Firestore-backed Wordly races (`wordly_matches/<id>`).
class WordlyMatchService {
  WordlyMatchService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static const collection = 'wordly_matches';
  static const startDelayMs = 3500;

  final FirebaseFirestore _db;
  final Random _random = Random();

  /// Server clock minus local clock, measured on create/join.
  int serverOffsetMs = 0;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collection);

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  int get serverNowMs => DateTime.now().millisecondsSinceEpoch + serverOffsetMs;

  static String inviteLink(String matchId) =>
      'hashforgamers://game/wordlymatch_$matchId';

  WordlyPlayer _me() {
    final user = Get.find<UserController>().user.value;
    final displayName = (user.name ?? '').trim();
    final gamerTag = (user.gameUserName ?? '').trim();
    final photo = (user.photoUrl ?? '').trim();
    return WordlyPlayer(
      uid: uid ?? '',
      name: gamerTag.isNotEmpty
          ? gamerTag
          : (displayName.isNotEmpty ? displayName : 'You'),
      photo: photo.isEmpty ? null : photo,
      joinedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Stream<WordlyMatch?> watch(String matchId) {
    return _col.doc(matchId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return WordlyMatch.fromMap(snap.id, data);
    });
  }

  Future<void> _syncClock(DocumentReference<Map<String, dynamic>> ref) async {
    final me = uid;
    if (me == null) return;
    try {
      final before = DateTime.now().millisecondsSinceEpoch;
      await ref.update({'clock.$me': FieldValue.serverTimestamp()});
      final snap = await ref.get(const GetOptions(source: Source.server));
      final after = DateTime.now().millisecondsSinceEpoch;
      final stamp = (snap.data()?['clock'] as Map?)?[me];
      if (stamp is Timestamp) {
        serverOffsetMs = stamp.millisecondsSinceEpoch - (before + after) ~/ 2;
      }
    } catch (_) {
      serverOffsetMs = 0;
    }
  }

  Future<String> createMatch() async {
    final me = uid;
    if (me == null) throw Exception('Please sign in to race online.');
    final ref = _col.doc();
    await ref.set({
      'id': ref.id,
      'host_uid': me,
      'status': 'waiting',
      'players': {me: _me().toMap()},
      'round': 0,
      'word_index': 0,
      'start_at_ms': 0,
      'progress': <String, dynamic>{},
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    await _syncClock(ref);
    return ref.id;
  }

  Future<void> joinMatch(String matchId) async {
    final me = uid;
    if (me == null) throw Exception('Please sign in to join.');
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw Exception('This race no longer exists.');
      }
      final match = WordlyMatch.fromMap(snap.id, data);
      if (match.players.containsKey(me)) return;
      if (match.status == WordlyMatchStatus.active) {
        throw Exception('This round already started. Try the next one.');
      }
      if (match.players.length >= WordlyMatch.maxPlayers) {
        throw Exception('This race is full.');
      }
      tx.update(ref, {
        'players.$me': _me().toMap(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
    await _syncClock(ref);
  }

  /// Host starts a round with a fresh word.
  Future<void> startRound(String matchId, {required int wordCount}) async {
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) throw Exception('Race not found.');
      final match = WordlyMatch.fromMap(snap.id, data);
      if (match.hostUid != uid) throw Exception('Only the host can start.');
      if (match.players.length < 2) {
        throw Exception('Need at least 2 players.');
      }
      if (match.status == WordlyMatchStatus.active) return;
      tx.update(ref, {
        'status': 'active',
        'round': match.round + 1,
        'word_index': _random.nextInt(wordCount),
        'start_at_ms': serverNowMs + startDelayMs,
        'progress': <String, dynamic>{},
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Publishes my board; the last board to finish closes the round.
  Future<void> submitProgress(
    String matchId, {
    required int round,
    required WordlyProgress progress,
  }) async {
    final me = uid;
    if (me == null) return;
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final match = WordlyMatch.fromMap(snap.id, data);
      if (match.round != round || match.status != WordlyMatchStatus.active) {
        return;
      }
      final all = {...match.progress, me: progress};
      final allDone = match.players.keys.every((u) => all[u]?.done == true);
      tx.update(ref, {
        'progress.$me': progress.toMap(),
        if (allDone) 'status': 'finished',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Anyone may close a round once its timer has run out.
  Future<void> closeIfExpired(String matchId, int round) async {
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final match = WordlyMatch.fromMap(snap.id, data);
      if (match.round != round || match.status != WordlyMatchStatus.active) {
        return;
      }
      if (serverNowMs < match.endAtMs) return;
      tx.update(ref, {
        'status': 'finished',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> backToLobby(String matchId) async {
    await _col.doc(matchId).update({
      'status': 'waiting',
      'progress': <String, dynamic>{},
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveMatch(String matchId) async {
    final me = uid;
    if (me == null) return;
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final match = WordlyMatch.fromMap(snap.id, data);
      if (!match.players.containsKey(me)) return;
      final remaining = match.ordered.where((p) => p.uid != me).toList();
      if (remaining.isEmpty) {
        tx.delete(ref);
        return;
      }
      final active = match.status == WordlyMatchStatus.active;
      final allDone = remaining.every((p) => match.progressOf(p.uid).done);
      tx.update(ref, {
        'players.$me': FieldValue.delete(),
        'progress.$me': FieldValue.delete(),
        if (match.hostUid == me) 'host_uid': remaining.first.uid,
        if (active && (allDone || remaining.length < 2)) 'status': 'finished',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
}
