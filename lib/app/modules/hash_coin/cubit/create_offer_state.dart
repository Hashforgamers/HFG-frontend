part of 'create_offer_cubit.dart';

abstract class CreateOfferState extends Equatable {
  const CreateOfferState();
}

class CreateOfferInitial extends CreateOfferState {
  @override
  List<Object?> get props => [];
}

class CreateOfferLoading extends CreateOfferState {
  @override
  List<Object?> get props => [];
}

class CreateOfferSuccess extends CreateOfferState {
  @override
  List<Object?> get props => [];
}

class CreateOfferFailure extends CreateOfferState {
  final String message;
  const CreateOfferFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
