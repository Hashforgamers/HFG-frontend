part of 'transaction_cubit.dart';


abstract class TransactionState extends Equatable {
  const TransactionState(); 
}

class TransactionInitial extends TransactionState {
  @override
  List<Object> get props => [];
}

class TransactionLoading extends TransactionState {
  @override 
  List<Object> get props => [];
}

class TransactionLoaded extends TransactionState {
  final List<TransactionHistoryModel> transactions;
  const TransactionLoaded({required this.transactions});
  @override
  List<Object> get props => [transactions];
}

class TransactionError extends TransactionState {
  final String message;
  const TransactionError({required this.message});
  @override
  List<Object> get props => [message];
}