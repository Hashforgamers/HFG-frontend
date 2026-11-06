import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/ludo/ludo_dice_policy.dart';

void main() {
  int adjust(
    int roll, {
    bool easy = true,
    bool isBot = false,
    bool home = false,
    int seed = 1,
  }) => LudoDicePolicy.adjust(
    roll,
    easy: easy,
    isBot: isBot,
    allPawnsHome: home,
    random: Random(seed),
  );

  test('fair modes are never touched', () {
    for (var r = 1; r <= 6; r++) {
      expect(adjust(r, easy: false, home: true), r);
      expect(adjust(r, easy: false, isBot: true), r);
    }
  });

  test('a stuck new player gets a six about a third of the time', () {
    final rng = Random(42);
    var sixes = 0;
    const n = 6000;
    for (var i = 0; i < n; i++) {
      final fair = rng.nextInt(6) + 1;
      if (LudoDicePolicy.adjust(
            fair,
            easy: true,
            isBot: false,
            allPawnsHome: true,
            random: rng,
          ) ==
          6) {
        sixes++;
      }
    }
    // Fair alone is ~16.7%; with the assist ~44%.
    expect(sixes / n, inInclusiveRange(0.40, 0.48));
  });

  test('no assist once a pawn is out', () {
    for (var s = 0; s < 50; s++) {
      expect(adjust(3, home: false, seed: s), 3);
    }
  });

  test('bots lose about half their sixes, and stay in range', () {
    final rng = Random(7);
    var sixes = 0;
    for (var i = 0; i < 2000; i++) {
      final r = LudoDicePolicy.adjust(
        6,
        easy: true,
        isBot: true,
        allPawnsHome: false,
        random: rng,
      );
      expect(r, inInclusiveRange(1, 6));
      if (r == 6) sixes++;
    }
    expect(sixes / 2000, inInclusiveRange(0.45, 0.55));
  });
}
