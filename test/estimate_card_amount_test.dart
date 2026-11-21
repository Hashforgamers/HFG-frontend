import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/arena/views/booking_pricing_sheet.dart';

void main() {
  final card = {
    'rules': [
      {'min_minutes': 1, 'max_minutes': null, 'min_players': 1, 'max_players': 4,
       'amount': '250', 'unit_minutes': 60, 'per_player': false},
    ],
  };
  test('hourly rule scales by minutes', () {
    expect(estimateCardAmount(card, minutes: 90), 375);
    expect(estimateCardAmount(card, minutes: 30), 125);
  });
  test('no matching rule -> null, per-player and flat', () {
    expect(estimateCardAmount(card, minutes: 60, players: 5), isNull);
    final flat = {'rules': [{'min_minutes': 1, 'min_players': 1, 'max_players': 4,
      'amount': '99.995', 'unit_minutes': 0, 'per_player': true}]};
    expect(estimateCardAmount(flat, minutes: 45, players: 2), 199.99);
  });
}
