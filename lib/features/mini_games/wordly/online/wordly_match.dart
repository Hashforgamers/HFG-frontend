/// Firestore model for a Wordly race (`wordly_matches/<id>`): everyone gets
/// the same word; rivals see each other's tile colours, never the letters.
enum WordlyMatchStatus { waiting, active, finished }

class WordlyPlayer {
  const WordlyPlayer({
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

  factory WordlyPlayer.fromMap(Map<String, dynamic> m) => WordlyPlayer(
    uid: (m['uid'] ?? '').toString(),
    name: (m['name'] ?? 'Player').toString(),
    photo: m['photo'] as String?,
    joinedAtMs: (m['joined_at_ms'] as num?)?.toInt() ?? 0,
  );
}

/// A player's board for the current round, as colour codes only.
class WordlyProgress {
  const WordlyProgress({
    required this.rows,
    required this.solved,
    required this.done,
    required this.finishedAtMs,
  });

  /// One `GYBBG`-style string per submitted guess.
  final List<String> rows;
  final bool solved;
  final bool done;

  /// Server-clock ms when the board finished (0 while playing).
  final int finishedAtMs;

  static const empty = WordlyProgress(
    rows: [],
    solved: false,
    done: false,
    finishedAtMs: 0,
  );

  int get bestGreens => rows.fold(
    0,
    (best, r) => r.split('').where((c) => c == 'G').length > best
        ? r.split('').where((c) => c == 'G').length
        : best,
  );

  Map<String, dynamic> toMap() => {
    'rows': rows,
    'solved': solved,
    'done': done,
    'finished_at_ms': finishedAtMs,
  };

  factory WordlyProgress.fromMap(Map<String, dynamic> m) => WordlyProgress(
    rows: [
      if (m['rows'] is List)
        for (final r in m['rows'] as List) r.toString(),
    ],
    solved: m['solved'] == true,
    done: m['done'] == true,
    finishedAtMs: (m['finished_at_ms'] as num?)?.toInt() ?? 0,
  );
}

class WordlyMatch {
  const WordlyMatch({
    required this.id,
    required this.hostUid,
    required this.status,
    required this.players,
    required this.round,
    required this.wordIndex,
    required this.startAtMs,
    required this.progress,
  });

  final String id;
  final String hostUid;
  final WordlyMatchStatus status;
  final Map<String, WordlyPlayer> players;
  final int round;

  /// Index into the bundled answer list.
  final int wordIndex;

  /// Round start in server-clock epoch ms.
  final int startAtMs;
  final Map<String, WordlyProgress> progress;

  static const maxPlayers = 4;
  static const roundMs = 3 * 60 * 1000;

  int get endAtMs => startAtMs + roundMs;

  WordlyProgress progressOf(String uid) =>
      progress[uid] ?? WordlyProgress.empty;

  List<WordlyPlayer> get ordered {
    final list = players.values.toList()
      ..sort((a, b) {
        if (a.uid == hostUid) return -1;
        if (b.uid == hostUid) return 1;
        return a.joinedAtMs.compareTo(b.joinedAtMs);
      });
    return list;
  }

  bool get allDone =>
      players.isNotEmpty && players.keys.every((u) => progressOf(u).done);

  /// Solvers first (fewest guesses, then fastest); then by best green count.
  List<WordlyPlayer> get standings {
    final list = ordered;
    list.sort((a, b) {
      final pa = progressOf(a.uid);
      final pb = progressOf(b.uid);
      if (pa.solved != pb.solved) return pa.solved ? -1 : 1;
      if (pa.solved) {
        if (pa.rows.length != pb.rows.length) {
          return pa.rows.length.compareTo(pb.rows.length);
        }
        return pa.finishedAtMs.compareTo(pb.finishedAtMs);
      }
      return pb.bestGreens.compareTo(pa.bestGreens);
    });
    return list;
  }

  factory WordlyMatch.fromMap(String id, Map<String, dynamic> m) {
    final players = <String, WordlyPlayer>{};
    if (m['players'] is Map) {
      (m['players'] as Map).forEach((k, v) {
        if (v is Map) {
          players[k.toString()] = WordlyPlayer.fromMap(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }
    final progress = <String, WordlyProgress>{};
    if (m['progress'] is Map) {
      (m['progress'] as Map).forEach((k, v) {
        if (v is Map) {
          progress[k.toString()] = WordlyProgress.fromMap(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }
    return WordlyMatch(
      id: id,
      hostUid: (m['host_uid'] ?? '').toString(),
      status: switch (m['status']) {
        'active' => WordlyMatchStatus.active,
        'finished' => WordlyMatchStatus.finished,
        _ => WordlyMatchStatus.waiting,
      },
      players: players,
      round: (m['round'] as num?)?.toInt() ?? 0,
      wordIndex: (m['word_index'] as num?)?.toInt() ?? 0,
      startAtMs: (m['start_at_ms'] as num?)?.toInt() ?? 0,
      progress: progress,
    );
  }
}
