part of 'hash_store_cart_cubit.dart';

abstract class HashStoreCartState extends Equatable {
  const HashStoreCartState();
}

class HashStoreCartInitial extends HashStoreCartState {
  @override
  List<Object?> get props => [];
}

class HashStoreCartLoading extends HashStoreCartState {
  @override
  List<Object?> get props => [];
}

class HashStoreCartLoaded extends HashStoreCartState {
  final List<Map<String, dynamic>> cartItems;
  const HashStoreCartLoaded({required this.cartItems});
  @override
  List<Object?> get props => [cartItems];
}

class HashStoreCartError extends HashStoreCartState {
  final String message;
  const HashStoreCartError({required this.message});
  @override
  List<Object?> get props => [message];
}
