import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tournament_home_state.dart';

class TournamentHomeCubit extends Cubit<TournamentHomeState> {
  TournamentHomeCubit() : super(TournamentHomeInitial());

  final remoteRepo = locator<RemoteRepoInterface>();
  List<TournamentModel> _allTournaments = [];

  Future<void> fetchTournaments() async {
    emit(TournamentHomeLoading());
    try {
      final events = await remoteRepo.fetchPublicEvents();
      final tournaments = events.map(TournamentModel.fromJson).toList();
      final myTeams = await _fetchMyTeamsSafe();

      _allTournaments = tournaments;
      emit(TournamentHomeLoaded(tournaments: tournaments, myTeams: myTeams));
    } catch (e) {
      emit(TournamentHomeError(message: e.toString()));
    }
  }

  void filterTournaments(String category) {
    if (state is! TournamentHomeLoaded) return;
    final currentState = state as TournamentHomeLoaded;

    if (category == 'All') {
      emit(
        TournamentHomeLoaded(
          tournaments: _allTournaments,
          myTeams: currentState.myTeams,
        ),
      );
      return;
    }

    final filtered = _allTournaments
        .where((t) => t.matchesFilter(category))
        .toList();

    emit(
      TournamentHomeLoaded(
        tournaments: filtered,
        myTeams: currentState.myTeams,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMyTeamsSafe() async {
    try {
      final userId = await _resolveUserId();
      if (userId == null || userId <= 0) return const [];
      return await remoteRepo.fetchUserTeams(userId: userId);
    } catch (_) {
      return const [];
    }
  }

  Future<int?> _resolveUserId() async {
    final userData = await remoteRepo.getUserFromPreferences();
    final fromUserData = _parseUserIdFromDynamic(userData);
    if (fromUserData != null && fromUserData > 0) {
      return fromUserData;
    }

    final prefs = await SharedPreferences.getInstance();
    final fromPrefs = _parseUserIdFromDynamic(prefs.getString('user_id'));
    if (fromPrefs != null && fromPrefs > 0) {
      return fromPrefs;
    }

    if (Get.isRegistered<UserController>()) {
      final controller = Get.find<UserController>();
      final fromController = _parseUserIdFromDynamic(controller.userId);
      if (fromController != null && fromController > 0) {
        return fromController;
      }
    }
    return null;
  }

  int? _parseUserIdFromDynamic(dynamic source) {
    if (source == null) return null;
    if (source is int) return source;
    if (source is num) return source.toInt();
    if (source is String) return int.tryParse(source.trim());

    if (source is Map<String, dynamic>) {
      final nested =
          source['id'] ??
          source['user_id'] ??
          source['userId'] ??
          (source['user'] is Map<String, dynamic>
              ? (source['user']['id'] ??
                    source['user']['user_id'] ??
                    source['user']['userId'])
              : null);
      return _parseUserIdFromDynamic(nested);
    }

    if (source is Map) {
      return _parseUserIdFromDynamic(Map<String, dynamic>.from(source));
    }
    return null;
  }
}
