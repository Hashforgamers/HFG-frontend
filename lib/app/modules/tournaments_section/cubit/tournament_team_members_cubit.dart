import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tournament_team_members_state.dart';

class TournamentTeamMembersCubit extends Cubit<TournamentTeamMembersState> {
  TournamentTeamMembersCubit() : super(TournamentTeamMembersInitial());

  final remoteRepo = locator<RemoteRepoInterface>();

  Future<void> fetchTeamMembers({
    required String eventId,
    required String teamId,
  }) async {
    emit(TournamentTeamMembersLoading());
    try {
      final members = await remoteRepo.fetchEventTeamMembers(
        eventId: eventId,
        teamId: teamId,
      );
      emit(TournamentTeamMembersLoaded(teamId: teamId, members: members));
    } catch (e) {
      emit(TournamentTeamMembersError(message: _cleanError(e)));
    }
  }

  String _cleanError(Object error) {
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return raw.replaceFirst('Exception: ', '');
    }
    return raw;
  }

  Future<void> renameTeam({
    required String eventId,
    required String teamId,
    required String teamName,
  }) async {
    final trimmed = teamName.trim();
    if (trimmed.length < 3) {
      throw Exception('Team name must be at least 3 characters.');
    }
    await remoteRepo.updateEventTeam(
      eventId: eventId,
      teamId: teamId,
      teamName: trimmed,
    );
  }

  Future<void> addTeamMemberByUserId({
    required String eventId,
    required String teamId,
    required int userId,
  }) async {
    if (userId <= 0) {
      throw Exception('Invalid user selected.');
    }
    await remoteRepo.addEventTeamMember(
      eventId: eventId,
      teamId: teamId,
      userId: userId,
    );
  }

  Future<void> inviteTeamMember({
    required String eventId,
    required String teamId,
    required int inviterUserId,
    required int invitedUserId,
  }) async {
    if (invitedUserId <= 0 || inviterUserId <= 0) {
      throw Exception('Invalid user selected for invite.');
    }
    if (inviterUserId == invitedUserId) {
      throw Exception('You cannot invite yourself.');
    }
    await remoteRepo.inviteUserToEventTeam(
      eventId: eventId,
      teamId: teamId,
      inviterUserId: inviterUserId,
      invitedUserId: invitedUserId,
    );
  }

  Future<void> leaveTeam({
    required String eventId,
    required String teamId,
    required int userId,
  }) async {
    if (userId <= 0) {
      throw Exception('Invalid user for leave team.');
    }
    await remoteRepo.leaveEventTeam(
      eventId: eventId,
      teamId: teamId,
      userId: userId,
    );
  }

  Future<void> forceRemoveMember({
    required String eventId,
    required String teamId,
    required int actingUserId,
    required int targetUserId,
  }) async {
    if (actingUserId <= 0 || targetUserId <= 0) {
      throw Exception('Invalid user for remove action.');
    }
    if (actingUserId == targetUserId) {
      throw Exception('You cannot remove yourself.');
    }
    await remoteRepo.forceRemoveEventTeamMember(
      eventId: eventId,
      teamId: teamId,
      actingUserId: actingUserId,
      targetUserId: targetUserId,
    );
  }

  Future<int?> resolveCurrentUserId() async {
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
