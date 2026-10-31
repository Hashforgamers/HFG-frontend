import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';

import 'bird_match.dart';

/// Firestore-backed Laggy Bird races (`bird_matches/<id>`).
class BirdMatchService {
  BirdMatchService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static const collection = 'bird_matches';

  /// Countdown between the host pressing Start and the round beginning.
  static const startDelayMs = 4000;

  final FirebaseFirestore _db;
  final Random _random = Random();

  /// Server clock minus local clock, measured on create/join.
  int serverOffsetMs = 0;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collection);

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  int get serverNowMs => DateTime.now().millisecondsSinceEpoch + serverOffsetMs;

  static String inviteLink(String matchId) =>
      'hashforgamers://game/birdmatch_$matchId';

  BirdPlayer _me(String skin) {
    final user = Get.find<UserController>().user.value;
    final displayName = (user.name ?? '').trim();
    final gamerTag = (user.gameUserName ?? '').trim();
    final photo = (user.photoUrl ?? '').trim();
    return BirdPlayer(
      uid: uid ?? '',
      name: gamerTag.isNotEmpty
          ? gamerTag
          : (displayName.isNotEmpty ? displayName : 'You'),
      photo: photo.isEmpty ? null : photo,
      skin: skin,
      joinedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Stream<BirdMatch?> watch(String matchId) {
    return _col.doc(matchId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return BirdMatch.fromMap(snap.id, data);
    });
  }

  Stream<Map<String, BirdRun>> watchRuns(String matchId, int round) {
    return _col
        .doc(matchId)
        .collection('runs')
        .where('round', isEqualTo: round)
        .snapshots()
        .map(
          (q) => {
            for (final d in q.docs)
              (d.data()['uid'] ?? '').toString(): BirdRun.fromMap(d.data()),
          },
        );
  }

  /// Estimates [serverOffsetMs] by stamping the room with a server time.
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

  Future<String> createMatch({
    required String skin,
    required String difficulty,
  }) async {
    final me = uid;
    if (me == null) throw Exception('Please sign in to race online.');
    final ref = _col.doc();
    await ref.set({
      'id': ref.id,
      'host_uid': me,
      'status': 'waiting',
      'players': {me: _me(skin).toMap()},
      'round': 0,
      'seed': 0,
      'difficulty': difficulty,
      'start_at_ms': 0,
      'results': <String, dynamic>{},
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    await _syncClock(ref);
    return ref.id;
  }

  /// Joins the room (or re-syncs on rejoin).
  Future<void> joinMatch(String matchId, {required String skin}) async {
    final me = uid;
    if (me == null) throw Exception('Please sign in to join.');
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw Exception('This race no longer exists.');
      }
      final match = BirdMatch.fromMap(snap.id, data);
      if (match.players.containsKey(me)) return;
      if (match.status == BirdMatchStatus.active) {
        throw Exception('This race is already flying. Try again next round.');
      }
      if (match.players.length >= BirdMatch.maxPlayers) {
        throw Exception('This race is full.');
      }
      tx.update(ref, {
        'players.$me': _me(skin).toMap(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
    await _syncClock(ref);
  }

  Future<void> setSkin(String matchId, String skin) async {
    final me = uid;
    if (me == null) return;
    await _col.doc(matchId).update({'players.$me.skin': skin});
  }

  /// Host starts a round: fresh course seed, synced start a few seconds out.
  Future<void> startRound(String matchId, {required String difficulty}) async {
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) throw Exception('Race not found.');
      final match = BirdMatch.fromMap(snap.id, data);
      if (match.hostUid != uid) throw Exception('Only the host can start.');
      if (match.players.length < 2) {
        throw Exception('Need at least 2 birds to race.');
      }
      if (match.status == BirdMatchStatus.active) return;
      tx.update(ref, {
        'status': 'active',
        'round': match.round + 1,
        'seed': _random.nextInt(1 << 31),
        'difficulty': difficulty,
        'start_at_ms': serverNowMs + startDelayMs,
        'results': <String, dynamic>{},
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _runRef(
    String matchId,
    int round,
    String who,
  ) => _col.doc(matchId).collection('runs').doc('${round}_$who');

  /// Appends flaps (run-time ms) to my run for [round].
  Future<void> pushFlaps(String matchId, int round, List<int> flaps) async {
    final me = uid;
    if (me == null || flaps.isEmpty) return;
    await _runRef(matchId, round, me).set({
      'uid': me,
      'round': round,
      'flaps': FieldValue.arrayUnion(flaps),
    }, SetOptions(merge: true));
  }

  /// Records my crash; the last bird down also closes the round.
  Future<void> reportCrash(
    String matchId, {
    required int round,
    required int score,
    required int deadAtMs,
    String? forUid,
  }) async {
    final who = forUid ?? uid;
    if (who == null) return;
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final match = BirdMatch.fromMap(snap.id, data);
      if (match.round != round || match.status != BirdMatchStatus.active) {
        return;
      }
      if (match.results.containsKey(who)) return;
      final done = {...match.results.keys, who};
      final allDone = match.players.keys.every(done.contains);
      tx.update(ref, {
        'results.$who': {'score': score, 'dead_at_ms': deadAtMs},
        if (allDone) 'status': 'finished',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Host sends everyone back to the lobby for another round.
  Future<void> backToLobby(String matchId) async {
    await _col.doc(matchId).update({
      'status': 'waiting',
      'results': <String, dynamic>{},
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Leaves the room. Mid-round this counts as a crash; the host role passes
  /// to the next player, and an empty room is deleted.
  Future<void> leaveMatch(String matchId, {int? score, int? deadAtMs}) async {
    final me = uid;
    if (me == null) return;
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final match = BirdMatch.fromMap(snap.id, data);
      if (!match.players.containsKey(me)) return;
      final remaining = match.ordered.where((p) => p.uid != me).toList();
      if (remaining.isEmpty) {
        tx.delete(ref);
        return;
      }
      final results = {...match.results}..remove(me);
      final allDone =
          match.status == BirdMatchStatus.active &&
          remaining.every((p) => results.containsKey(p.uid));
      tx.update(ref, {
        'players.$me': FieldValue.delete(),
        'results.$me': FieldValue.delete(),
        if (match.hostUid == me) 'host_uid': remaining.first.uid,
        if (allDone) 'status': 'finished',
        if (match.status == BirdMatchStatus.active &&
            remaining.length < 2 &&
            !allDone)
          'status': 'finished',
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }
}

/// Batches my flaps into at most ~5 writes per second.
class BirdFlapUploader {
  BirdFlapUploader(this._service, this.matchId, this.round);

  final BirdMatchService _service;
  final String matchId;
  final int round;
  final List<int> _pending = [];
  Timer? _timer;
  bool _closed = false;

  void add(int runMs) {
    if (_closed) return;
    _pending.add(runMs);
    _timer ??= Timer(const Duration(milliseconds: 180), _flush);
  }

  Future<void> _flush() async {
    _timer = null;
    if (_pending.isEmpty) return;
    final batch = List<int>.of(_pending);
    _pending.clear();
    try {
      await _service.pushFlaps(matchId, round, batch);
    } catch (_) {
      // Re-queue so a brief network blip doesn't lose flaps.
      if (!_closed) {
        _pending.insertAll(0, batch);
        _timer ??= Timer(const Duration(milliseconds: 400), _flush);
      }
    }
  }

  Future<void> close() async {
    _timer?.cancel();
    _timer = null;
    await _flush();
    _closed = true;
  }
}
