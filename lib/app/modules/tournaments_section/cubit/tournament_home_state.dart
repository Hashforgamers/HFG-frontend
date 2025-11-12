part of 'tournament_home_cubit.dart';

abstract class TournamentHomeState extends Equatable {
  const TournamentHomeState();
  @override
  List<Object?> get props => [];
}

class TournamentHomeInitial extends TournamentHomeState {}
class TournamentHomeLoading extends TournamentHomeState {}

class TournamentHomeLoaded extends TournamentHomeState {
  final List<Map<String, dynamic>> tournaments;
  const TournamentHomeLoaded({required this.tournaments});
  @override
  List<Object?> get props => [tournaments];
}

class TournamentHomeError extends TournamentHomeState {
  final String message;
  const TournamentHomeError({required this.message});
  @override
  List<Object?> get props => [message];
}