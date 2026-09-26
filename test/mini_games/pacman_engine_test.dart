import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/pacman/pacman_engine.dart';

void main() {
  test('maze rows are all the same width', () {
    expect(kPacMaze.length, kPacRows);
    for (final row in kPacMaze) {
      expect(row.length, kPacCols, reason: row);
    }
  });

  test('every dot is reachable from the start', () {
    final seen = <int>{};
    final queue = [(9, 15)];
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeLast();
      final wx = (x % kPacCols + kPacCols) % kPacCols;
      if (PacEngine.isWall(wx, y) || !seen.add(PacEngine.key(wx, y))) continue;
      queue.addAll([(wx + 1, y), (wx - 1, y), (wx, y + 1), (wx, y - 1)]);
    }
    final e = PacEngine()..newGame();
    expect(e.dots.difference(seen), isEmpty);
    expect(e.pellets.difference(seen), isEmpty);
  });

  test('player moves and eats dots', () {
    final e = PacEngine(random: Random(1))..newGame();
    final before = e.dots.length;
    e.wanted = PacDir.left;
    for (var i = 0; i < 30; i++) {
      e.update(1 / 60);
    }
    expect(e.player.x, lessThan(9));
    expect(e.dots.length, lessThan(before));
    expect(e.score, greaterThan(0));
  });

  test('player never enters a wall', () {
    final e = PacEngine(random: Random(2))..newGame();
    final dirs = [PacDir.up, PacDir.left, PacDir.down, PacDir.right];
    final r = Random(3);
    for (var i = 0; i < 3000; i++) {
      if (i % 20 == 0) e.wanted = dirs[r.nextInt(4)];
      if (!e.update(1 / 60)) e.resetPositions();
      expect(PacEngine.isWall(e.player.x, e.player.y), isFalse);
      for (final g in e.ghosts) {
        if (g.mode != GhostMode.house) {
          expect(PacEngine.isWall(g.x, g.y), isFalse);
        }
      }
    }
  });

  test('ghosts leave the house over time', () {
    final e = PacEngine(random: Random(4))..newGame();
    for (var i = 0; i < 60 * 10; i++) {
      if (!e.update(1 / 60)) e.resetPositions();
    }
    expect(e.ghosts.where((g) => g.mode == GhostMode.house).length,
        lessThan(4));
  });
}
