import '../constants.dart';

/// Match lifecycle.
enum LudoMatchStatus { waiting, active, finished, cancelled }

LudoMatchStatus _statusFromString(String? s) {
  switch (s) {
    case 'active':
      return LudoMatchStatus.active;
    case 'finished':
      return LudoMatchStatus.finished;
    case 'cancelled':
      return LudoMatchStatus.cancelled;
    default:
      return LudoMatchStatus.waiting;
  }
}

String statusToString(LudoMatchStatus s) => s.name;

/// The four fixed board seats, in turn order.
const List<LudoPlayerType> kLudoSeatOrder = [
  LudoPlayerType.green,
  LudoPlayerType.yellow,
  LudoPlayerType.blue,
  LudoPlayerType.red,
];

LudoPlayerType seatFromString(String s) =>
    kLudoSeatOrder.firstWhere((e) => e.name == s, orElse: () => LudoPlayerType.green);

/// A player occupying a seat.
class LudoSeatInfo {
  const LudoSeatInfo({required this.uid, required this.name, this.photo});

  final String uid;
  final String name;
  final String? photo;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    if (photo != null && photo!.isNotEmpty) 'photo': photo,
  };

  factory LudoSeatInfo.fromMap(Map<String, dynamic> m) => LudoSeatInfo(
    uid: (m['uid'] ?? '').toString(),
    name: (m['name'] ?? 'Player').toString(),
    photo: (m['photo'] as String?),
  );
}

/// Immutable snapshot of a networked Ludo match, mirrored in Firestore at
/// `ludo_matches/<id>`. Only occupied seats appear in [seats]/[pawns].
class LudoMatch {
  const LudoMatch({
    required this.id,
    required this.hostUid,
    required this.status,
    required this.seats,
    required this.invitedUids,
    required this.turn,
    required this.dice,
    required this.winners,
    required this.pawns,
    required this.lastWriterUid,
    required this.version,
    required this.turnStartedAtMs,
    this.reactionEmoji = '',
    this.reactionSeat,
    this.reactionId = 0,
  });

  final String id;
  final String hostUid;
  final LudoMatchStatus status;
  final Map<LudoPlayerType, LudoSeatInfo> seats;
  final List<String> invitedUids;
  final LudoPlayerType turn;
  final int dice;
  final List<LudoPlayerType> winners;

  /// Per-seat pawn steps (4 ints each, -1 = home). Only occupied seats present.
  final Map<LudoPlayerType, List<int>> pawns;

  /// uid of the device that produced this state — used to ignore our own echo.
  final String lastWriterUid;
  final int version;

  /// Client epoch millis when the current turn (or last action) began — drives
  /// the per-turn countdown. 0 when unknown.
  final int turnStartedAtMs;

  /// The most recent in-match emoji reaction. [reactionId] is a monotonically
  /// increasing epoch-ms stamp so every client can tell a fresh reaction from a
  /// repeated snapshot; 0 means "no reaction yet".
  final String reactionEmoji;
  final LudoPlayerType? reactionSeat;
  final int reactionId;

  bool get isFull => seats.length >= 4;
  int get seatCount => seats.length;
  List<LudoPlayerType> get occupiedSeats =>
      kLudoSeatOrder.where(seats.containsKey).toList();

  LudoPlayerType? seatOf(String uid) {
    for (final e in seats.entries) {
      if (e.value.uid == uid) return e.key;
    }
    return null;
  }

  LudoPlayerType? firstEmptySeat() =>
      kLudoSeatOrder.where((s) => !seats.containsKey(s)).cast<LudoPlayerType?>().firstWhere(
            (s) => s != null,
            orElse: () => null,
          );

  Map<String, dynamic> toMap() => {
    'id': id,
    'host_uid': hostUid,
    'status': statusToString(status),
    'seats': {
      for (final e in seats.entries) e.key.name: e.value.toMap(),
    },
    'invited_uids': invitedUids,
    'turn': turn.name,
    'dice': dice,
    'winners': winners.map((e) => e.name).toList(),
    'pawns': {
      for (final e in pawns.entries) e.key.name: e.value,
    },
    'last_writer_uid': lastWriterUid,
    'version': version,
    'turn_started_at_ms': turnStartedAtMs,
    'reaction_emoji': reactionEmoji,
    if (reactionSeat != null) 'reaction_seat': reactionSeat!.name,
    'reaction_id': reactionId,
  };

  factory LudoMatch.fromMap(String id, Map<String, dynamic> m) {
    final seatsRaw = (m['seats'] as Map?) ?? const {};
    final pawnsRaw = (m['pawns'] as Map?) ?? const {};
    return LudoMatch(
      id: id,
      hostUid: (m['host_uid'] ?? '').toString(),
      status: _statusFromString(m['status'] as String?),
      seats: {
        for (final e in seatsRaw.entries)
          seatFromString(e.key.toString()): LudoSeatInfo.fromMap(
            Map<String, dynamic>.from(e.value as Map),
          ),
      },
      invitedUids:
          (m['invited_uids'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      turn: seatFromString((m['turn'] ?? 'green').toString()),
      dice: (m['dice'] as num?)?.toInt() ?? 1,
      winners:
          (m['winners'] as List?)
              ?.map((e) => seatFromString(e.toString()))
              .toList() ??
          const [],
      pawns: {
        for (final e in pawnsRaw.entries)
          seatFromString(e.key.toString()):
              (e.value as List).map((v) => (v as num).toInt()).toList(),
      },
      lastWriterUid: (m['last_writer_uid'] ?? '').toString(),
      version: (m['version'] as num?)?.toInt() ?? 0,
      turnStartedAtMs: (m['turn_started_at_ms'] as num?)?.toInt() ?? 0,
      reactionEmoji: (m['reaction_emoji'] ?? '').toString(),
      reactionSeat: m['reaction_seat'] == null
          ? null
          : seatFromString(m['reaction_seat'].toString()),
      reactionId: (m['reaction_id'] as num?)?.toInt() ?? 0,
    );
  }
}
