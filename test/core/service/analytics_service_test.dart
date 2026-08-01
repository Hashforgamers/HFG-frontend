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
