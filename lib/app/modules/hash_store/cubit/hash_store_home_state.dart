part of 'hash_store_home_cubit.dart';

abstract class HashStoreHomeState extends Equatable {
  const HashStoreHomeState();
}

class HashStoreHomeInitial extends HashStoreHomeState {
  @override
  List<Object?> get props => [];
}

class HashStoreHomeLoading extends HashStoreHomeState {
  @override
  List<Object?> get props => [];
}

class HashStoreHomeLoaded extends HashStoreHomeState {
  final List<Map<String, dynamic>> products;
  const HashStoreHomeLoaded({required this.products});
  @override
  List<Object?> get props => [products];
}

class HashStoreHomeError extends HashStoreHomeState {
  final String message;
  const HashStoreHomeError({required this.message});
  @override
  List<Object?> get props => [message];
}
