import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/app/modules/chat/widgets/score_challenge_card.dart';
import 'package:hash/features/mini_games/mini_game_launcher.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';

void main() {
  test('challenge copy for the reader and for the sender', () {
    final theirs = scoreChallengeCopy(challenger: 'Zeyan', gameName: 'Road Rumble', score: 16, isMine: false);
    expect(theirs.title, 'Zeyan challenges you');
    expect(theirs.body, 'Beat 16 in Road Rumble');
    expect(theirs.action, 'Beat it');
    final mine = scoreChallengeCopy(challenger: 'Zeyan', gameName: 'Road Rumble', score: 16, isMine: true);
    expect(mine.title, 'You threw down a challenge');
    expect(mine.action, 'Play again');
    expect(scoreChallengeCopy(challenger: '  ', gameName: 'Ludo', score: 1, isMine: false).title, 'A player challenges you');
  });

  test('match invites map onto real leaderboard boards', () {
    expect(ChatService.leaderboardGameIdFor('ludo'), 'ludo');
    expect(ChatService.leaderboardGameIdFor('bird'), 'laggy_bird');
    expect(ChatService.leaderboardGameIdFor('wordly'), 'wordly');
    expect(ChatService.leaderboardGameIdFor('arrow'), 'arrow_escape');
    expect(ChatService.leaderboardGameIdFor('snl'), isNull); // no board of its own: lounge only
    for (final game in ['ludo', 'bird', 'wordly', 'arrow']) {
      expect(MiniGameLeaderboardService.supportedGameIds, contains(ChatService.leaderboardGameIdFor(game)));
    }
  });

  test('every leaderboard game can be opened from a challenge card', () {
    for (final id in MiniGameLeaderboardService.supportedGameIds) {
      expect(MiniGameLauncher.find(id), isNotNull, reason: id);
    }
    expect(MiniGameLauncher.find('not_a_game'), isNull);
  });
}
