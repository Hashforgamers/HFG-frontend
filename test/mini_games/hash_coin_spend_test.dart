import 'package:flutter_test/flutter_test.dart';
import 'package:hash/core/repositories/model/hash_coin_spend.dart';
import 'package:hash/features/mini_games/common/mini_game_coins.dart';
import 'package:hash/features/mini_games/html_games/services/hash_rush_shop.dart';

void main() {
  group('spend refusals (backend contract, 12 Oct 2026)', () {
    test('402 carries the balance', () {
      final e = HashCoinSpendException.fromResponse(402, {'error': 'insufficient_hash_coins', 'hash_coins': 100});
      expect(e.insufficient, isTrue);
      expect(e.balance, 100);
      expect(MiniGameCoins.refusalMessage(e, 1000), 'You need 1000 HashCoins. You have 100.');
    });

    test('409 item_already_owned is not a charge', () {
      final e = HashCoinSpendException.fromResponse(409, {'error': 'item_already_owned', 'hash_coins': 3500});
      expect(e.alreadyOwned, isTrue);
      expect(e.insufficient, isFalse);
      expect(e.balance, 3500);
    });

    test('400s that mean "not sold" get a neutral message', () {
      for (final code in ['unknown_source', 'invalid_amount', 'invalid_item_id', 'unknown_item']) {
        final e = HashCoinSpendException.fromResponse(400, {'error': code});
        expect(e.notSold, isTrue, reason: code);
        expect(MiniGameCoins.refusalMessage(e, 60), contains('available yet'));
      }
      final other = HashCoinSpendException.fromResponse(409, {'error': 'idempotency_conflict'});
      expect(other.notSold, isFalse);
      expect(MiniGameCoins.refusalMessage(other, 60), contains('try again'));
    });

    test('garbage bodies do not throw', () {
      for (final body in [null, 'oops', 42, <String, Object?>{}, {'error': 7}]) {
        final e = HashCoinSpendException.fromResponse(500, body);
        expect(e.code, '');
        expect(e.balance, isNull);
      }
    });
  });

  group('purchases', () {
    final body = {
      'purchases': [
        {'source': 'ludo_skin_purchase', 'item_id': 'glossy', 'amount': 500, 'purchased_at': '2026-10-12T04:00:00Z'},
        {'source': 'hash_rush_skin_army_emerald', 'item_id': 'emerald', 'amount': 150},
        {'source': 'hash_rush_skin_cannon_gold', 'item_id': 'gold', 'amount': 1200},
        {'source': 'hash_rush_skin_army_not_a_skin', 'item_id': 'x', 'amount': 1},
        {'source': 'mini_game_cosmetic', 'item_id': 'neon_trail', 'amount': 300},
        {'source': 'mini_game_cosmetic'},
        'junk',
      ],
    };

    test('parses the ledger and skips malformed rows', () {
      final list = HashCoinPurchase.listFrom(body);
      expect(list.length, 5);
      expect(HashCoinPurchase.itemIds(list, 'ludo_skin_purchase'), {'glossy'});
      expect(HashCoinPurchase.itemIds(list, 'mini_game_cosmetic'), {'neon_trail'});
      expect(HashCoinPurchase.listFrom({'purchases': []}), isEmpty);
      expect(HashCoinPurchase.listFrom(null), isEmpty);
    });

    test('Hash Rush skins are restored per slot, unknown ids dropped', () {
      final owned = HashRushShop.ownedFrom(HashCoinPurchase.listFrom(body));
      expect(owned, {
        'army': ['emerald'],
        'cannon': ['gold'],
      });
    });
  });

  group('Hash Rush sources and prices sent to the backend', () {
    test('upgrades use hash_rush_upgrade_<id> with the ladder price', () {
      final q = HashRushShop.quote({'kind': 'upgrade', 'id': 'fireRate', 'level': 0});
      expect(q?.source, 'hash_rush_upgrade_fireRate');
      expect(q?.cost, 60);
      expect(HashRushShop.quote({'kind': 'upgrade', 'id': 'fireRate', 'level': 15}), isNull);
    });

    test('skins use hash_rush_skin_<slot>_<id>', () {
      final q = HashRushShop.quote({'kind': 'skin', 'slot': 'army', 'id': 'emerald'});
      expect(q?.source, 'hash_rush_skin_army_emerald');
      expect(q?.cost, 150);
      expect(HashRushShop.quote({'kind': 'skin', 'slot': 'hat', 'id': 'emerald'}), isNull);
      expect(HashRushShop.quote({'kind': 'skin', 'slot': 'army', 'id': 'classic'}), isNull);
    });

    test('the continue costs 1000', () => expect(MiniGameCoins.hashRushContinue, 1000));
  });
}
