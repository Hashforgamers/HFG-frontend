part of 'hash_coin_cubit.dart';

abstract class HashCoinState extends Equatable {
  const HashCoinState();
}

class HashCoinInitial extends HashCoinState {
  @override
  List<Object?> get props => [];
}

class HashCoinLoading extends HashCoinState {
  @override
  List<Object?> get props => [];
}

class HashCoinLoaded extends HashCoinState {
  final int hashCoin;

  const HashCoinLoaded({required this.hashCoin});

  @override
  List<Object?> get props => [];
}

class HashCoinError extends HashCoinState {
  final String message;

  const HashCoinError({required this.message});

  @override
  List<Object?> get props => [];
}
