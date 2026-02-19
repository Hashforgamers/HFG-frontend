import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tournaments_register_state.dart';

class TournamentsRegisterCubit extends Cubit<TournamentsRegisterState> {
  TournamentsRegisterCubit() : super(TournamentsRegisterInitial()) {
    AppLogger.d('🟩 TournamentsRegisterCubit created');
  }

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> registerTeam({
    required String eventId,
    required String leaderName,
    required String teamName,
    List<String> players = const [],
  }) async {
    emit(TournamentsRegisterLoading());
    try {
      if (leaderName.trim().isEmpty) {
        throw Exception('Leader name is required.');
      }
      if (teamName.trim().isEmpty) {
        throw Exception('Team name is required.');
      }

      final userId = await _resolveUserId();
      if (userId == null || userId <= 0) {
        throw Exception('User not found. Please login again.');
      }

      final createTeamResponse = await remoteRepo.createEventTeam(
        eventId: eventId,
        userId: userId,
        teamName: teamName.trim(),
        isIndividual: false,
      );

      final teamId = _extractTeamId(createTeamResponse);
      if (teamId.isEmpty) {
        throw Exception('Team created but team id not returned by API');
      }

      final registerResponse = await remoteRepo.registerEventTeam(
        eventId: eventId,
        userId: userId,
        teamId: teamId,
      );

      final result = <String, dynamic>{
        ...registerResponse,
        "team_id": teamId,
        "team": teamName,
        "leader": leaderName,
        "players": players.where((e) => e.trim().isNotEmpty).toList(),
      };

      emit(TournamentsRegisterSuccess(data: result));
    } catch (e) {
      emit(TournamentsRegisterError(message: _cleanError(e)));
    }
  }

  Future<void> joinTeam({
    required String eventId,
    required String teamId,
  }) async {
    emit(TournamentsRegisterLoading());
    try {
      if (teamId.trim().isEmpty) {
        throw Exception('Team ID is required.');
      }

      final userId = await _resolveUserId();
      if (userId == null || userId <= 0) {
        throw Exception('User not found. Please login again.');
      }

      final response = await remoteRepo.joinEventTeam(
        eventId: eventId,
        teamId: teamId.trim(),
        userId: userId,
      );

      emit(
        TournamentsRegisterSuccess(
          data: <String, dynamic>{
            ...response,
            'team_id': teamId.trim(),
            'action': 'join_team',
          },
        ),
      );
    } catch (e) {
      emit(TournamentsRegisterError(message: _cleanError(e)));
    }
  }

  String _extractTeamId(Map<String, dynamic> payload) {
    final directId = payload['team_id'] ?? payload['id'];
    if (directId != null && directId.toString().isNotEmpty) {
      return directId.toString();
    }

    final team = payload['team'];
    if (team is Map<String, dynamic>) {
      final nestedId = team['id'] ?? team['team_id'];
      if (nestedId != null && nestedId.toString().isNotEmpty) {
        return nestedId.toString();
      }
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nestedId = data['team_id'] ?? data['id'];
      if (nestedId != null && nestedId.toString().isNotEmpty) {
        return nestedId.toString();
      }
    }

    return '';
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
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
