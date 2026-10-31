import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/html_games/services/hash_rush_shop.dart';

void main() {
  test('upgrade prices climb per level and stop at the cap', () {
    expect(HashRushShop.upgradeCost('fireRate', 0), 60);
    expect(HashRushShop.upgradeCost('fireRate', 1), 80);
    expect(HashRushShop.upgradeCost('abilityCooldown', 9), isNotNull);
    expect(HashRushShop.upgradeCost('abilityCooldown', 10), isNull);
    expect(HashRushShop.upgradeCost('fireRate', -1), isNull);
    expect(HashRushShop.upgradeCost('bogus', 0), isNull);
  });

  test('the catalog lists every level of every upgrade and no free skin', () {
    final catalog = HashRushShop.catalog();
    final upgrades = catalog['upgrades']! as Map<String, List<int?>>;
    expect(upgrades['fireRate'], hasLength(15));
    expect(upgrades['abilityCooldown'], hasLength(10));
    expect(upgrades.values.expand((costs) => costs), everyElement(isPositive));
    expect((catalog['skins']! as Map).containsKey('classic'), isFalse);
  });

  test('a buy request is priced here, whatever else the page sends', () {
    final upgrade = HashRushShop.quote({
      'kind': 'upgrade',
      'id': 'unitDamage',
      'level': 2,
      'cost': 1,
    });
    expect(upgrade?.cost, HashRushShop.upgradeCost('unitDamage', 2));
    expect(upgrade?.source, 'hash_rush_upgrade_unitDamage');

    final skin = HashRushShop.quote({
      'kind': 'skin',
      'slot': 'cannon',
      'id': 'gold',
    });
    expect(skin?.cost, 1200);
    expect(skin?.source, 'hash_rush_skin_cannon_gold');
  });

  test('requests for things that are not sold are refused', () {
    expect(
      HashRushShop.quote({'kind': 'skin', 'slot': 'army', 'id': 'classic'}),
      isNull,
    );
    expect(
      HashRushShop.quote({'kind': 'skin', 'slot': 'hat', 'id': 'gold'}),
      isNull,
    );
    expect(
      HashRushShop.quote({'kind': 'upgrade', 'id': 'fireRate', 'level': 15}),
      isNull,
    );
    expect(
      HashRushShop.quote({'kind': 'upgrade', 'id': 'fireRate', 'level': '0'}),
      isNull,
    );
    expect(HashRushShop.quote({'kind': 'coins', 'id': 'gold'}), isNull);
  });
}
