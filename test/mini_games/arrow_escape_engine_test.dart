import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/arrow_escape/arrow_escape_engine.dart';

EscapeArrow _arrow(int id, List<(int, int)> cells, ArrowDir dir) => EscapeArrow(
  id: id,
  cells: [for (final (x, y) in cells) Point(x, y)],
  dir: dir,
);

void main() {
  test('generated boards are valid and always solvable', () {
    for (var seed = 0; seed < 40; seed++) {
      for (final level in [1, 4, 9, 14]) {
        final (cols, rows) = ArrowEscapeRun.sizeFor(level);
        final board = ArrowBoard.generate(
          cols: cols,
          rows: rows,
          rng: Random(seed),
          maxLength: 6,
        );
        expect(board.arrows.length, greaterThan(2));
        expect(board.solvable, isTrue, reason: 'seed $seed level $level');

        final seen = <Point<int>>{};
        for (final a in board.arrows) {
          expect(a.length, greaterThanOrEqualTo(2));
          // Head points away from the neck; body is one connected chain.
          expect(a.head.x - a.cells[1].x, a.dir.dx);
          expect(a.head.y - a.cells[1].y, a.dir.dy);
          for (var i = 0; i < a.length; i++) {
            final c = a.cells[i];
            expect(c.x >= 0 && c.x < cols && c.y >= 0 && c.y < rows, isTrue);
            expect(seen.add(c), isTrue, reason: 'cell used twice');
            if (i > 0) {
              final p = a.cells[i - 1];
              expect((c.x - p.x).abs() + (c.y - p.y).abs(), 1);
            }
          }
        }
      }
    }
  });

  test('an arrow escapes only when its lane is clear', () {
    // A (row 0) points right at B, which points down and is free.
    final a = _arrow(0, [(1, 0), (0, 0)], ArrowDir.right);
    final b = _arrow(1, [(3, 1), (3, 0)], ArrowDir.down);
    final board = ArrowBoard(cols: 4, rows: 4, arrows: [a, b]);

    expect(board.arrowAt(3, 0), b);
    expect(board.arrowAt(2, 2), isNull);
    expect(board.hint, b);

    final blocked = board.launch(a);
    expect(blocked.escaped, isFalse);
    expect(blocked.steps, 1);
    expect(board.arrows.length, 2);

    expect(board.launch(b).escaped, isTrue);
    final free = board.launch(a);
    expect(free.escaped, isTrue);
    expect(free.steps, 2);
    expect(board.cleared, isTrue);
  });

  test('levels are fixed puzzles that get harder as they climb', () {
    int cells(int level) {
      final (cols, rows) = ArrowEscapeRun.sizeFor(level);
      return cols * rows;
    }

    double average(Iterable<int> levels, num Function(ArrowBoard) of) {
      final values = [for (final l in levels) of(ArrowEscapeRun.boardFor(l))];
      return values.reduce((a, b) => a + b) / values.length;
    }

    for (final level in [1, 7, 23, 60, 150]) {
      final a = ArrowEscapeRun.boardFor(level);
      final b = ArrowEscapeRun.boardFor(level);
      expect(a.solvable, isTrue);
      expect(
        [for (final x in a.arrows) x.cells],
        [for (final x in b.arrows) x.cells],
      );
    }
    expect(cells(40), greaterThan(cells(10)));
    expect(cells(10), greaterThan(cells(1)));
    expect(ArrowEscapeRun.hintsFor(30), lessThan(ArrowEscapeRun.hintsFor(1)));

    final early = [1, 2, 3, 4, 5];
    final late = [40, 41, 42, 43, 44];
    expect(
      average(late, (b) => b.depth!),
      greaterThan(average(early, (b) => b.depth!) + 2),
    );
    expect(
      average(late, (b) => b.freeCount / b.arrows.length),
      lessThan(average(early, (b) => b.freeCount / b.arrows.length)),
    );
  });

  test('hints run out, and a revive refills lives on the same board', () {
    final run = ArrowEscapeRun(startLevel: 30);
    expect(run.level, 30);
    expect(run.hints, 1);
    expect(run.useHint(), isNotNull);
    expect(run.useHint(), isNull);

    final stuck = run.board.arrows.firstWhere(
      (a) => !run.board.probe(a).escaped,
    );
    for (var i = 0; i < ArrowEscapeRun.maxLives; i++) {
      run.tap(stuck);
    }
    expect(run.over, isTrue);
    final left = run.board.arrows.length;
    run.revive();
    expect(run.over, isFalse);
    expect(run.board.arrows.length, left);

    // Past the refill levels a clear no longer hands a life back.
    run.lives = 1;
    run.nextLevel();
    expect(run.lives, 1);
  });

  test('two arrows facing each other cannot be solved', () {
    final board = ArrowBoard(
      cols: 4,
      rows: 1,
      arrows: [
        _arrow(0, [(1, 0), (0, 0)], ArrowDir.right),
        _arrow(1, [(2, 0), (3, 0)], ArrowDir.left),
      ],
    );
    expect(board.solvable, isFalse);
    expect(board.hint, isNull);
  });

  test('a run scores streaks, pays level bonuses and ends on three bumps', () {
    final run = ArrowEscapeRun(rng: Random(3));
    final count = run.board.arrows.length;

    var expected = 0;
    for (var i = 0; i < count; i++) {
      final (outcome, _) = run.tap(run.board.hint!);
      expected += 10 + 2 * min(i, 10);
      expect(
        outcome,
        i == count - 1 ? ArrowTapOutcome.levelCleared : ArrowTapOutcome.escaped,
      );
    }
    expect(run.score, expected + ArrowEscapeRun.clearBonus(1));

    run.nextLevel();
    expect(run.level, 2);
    expect(run.lives, ArrowEscapeRun.maxLives);

    // Swap in a deadlocked pair to force bumps.
    run.board = ArrowBoard(
      cols: 4,
      rows: 1,
      arrows: [
        _arrow(0, [(1, 0), (0, 0)], ArrowDir.right),
        _arrow(1, [(2, 0), (3, 0)], ArrowDir.left),
      ],
    );
    final before = run.score;
    expect(run.tap(run.board.arrows.first).$1, ArrowTapOutcome.blocked);
    expect(run.streak, 0);
    expect(run.tap(run.board.arrows.first).$1, ArrowTapOutcome.blocked);
    expect(run.tap(run.board.arrows.first).$1, ArrowTapOutcome.gameOver);
    expect(run.over, isTrue);
    expect(run.score, before);
  });
}
