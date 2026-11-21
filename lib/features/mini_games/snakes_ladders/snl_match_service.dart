import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ludo/constants.dart';
import '../ludo/online/ludo_match.dart';
import 'snl_match.dart';

/// Firestore-backed Snakes & Ladders matches (`snl_matches/<id>`).
///
/// Rolls run in a transaction on the roller's device, so the dice can't be
/// replayed or raced, and every client animates the resulting [SnlMove].
class SnlMatchService {
  SnlMatchService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static const collection = 'snl_matches';

  final FirebaseFirestore _db;
  final Random _random = Random();

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(collection);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  LudoSeatInfo _me() {
    final user = Get.find<UserController>().user.value;
    final displayName = (user.name ?? '').trim();
    final gamerTag = (user.gameUserName ?? '').trim();
    final photo = (user.photoUrl ?? '').trim();
    return LudoSeatInfo(
      uid: _uid ?? '',
      name: displayName.isNotEmpty
          ? displayName
          : (gamerTag.isNotEmpty ? gamerTag : 'You'),
      photo: photo.isEmpty ? null : photo,
    );
  }

  Stream<SnlMatch?> watch(String matchId) {
    return _col.doc(matchId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return SnlMatch.fromMap(snap.id, data);
    });
  }

  static String inviteLink(String matchId) =>
      'hashforgamers://game/snlmatch_$matchId';

  /// Host creates a room and takes the first seat.
  Future<String> createMatch() async {
    final uid = _uid;
    if (uid == null) throw Exception('Please sign in to start a match.');
    final ref = _col.doc();
    await ref.set({
      'id': ref.id,
      'host_uid': uid,
      'status': 'waiting',
      'seats': {LudoPlayerType.green.name: _me().toMap()},
      'positions': {LudoPlayerType.green.name: 0},
      'turn': LudoPlayerType.green.name,
      'dice': 0,
      'winners': <String>[],
      'version': 0,
      'turn_started_at_ms': DateTime.now().millisecondsSinceEpoch,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Takes the first empty seat (or returns the existing one on rejoin).
  Future<LudoPlayerType> joinMatch(String matchId) async {
    final uid = _uid;
    if (uid == null) throw Exception('Please sign in to join.');
    final me = _me();
    final ref = _col.doc(matchId);
    return _db.runTransaction<LudoPlayerType>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw Exception('This room no longer exists.');
      }
      final match = SnlMatch.fromMap(snap.id, data);
      final existing = match.seatOf(uid);
      if (existing != null) return existing;
      if (match.status != LudoMatchStatus.waiting) {
        throw Exception('This match has already started.');
      }
      final seat = match.firstEmptySeat();
      if (seat == null) throw Exception('This room is full.');
      tx.update(ref, {
        'seats.${seat.name}': me.toMap(),
        'positions.${seat.name}': 0,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return seat;
    });
  }

  Future<void> startMatch(String matchId) async {
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) throw Exception('Room not found.');
      final match = SnlMatch.fromMap(snap.id, data);
      if (match.hostUid != _uid) throw Exception('Only the host can start.');
      if (match.seatCount < 2) throw Exception('Need at least 2 players.');
      tx.update(ref, {
        'status': 'active',
        'turn': match.occupiedSeats.first.name,
        'turn_started_at_ms': DateTime.now().millisecondsSinceEpoch,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Rolls for [seat]. Pass [expectedTurnStartedAt] when rolling on behalf of
  /// an idle player so two clients can't both force the same turn.
  Future<void> roll(
    String matchId,
    LudoPlayerType seat, {
    int? expectedTurnStartedAt,
  }) async {
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final match = SnlMatch.fromMap(snap.id, data);
      if (match.status != LudoMatchStatus.active || match.turn != seat) return;
      if (expectedTurnStartedAt != null &&
          match.turnStartedAtMs != expectedTurnStartedAt) {
        return;
      }

      final dice = 1 + _random.nextInt(6);
      final from = match.positions[seat] ?? 0;
      final result = snlApplyRoll(from, dice);
      final positions = {...match.positions, seat: result.to};
      final winners = [...match.winners];
      var status = 'active';

      if (result.to == kSnlGoal && !winners.contains(seat)) winners.add(seat);
      final stillPlaying = match.occupiedSeats
          .where((s) => !winners.contains(s))
          .toList();
      if (stillPlaying.length <= 1) {
        // Last one left takes the final place.
        winners.addAll(stillPlaying.where((s) => !winners.contains(s)));
        status = 'finished';
      }

      // A six rolls again (unless that roll won).
      final next = status == 'finished'
          ? seat
          : (dice == 6 && result.to != kSnlGoal)
          ? seat
          : _nextSeat(seat, stillPlaying);
      final now = DateTime.now().millisecondsSinceEpoch;

      tx.update(ref, {
        'positions': {for (final e in positions.entries) e.key.name: e.value},
        'dice': dice,
        'turn': next.name,
        'winners': winners.map((s) => s.name).toList(),
        'status': status,
        'last_move': SnlMove(
          seat: seat,
          dice: dice,
          from: from,
          landed: result.landed,
          to: result.to,
          id: now,
        ).toMap(),
        'turn_started_at_ms': now,
        'version': match.version + 1,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// A player quits: seat removed; last player standing wins.
  Future<void> leaveMatch(String matchId, LudoPlayerType seat) async {
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final match = SnlMatch.fromMap(snap.id, data);
      if (!match.seats.containsKey(seat)) return;

      final remaining = match.occupiedSeats.where((s) => s != seat).toList();
      final updates = <String, dynamic>{
        'seats.${seat.name}': FieldValue.delete(),
        'positions.${seat.name}': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      if (match.status == LudoMatchStatus.active) {
        final stillPlaying = remaining
            .where((s) => !match.winners.contains(s))
            .toList();
        final winners = match.winners.where((s) => s != seat).toList();
        if (stillPlaying.length <= 1) {
          winners.addAll(stillPlaying.where((s) => !winners.contains(s)));
          updates['winners'] = winners.map((s) => s.name).toList();
          updates['status'] = 'finished';
        } else if (match.turn == seat) {
          updates['turn'] = _nextSeat(seat, stillPlaying).name;
          updates['turn_started_at_ms'] = DateTime.now().millisecondsSinceEpoch;
        }
      } else if (match.status == LudoMatchStatus.waiting && remaining.isEmpty) {
        updates['status'] = 'cancelled';
      }
      tx.update(ref, updates);
    });
  }

  LudoPlayerType _nextSeat(LudoPlayerType from, List<LudoPlayerType> among) {
    if (among.isEmpty) return from;
    final start = kLudoSeatOrder.indexOf(from);
    for (var i = 1; i <= kLudoSeatOrder.length; i++) {
      final c = kLudoSeatOrder[(start + i) % kLudoSeatOrder.length];
      if (among.contains(c)) return c;
    }
    return among.first;
  }

  // Remember the room so an accidental back-out can rejoin it.
  static String _activeKey(String uid) => 'snl_active_match_$uid';

  Future<void> saveActiveMatch(String matchId) async {
    final uid = _uid;
    if (uid == null) return;
    (await SharedPreferences.getInstance()).setString(_activeKey(uid), matchId);
  }

  Future<void> clearActiveMatch([String? matchId]) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    if (matchId != null && prefs.getString(_activeKey(uid)) != matchId) return;
    await prefs.remove(_activeKey(uid));
  }

  Future<String?> activeMatchId() async {
    final uid = _uid;
    if (uid == null) return null;
    return (await SharedPreferences.getInstance()).getString(_activeKey(uid));
  }
}
