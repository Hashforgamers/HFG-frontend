import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'tournaments_leaderboard_state.dart';

class TournamentsLeaderboardCubit extends Cubit<TournamentsLeaderboardState> {
  TournamentsLeaderboardCubit() : super(TournamentsLeaderboardInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> fetchLeaderboard({required String eventId}) async {
    emit(TournamentsLeaderboardLoading());
    try {
      final event = await remoteRepo.fetchEventById(eventId: eventId);
      final dynamic teams = event['teams'] ?? event['leaderboard'] ?? [];

      final leaderboard = <Map<String, dynamic>>[];
      if (teams is List) {
        for (var index = 0; index < teams.length; index++) {
          final item = teams[index];
          if (item is! Map) continue;
          leaderboard.add({
            'rank': item['rank'] ?? item['position'] ?? (index + 1),
            'player': item['name'] ?? item['team_name'] ?? 'Team ${index + 1}',
            'points': item['points'] ?? item['score'] ?? 0,
          });
        }
      }

      emit(TournamentsLeaderboardLoaded(leaderboard: leaderboard));
    } catch (e) {
      emit(TournamentsLeaderboardError(message: e.toString()));
    }
  }
}
