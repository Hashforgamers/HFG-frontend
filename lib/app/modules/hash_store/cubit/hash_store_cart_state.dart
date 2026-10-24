part of 'hash_store_cart_cubit.dart';

class HashStoreCartState extends Equatable {
  /// Medusa cart; null when the account has no open cart.
  final Map<String, dynamic>? cart;
  final bool loading;

  /// An add/update/remove request is in flight.
  final bool busy;
  final String? error;

  const HashStoreCartState({
    this.cart,
    this.loading = false,
    this.busy = false,
    this.error,
  });

  List<Map<String, dynamic>> get items => (cart?['items'] as List? ?? [])
      .map((i) => Map<String, dynamic>.from(i as Map))
      .toList();

  int get itemCount =>
      items.fold(0, (sum, i) => sum + ((i['quantity'] as num?)?.toInt() ?? 0));

  @override
  List<Object?> get props => [cart, loading, busy, error];
}
