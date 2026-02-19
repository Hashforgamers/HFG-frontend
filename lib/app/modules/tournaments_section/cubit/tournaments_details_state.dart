part of 'tournaments_details_cubit.dart';

abstract class TournamentsDetailsState extends Equatable {
  const TournamentsDetailsState();
  @override
  List<Object?> get props => [];
}

class TournamentsDetailsInitial extends TournamentsDetailsState {}

class TournamentsDetailsLoading extends TournamentsDetailsState {}

class TournamentsDetailsLoaded extends TournamentsDetailsState {
  final TournamentModel tournament;
  const TournamentsDetailsLoaded({required this.tournament});
  @override
  List<Object?> get props => [tournament];
}

class TournamentsDetailsError extends TournamentsDetailsState {
  final String message;
  const TournamentsDetailsError({required this.message});
  @override
  List<Object?> get props => [message];
}
