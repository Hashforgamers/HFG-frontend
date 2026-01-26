part of 'tournaments_leaderboard_cubit.dart';

abstract class TournamentsLeaderboardState extends Equatable {
  const TournamentsLeaderboardState();

  @override
  List<Object?> get props => [];
}

class TournamentsLeaderboardInitial extends TournamentsLeaderboardState {}

class TournamentsLeaderboardLoading extends TournamentsLeaderboardState {}

class TournamentsLeaderboardLoaded extends TournamentsLeaderboardState {
  final List<Map<String, dynamic>> leaderboard;
  const TournamentsLeaderboardLoaded({required this.leaderboard});

  @override
  List<Object?> get props => [leaderboard];
}

class TournamentsLeaderboardError extends TournamentsLeaderboardState {
  final String message;
  const TournamentsLeaderboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
