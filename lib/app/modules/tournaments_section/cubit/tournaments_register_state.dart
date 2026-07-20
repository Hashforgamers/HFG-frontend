part of 'tournaments_register_cubit.dart';

abstract class TournamentsRegisterState extends Equatable {
  const TournamentsRegisterState();

  @override
  List<Object?> get props => [];
}

class TournamentsRegisterInitial extends TournamentsRegisterState {}

class TournamentsRegisterLoading extends TournamentsRegisterState {}

class TournamentsRegisterSuccess extends TournamentsRegisterState {
  final Map<String, dynamic> data;
  const TournamentsRegisterSuccess({required this.data});

  @override
  List<Object?> get props => [data];
}

class TournamentsRegisterSettlementPending extends TournamentsRegisterState {
  final String registrationId;
  final String message;

  const TournamentsRegisterSettlementPending({
    required this.registrationId,
    required this.message,
  });

  @override
  List<Object?> get props => [registrationId, message];
}

class TournamentsRegisterError extends TournamentsRegisterState {
  final String message;
  const TournamentsRegisterError({required this.message});

  @override
  List<Object?> get props => [message];
}
