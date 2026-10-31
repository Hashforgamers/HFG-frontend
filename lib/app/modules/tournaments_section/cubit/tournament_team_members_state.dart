part of 'tournament_team_members_cubit.dart';

abstract class TournamentTeamMembersState extends Equatable {
  const TournamentTeamMembersState();

  @override
  List<Object?> get props => [];
}

class TournamentTeamMembersInitial extends TournamentTeamMembersState {}

class TournamentTeamMembersLoading extends TournamentTeamMembersState {}

class TournamentTeamMembersLoaded extends TournamentTeamMembersState {
  const TournamentTeamMembersLoaded({
    required this.teamId,
    required this.eventId,
    required this.tournament,
    required this.members,
  });

  final String teamId;
  final String eventId;
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> members;

  String get tournamentSource =>
      (tournament['source'] ?? '').toString().trim().toLowerCase();

  bool get isCommunity => tournamentSource == 'community';

  @override
  List<Object?> get props => [teamId, eventId, tournament, members];
}

class TournamentTeamMembersError extends TournamentTeamMembersState {
  const TournamentTeamMembersError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
