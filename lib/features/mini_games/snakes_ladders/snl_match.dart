import '../ludo/constants.dart';
import '../ludo/online/ludo_match.dart';

/// Board jumps: ladders go up, snakes go down. Keys are the square landed on.
const Map<int, int> kSnlLadders = {
  1: 38,
  4: 14,
  9: 31,
  21: 42,
  28: 84,
  36: 44,
  51: 67,
  71: 91,
  80: 100,
};

const Map<int, int> kSnlSnakes = {
  16: 6,
  47: 26,
  49: 11,
  56: 53,
  62: 19,
  64: 60,
  87: 24,
  93: 73,
  95: 75,
  98: 78,
};

const int kSnlGoal = 100;

/// Result of applying a roll of [dice] from square [from]: where the token
/// lands (exact roll needed for 100, otherwise it stays) and where it ends
/// after any snake or ladder.
({int landed, int to}) snlApplyRoll(int from, int dice) {
  final target = from + dice;
  final landed = target > kSnlGoal ? from : target;
  final to = kSnlLadders[landed] ?? kSnlSnakes[landed] ?? landed;
  return (landed: landed, to: to);
}

/// The last roll, so every device animates the same move.
class SnlMove {
  const SnlMove({
    required this.seat,
    required this.dice,
    required this.from,
    required this.landed,
    required this.to,
    required this.id,
  });

  final LudoPlayerType seat;
  final int dice;
  final int from;
  final int landed;
  final int to;

  /// Epoch-ms stamp; a new id means a new move to animate.
  final int id;

  bool get isLadder => to > landed;
  bool get isSnake => to < landed;
  bool get bounced => landed == from && dice > 0;

  Map<String, dynamic> toMap() => {
    'seat': seat.name,
    'dice': dice,
    'from': from,
    'landed': landed,
    'to': to,
    'id': id,
  };

  static SnlMove? fromMap(Object? raw) {
    if (raw is! Map) return null;
    return SnlMove(
      seat: seatFromString((raw['seat'] ?? 'green').toString()),
      dice: (raw['dice'] as num?)?.toInt() ?? 0,
      from: (raw['from'] as num?)?.toInt() ?? 0,
      landed: (raw['landed'] as num?)?.toInt() ?? 0,
      to: (raw['to'] as num?)?.toInt() ?? 0,
      id: (raw['id'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A networked Snakes & Ladders match, mirrored at `snl_matches/<id>`.
/// Seats, colours and seat info are shared with Ludo.
class SnlMatch {
  const SnlMatch({
    required this.id,
    required this.hostUid,
    required this.status,
    required this.seats,
    required this.positions,
    required this.turn,
    required this.dice,
    required this.winners,
    required this.turnStartedAtMs,
    required this.version,
    this.lastMove,
  });

  final String id;
  final String hostUid;
  final LudoMatchStatus status;
  final Map<LudoPlayerType, LudoSeatInfo> seats;

  /// Square per seat; 0 = not on the board yet.
  final Map<LudoPlayerType, int> positions;
  final LudoPlayerType turn;
  final int dice;
  final List<LudoPlayerType> winners;
  final int turnStartedAtMs;
  final int version;
  final SnlMove? lastMove;

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

  LudoPlayerType? firstEmptySeat() {
    for (final s in kLudoSeatOrder) {
      if (!seats.containsKey(s)) return s;
    }
    return null;
  }

  factory SnlMatch.fromMap(String id, Map<String, dynamic> m) {
    final seatsRaw = (m['seats'] as Map?) ?? const {};
    final posRaw = (m['positions'] as Map?) ?? const {};
    return SnlMatch(
      id: id,
      hostUid: (m['host_uid'] ?? '').toString(),
      status: switch (m['status']) {
        'active' => LudoMatchStatus.active,
        'finished' => LudoMatchStatus.finished,
        'cancelled' => LudoMatchStatus.cancelled,
        _ => LudoMatchStatus.waiting,
      },
      seats: {
        for (final e in seatsRaw.entries)
          seatFromString(e.key.toString()): LudoSeatInfo.fromMap(
            Map<String, dynamic>.from(e.value as Map),
          ),
      },
      positions: {
        for (final e in posRaw.entries)
          seatFromString(e.key.toString()): (e.value as num).toInt(),
      },
      turn: seatFromString((m['turn'] ?? 'green').toString()),
      dice: (m['dice'] as num?)?.toInt() ?? 0,
      winners:
          (m['winners'] as List?)
              ?.map((e) => seatFromString(e.toString()))
              .toList() ??
          const [],
      turnStartedAtMs: (m['turn_started_at_ms'] as num?)?.toInt() ?? 0,
      version: (m['version'] as num?)?.toInt() ?? 0,
      lastMove: SnlMove.fromMap(m['last_move']),
    );
  }
}
