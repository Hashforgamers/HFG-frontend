import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/notification_permission_gate.dart';

void main() {
  const p = PermissionAskPolicy();
  const day = 24 * 60 * 60 * 1000;

  test('asks on the first completed match', () {
    expect(p.shouldAsk(asks: 0, lastAskedMs: 0, nowMs: 5), isTrue);
  });

  test('after "Not now", waits 3 days before asking again', () {
    expect(p.shouldAsk(asks: 1, lastAskedMs: 0, nowMs: 2 * day), isFalse);
    expect(p.shouldAsk(asks: 1, lastAskedMs: 0, nowMs: 3 * day), isTrue);
  });

  test('never more than twice', () {
    expect(p.shouldAsk(asks: 2, lastAskedMs: 0, nowMs: 100 * day), isFalse);
  });
}
