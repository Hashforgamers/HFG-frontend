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
    required this.members,
  });

  final String teamId;
  final List<Map<String, dynamic>> members;

  @override
  List<Object?> get props => [teamId, members];
}

class TournamentTeamMembersError extends TournamentTeamMembersState {
  const TournamentTeamMembersError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
