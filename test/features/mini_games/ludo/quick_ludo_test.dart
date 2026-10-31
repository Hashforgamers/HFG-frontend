import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/ludo/constants.dart';
import 'package:hash/features/mini_games/ludo/ludo_provider.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_match.dart';

LudoProvider _quick() => LudoProvider(
  tokens: 2,
  seats: {LudoPlayerType.green, LudoPlayerType.blue},
  soundEnabled: false,
)..startGame();

void main() {
  test('Quick Ludo gives every player 2 pawns', () {
    final game = _quick();
    for (final seat in kLudoSeatOrder) {
      expect(game.player(seat).pawns.length, 2);
    }
    game.dispose();
  });

  test('turns alternate between the two seated players only', () {
    final game = _quick();
    expect(game.currentTurnSeat, LudoPlayerType.green);
    game.nextTurn();
    expect(game.currentTurnSeat, LudoPlayerType.blue);
    game.nextTurn();
    expect(game.currentTurnSeat, LudoPlayerType.green);
    game.dispose();
  });

  test('1v1 ends as soon as one player brings both pawns home', () {
    final game = _quick();
    final green = game.player(LudoPlayerType.green);
    final home = green.path.length - 1;
    green.movePawn(0, home);
    green.movePawn(1, home);
    game.validateWin(LudoPlayerType.green);
    expect(game.winners, [LudoPlayerType.green]);
    expect(game.gameState, LudoGameState.finish);
    game.dispose();
  });

  test('classic 4-player game still needs three finishers', () {
    final game = LudoProvider(soundEnabled: false)..startGame();
    final green = game.player(LudoPlayerType.green);
    for (var i = 0; i < 4; i++) {
      green.movePawn(i, green.path.length - 1);
    }
    game.validateWin(LudoPlayerType.green);
    expect(game.winners, [LudoPlayerType.green]);
    expect(game.gameState, isNot(LudoGameState.finish));
    game.dispose();
  });

  test('first match is a 2-token 1v1 vs AI, unranked and not Quick Ludo', () {
    final game = LudoProvider.firstMatch()..startGame();
    expect(game.firstMatch, isTrue);
    expect(game.againstAi, isTrue);
    expect(game.quickLudo, isFalse);
    expect(game.activeSeats, {LudoPlayerType.green, LudoPlayerType.blue});
    expect(game.player(LudoPlayerType.green).pawns.length, 2);
    game.dispose();
  });
}
