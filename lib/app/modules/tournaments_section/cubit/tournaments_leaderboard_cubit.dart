import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

part 'tournaments_leaderboard_state.dart';

class TournamentsLeaderboardCubit extends Cubit<TournamentsLeaderboardState> {
  TournamentsLeaderboardCubit() : super(TournamentsLeaderboardInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> fetchLeaderboard({required String eventId}) async {
    emit(TournamentsLeaderboardLoading());
    try {
      final response = await remoteRepo.fetchEventLeaderboard(
        eventId: eventId,
        stage: 'auto',
      );
      final raw = response['leaderboard'];
      final leaderboard = raw is List
          ? raw
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];
      emit(
        TournamentsLeaderboardLoaded(
          leaderboard: leaderboard,
          availability:
              (response['availability'] ??
                      (leaderboard.isEmpty ? 'not_available_yet' : 'available'))
                  .toString(),
          stage: (response['stage'] ?? 'auto').toString(),
          source: response['source']?.toString(),
          eventTitle: response['event_title']?.toString(),
        ),
      );
    } catch (e, st) {
      AppLogger.e(
        'Leaderboard fetch failed for eventId=$eventId',
        error: e,
        stackTrace: st,
      );
      emit(TournamentsLeaderboardError(message: e.toString()));
    }
  }
}
