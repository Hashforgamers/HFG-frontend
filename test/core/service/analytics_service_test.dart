import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/service/analytics_service.dart';

void main() {
  test('analytics parameters omit null, empty, and PII values', () {
    final result = AnalyticsService.sanitizeParameters({
      'tournament_id': 't-1',
      'city': null,
      'game_name': '  Valorant  ',
      'source_screen': '   ',
      'email': 'player@example.com',
      'phone_number': '+910000000000',
      'upi_id': 'player@bank',
      'host_verified': true,
    });

    expect(result, {
      'tournament_id': 't-1',
      'game_name': 'Valorant',
      'host_verified': 1,
    });
  });

  test('over-long string values are trimmed to the Firebase limit', () {
    final result = AnalyticsService.sanitizeParameters({
      'deep_link': 'https://hashforgamers.co.in/tournament/123?${'x' * 200}',
    });
    expect((result['deep_link']! as String).length, 100);
  });

  test('caller parameters keep priority when the event exceeds the cap', () {
    // Firebase drops anything past 25 parameters without telling us, so the
    // parameters the caller asked for have to claim the budget first.
    final caller = <String, Object>{
      for (var i = 0; i < 22; i++) 'caller_$i': i,
    };
    final standard = <String, Object>{
      'hash_session_id': 's-1',
      'platform': 'android',
      'app_version': '1.5.10',
      'build_number': '42',
      'timestamp': 'now',
      'screen_name': 'home',
    };

    final merged = AnalyticsService.mergeParameters(
      caller: caller,
      standard: standard,
    );

    expect(merged.length, 25);
    for (final key in caller.keys) {
      expect(merged.containsKey(key), isTrue, reason: key);
    }
  });

  test('payment failures are normalized', () {
    expect(
      AnalyticsService.normalizeFailureReason('Connection timeout'),
      'timeout',
    );
    expect(
      AnalyticsService.normalizeFailureReason('Payment declined'),
      'payment_declined',
    );
    expect(
      AnalyticsService.normalizeFailureReason('user cancelled'),
      'user_cancelled',
    );
  });
}
