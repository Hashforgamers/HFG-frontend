import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../ludo_analytics.dart';
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

  /// Quick Match rooms wait this long for a real opponent before a bot takes
  /// the empty seat and the match starts.
  static const int quickFillSeconds = 15;

  /// Quick Match rooms older than this are treated as abandoned: they're no
  /// longer offered to new players and are closed when found.
  static const int quickStaleMs = 2 * 60 * 1000;

  /// If the host's device never auto-starts a Quick Match room (backgrounded,
  /// lost signal), any seated player may start it after this long.
  static const int quickStartFallbackMs = (quickFillSeconds + 10) * 1000;

  // No 0/O/1/I/L so codes read unambiguously over a call or in a chat.
  static const String _codeAlphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;

  static const List<String> _femaleBotNames = [
    'Ananya',
    'Priya',
    'Sneha',
    'Diya',
    'Meera',
    'Riya',
    'Kavya',
    'Nisha',
    'Pooja',
    'Tanvi',
    'Zoya',
    'Aisha',
    'Ishita',
    'Neha',
    'Simran',
    'Shreya',
    'Aditi',
    'Khushi',
    'Sanya',
    'Naina',
    'Ira',
    'Myra',
    'Saanvi',
    'Anika',
  ];
  static const List<String> _maleBotNames = [
    'Aarav',
    'Rohan',
    'Ishaan',
    'Kabir',
    'Vihaan',
    'Arjun',
    'Aditya',
    'Karan',
    'Rahul',
    'Yash',
    'Dev',
    'Ayaan',
  ];

  /// Share of bots given a female name.
  static const double _femaleBotShare = 0.8;

  final Random _random = Random();

  String _newRoomCode() => List.generate(
    _codeLength,
    (_) => _codeAlphabet[_random.nextInt(_codeAlphabet.length)],
  ).join();

  /// Normalises what a user typed into a room code (case, spaces, dashes).
  static String normalizeRoomCode(String input) =>
      input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  LudoSeatInfo _newBot(LudoMatch match) =>
      _newBotAvoiding(match.seats.values.map((s) => s.name).toSet());

  LudoSeatInfo _newBotAvoiding(Set<String> taken) {
    final pool = _random.nextDouble() < _femaleBotShare
        ? _femaleBotNames
        : _maleBotNames;
    final free = pool.where((n) => !taken.contains(n)).toList();
    final name = free.isEmpty
        ? pool[_random.nextInt(pool.length)]
        : free[_random.nextInt(free.length)];
    return LudoSeatInfo(
      uid: 'bot_${_random.nextInt(1 << 32).toRadixString(36)}',
      name: name,
      bot: true,
    );
  }

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

  /// Every in-progress match anyone can drop in and spectate, most-recently
  /// active first.
  ///
  /// Queries by recent activity rather than by status: abandoned matches keep
  /// status `active` forever, and a `status == active` query capped at
  /// [limit] could fill up with them and hide every genuinely live match. A
  /// single-field range on the turn clock needs no composite index; status is
  /// checked client-side.
  Stream<List<LudoMatch>> watchLiveMatches({int limit = 30}) {
    const staleMs = 15 * 60 * 1000; // 15 min with no move => abandoned
    final cutoff = DateTime.now().millisecondsSinceEpoch - staleMs;
    return _col
        .where('turn_started_at_ms', isGreaterThan: cutoff)
        .orderBy('turn_started_at_ms', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final now = DateTime.now().millisecondsSinceEpoch;
          return snap.docs
              .map((d) => LudoMatch.fromMap(d.id, d.data()))
              .where(
                (m) =>
                    m.status == LudoMatchStatus.active &&
                    now - m.turnStartedAtMs < staleMs,
              )
              .toList();
        });
  }

  Future<LudoMatch?> fetch(String matchId) async {
    final snap = await _col.doc(matchId).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return LudoMatch.fromMap(snap.id, data);
  }

  /// Host creates a match and takes the green seat. [quick] rooms are listed
  /// for Quick Match and auto-start with a bot after [quickFillSeconds].
  Future<LudoMatch> createMatch({
    List<String> invitedUids = const [],
    bool quick = false,
  }) async {
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
      roomCode: _newRoomCode(),
      quick: quick,
      quickOpen: quick,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
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

  /// The same invite as an https App Link, so it shows up as a tappable link
  /// in WhatsApp (custom schemes aren't linkified there).
  static String webInviteLink(String matchId) =>
      'https://hashforgamers.co.in/game/ludomatch_$matchId';

  /// Ready-to-send invite text for WhatsApp / the share sheet.
  static String inviteMessage(LudoMatch match) {
    final code = match.roomCode;
    return [
      'Let\'s play Ludo on Hash! 🎲',
      if (code.isNotEmpty) 'Room code: $code',
      'Join here: ${webInviteLink(match.id)}',
    ].join('\n');
  }

  /// Finds a still-open room by its code. Returns null if no waiting room has
  /// that code.
  Future<String?> findByCode(String rawCode) async {
    final code = normalizeRoomCode(rawCode);
    if (code.length != _codeLength) return null;
    final snap = await _col.where('room_code', isEqualTo: code).limit(5).get();
    final uid = _uid;
    for (final d in snap.docs) {
      final m = LudoMatch.fromMap(d.id, d.data());
      // A room I'm already in can be reopened even after it has started.
      if (uid != null &&
          m.seatOf(uid) != null &&
          (m.status == LudoMatchStatus.waiting ||
              m.status == LudoMatchStatus.active)) {
        return m.id;
      }
      if (m.status == LudoMatchStatus.waiting && !m.isFull) return m.id;
    }
    return null;
  }

  /// Quick Match rooms someone is waiting in right now (still open, not
  /// stale, not full), longest-waiting first. Drives the live "looking" count
  /// and the Home banner.
  Stream<List<LudoMatch>> watchOpenQuickRooms({int limit = 30}) {
    return _col
        .where('quick_open', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final rooms =
              snap.docs
                  .map((d) => LudoMatch.fromMap(d.id, d.data()))
                  .where(
                    (m) =>
                        m.status == LudoMatchStatus.waiting &&
                        !m.isFull &&
                        now - m.createdAtMs <= quickStaleMs,
                  )
                  .toList()
                ..sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
          return rooms;
        });
  }

  /// Ask for a rematch after a finished match. The first player to ask opens a
  /// new room (same seats' humans invited); everyone else gets its id via the
  /// old match's `rematch_id` and joins it. Returns the new room's id.
  ///
  /// If the old match was just me against bots, the rematch seats the same
  /// number of bots and starts straight away.
  ///
  /// [created] is true for whoever opened the new room (vs joining one).
  Future<({String id, bool created, bool vsBot, int humans})> requestRematch(
    String oldMatchId,
  ) async {
    final uid = _uid;
    if (uid == null) throw Exception('Please sign in to play online.');
    final me = _me();
    final oldRef = _col.doc(oldMatchId);
    final newRef = _col.doc();

    return _db.runTransaction((tx) async {
      final snap = await tx.get(oldRef);
      final data = snap.data();
      if (!snap.exists || data == null) {
        throw Exception('This match no longer exists.');
      }
      final old = LudoMatch.fromMap(snap.id, data);
      final vsBot = old.botSeats.isNotEmpty;
      if (old.rematchId.isNotEmpty) {
        return (
          id: old.rematchId,
          created: false,
          vsBot: vsBot,
          humans: old.humanCount,
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final otherHumans = [
        for (final s in old.seats.values)
          if (!s.bot && s.uid != uid) s.uid,
      ];
      final soloVsBots = otherHumans.isEmpty && old.botSeats.isNotEmpty;

      var match = LudoMatch(
        id: newRef.id,
        hostUid: uid,
        status: LudoMatchStatus.waiting,
        seats: {LudoPlayerType.green: me},
        invitedUids: otherHumans,
        turn: LudoPlayerType.green,
        dice: 1,
        winners: const [],
        pawns: {LudoPlayerType.green: _freshPawns()},
        lastWriterUid: uid,
        version: 0,
        turnStartedAtMs: now,
        roomCode: _newRoomCode(),
        createdAtMs: now,
      );
      if (soloVsBots) {
        final seats = Map.of(match.seats);
        final pawns = Map.of(match.pawns);
        for (var i = 0; i < old.botSeats.length; i++) {
          final seat = kLudoSeatOrder.firstWhere((s) => !seats.containsKey(s));
          seats[seat] = _newBotAvoiding(
            seats.values.map((s) => s.name).toSet(),
          );
          pawns[seat] = _freshPawns();
        }
        match = LudoMatch.fromMap(newRef.id, {
          ...match.toMap(),
          'status': statusToString(LudoMatchStatus.active),
          'seats': {for (final e in seats.entries) e.key.name: e.value.toMap()},
          'pawns': {for (final e in pawns.entries) e.key.name: e.value},
        });
      }

      tx.set(newRef, {
        ...match.toMap(),
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      tx.update(oldRef, {
        'rematch_id': newRef.id,
        'rematch_by': me.name,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return (
        id: newRef.id,
        created: true,
        vsBot: vsBot,
        humans: old.humanCount,
      );
    });
  }

  /// Quick Match: join the longest-waiting open room, or open a new one if
  /// none is available. Returns the match id to show, and whether a new room
  /// had to be created.
  ///
  /// Only an equality filter is used (no composite index needed); age and
  /// capacity are checked client-side and again inside the join transaction.
  Future<({String id, bool created})> quickMatch() async {
    final uid = _uid;
    if (uid == null) throw Exception('Please sign in to play online.');
    final snap = await _col
        .where('quick_open', isEqualTo: true)
        .limit(20)
        .get();
    final now = DateTime.now().millisecondsSinceEpoch;
    final open = <LudoMatch>[];
    for (final d in snap.docs) {
      final m = LudoMatch.fromMap(d.id, d.data());
      final stale = now - m.createdAtMs > quickStaleMs;
      if (m.status != LudoMatchStatus.waiting || stale) {
        unawaited(_closeQuickRoom(m.id, cancel: stale));
        continue;
      }
      if (!m.isFull) open.add(m);
    }
    // Fill the room that has waited longest first, so nobody sits alone.
    open.sort((a, b) => a.createdAtMs.compareTo(b.createdAtMs));
    for (final m in open) {
      try {
        await joinMatch(m.id);
        return (id: m.id, created: false);
      } catch (e) {
        // Someone else took the last seat or it just started; try the next.
        debugPrint('[LudoMatch] quick join ${m.id} skipped: $e');
      }
    }
    return (id: (await createMatch(quick: true)).id, created: true);
  }

  /// Best-effort: delist a Quick Match room (and cancel it if it went stale
  /// while still waiting). Security rules may refuse a non-host; that's fine,
  /// it is skipped client-side anyway.
  Future<void> _closeQuickRoom(String matchId, {required bool cancel}) async {
    final ref = _col.doc(matchId);
    try {
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final data = snap.data();
        if (!snap.exists || data == null) return;
        final m = LudoMatch.fromMap(snap.id, data);
        tx.update(ref, {
          'quick_open': false,
          if (cancel && m.status == LudoMatchStatus.waiting)
            'status': statusToString(LudoMatchStatus.cancelled),
          'updated_at': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('[LudoMatch] close quick room $matchId: $e');
    }
  }

  /// Join the first empty seat (or a specific one) transactionally.
  Future<LudoPlayerType> joinMatch(
    String matchId, {
    LudoPlayerType? seat,
  }) async {
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
      if (match.quick &&
          DateTime.now().millisecondsSinceEpoch - match.createdAtMs >
              quickStaleMs) {
        throw Exception('This room has closed.');
      }

      final target = (seat != null && !match.seats.containsKey(seat))
          ? seat
          : match.firstEmptySeat();
      if (target == null) throw Exception('No seats available.');

      tx.update(ref, {
        'seats.${target.name}': me.toMap(),
        'pawns.${target.name}': _freshPawns(),
        // Last seat taken: stop offering this room to Quick Match.
        if (match.seatCount + 1 >= 4) 'quick_open': false,
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
        'quick_open': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Host seats a bot in the first empty seat of a waiting room.
  Future<void> addBot(String matchId) async {
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) throw Exception('Match not found.');
      final match = LudoMatch.fromMap(snap.id, data);
      if (match.hostUid != _uid) throw Exception('Only the host can add bots.');
      if (match.status != LudoMatchStatus.waiting) return;
      final seat = match.firstEmptySeat();
      if (seat == null) throw Exception('This match is full.');
      tx.update(ref, {
        'seats.${seat.name}': _newBot(match).toMap(),
        'pawns.${seat.name}': _freshPawns(),
        if (match.seatCount + 1 >= 4) 'quick_open': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Quick Match auto-start: if nobody joined, a bot takes the second seat;
  /// then the match starts. Runs in a transaction, so a player who joins at the
  /// last moment is seen and no bot is added. No-op once the room has started.
  ///
  /// The host normally calls this; any seated player may after
  /// [quickStartFallbackMs] so a backgrounded host can't strand the room.
  ///
  /// Returns how many bots this call seated (0 if it started without one or
  /// did nothing).
  Future<int> fillWithBotAndStart(String matchId) async {
    final ref = _col.doc(matchId);
    return _db.runTransaction<int>((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return 0;
      final match = LudoMatch.fromMap(snap.id, data);
      if (match.status != LudoMatchStatus.waiting) return 0;
      final uid = _uid;
      final isHost = match.hostUid == uid;
      final waitedMs =
          DateTime.now().millisecondsSinceEpoch - match.createdAtMs;
      final seated = uid != null && match.seatOf(uid) != null;
      if (!isHost && !(seated && waitedMs >= quickStartFallbackMs)) return 0;

      final updates = <String, dynamic>{};
      var seats = match.occupiedSeats;
      if (match.seatCount < 2) {
        final seat = match.firstEmptySeat()!;
        updates['seats.${seat.name}'] = _newBot(match).toMap();
        updates['pawns.${seat.name}'] = _freshPawns();
        seats = kLudoSeatOrder
            .where((s) => s == seat || match.seats.containsKey(s))
            .toList();
      }
      tx.update(ref, {
        ...updates,
        'status': statusToString(LudoMatchStatus.active),
        'turn': seats.first.name,
        'turn_started_at_ms': DateTime.now().millisecondsSinceEpoch,
        'quick_open': false,
        'last_writer_uid': uid,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return updates.isEmpty ? 0 : 1;
    });
  }

  /// Authoritative state write after a local turn resolves. Callers must only
  /// invoke this when it is their turn (the provider enforces this).
  static final Set<String> _reportedWriteErrors = <String>{};

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
    try {
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
    } catch (e) {
      // A rejected write (e.g. security rules disallowing a non-active seat to
      // force-advance an abandoned turn) must never crash gameplay. The next
      // authoritative snapshot will re-sync this device.
      debugPrint('[LudoMatch] writeState rejected: $e');
      // Once per match and error code: a rejected force-advance repeats every
      // turn and used to flood ludo_sync_failed from a handful of devices.
      if (_reportedWriteErrors.add('$matchId/${LudoAnalytics.errorCode(e)}')) {
        LudoAnalytics.syncFailed(stage: 'write_state', error: e);
      }
    }
  }

  Future<void> cancelMatch(String matchId) async {
    await _col.doc(matchId).update({
      'status': statusToString(LudoMatchStatus.cancelled),
      'quick_open': false,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// A player quits mid-match. Their seat is removed and the match resolves:
  /// - only one player left (active game) → that player WINS, match finishes;
  /// - two or more left → match continues, turn advances if it was the
  ///   leaver's turn;
  /// - nobody left → match ends (finished/cancelled) instead of hanging.
  /// Runs in a transaction so simultaneous leaves resolve consistently.
  Future<void> leaveMatch(String matchId, LudoPlayerType seat) async {
    final ref = _col.doc(matchId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (!snap.exists || data == null) return;
      final match = LudoMatch.fromMap(snap.id, data);
      if (!match.seats.containsKey(seat)) return; // already gone

      final remaining = match.occupiedSeats.where((s) => s != seat).toList();
      // Bots can't carry on alone: with no human left the match ends.
      final humansLeft = remaining.where((s) => !match.seats[s]!.bot).length;

      final updates = <String, dynamic>{
        'seats.${seat.name}': FieldValue.delete(),
        'pawns.${seat.name}': FieldValue.delete(),
        'last_writer_uid': _uid,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (match.status == LudoMatchStatus.active) {
        if (remaining.length <= 1 || humansLeft == 0) {
          // Last player standing wins by forfeit (or nobody left → just end).
          final winners = match.winners.map((e) => e.name).toList();
          if (remaining.length == 1 &&
              !winners.contains(remaining.first.name)) {
            winners.add(remaining.first.name);
          }
          updates['winners'] = winners;
          updates['status'] = statusToString(LudoMatchStatus.finished);
        } else if (match.turn == seat) {
          // It was the leaver's turn — hand it to the next remaining player.
          updates['turn'] = _nextSeatAmong(seat, remaining).name;
          updates['turn_started_at_ms'] = DateTime.now().millisecondsSinceEpoch;
        }
      } else if (match.status == LudoMatchStatus.waiting && humansLeft == 0) {
        updates['status'] = statusToString(LudoMatchStatus.cancelled);
        updates['quick_open'] = false;
      }

      tx.update(ref, updates);
    });
  }

  /// Next seat after [from] in turn order that is still in [remaining].
  LudoPlayerType _nextSeatAmong(
    LudoPlayerType from,
    List<LudoPlayerType> remaining,
  ) {
    final start = kLudoSeatOrder.indexOf(from);
    for (int i = 1; i <= kLudoSeatOrder.length; i++) {
      final candidate = kLudoSeatOrder[(start + i) % kLudoSeatOrder.length];
      if (remaining.contains(candidate)) return candidate;
    }
    return remaining.first;
  }

  /// Broadcast an emoji reaction to everyone in the match. [key] is a stable
  /// reaction id (see `kLudoReactions`). This only touches the `reaction_*`
  /// fields (never turn/dice/pawns), so it can be sent on any turn without
  /// disturbing the authoritative game state. Best-effort: a rejected write
  /// (e.g. security rules) is swallowed so it never interrupts play.
  Future<void> sendReaction(
    String matchId, {
    LudoPlayerType? seat,
    required String key,
    String name = '',
  }) async {
    try {
      await _col.doc(matchId).update({
        'reaction_emoji': key,
        // Seated players carry their seat; spectators carry a name instead.
        'reaction_seat': seat?.name ?? FieldValue.delete(),
        'reaction_name': name,
        'reaction_id': DateTime.now().millisecondsSinceEpoch,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Reactions are cosmetic; never let one break the match.
    }
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

  /// The remembered match, but only while it can still be resumed: it is
  /// waiting or active and this user still holds a seat. Anything else is
  /// forgotten so "Resume Match" never opens a dead room.
  Future<String?> activeMatchId() async {
    final uid = _uid;
    if (uid == null) return null;
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_activeKey(uid));
    if (id == null) return null;
    try {
      final snap = await _col.doc(id).get();
      final data = snap.data();
      final match = (snap.exists && data != null)
          ? LudoMatch.fromMap(snap.id, data)
          : null;
      final live =
          match != null &&
          (match.status == LudoMatchStatus.waiting ||
              match.status == LudoMatchStatus.active) &&
          match.seatOf(uid) != null;
      if (!live) {
        await prefs.remove(_activeKey(uid));
        return null;
      }
    } catch (_) {
      // Offline: keep offering it; the match screen handles reconnecting.
    }
    return id;
  }
}
