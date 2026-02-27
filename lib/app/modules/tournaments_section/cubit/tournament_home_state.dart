part of 'tournament_home_cubit.dart';

abstract class TournamentHomeState extends Equatable {
  const TournamentHomeState();
  @override
  List<Object?> get props => [];
}

class TournamentHomeInitial extends TournamentHomeState {}

class TournamentHomeLoading extends TournamentHomeState {}

class TournamentHomeLoaded extends TournamentHomeState {
  final List<TournamentModel> tournaments;
  final List<TournamentModel> joinableTournaments;
  final List<Map<String, dynamic>> myTeams;
  const TournamentHomeLoaded({
    required this.tournaments,
    this.joinableTournaments = const [],
    this.myTeams = const [],
  });
  @override
  List<Object?> get props => [tournaments, joinableTournaments, myTeams];
}

class TournamentHomeError extends TournamentHomeState {
  final String message;
  const TournamentHomeError({required this.message});
  @override
  List<Object?> get props => [message];
}
