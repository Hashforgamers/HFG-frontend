import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/snakes_ladders/snl_board.dart';
import 'package:hash/features/mini_games/snakes_ladders/snl_match.dart';

void main() {
  group('snlApplyRoll', () {
    test('plain move', () {
      expect(snlApplyRoll(10, 3), (landed: 13, to: 13));
    });
    test('ladder climbs', () {
      expect(snlApplyRoll(25, 3), (landed: 28, to: 84));
    });
    test('snake slides', () {
      expect(snlApplyRoll(85, 2), (landed: 87, to: 24));
    });
    test('needs exact roll to finish', () {
      expect(snlApplyRoll(97, 5), (landed: 97, to: 97));
      expect(snlApplyRoll(97, 3), (landed: 100, to: 100));
    });
    test('first roll can hit the ladder on 1', () {
      expect(snlApplyRoll(0, 1), (landed: 1, to: 38));
    });
  });

  test('board data is consistent', () {
    for (final e in kSnlLadders.entries) {
      expect(e.value, greaterThan(e.key));
      expect(kSnlSnakes.containsKey(e.key), isFalse);
    }
    for (final e in kSnlSnakes.entries) {
      expect(e.value, lessThan(e.key));
      expect(e.key, lessThan(kSnlGoal));
    }
  });

  test('cell layout zigzags from bottom-left', () {
    const side = 100.0;
    expect(snlCellCenter(1, side), const Offset(5, 95));
    expect(snlCellCenter(10, side), const Offset(95, 95));
    expect(snlCellCenter(11, side), const Offset(95, 85));
    expect(snlCellCenter(100, side), const Offset(5, 5));
  });

  testWidgets('board paints without errors', (tester) async {
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          width: 400,
          height: 400,
          child: CustomPaint(painter: SnlBoardPainter()),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
