import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';

void main() {
  // Same cases as functions/reward_rules.test.js so client and server agree.
  test('IST week key starts Monday 00:00 IST', () {
    String k(DateTime utc) => MiniGameLeaderboardService.istWeekKey(utc);
    expect(k(DateTime.utc(2026, 10, 9, 6)), '20261005');
    expect(k(DateTime.utc(2026, 10, 11, 18, 29)), '20261005');
    expect(k(DateTime.utc(2026, 10, 11, 18, 30)), '20261012');
  });
}
