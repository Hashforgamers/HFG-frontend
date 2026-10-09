import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_quit_cooldown.dart';

void main() {
  const policy = LudoQuitPolicy(threshold: 2, cooldown: Duration(minutes: 2));
  const min = 60 * 1000;
  const now = 100 * min;

  test('one early quit is free', () {
    expect(policy.remaining([now - 10000], now), Duration.zero);
  });

  test('second quit inside the window starts the cooldown', () {
    final r = policy.remaining([now - 20 * min, now - 30000], now);
    expect(r, const Duration(seconds: 90));
  });

  test('cooldown expires', () {
    expect(
      policy.remaining([now - 20 * min, now - 3 * min], now),
      Duration.zero,
    );
  });

  test('quits older than the window are forgotten', () {
    expect(policy.remaining([now - 31 * min, now - 10000], now), Duration.zero);
    expect(policy.recent([now - 31 * min, now - 10000], now), [now - 10000]);
  });
}
