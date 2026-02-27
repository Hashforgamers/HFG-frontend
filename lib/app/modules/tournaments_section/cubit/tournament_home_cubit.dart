import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
  List<TournamentModel> _allJoinableTournaments = [];
  final Map<String, List<TournamentModel>> _joinedByTab = {
    'All': const [],
    'Live': const [],
    'Upcoming': const [],
    'Completed': const [],
  };

  Future<void> fetchTournaments() async {
    emit(TournamentHomeLoading());
    try {
      final userId = await _resolveUserId();
      final events = await remoteRepo.fetchPublicEvents();
      final joinable = events.map(TournamentModel.fromJson).toList();
      _allJoinableTournaments = joinable;

      List<TournamentModel> joinedAll = const [];
      if (userId != null && userId > 0) {
        final joinedPayload = await remoteRepo.fetchJoinedTournaments(userId: userId);
        _joinedByTab['All'] = (joinedPayload['all'] ?? const [])
            .map((e) => TournamentModel.fromJson({...e, 'is_joined': true}))
            .toList();
        _joinedByTab['Live'] = (joinedPayload['live'] ?? const [])
            .map((e) => TournamentModel.fromJson({...e, 'is_joined': true}))
            .toList();
        _joinedByTab['Upcoming'] = (joinedPayload['upcoming'] ?? const [])
            .map((e) => TournamentModel.fromJson({...e, 'is_joined': true}))
            .toList();
        _joinedByTab['Completed'] = (joinedPayload['completed'] ?? const [])
            .map((e) => TournamentModel.fromJson({...e, 'is_joined': true}))
            .toList();
        joinedAll = _joinedByTab['All'] ?? const [];
      }

      final myTeams = await _fetchMyTeamsSafe();
      emit(
        TournamentHomeLoaded(
          tournaments: joinedAll,
          joinableTournaments: _allJoinableTournaments,
          myTeams: myTeams,
        ),
      );
    } catch (e) {
      emit(TournamentHomeError(message: e.toString()));
    }
  }

  void filterTournaments(String category) {
    if (state is! TournamentHomeLoaded) return;
    final currentState = state as TournamentHomeLoaded;
    final filtered = _joinedByTab[category] ?? const <TournamentModel>[];

    emit(
      TournamentHomeLoaded(
        tournaments: filtered,
        joinableTournaments: currentState.joinableTournaments,
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
    if (Get.isRegistered<UserController>()) {
      final controller = Get.find<UserController>();
      final fromController = _parseUserIdFromDynamic(controller.userId);
      if (fromController != null && fromController > 0) {
        return fromController;
      }
    }

    final fid = firebase_auth.FirebaseAuth.instance.currentUser?.uid ?? '';
    if (fid.isNotEmpty) {
      final apiUser = await remoteRepo.checkUserExistsInAPI(fid);
      final fromApi = _parseUserIdFromDynamic(apiUser);
      if (fromApi != null && fromApi > 0) {
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().id.value = fromApi.toString();
        }
        return fromApi;
      }
    }

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
