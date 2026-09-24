import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import 'ludo_match.dart';

/// Firestore-backed store for real-time Ludo matches (`ludo_matches/<id>`).
///
/// The match doc is the single source of truth. Every device streams it; the
/// device whose seat matches `turn` is the authoritative writer for that turn.
/// Turn ownership is also enforced by Firestore security rules (see the rules
/// shipped alongside this feature) so a client can only write when it is their
/// turn or when joining an empty seat.
class LudoMatchService {
  LudoMatchService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('ludo_matches');

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  List<int> _freshPawns() => List<int>.filled(4, -1);

  LudoSeatInfo _me() {
    final user = Get.find<UserController>().user.value;
    final displayName = (user.name ?? '').trim();
    final gamerTag = (user.gameUserName ?? '').trim();
    final photo = (user.photoUrl ?? '').trim();
    final name = displayName.isNotEmpty
        ? displayName
        : (gamerTag.isNotEmpty ? gamerTag : 'You');
    return LudoSeatInfo(
      uid: _uid ?? '',
      name: name,
      photo: photo.isEmpty ? null : photo,
    );
  }

  Stream<LudoMatch?> watch(String matchId) {
    return _col.doc(matchId).snapshots().map((snap) {
      final data = snap.data();
      if (!snap.exists || data == null) return null;
      return LudoMatch.fromMap(snap.id, data);
    });
  }

  Future<LudoMatch?> fetch(String matchId) async {
    final snap = await _col.doc(matchId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return LudoMatch.fromMap(snap.id, data);
  }

  /// Host creates a match and takes the green seat.
  Future<LudoMatch> createMatch({List<String> invitedUids = const []}) async {
    final uid = _uid;
    if (uid == null) {
      throw Exception('Please sign in to start a match.');
    }
    final ref = _col.doc();
    final host = _me();
    final match = LudoMatch(
      id: ref.id,
      hostUid: uid,
      status: LudoMatchStatus.waiting,
      seats: {LudoPlayerType.green: host},
      invitedUids: invitedUids,
      turn: LudoPlayerType.green,
      dice: 1,
      winners: const [],
      pawns: {LudoPlayerType.green: _freshPawns()},
      lastWriterUid: uid,
      version: 0,
      turnStartedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await ref.set({
      ...match.toMap(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    debugPrint(
      '[LudoMatch] created ${ref.id} | join: hashforgamers://game/ludomatch_${ref.id}',
    );
    return match;
  }

  /// Shareable deep link that opens this match's lobby.
  static String inviteLink(String matchId) =>
      'hashforgamers://game/ludomatch_$matchId';

  /// Join the first empty seat (or a specific one) transactionally.
  Future<LudoPlayerType> joinMatch(String matchId, {LudoPlayerType? seat}) async {
    final uid = _uid;
    if (uid == null) throw Exception('Please sign in to join.');
    final me = _me();
    final ref = _col.doc(matchId);

    return _db.runTransaction<LudoPlayerType>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw Exception('This match no longer exists.');
      }
      final match = LudoMatch.fromMap(snap.id, data);

      // Already seated? Return existing seat (rejoin).
      final existing = match.seatOf(uid);
      if (existing != null) return existing;

      if (match.status != LudoMatchStatus.waiting) {
        throw Exception('This match has already started.');
      }
      if (match.isFull) {
        throw Exception('This match is full.');
      }

      final target =
          (seat != null && !match.seats.containsKey(seat)) ? seat : match.firstEmptySeat();
      if (target == null) throw Exception('No seats available.');

      tx.update(ref, {
        'seats.${target.name}': me.toMap(),
        'pawns.${target.name}': _freshPawns(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return target;
    });
  }

  /// Host flips the match to active (needs at least 2 seats).
  Future<void> startMatch(String matchId) async {
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) throw Exception('Match not found.');
      final match = LudoMatch.fromMap(snap.id, data);
      if (match.hostUid != _uid) throw Exception('Only the host can start.');
      if (match.seatCount < 2) throw Exception('Need at least 2 players.');
      tx.update(ref, {
        'status': statusToString(LudoMatchStatus.active),
        'turn': match.occupiedSeats.first.name,
        'turn_started_at_ms': DateTime.now().millisecondsSinceEpoch,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Authoritative state write after a local turn resolves. Callers must only
  /// invoke this when it is their turn (the provider enforces this).
  Future<void> writeState(
    String matchId, {
    required LudoPlayerType turn,
    required int dice,
    required List<LudoPlayerType> winners,
    required Map<LudoPlayerType, List<int>> pawns,
    required int version,
    LudoMatchStatus? status,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await _col.doc(matchId).update({
      'turn': turn.name,
      'dice': dice,
      'winners': winners.map((e) => e.name).toList(),
      'pawns': {for (final e in pawns.entries) e.key.name: e.value},
      'last_writer_uid': uid,
      'version': version,
      'turn_started_at_ms': DateTime.now().millisecondsSinceEpoch,
      if (status != null) 'status': statusToString(status),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelMatch(String matchId) async {
    await _col.doc(matchId).update({
      'status': statusToString(LudoMatchStatus.cancelled),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // --- Active-match memory so a player can rejoin a room they accidentally
  // backed out of. Keyed per user. ---

  static String _activeKey(String uid) => 'ludo_active_match_$uid';

  Future<void> saveActiveMatch(String matchId) async {
    final uid = _uid;
    if (uid == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeKey(uid), matchId);
  }

  /// Clears the remembered match. If [matchId] is given, only clears when it
  /// matches (so a newer match isn't wiped by a stale screen tearing down).
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeKey(uid));
  }
}
