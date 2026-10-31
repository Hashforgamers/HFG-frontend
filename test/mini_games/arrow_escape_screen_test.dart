import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/arrow_escape/arrow_escape_engine.dart';
import 'package:hash/features/mini_games/arrow_escape/arrow_escape_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('tapping every free arrow clears the level', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(home: ArrowEscapeScreen(rng: Random(11))),
    );
    await tester.pump();
    await tester.tap(find.text('Play').last);
    await tester.pump();

    // Same seed, same board as the screen is showing.
    final board = ArrowEscapeRun(rng: Random(11)).board;
    final rect = tester.getRect(find.byKey(const Key('arrow_escape_board')));
    final cell = rect.width / board.cols;
    expect(find.textContaining('${board.arrows.length} arrows left'), findsOne);

    while (!board.cleared) {
      final arrow = board.hint!;
      board.launch(arrow);
      await tester.tapAt(
        rect.topLeft +
            Offset((arrow.head.x + 0.5) * cell, (arrow.head.y + 0.5) * cell),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.textContaining('LEVEL 1 CLEARED'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Next level').last);
    await tester.pump();
    expect(find.textContaining('LEVEL 2'), findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('arrow_escape_level'), 2);
  });
}
