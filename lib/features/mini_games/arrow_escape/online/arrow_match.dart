/// Firestore model for an Arrow Escape race (`arrow_escape_matches/<id>`):
/// everyone untangles the same board; rivals only see how far along you are.
enum ArrowMatchStatus { waiting, active, finished }

class ArrowPlayer {
  const ArrowPlayer({
    required this.uid,
    required this.name,
    required this.joinedAtMs,
    this.photo,
  });

  final String uid;
  final String name;
  final String? photo;
  final int joinedAtMs;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'joined_at_ms': joinedAtMs,
    if (photo != null && photo!.isNotEmpty) 'photo': photo,
  };

  factory ArrowPlayer.fromMap(Map<String, dynamic> m) => ArrowPlayer(
    uid: (m['uid'] ?? '').toString(),
    name: (m['name'] ?? 'Player').toString(),
    photo: m['photo'] as String?,
    joinedAtMs: (m['joined_at_ms'] as num?)?.toInt() ?? 0,
  );
}

/// A player's board for the current round.
class ArrowProgress {
  const ArrowProgress({
    required this.escaped,
    required this.total,
    required this.bumps,
    required this.done,
    required this.finishedAtMs,
  });

  final int escaped;
  final int total;
  final int bumps;
  final bool done;

  /// Server-clock ms when the board finished (0 while playing).
  final int finishedAtMs;

  static const empty = ArrowProgress(
    escaped: 0,
    total: 0,
    bumps: 0,
    done: false,
    finishedAtMs: 0,
  );

  bool get cleared => total > 0 && escaped >= total;
  double get fraction => total <= 0 ? 0 : (escaped / total).clamp(0.0, 1.0);

  Map<String, dynamic> toMap() => {
    'escaped': escaped,
    'total': total,
    'bumps': bumps,
    'done': done,
    'finished_at_ms': finishedAtMs,
  };

  factory ArrowProgress.fromMap(Map<String, dynamic> m) => ArrowProgress(
    escaped: (m['escaped'] as num?)?.toInt() ?? 0,
    total: (m['total'] as num?)?.toInt() ?? 0,
    bumps: (m['bumps'] as num?)?.toInt() ?? 0,
    done: m['done'] == true,
    finishedAtMs: (m['finished_at_ms'] as num?)?.toInt() ?? 0,
  );
}

class ArrowMatch {
  const ArrowMatch({
    required this.id,
    required this.hostUid,
    required this.status,
    required this.players,
    required this.round,
    required this.seed,
    required this.startAtMs,
    required this.progress,
  });

  final String id;
  final String hostUid;
  final ArrowMatchStatus status;
  final Map<String, ArrowPlayer> players;
  final int round;

  /// Board seed, so every player generates the same puzzle.
  final int seed;

  /// Round start in server-clock epoch ms.
  final int startAtMs;
  final Map<String, ArrowProgress> progress;

  static const maxPlayers = 4;
  static const roundMs = 2 * 60 * 1000;

  /// Race board size.
  static const cols = 7;
  static const rows = 9;
  static const maxLength = 5;

  int get endAtMs => startAtMs + roundMs;

  ArrowProgress progressOf(String uid) => progress[uid] ?? ArrowProgress.empty;

  List<ArrowPlayer> get ordered {
    final list = players.values.toList()
      ..sort((a, b) {
        if (a.uid == hostUid) return -1;
        if (b.uid == hostUid) return 1;
        return a.joinedAtMs.compareTo(b.joinedAtMs);
      });
    return list;
  }

  /// Cleared boards first (fastest wins); then most arrows out, fewest bumps.
  List<ArrowPlayer> get standings {
    final list = ordered;
    list.sort((a, b) {
      final pa = progressOf(a.uid);
      final pb = progressOf(b.uid);
      if (pa.cleared != pb.cleared) return pa.cleared ? -1 : 1;
      if (pa.cleared) return pa.finishedAtMs.compareTo(pb.finishedAtMs);
      if (pa.escaped != pb.escaped) return pb.escaped.compareTo(pa.escaped);
      return pa.bumps.compareTo(pb.bumps);
    });
    return list;
  }

  factory ArrowMatch.fromMap(String id, Map<String, dynamic> m) {
    final players = <String, ArrowPlayer>{};
    if (m['players'] is Map) {
      (m['players'] as Map).forEach((k, v) {
        if (v is Map) {
          players[k.toString()] = ArrowPlayer.fromMap(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }
    final progress = <String, ArrowProgress>{};
    if (m['progress'] is Map) {
      (m['progress'] as Map).forEach((k, v) {
        if (v is Map) {
          progress[k.toString()] = ArrowProgress.fromMap(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }
    return ArrowMatch(
      id: id,
      hostUid: (m['host_uid'] ?? '').toString(),
      status: switch (m['status']) {
        'active' => ArrowMatchStatus.active,
        'finished' => ArrowMatchStatus.finished,
        _ => ArrowMatchStatus.waiting,
      },
      players: players,
      round: (m['round'] as num?)?.toInt() ?? 0,
      seed: (m['seed'] as num?)?.toInt() ?? 0,
      startAtMs: (m['start_at_ms'] as num?)?.toInt() ?? 0,
      progress: progress,
    );
  }
}
