part of 'purchase_pass_cubit.dart';

abstract class PurchasePassState extends Equatable {}

class PurchasePassInitial extends PurchasePassState {
  @override
  List<Object?> get props => [];
}

class PurchasePassLoading extends PurchasePassState {
  @override
  List<Object?> get props => [];
}

class PurchasePassSuccess extends PurchasePassState {
  final String confirmationMessage;
  PurchasePassSuccess({required this.confirmationMessage});
  @override
  List<Object?> get props => [confirmationMessage];
}

class PurchasePassError extends PurchasePassState {
  final String errorMessage;
  PurchasePassError({required this.errorMessage});
  @override
  List<Object?> get props => [errorMessage];
}
