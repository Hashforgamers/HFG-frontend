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
  final String availability;
  final String stage;
  final String? source;
  final String? eventTitle;
  const TournamentsLeaderboardLoaded({
    required this.leaderboard,
    required this.availability,
    required this.stage,
    this.source,
    this.eventTitle,
  });

  bool get isAvailable => availability == 'available';

  @override
  List<Object?> get props => [
    leaderboard,
    availability,
    stage,
    source,
    eventTitle,
  ];
}

class TournamentsLeaderboardError extends TournamentsLeaderboardState {
  final String message;
  const TournamentsLeaderboardError({required this.message});

  @override
  List<Object?> get props => [message];
}
