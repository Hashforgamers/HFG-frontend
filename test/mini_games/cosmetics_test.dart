import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/common/cosmetic_shop_screen.dart';
import 'package:hash/features/mini_games/common/cosmetics.dart';
import 'package:hash/features/mini_games/common/game_looks.dart';
import 'package:hash/features/mini_games/common/game_shops.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final catalogs = <String, List<Cosmetic<Object?>>>{
    ArrowLook.slot: ArrowLook.all,
    PacLook.slot: PacLook.all,
    WordlyLook.slot: WordlyLook.all,
    SnlLook.slot: SnlLook.all,
  };

  test('every catalog is well formed', () {
    final seen = <String>{};
    for (final MapEntry(key: slot, value: items) in catalogs.entries) {
      expect(items.first.id, CosmeticStore.defaultOf(slot));
      expect(items.first.price, 0);
      expect(items.where((i) => i.price == 0).length, 1);
      expect(
        items.map((i) => i.rarity).toSet(),
        CosmeticRarity.values.toSet(),
        reason: '$slot should offer every tier',
      );
      for (final item in items) {
        expect(item.id.startsWith('${slot}_'), isTrue);
        expect(seen.add(item.id), isTrue, reason: 'duplicate ${item.id}');
      }
    }
  });

  test(
    'buying equips per slot, persists, and survives a failed payment',
    () async {
      var fail = false;
      Future<int> spend(Cosmetic<Object?> item) async {
        if (fail) throw Exception('insufficient');
        return 9000 - item.price;
      }

      final store = CosmeticStore(spend: spend, mirror: false);
      await store.load();
      final neon = ArrowLook.all.firstWhere((i) => i.id == 'arrow_theme_neon');
      final pink = PacLook.all.firstWhere((i) => i.id == 'pac_theme_pink');

      expect(
        store.pick(ArrowLook.slot, ArrowLook.all).id,
        'arrow_theme_classic',
      );
      await store.equip(ArrowLook.slot, neon.id); // not owned: ignored
      expect(store.selected(ArrowLook.slot), 'arrow_theme_classic');

      expect(await store.buy(ArrowLook.slot, neon), 9000 - neon.price);
      expect(store.pick(ArrowLook.slot, ArrowLook.all).look, neon.look);
      expect(store.selected(PacLook.slot), 'pac_theme_classic');
      await expectLater(store.buy(ArrowLook.slot, neon), throwsStateError);

      fail = true;
      await expectLater(store.buy(PacLook.slot, pink), throwsException);
      expect(store.owns(pink.id), isFalse);

      await store.equip(ArrowLook.slot, 'arrow_theme_classic');
      final reopened = CosmeticStore(spend: spend, mirror: false);
      await reopened.load();
      expect(reopened.owns(neon.id), isTrue);
      expect(reopened.selected(ArrowLook.slot), 'arrow_theme_classic');
    },
  );

  testWidgets('each game shop lists its themes under rarity headings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = CosmeticStore(spend: (i) async => 0, mirror: false);

    for (final tabs in [
      GameShops.arrowEscape,
      GameShops.pacMan,
      GameShops.wordly,
      GameShops.snakesLadders,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: CosmeticShopScreen(
            key: ValueKey(tabs.first.slot),
            title: 'THEMES',
            tabs: tabs,
            store: store,
            balance: 99999,
          ),
        ),
      );
      await tester.pump();
      for (final rarity in CosmeticRarity.values) {
        expect(find.text(rarity.label), findsWidgets);
      }
      for (final item in tabs.first.items) {
        expect(find.text(item.name), findsWidgets);
      }
      expect(tester.takeException(), isNull);
    }

    // Buy the last Snakes & Ladders board.
    final gold = SnlLook.all.last;
    await tester.tap(find.text('Buy · ${gold.price}').last);
    await tester.pump();
    await tester.tap(find.text('Buy').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.selected(SnlLook.slot), gold.id);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 5));
  });
}
