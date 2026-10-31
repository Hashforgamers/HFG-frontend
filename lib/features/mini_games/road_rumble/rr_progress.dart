import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'rr_engine.dart';

/// What a finished race pays out, worked out once so the results screen and
/// the saved career agree.
class RrResult {
  const RrResult({
    required this.outcome,
    required this.place,
    required this.prize,
    required this.fine,
    required this.kos,
    required this.score,
    required this.qualified,
    required this.levelUp,
    this.bonus = 0,
  });

  final RrOutcome outcome;
  final int place;
  final int prize;
  final int fine;
  final int kos;

  /// Arcade leaderboard points, kept in the same range as the other games.
  final int score;
  final bool qualified;
  final bool levelUp;

  /// Cash for close calls with traffic.
  final int bonus;
}

/// The player's career: cash, garage and which tracks are qualified on the
/// current level. Stored on the device.
class RrProgress {
  static const _key = 'road_rumble_progress';
  static const maxLevel = 5;
  static const qualifyPlace = 4;

  static const _prizes = [
    1000,
    800,
    650,
    500,
    400,
    300,
    250,
    200,
    150,
    100,
    80,
    60,
    40,
    20,
    10,
  ];
  static const _points = [
    100,
    80,
    65,
    55,
    45,
    38,
    32,
    27,
    22,
    18,
    14,
    10,
    7,
    4,
    2,
  ];

  int cash = 0;
  int level = 1;
  int bike = 0;
  Set<int> owned = {0};
  Set<String> qualified = {};
  bool sound = true;

  static Future<RrProgress> load() async {
    final progress = RrProgress();
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return progress;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      progress
        ..cash = max(0, json['cash'] as int? ?? 0)
        ..level = (json['level'] as int? ?? 1).clamp(1, maxLevel)
        ..bike = (json['bike'] as int? ?? 0).clamp(0, rrBikes.length - 1)
        ..owned = {0, ...(json['owned'] as List? ?? const []).cast<int>()}
        ..qualified = {
          ...(json['qualified'] as List? ?? const []).cast<String>(),
        }
        ..sound = json['sound'] as bool? ?? true;
      if (!progress.owned.contains(progress.bike)) progress.bike = 0;
    } catch (_) {
      // A corrupt save just starts a fresh career.
    }
    return progress;
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'cash': cash,
        'level': level,
        'bike': bike,
        'owned': owned.toList(),
        'qualified': qualified.toList(),
        'sound': sound,
      }),
    );
  }

  /// Applies a finished race to the career and returns what it paid.
  RrResult apply(RrEngine e) {
    final lvl = e.level;
    final kos = min(e.kos, 5);
    var prize = 0;
    var fine = 0;
    var score = kos * 3;
    var didQualify = false;
    var levelUp = false;
    switch (e.outcome) {
      case RrOutcome.finished:
        final i = (e.finishPlace - 1).clamp(0, _prizes.length - 1);
        prize = _prizes[i] * lvl;
        score += (_points[i] * (1 + 0.15 * (lvl - 1))).round();
        if (e.finishPlace <= qualifyPlace) {
          didQualify = true;
          qualified.add(e.track.id);
          if (qualified.length >= rrTracks.length) {
            levelUp = true;
            qualified = {};
            if (level < maxLevel) level++;
          }
        }
      case RrOutcome.busted:
        fine = 250 * lvl;
      case RrOutcome.wrecked:
        fine = 300 * lvl;
      case RrOutcome.none:
        break;
    }
    // Close calls pay only on a finish; money for blows landed is kept regardless.
    final bonus =
        (e.outcome == RrOutcome.finished
            ? min(e.nearMisses, 10) * 25 * lvl
            : 0) +
        e.fightCash;
    cash = max(0, cash + prize + bonus - fine);
    return RrResult(
      outcome: e.outcome,
      place: e.finishPlace,
      prize: prize,
      fine: fine,
      kos: e.kos,
      score: score,
      qualified: didQualify,
      levelUp: levelUp,
      bonus: bonus,
    );
  }
}
