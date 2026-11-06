import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/score/leader_marquee.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';

LeaderboardEntry e(String name, int score) => LeaderboardEntry(
  userId: name,
  displayName: name,
  totalScore: score,
  scores: const {},
);

void main() {
  test('share text has my rank, top 3 and the link', () {
    final text = arcadeShareText(
      top: [e('Ana', 12500), e('Bo', 900), e('Cy', 80), e('Di', 1)],
      myRank: 7,
      myScore: 1234,
    );
    expect(
      text,
      contains("I'm #7 on the Hash Arcade leaderboard with 1,234 pts!"),
    );
    expect(text, contains('🥇 Ana · 12,500 pts'));
    expect(text, contains('🥉 Cy · 80 pts'));
    expect(text, isNot(contains('Di')));
    expect(text, contains('https://www.hashforgamers.com/game/arcade'));
  });

  test('without a rank it leads with the board', () {
    final text = arcadeShareText(top: [e('Ana', 5)], board: 'Ludo');
    expect(text.split('\n').first, 'This week on the Ludo leaderboard 🎮');
  });
}
