/// Firestore models for Laggy Bird races.
///
/// `bird_matches/<id>` holds the room (players, course seed, start time and
/// per-round results). Each player's flaps for a round live in their own doc
/// at `bird_matches/<id>/runs/<round>_<uid>` so high-frequency writes never
/// contend with each other or with the room doc.
enum BirdMatchStatus { waiting, active, finished }

class BirdPlayer {
  const BirdPlayer({
    required this.uid,
    required this.name,
    required this.skin,
    required this.joinedAtMs,
    this.photo,
  });

  final String uid;
  final String name;
  final String? photo;

  /// Bird key: a PNG asset path or `skin:<id>`.
  final String skin;
  final int joinedAtMs;

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'name': name,
    'skin': skin,
    'joined_at_ms': joinedAtMs,
    if (photo != null && photo!.isNotEmpty) 'photo': photo,
  };

  factory BirdPlayer.fromMap(Map<String, dynamic> m) => BirdPlayer(
    uid: (m['uid'] ?? '').toString(),
    name: (m['name'] ?? 'Player').toString(),
    skin: (m['skin'] ?? '').toString(),
    joinedAtMs: (m['joined_at_ms'] as num?)?.toInt() ?? 0,
    photo: m['photo'] as String?,
  );
}

/// How a player's run ended in the current round.
class BirdResult {
  const BirdResult({required this.score, required this.deadAtMs});

  final int score;

  /// Run time (ms since the round started) when the bird crashed.
  final int deadAtMs;

  factory BirdResult.fromMap(Map<String, dynamic> m) => BirdResult(
    score: (m['score'] as num?)?.toInt() ?? 0,
    deadAtMs: (m['dead_at_ms'] as num?)?.toInt() ?? 0,
  );
}

class BirdMatch {
  const BirdMatch({
    required this.id,
    required this.hostUid,
    required this.status,
    required this.players,
    required this.round,
    required this.seed,
    required this.difficulty,
    required this.startAtMs,
    required this.results,
  });

  final String id;
  final String hostUid;
  final BirdMatchStatus status;
  final Map<String, BirdPlayer> players;
  final int round;
  final int seed;
  final String difficulty;

  /// Round start in server-clock epoch ms.
  final int startAtMs;
  final Map<String, BirdResult> results;

  static const maxPlayers = 4;

  /// Players in join order, host first.
  List<BirdPlayer> get ordered {
    final list = players.values.toList()
      ..sort((a, b) {
        if (a.uid == hostUid) return -1;
        if (b.uid == hostUid) return 1;
        return a.joinedAtMs.compareTo(b.joinedAtMs);
      });
    return list;
  }

  bool get allFinished =>
      players.isNotEmpty && players.keys.every(results.containsKey);

  /// Final standings: higher score first, then whoever stayed up longer.
  List<BirdPlayer> get standings {
    final list = ordered;
    list.sort((a, b) {
      final ra = results[a.uid];
      final rb = results[b.uid];
      final sa = ra?.score ?? -1;
      final sb = rb?.score ?? -1;
      if (sa != sb) return sb.compareTo(sa);
      return (rb?.deadAtMs ?? 0).compareTo(ra?.deadAtMs ?? 0);
    });
    return list;
  }

  factory BirdMatch.fromMap(String id, Map<String, dynamic> m) {
    final players = <String, BirdPlayer>{};
    final rawPlayers = m['players'];
    if (rawPlayers is Map) {
      rawPlayers.forEach((k, v) {
        if (v is Map) {
          players[k.toString()] = BirdPlayer.fromMap(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }
    final results = <String, BirdResult>{};
    final rawResults = m['results'];
    if (rawResults is Map) {
      rawResults.forEach((k, v) {
        if (v is Map) {
          results[k.toString()] = BirdResult.fromMap(
            Map<String, dynamic>.from(v),
          );
        }
      });
    }
    return BirdMatch(
      id: id,
      hostUid: (m['host_uid'] ?? '').toString(),
      status: switch (m['status']) {
        'active' => BirdMatchStatus.active,
        'finished' => BirdMatchStatus.finished,
        _ => BirdMatchStatus.waiting,
      },
      players: players,
      round: (m['round'] as num?)?.toInt() ?? 0,
      seed: (m['seed'] as num?)?.toInt() ?? 0,
      difficulty: (m['difficulty'] ?? 'easy').toString(),
      startAtMs: (m['start_at_ms'] as num?)?.toInt() ?? 0,
      results: results,
    );
  }
}

/// A player's flap log for one round.
class BirdRun {
  const BirdRun({required this.uid, required this.flaps});

  final String uid;

  /// Run-time ms of each flap, ascending.
  final List<int> flaps;

  factory BirdRun.fromMap(Map<String, dynamic> m) {
    final raw = m['flaps'];
    final flaps = <int>[
      if (raw is List)
        for (final f in raw)
          if (f is num) f.toInt(),
    ]..sort();
    return BirdRun(uid: (m['uid'] ?? '').toString(), flaps: flaps);
  }
}
