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
  final List<TournamentModel> allJoinedTournaments;
  final List<TournamentModel> joinableTournaments;
  final List<Map<String, dynamic>> myTeams;
  final GamerProfileModel? gamerProfile;
  const TournamentHomeLoaded({
    required this.tournaments,
    this.allJoinedTournaments = const [],
    this.joinableTournaments = const [],
    this.myTeams = const [],
    this.gamerProfile,
  });
  @override
  List<Object?> get props => [
    tournaments,
    allJoinedTournaments,
    joinableTournaments,
    myTeams,
    gamerProfile,
  ];
}

class TournamentHomeError extends TournamentHomeState {
  final String message;
  const TournamentHomeError({required this.message});
  @override
  List<Object?> get props => [message];
}
