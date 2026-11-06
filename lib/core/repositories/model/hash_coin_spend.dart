/// Why `POST /api/users/hash-coins/spend` refused a purchase.
///
/// [code] is the server's `error` string: `insufficient_hash_coins` (402),
/// `item_already_owned` or `idempotency_conflict` (409), or one of the 400s
/// (`unknown_source`, `invalid_amount`, `invalid_item_id`, `unknown_item`,
/// `invalid_reference_id`, `invalid_request`). Empty when the server sent
/// nothing recognisable.
class HashCoinSpendException implements Exception {
  const HashCoinSpendException({
    required this.code,
    this.statusCode,
    this.balance,
  });

  final String code;
  final int? statusCode;

  /// The player's balance, when the server included it (402 and
  /// `item_already_owned` do).
  final int? balance;

  bool get insufficient => code == 'insufficient_hash_coins';

  /// The item is already this player's; nothing was charged.
  bool get alreadyOwned => code == 'item_already_owned';

  /// The app asked for something the server does not sell (yet), or at a
  /// price it does not accept: an app/backend mismatch, not a player error.
  bool get notSold =>
      code == 'unknown_source' ||
      code == 'invalid_amount' ||
      code == 'invalid_item_id' ||
      code == 'unknown_item';

  /// Builds the exception from a response's status and decoded body.
  factory HashCoinSpendException.fromResponse(int? statusCode, Object? body) {
    String code = '';
    int? balance;
    if (body is Map) {
      final error = body['error'];
      if (error is String) code = error;
      final coins = body['hash_coins'];
      if (coins is num) balance = coins.toInt();
    }
    return HashCoinSpendException(
      code: code,
      statusCode: statusCode,
      balance: balance,
    );
  }

  @override
  String toString() =>
      'HashCoinSpendException(${code.isEmpty ? 'unknown' : code}, status: $statusCode)';
}

/// A permanent item the player has bought with HashCoins, as returned by
/// `GET /api/users/hash-coins/purchases`. Consumables and upgrades are not
/// listed there.
class HashCoinPurchase {
  const HashCoinPurchase({
    required this.source,
    required this.itemId,
    required this.amount,
  });

  /// e.g. `ludo_skin_purchase`, `mini_game_cosmetic`,
  /// `hash_rush_skin_army_emerald`.
  final String source;
  final String itemId;
  final int amount;

  /// Parses the endpoint's body; anything malformed is skipped.
  static List<HashCoinPurchase> listFrom(Object? body) {
    final raw = body is Map ? body['purchases'] : null;
    if (raw is! List) return const [];
    return [
      for (final e in raw)
        if (e is Map && e['source'] is String && e['item_id'] is String)
          HashCoinPurchase(
            source: e['source'] as String,
            itemId: e['item_id'] as String,
            amount: e['amount'] is num ? (e['amount'] as num).toInt() : 0,
          ),
    ];
  }

  /// Item ids bought under [source].
  static Set<String> itemIds(
    Iterable<HashCoinPurchase> purchases,
    String source,
  ) => {
    for (final p in purchases)
      if (p.source == source) p.itemId,
  };
}
