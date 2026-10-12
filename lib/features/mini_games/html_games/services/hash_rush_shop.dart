import 'dart:math' as math;

import 'package:hash/core/repositories/model/hash_coin_spend.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

/// What Hash Rush upgrades and skins cost, in HashCoins.
///
/// The game page only names the item it wants; the price is decided here so a
/// page can never choose what it is charged. Ids match the game's own tables
/// (games/hash_rush/src/gameplay/Upgrades.ts and Skins.ts).
class HashRushShop {
  /// Upgrade id → (price of the first level, growth per level, top level).
  static const _upgrades = <String, (int, double, int)>{
    'fireRate': (60, 1.32, 15),
    'startArmy': (50, 1.3, 15),
    'unitDamage': (70, 1.34, 15),
    'unitHealth': (70, 1.34, 15),
    'cannonPower': (60, 1.32, 15),
    'abilityCooldown': (90, 1.4, 10),
  };

  /// The starter skin is free and never sold.
  static const _skins = <String, int>{
    'emerald': 150,
    'royal': 300,
    'arctic': 500,
    'shadow': 800,
    'gold': 1200,
  };

  /// Price of taking [id] from [level] to the next one, or null when there
  /// is no such upgrade or it is already maxed.
  static int? upgradeCost(String id, int level) {
    final def = _upgrades[id];
    if (def == null || level < 0 || level >= def.$3) return null;
    return (def.$1 * math.pow(def.$2, level) / 5).round() * 5;
  }

  static int? skinCost(String id) => _skins[id];

  /// Skin ids the player owns in each slot, read from [purchases]
  /// (`hash_rush_skin_<slot>_<id>` sources). Unknown ids are dropped.
  static Map<String, List<String>> ownedFrom(
    Iterable<HashCoinPurchase> purchases,
  ) {
    final owned = <String, List<String>>{'army': [], 'cannon': []};
    for (final p in purchases) {
      for (final slot in owned.keys) {
        final prefix = 'hash_rush_skin_${slot}_';
        if (!p.source.startsWith(prefix)) continue;
        final id = p.source.substring(prefix.length);
        if (_skins.containsKey(id) && !owned[slot]!.contains(id)) {
          owned[slot]!.add(id);
        }
      }
    }
    return owned;
  }

  /// [ownedFrom] the server's purchase ledger; empty when it can't be read.
  static Future<Map<String, List<String>>> ownedSkins() async {
    try {
      return ownedFrom(
        await locator<RemoteRepoInterface>().getHashCoinPurchases().timeout(
          const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      return ownedFrom(const []);
    }
  }

  /// The price list the game displays.
  static Map<String, Object> catalog() => {
    'upgrades': {
      for (final e in _upgrades.entries)
        e.key: [for (var l = 0; l < e.value.$3; l++) upgradeCost(e.key, l)],
    },
    'skins': _skins,
  };

  /// Resolves a `buy` request from the page to what it costs and the ledger
  /// source to record it under, or null when the request names nothing sold.
  static ({int cost, String source})? quote(Map<Object?, Object?> request) {
    final id = request['id'];
    if (id is! String) return null;
    switch (request['kind']) {
      case 'upgrade':
        final level = request['level'];
        if (level is! int) return null;
        final cost = upgradeCost(id, level);
        return cost == null
            ? null
            : (cost: cost, source: 'hash_rush_upgrade_$id');
      case 'skin':
        final slot = request['slot'];
        final cost = skinCost(id);
        if (cost == null || (slot != 'army' && slot != 'cannon')) return null;
        return (cost: cost, source: 'hash_rush_skin_${slot}_$id');
    }
    return null;
  }
}
