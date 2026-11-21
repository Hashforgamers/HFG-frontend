import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/live/utils/live_time.dart';

void main() {
  final now = DateTime(2026, 10, 25, 18);

  test('startsInLabel', () {
    expect(
      startsInLabel(now.add(const Duration(seconds: 30)), now),
      'Starting now',
    );
    expect(
      startsInLabel(now.add(const Duration(minutes: 42)), now),
      'Starts in 42m',
    );
    expect(
      startsInLabel(now.add(const Duration(hours: 2, minutes: 15)), now),
      'Starts in 2h 15m',
    );
    expect(
      startsInLabel(now.add(const Duration(hours: 3)), now),
      'Starts in 3h',
    );
    expect(
      startsInLabel(now.add(const Duration(hours: 30)), now),
      'Starts tomorrow',
    );
    expect(
      startsInLabel(now.add(const Duration(days: 4, hours: 1)), now),
      'Starts in 4 days',
    );
    expect(
      startsInLabel(now.subtract(const Duration(minutes: 5)), now),
      'Starting now',
    );
  });

  test('agoLabel', () {
    expect(
      agoLabel(now.subtract(const Duration(seconds: 20)), now),
      'just now',
    );
    expect(agoLabel(now.subtract(const Duration(minutes: 9)), now), '9m ago');
    expect(agoLabel(now.subtract(const Duration(hours: 5)), now), '5h ago');
    expect(agoLabel(now.subtract(const Duration(days: 3)), now), '3d ago');
    expect(agoLabel(now.subtract(const Duration(days: 15)), now), '2w ago');
  });
}
