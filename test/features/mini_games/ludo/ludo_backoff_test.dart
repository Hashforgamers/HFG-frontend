import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_backoff.dart';

/// Always returns 0.5, i.e. zero jitter.
class _Mid implements Random {
  @override
  double nextDouble() => 0.5;
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
}

void main() {
  test('delays double and cap at max', () {
    final b = LudoBackoff(maxAttempts: 10, random: _Mid());
    final delays = [for (var i = 0; i < 7; i++) b.fail().inSeconds];
    expect(delays, [1, 2, 4, 8, 16, 16, 16]);
  });

  test('exhausted after maxAttempts, reset starts over', () {
    final b = LudoBackoff(maxAttempts: 3, random: _Mid());
    b.fail();
    b.fail();
    expect(b.exhausted, isFalse);
    b.fail();
    expect(b.exhausted, isTrue);
    expect(b.attempts, 3);
    b.reset();
    expect(b.exhausted, isFalse);
    expect(b.fail(), const Duration(seconds: 1));
  });

  test('jitter stays within ±20%', () {
    final b = LudoBackoff(maxAttempts: 100, random: Random(7));
    for (var i = 0; i < 50; i++) {
      b.reset();
      final ms = b.fail().inMilliseconds;
      expect(ms, inInclusiveRange(800, 1200));
    }
  });
}
