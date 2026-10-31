part of 'hash_store_categories_cubit.dart';

abstract class HashStoreCategoriesState extends Equatable {
  const HashStoreCategoriesState();
}

class HashStoreCategoriesInitial extends HashStoreCategoriesState {
  @override
  List<Object?> get props => [];
}

class HashStoreCategoriesLoading extends HashStoreCategoriesState {
  @override
  List<Object?> get props => [];
}

class HashStoreCategoriesLoaded extends HashStoreCategoriesState {
  final List<Map<String, dynamic>> categories;
  const HashStoreCategoriesLoaded({required this.categories});
  @override
  List<Object?> get props => [categories];
}

class HashStoreCategoriesError extends HashStoreCategoriesState {
  final String message;
  const HashStoreCategoriesError({required this.message});
  @override
  List<Object?> get props => [message];
}
