import 'dart:async';

import 'package:get/get.dart';
import 'package:hash/core/service/notification_service.dart';

import '../models/tournament.dart';
import '../models/tournament_operations.dart';
import '../services/community_api.dart';

/// Tournament detail + registration.
/// Uses authed detail when a session exists (for room_details), else public.
class TournamentDetailController extends GetxController {
  final CommunityApi _api = CommunityApi();

  final Rxn<Tournament> tournament = Rxn<Tournament>();
  final RxBool loading = true.obs;
  final RxBool acting = false.obs; // register / cancel in flight
  final RxBool canManage = false.obs;
  final RxBool hasJoined = false.obs;
  final matches = <CommunityMatch>[].obs;
  final announcements = <Map<String, dynamic>>[].obs;
  final lifecycleStatus = Rxn<TournamentLifecycleStatus>();
  final currentTeamId = RxnString();
  final participantTeams = <CommunityTeam>[].obs;
  final currentUserId = Rxn<int>();
  final RxnString error = RxnString();

  late String _id;
  Timer? _liveTimer;
  String? _lastStatus;
  final Set<String> _knownMatchStates = {};

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Tournament) {
      tournament.value = arg;
      _id = arg.id;
      canManage.value = arg.canManage;
    } else if (arg is Map) {
      _id = (arg['id'] ?? '').toString();
      canManage.value = arg['can_manage'] == true;
    } else if (arg is String) {
      _id = arg;
    } else {
      _id = '';
    }
    refreshDetail();
    _liveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refreshLiveData(notify: true),
    );
  }

  Future<void> refreshDetail() async {
    if (_id.isEmpty) {
      loading.value = false;
      return;
    }
    loading.value = true;
    error.value = null;
    try {
      // Prefer authed detail (may include room_details); fall back to public.
      Tournament t;
      try {
        t = await _api.getTournament(_id);
      } catch (_) {
        t = await _api.getPublicTournament(_id);
      }
      tournament.value = t;
      canManage.value = canManage.value || t.canManage;
      await refreshLiveData();
      try {
        final joined = await _api.myTournaments(role: 'joined');
        final joinedItem = joined
            .where(
              (item) =>
                  item.tournament.id == _id &&
                  {
                    'confirmed',
                    'pending_payment',
                  }.contains(item.registration?.status),
            )
            .firstOrNull;
        hasJoined.value = joinedItem != null;
        final userId = joinedItem?.registration?.userId;
        currentUserId.value = userId;
        if (userId != null) {
          final teams = await _api.tournamentTeams(_id);
          participantTeams.assignAll(teams);
          currentTeamId.value = teams
              .where(
                (team) => team.members.any((member) => member.userId == userId),
              )
              .firstOrNull
              ?.id;
        }
      } catch (_) {
        hasJoined.value = false;
        currentTeamId.value = null;
        currentUserId.value = null;
        participantTeams.clear();
      }
      if (hasJoined.value) {
        try {
          announcements.assignAll(await _api.tournamentAnnouncements(_id));
        } catch (_) {
          announcements.clear();
        }
      }
    } catch (_) {
      if (tournament.value == null) {
        error.value = 'Could not load this tournament.';
      }
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshLiveData({bool notify = false}) async {
    if (_id.isEmpty) return;
    try {
      final nextMatches = await _api.tournamentMatches(_id);
      String? nextStatus = tournament.value?.status;
      try {
        final lifecycle = await _api.getTournamentStatus(_id);
        lifecycleStatus.value = lifecycle;
        nextStatus = lifecycle.status;
      } catch (_) {
        // The public detail status remains the fallback.
      }
      if (notify && hasJoined.value) {
        if (_lastStatus != null &&
            nextStatus == 'live' &&
            _lastStatus != 'live') {
          await _notify(
            'Tournament is live',
            '${tournament.value?.title ?? 'Your tournament'} has started.',
          );
        }
        for (final match in nextMatches) {
          final state = '${match.id}:${match.status}';
          if (_knownMatchStates.isNotEmpty &&
              !_knownMatchStates.contains(state) &&
              {'scheduled', 'ready', 'in_progress'}.contains(match.status)) {
            await _notify(
              match.status == 'in_progress'
                  ? 'Match started'
                  : 'New match scheduled',
              '${match.teamA?.name ?? 'TBD'} vs ${match.teamB?.name ?? 'TBD'}',
            );
          }
        }
      }
      matches.assignAll(nextMatches);
      _lastStatus = nextStatus;
      _knownMatchStates
        ..clear()
        ..addAll(nextMatches.map((match) => '${match.id}:${match.status}'));
    } catch (_) {
      // Public tournament detail remains useful if live data is unavailable.
    }
    if (hasJoined.value) {
      try {
        announcements.assignAll(await _api.tournamentAnnouncements(_id));
      } catch (_) {
        announcements.clear();
      }
    }
  }

  Future<void> _notify(String title, String body) async {
    if (!Get.isRegistered<NotificationController>()) return;
    await Get.find<NotificationController>().showLiveNotification(
      title: title,
      body: body,
    );
  }

  Future<void> cancelRegistration() async {
    if (_id.isEmpty) return;
    acting.value = true;
    try {
      await _api.cancelMyRegistration(_id);
      await refreshDetail();
      Get.snackbar(
        'Registration cancelled',
        '',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Could not cancel',
        _reason(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      acting.value = false;
    }
  }

  String _reason(Object e) {
    final s = e.toString();
    if (s.contains('409')) return 'Already registered or tournament is full.';
    if (s.contains('403')) return 'Not allowed for this tournament.';
    return 'Please try again.';
  }

  @override
  void onClose() {
    _liveTimer?.cancel();
    super.onClose();
  }
}
