part of 'hash_store_orders_cubit.dart';

abstract class HashStoreOrdersState extends Equatable {
  const HashStoreOrdersState();
}

class HashStoreOrdersInitial extends HashStoreOrdersState {
  @override
  List<Object?> get props => [];
}

class HashStoreOrdersLoading extends HashStoreOrdersState {
  @override
  List<Object?> get props => [];
}

class HashStoreOrdersLoaded extends HashStoreOrdersState {
  final List<Map<String, dynamic>> orders;
  const HashStoreOrdersLoaded({required this.orders});
  @override
  List<Object?> get props => [orders];
}

class HashStoreOrdersError extends HashStoreOrdersState {
  final String message;
  const HashStoreOrdersError({required this.message});
  @override
  List<Object?> get props => [message];
}