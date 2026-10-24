import 'package:equatable/equatable.dart';
import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/core/utils/safe_emit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'hash_store_cart_state.dart';

/// One per shop session, shared by the catalog, product and cart screens.
class HashStoreCartCubit extends Cubit<HashStoreCartState>
    with SafeEmit<HashStoreCartState> {
  HashStoreCartCubit() : super(const HashStoreCartState());

  final _store = MedusaStoreService.instance;

  Future<void> fetchCart() async {
    emit(HashStoreCartState(cart: state.cart, loading: true));
    try {
      emit(HashStoreCartState(cart: await _store.cart()));
    } catch (e) {
      emit(HashStoreCartState(cart: state.cart, error: e.toString()));
    }
  }

  /// Rethrows [VendorMismatch] so the screen can ask before replacing the
  /// cart; other failures are rethrown as [StoreException] after the state
  /// is restored.
  Future<void> addItem(
    Map<String, dynamic> product, {
    int quantity = 1,
    bool replaceCart = false,
  }) => _run(
    () => _store.addItem(
      variantId: product['variant_id'] as String,
      vendorId: product['vendor_id'] as String,
      quantity: quantity,
      replaceCart: replaceCart,
    ),
  );

  Future<void> setQuantity(String itemId, int quantity) =>
      _run(() => _store.setQuantity(_cartId, itemId, quantity));

  Future<void> removeItem(String itemId) =>
      _run(() => _store.removeItem(_cartId, itemId));

  /// After checkout (or when another screen changed the cart).
  void replace(Map<String, dynamic>? cart) =>
      emit(HashStoreCartState(cart: cart));

  String get _cartId => state.cart!['id'] as String;

  Future<void> _run(Future<Map<String, dynamic>?> Function() call) async {
    final before = state.cart;
    emit(HashStoreCartState(cart: before, busy: true));
    try {
      emit(HashStoreCartState(cart: await call()));
    } catch (_) {
      emit(HashStoreCartState(cart: before));
      rethrow;
    }
  }
}
