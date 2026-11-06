import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/home/widgets/home_sign_off_card.dart';

void main() {
  test('copy follows the streak and never names a country', () {
    final long = signOffCopy(streak: 3, name: 'Zeyan');
    expect(long.title, "You're on a 3-day streak, Zeyan");
    expect(long.body, 'One game today keeps it alive.');
    expect(signOffCopy(streak: 1, name: 'Zeyan').title, 'Day 1 of your streak, Zeyan');
    expect(signOffCopy(streak: 0, name: 'Zeyan').title, 'Ready when you are, Zeyan');
    for (final streak in [0, 1, 2, 40]) {
      final copy = signOffCopy(streak: streak, name: 'A');
      expect('${copy.title} ${copy.body}'.toLowerCase(), isNot(contains('india')));
    }
  });

  test('copy reads naturally without a name', () {
    expect(signOffCopy(streak: 5, name: '').title, "You're on a 5-day streak");
    expect(signOffCopy(streak: 0, name: '').title, 'Ready when you are');
  });

  test('first name is the first word of the display name', () {
    expect(firstNameOf('Zeyan Ansari'), 'Zeyan');
    expect(firstNameOf('  Zeyan   Ansari '), 'Zeyan');
    expect(firstNameOf(''), '');
    expect(firstNameOf('   '), '');
  });
}
