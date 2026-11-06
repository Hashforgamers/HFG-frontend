import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/arena/utils/arena_games_extractor.dart';

void main() {
  test('placeholder and console names never become game cards', () {
    for (final name in ['Unknown', 'n/a', 'TBD', 'PC', '']) {
      expect(isLikelyArenaGameTitle(name), isFalse, reason: name);
    }
    expect(isLikelyArenaGameTitle('Valorant'), isTrue);
    expect(sanitizeArenaGameList(['Unknown', 'Valorant', 'PS5']), [
      'Valorant',
    ]);
  });
}
