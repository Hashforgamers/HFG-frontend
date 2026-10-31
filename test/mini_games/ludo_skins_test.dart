import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_match.dart';
import 'package:hash/features/mini_games/ludo/skins/ludo_board_theme.dart';
import 'package:hash/features/mini_games/ludo/skins/ludo_dice_skin.dart';
import 'package:hash/features/mini_games/ludo/skins/ludo_skin.dart';
import 'package:hash/features/mini_games/ludo/skins/ludo_skin_store.dart';
import 'package:hash/features/mini_games/ludo/skins/ludo_skins_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final star = LudoSkin.byId('star');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('the catalog has unique ids and a free default', () {
    final ids = LudoSkin.all.map((s) => s.id).toSet();
    expect(ids.length, LudoSkin.all.length);
    expect(LudoSkin.byId(LudoSkin.classicId).price, 0);
    expect(LudoSkin.all.where((s) => s.price == 0).length, 1);
    expect(LudoSkin.byId('from_the_future').id, LudoSkin.classicId);
    expect(LudoSkin.byId(null).id, LudoSkin.classicId);
  });

  test('buying pays once, then owns, equips and remembers the skin', () async {
    final paid = <String>[];
    Future<int> spend(LudoShopItem s) async {
      paid.add(s.id);
      return 5000 - s.price;
    }

    final store = LudoSkinStore(spend: spend, mirror: false);
    await store.load();
    expect(store.selected, LudoSkin.classicId);
    expect(store.owns(star.id), isFalse);

    // Can't wear what you don't own.
    await store.equip(star.id);
    expect(store.selected, LudoSkin.classicId);

    expect(await store.buy(star), 5000 - star.price);
    expect(store.owns(star.id), isTrue);
    expect(store.selected, star.id);
    await expectLater(store.buy(star), throwsStateError);
    expect(paid, [star.id]);

    await store.equip(LudoSkin.classicId);
    final reopened = LudoSkinStore(spend: spend, mirror: false);
    await reopened.load();
    expect(reopened.owns(star.id), isTrue);
    expect(reopened.selected, LudoSkin.classicId);
  });

  test('board themes are bought and equipped separately from tokens', () async {
    final ids = LudoBoardTheme.all.map((t) => t.id).toSet();
    expect(ids.length, LudoBoardTheme.all.length);
    expect(ids.every(LudoBoardTheme.isBoard), isTrue);
    expect(LudoSkin.all.any((s) => LudoBoardTheme.isBoard(s.id)), isFalse);
    expect(LudoBoardTheme.byId('board_unknown').id, LudoBoardTheme.classicId);

    final store = LudoSkinStore(spend: (i) async => 0, mirror: false);
    await store.load();
    expect(store.selectedBoard, LudoBoardTheme.classicId);
    await store.buy(star);
    await store.buy(LudoBoardTheme.byId('board_neon'));
    expect(store.selected, star.id);
    expect(store.selectedBoard, 'board_neon');

    await store.equip(LudoBoardTheme.classicId);
    expect(store.selectedBoard, LudoBoardTheme.classicId);
    expect(store.selected, star.id);

    // Dice are a third, independent slot.
    final diceIds = LudoDiceSkin.all.map((d) => d.id).toSet();
    expect(diceIds.length, LudoDiceSkin.all.length);
    expect(diceIds.every(LudoDiceSkin.isDice), isTrue);
    expect(store.selectedDice, LudoDiceSkin.classicId);
    await store.buy(LudoDiceSkin.byId('dice_neon'));
    expect(store.selectedDice, 'dice_neon');
    expect(store.selected, star.id);
    expect(store.selectedBoard, LudoBoardTheme.classicId);

    // Every category has all three rarity tiers, with the free item Normal.
    for (final List<LudoShopItem> items in [
      LudoSkin.all,
      LudoBoardTheme.all,
      LudoDiceSkin.all,
    ]) {
      expect(items.map((i) => i.rarity).toSet(), LudoRarity.values.toSet());
      expect(items.first.rarity, LudoRarity.normal);
    }

    final reopened = LudoSkinStore(spend: (i) async => 0, mirror: false);
    await reopened.load();
    expect(reopened.owns('board_neon'), isTrue);
    expect(reopened.selectedBoard, LudoBoardTheme.classicId);
    expect(reopened.selectedDice, 'dice_neon');
  });

  testWidgets('every painted board and pawn skin draws', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ListView(
          children: [
            for (final theme in LudoBoardTheme.all.skip(1))
              SizedBox(
                width: 300,
                height: 300,
                child: LudoBoardSurface(theme: theme),
              ),
            for (final dice in LudoDiceSkin.all.skip(1))
              for (final value in const [1, 2, 3, 4, 5, 6])
                SizedBox(
                  width: 60,
                  height: 60,
                  child: LudoDice(
                    skin: dice,
                    value: value,
                    rolling: value == 6,
                  ),
                ),
            for (final skin in LudoSkin.all)
              SizedBox(
                width: 40,
                height: 40,
                child: LudoPawn(skin: skin, color: Colors.red),
              ),
          ],
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(tester.takeException(), isNull);
  });

  test('a seat carries its token, board and dice to the other players', () {
    const seat = LudoSeatInfo(
      uid: 'u1',
      name: 'Zed',
      skin: 'star',
      board: 'board_diamond',
      dice: 'dice_neon',
    );
    final copy = LudoSeatInfo.fromMap(seat.toMap());
    expect(copy.skin, 'star');
    expect(copy.board, 'board_diamond');
    expect(copy.dice, 'dice_neon');

    // Players on Classic (or an older app) send nothing extra.
    final plain = const LudoSeatInfo(uid: 'u2', name: 'Ana').toMap();
    expect(plain.keys, isNot(contains('board')));
    expect(LudoSeatInfo.fromMap(plain).dice, isNull);
  });

  test('a failed payment leaves the skin locked', () async {
    final store = LudoSkinStore(
      spend: (_) async => throw Exception('insufficient'),
      mirror: false,
    );
    await store.load();
    await expectLater(store.buy(star), throwsException);
    expect(store.owns(star.id), isFalse);
    expect(store.selected, LudoSkin.classicId);
  });

  testWidgets('the shop buys after a confirm and blocks unaffordable skins', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final store = LudoSkinStore(
      spend: (s) async => 600 - s.price,
      mirror: false,
    );

    await tester.pumpWidget(
      MaterialApp(home: LudoSkinsScreen(store: store, balance: 600)),
    );
    await tester.pump();
    expect(find.text('Equipped'), findsWidgets);

    // 800 coins with a 600 balance: refused before any dialog.
    await tester.tap(find.text('Buy · 800').last);
    await tester.pump();
    expect(find.text('Buy'), findsNothing);
    expect(store.owns('bullseye'), isFalse);

    await tester.tap(find.text('Buy · 500').last);
    await tester.pump();
    await tester.tap(find.text('Buy').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(store.owns('glossy'), isTrue);
    expect(store.selected, 'glossy');
    expect(find.textContaining('100'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Boards').last);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Midnight'), findsWidgets);
    expect(find.text('NORMAL'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Dice').last);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Ruby'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
