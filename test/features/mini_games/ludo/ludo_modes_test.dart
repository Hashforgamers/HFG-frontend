import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/ludo/constants.dart';
import 'package:hash/features/mini_games/ludo/ludo_provider.dart';

class _FixedRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

void main() {
  testWidgets(
    'AI chooses and advances a legal pawn when multiple moves exist',
    (tester) async {
      final game = LudoProvider(
        againstAi: true,
        random: _FixedRandom(),
        soundEnabled: false,
      )..startGame();
      final yellow = game.player(LudoPlayerType.yellow);
      yellow.movePawn(0, 0);
      yellow.movePawn(1, 5);
      game.nextTurn();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(seconds: 1));
      expect(game.gameState, LudoGameState.pickPawn);
      await tester.pump(const Duration(milliseconds: 700));
      expect(yellow.pawns[1].step, 6);
      expect(game.currentTurnSeat, LudoPlayerType.blue);
      game.dispose();
    },
  );

  testWidgets('AI rolls for all three opponents then hands back to the human', (
    tester,
  ) async {
    final game = LudoProvider(
      againstAi: true,
      random: _FixedRandom(),
      soundEnabled: false,
    )..startGame();
    expect(game.isMyTurn, isTrue);
    game.throwDice();
    await tester.pump(const Duration(seconds: 1));
    expect(game.currentTurnSeat, LudoPlayerType.yellow);
    expect(game.isMyTurn, isFalse);
    game.throwDice();
    expect(game.diceStarted, isFalse); // Human cannot roll an AI seat.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(game.currentTurnSeat, LudoPlayerType.green);
    expect(game.isMyTurn, isTrue);
    expect(game.diceStarted, isFalse);
    game.dispose();
  });

  testWidgets('pass and play waits for a real person on every turn', (
    tester,
  ) async {
    final game = LudoProvider(random: _FixedRandom(), soundEnabled: false)
      ..startGame();
    game.throwDice();
    await tester.pump(const Duration(seconds: 1));
    expect(game.currentTurnSeat, LudoPlayerType.yellow);
    await tester.pump(const Duration(seconds: 5));
    expect(game.currentTurnSeat, LudoPlayerType.yellow);
    expect(game.isMyTurn, isTrue);
    expect(game.diceStarted, isFalse);
    game.dispose();
  });

  testWidgets('reset cancels the result of an in-flight roll', (tester) async {
    final game = LudoProvider(soundEnabled: false)..startGame();
    game.throwDice();
    game.resetGame();
    await tester.pump(const Duration(seconds: 2));
    expect(game.currentTurnSeat, LudoPlayerType.green);
    expect(game.gameState, LudoGameState.throwDice);
    expect(game.players.every((player) => player.pawnInsideCount == 4), isTrue);
    game.dispose();
  });

  testWidgets('leaving during a roll cancels delayed notifications and AI', (
    tester,
  ) async {
    final game = LudoProvider(againstAi: true, soundEnabled: false)
      ..startGame();
    game.throwDice();
    game.dispose();
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
