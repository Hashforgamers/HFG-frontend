import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_matchmaking_timer.dart';

void main() {
  const t = LudoMatchmakingTimer(fillSeconds: 20);
  const created = 1000000;

  group('secondsLeft', () {
    test('counts down and rounds up', () {
      expect(t.secondsLeft(createdAtMs: created, nowMs: created), 20);
      expect(t.secondsLeft(createdAtMs: created, nowMs: created + 500), 20);
      expect(t.secondsLeft(createdAtMs: created, nowMs: created + 19001), 1);
    });
    test('never negative, and 0 for unknown creation time', () {
      expect(t.secondsLeft(createdAtMs: created, nowMs: created + 60000), 0);
      expect(t.secondsLeft(createdAtMs: 0, nowMs: created), 0);
    });
  });

  group('isDue (host)', () {
    bool due(int waitedMs, {bool full = false, int seenAt = 0}) => t.isDue(
      isHost: true,
      isFull: full,
      createdAtMs: created,
      nowMs: created + waitedMs,
      secondPlayerSeenAtMs: seenAt,
    );

    test('waits the full fill time alone', () {
      expect(due(19999), isFalse);
      expect(due(20000), isTrue);
    });
    test(
      'starts at once when full',
      () => expect(due(1000, full: true), isTrue),
    );
    test('starts 3s after a second player lands', () {
      final seen = created + 5000;
      expect(due(7999, seenAt: seen), isFalse);
      expect(due(8000, seenAt: seen), isTrue);
    });
  });

  test('non-host only steps in after the fallback', () {
    bool due(int waitedMs) => t.isDue(
      isHost: false,
      isFull: true,
      createdAtMs: created,
      nowMs: created + waitedMs,
      secondPlayerSeenAtMs: created,
    );
    expect(due(29999), isFalse);
    expect(due(30000), isTrue);
  });
}
