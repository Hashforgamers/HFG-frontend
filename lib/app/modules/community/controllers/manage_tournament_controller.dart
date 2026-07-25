import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../models/community_entities.dart';
import '../models/tournament.dart';
import '../models/tournament_operations.dart';
import '../services/community_api.dart';

class ManageTournamentController extends GetxController {
  final CommunityApi _api = CommunityApi();

  final tournament = Rxn<Tournament>();
  final registrations = <ManagedRegistration>[].obs;
  final results = <MatchResult>[].obs;
  final disputes = <Dispute>[].obs;
  final payouts = <Payout>[].obs;
  final teams = <CommunityTeam>[].obs;
  final matches = <CommunityMatch>[].obs;
  final leaderboard = <TournamentLeaderboardEntry>[].obs;
  final readiness = Rxn<TournamentReadiness>();
  final loading = true.obs;
  final acting = false.obs;
  final error = RxnString();

  late final String tournamentId;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Tournament) {
      tournamentId = arg.id;
      tournament.value = arg;
    } else if (arg is Map) {
      tournamentId = (arg['id'] ?? '').toString();
    } else {
      tournamentId = arg?.toString() ?? '';
    }
    load();
  }

  Future<void> load() async {
    if (tournamentId.isEmpty) {
      error.value = 'Tournament is missing.';
      loading.value = false;
      return;
    }
    loading.value = true;
    error.value = null;
    try {
      final canManage = await _api.canManageTournament(tournamentId);
      if (!canManage) {
        error.value =
            'Only this tournament’s host can open management controls.';
        tournament.value = null;
        return;
      }
      tournament.value = await _api.getTournament(tournamentId);
      final lists = await Future.wait([
        _safe(() => _api.tournamentRegistrations(tournamentId)),
        _safe(() => _api.tournamentResults(tournamentId)),
        _safe(() => _api.tournamentDisputes(tournamentId)),
        _safe(() => _api.tournamentPayouts(tournamentId)),
        _safe(() => _api.tournamentTeams(tournamentId)),
        _safe(() => _api.tournamentMatches(tournamentId, private: true)),
        _safe(() => _api.tournamentLeaderboard(tournamentId)),
      ]);
      registrations.assignAll(lists[0].cast<ManagedRegistration>());
      results.assignAll(lists[1].cast<MatchResult>());
      disputes.assignAll(lists[2].cast<Dispute>());
      payouts.assignAll(lists[3].cast<Payout>());
      teams.assignAll(lists[4].cast<CommunityTeam>());
      matches.assignAll(lists[5].cast<CommunityMatch>());
      leaderboard.assignAll(lists[6].cast<TournamentLeaderboardEntry>());
      try {
        readiness.value = await _api.tournamentReadiness(tournamentId);
      } catch (_) {
        readiness.value = null;
      }
    } on DioException catch (e) {
      error.value = _message(e, fallback: 'Could not load host controls.');
    } catch (_) {
      error.value = 'Could not load host controls.';
    } finally {
      loading.value = false;
    }
  }

  Future<List<T>> _safe<T>(Future<List<T>> Function() request) async {
    try {
      return await request();
    } catch (_) {
      return <T>[];
    }
  }

  Future<void> publish() async {
    try {
      final state = await _api.tournamentReadiness(tournamentId);
      readiness.value = state;
      if (!state.readyToPublish) {
        error.value = state.blockers.isEmpty
            ? 'Tournament is not ready to publish.'
            : state.blockers.join('\n');
        return;
      }
    } on DioException catch (e) {
      error.value = _message(e, fallback: 'Could not validate readiness.');
      return;
    }
    await _mutate(
      () => _api.updateTournament(tournamentId, {'status': 'published'}),
      success: 'Tournament published',
    );
  }

  Future<void> generateMatches() => _mutate(
    () => _api.generateMatches(tournamentId),
    success: 'Schedule and bracket generated',
  );

  Future<void> teamAction(
    CommunityTeam team,
    String action, {
    String? reason,
    int? seed,
  }) => _mutate(
    () => _api.manageTeam(
      tournamentId,
      team.id,
      action: action,
      reason: reason,
      seed: seed,
    ),
    success: 'Team updated',
  );

  Future<void> saveRoomDetails({
    required String summary,
    required RoomDetailsData data,
  }) => _mutate(
    () => _api.updateTournament(tournamentId, {
      'room_details': summary.trim().isEmpty ? null : summary.trim(),
      'room_details_data': data.toJson(),
    }),
    success: 'Room details updated',
  );

  Future<void> cancel(String reason) => _mutate(
    () => _api.cancelTournament(tournamentId, reason: reason.trim()),
    success: 'Tournament cancelled',
  );

  Future<void> registrationAction(
    ManagedRegistration registration,
    String action, {
    String? paymentReference,
  }) => _mutate(
    () => _api.updateTournamentRegistration(
      tournamentId,
      registration.id,
      action: action,
      paymentReference: paymentReference,
    ),
    success: 'Participant updated',
  );

  Future<void> resultAction(MatchResult result, String status) => _mutate(
    () => _api.verifyResult(tournamentId, result.id, status: status),
    success: status == 'verified' ? 'Result verified' : 'Result rejected',
  );

  Future<void> submitVerifiedWinners() async {
    final verified =
        results
            .where(
              (item) =>
                  (item.status == 'verified' ||
                      item.status == 'admin_overridden') &&
                  item.winnerUserId != null &&
                  item.rank != null,
            )
            .toList()
          ..sort((a, b) => a.rank!.compareTo(b.rank!));
    final seenUsers = <int>{};
    final seenRanks = <int>{};
    final winners = <Map<String, dynamic>>[];
    for (final result in verified) {
      if (!seenUsers.add(result.winnerUserId!) ||
          !seenRanks.add(result.rank!)) {
        continue;
      }
      winners.add({
        'user_id': result.winnerUserId,
        'rank': result.rank,
        // Per the pinned backend contract, zero delegates calculation to the
        // authoritative prize distribution stored by the tournament service.
        'amount': 0,
      });
    }
    if (winners.isEmpty) {
      error.value = 'Verify ranked results before submitting winners.';
      return;
    }
    await _mutate(
      () => _api.submitWinners(tournamentId, winners),
      success: 'Winners submitted for payout approval',
    );
  }

  Future<void> _mutate(
    Future<Object?> Function() request, {
    required String success,
  }) async {
    if (acting.value) return;
    acting.value = true;
    error.value = null;
    try {
      await request();
      if (isClosed) return;
      await load();
      if (isClosed) return;
      _showSnackbar(success, '', snackPosition: SnackPosition.BOTTOM);
    } on DioException catch (e) {
      if (isClosed) return;
      error.value = _message(e, fallback: 'Action could not be completed.');
      _showSnackbar('Could not update tournament', error.value!);
    } catch (_) {
      if (isClosed) return;
      error.value = 'Action could not be completed.';
    } finally {
      if (!isClosed) acting.value = false;
    }
  }

  void _showSnackbar(
    String title,
    String message, {
    SnackPosition snackPosition = SnackPosition.TOP,
  }) {
    if (isClosed || Get.overlayContext == null) return;
    Get.snackbar(title, message, snackPosition: snackPosition);
  }

  String _message(DioException e, {required String fallback}) {
    final data = e.response?.data;
    return data is Map && data['message'] != null
        ? data['message'].toString()
        : fallback;
  }
}
