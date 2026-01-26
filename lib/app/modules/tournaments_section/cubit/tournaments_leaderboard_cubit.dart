import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tournaments_leaderboard_state.dart';

class TournamentsLeaderboardCubit extends Cubit<TournamentsLeaderboardState> {
  TournamentsLeaderboardCubit() : super(TournamentsLeaderboardInitial());

  Future<void> fetchLeaderboard() async {
    emit(TournamentsLeaderboardLoading());
    try {
      // 🔹 Simulated API delay
      await Future.delayed(const Duration(milliseconds: 800));

      // 🔹 Mock leaderboard data
      final leaderboard = [
        {'rank': 1, 'player': 'Rohit Sharma', 'points': 950},
        {'rank': 2, 'player': 'Virat Kohli', 'points': 880},
        {'rank': 3, 'player': 'KL Rahul', 'points': 810},
        {'rank': 4, 'player': 'Hardik Pandya', 'points': 760},
        {'rank': 5, 'player': 'Shubman Gill', 'points': 700},
        {'rank': 6, 'player': 'MS Dhoni', 'points': 680},
        {'rank': 7, 'player': 'Jasprit Bumrah', 'points': 640},

        {'rank': 8, 'player': 'Rohit Sharma', 'points': 950},
        {'rank': 9, 'player': 'Virat Kohli', 'points': 880},
        {'rank': 10, 'player': 'KL Rahul', 'points': 810},
        {'rank': 11, 'player': 'Hardik Pandya', 'points': 760},
        {'rank': 12, 'player': 'Shubman Gill', 'points': 700},
        {'rank': 13, 'player': 'MS Dhoni', 'points': 680},
        {'rank': 14, 'player': 'Jasprit Bumrah', 'points': 640},
      ];

      emit(TournamentsLeaderboardLoaded(leaderboard: leaderboard));
    } catch (e) {
      emit(TournamentsLeaderboardError(message: e.toString()));
    }
  }
}
