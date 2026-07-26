import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/community_entities.dart';
import '../models/tournament.dart';
import '../models/tournament_operations.dart';
import '../services/community_api.dart';
import '../services/tournament_result_evidence_service.dart';

class HostMatchEvidence {
  const HostMatchEvidence({required this.assetId, required this.analysis});
  final String assetId;
  final TournamentEvidenceAnalysis analysis;
}

class ManageTournamentController extends GetxController {
  final CommunityApi _api = CommunityApi();
  final ImagePicker _imagePicker = ImagePicker();
  final TournamentResultEvidenceService _evidenceService =
      TournamentResultEvidenceService();

  final tournament = Rxn<Tournament>();
  final registrations = <ManagedRegistration>[].obs;
  final results = <MatchResult>[].obs;
  final disputes = <Dispute>[].obs;
  final payouts = <Payout>[].obs;
  final teams = <CommunityTeam>[].obs;
  final matches = <CommunityMatch>[].obs;
  final leaderboard = <TournamentLeaderboardEntry>[].obs;
  final readiness = Rxn<TournamentReadiness>();
  final lifecycleStatus = Rxn<TournamentLifecycleStatus>();
  final controlRoom = <String, dynamic>{}.obs;
  final announcements = <Map<String, dynamic>>[].obs;
  final auditLog = <Map<String, dynamic>>[].obs;
  final loading = true.obs;
  final acting = false.obs;
  final generatingMatches = false.obs;
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
        controlRoom.assignAll(await _api.tournamentControlRoom(tournamentId));
      } catch (_) {
        controlRoom.clear();
      }
      announcements.assignAll(
        await _safe(() => _api.tournamentAnnouncements(tournamentId)),
      );
      auditLog.assignAll(
        await _safe(() => _api.tournamentAuditLog(tournamentId)),
      );
      try {
        lifecycleStatus.value = await _api.getTournamentStatus(tournamentId);
      } catch (_) {
        lifecycleStatus.value = null;
      }
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

  Future<void> generateMatches() async {
    if (generatingMatches.value || acting.value) return;
    generatingMatches.value = true;
    try {
      await _mutate(
        () async {
          final generated = await _api.generateMatches(tournamentId);
          await _bestEffortAnnouncement(
            message:
                'The tournament bracket is ready. Open the tournament arena to see your match path.',
            audience: 'all_participants',
          );
          return generated;
        },
        success: 'Schedule and bracket generated',
        errorTitle: 'Could not generate bracket',
        errorFallback: 'Bracket generation failed. Please try again.',
      );
    } finally {
      if (!isClosed) generatingMatches.value = false;
    }
  }

  Future<void> closeRegistration() => _mutate(
    () => _api.closeRegistration(tournamentId),
    success: 'Registration closed',
  );

  Future<void> startTournament() => _mutate(() async {
    final started = await _api.startTournament(tournamentId);
    await _bestEffortAnnouncement(
      message:
          'The tournament is now live. Check the bracket and be ready for your match.',
      audience: 'all_participants',
    );
    return started;
  }, success: 'Tournament is now live');

  Future<void> startMatch(CommunityMatch match) => _mutate(() async {
    final started = await _api.operateMatch(
      tournamentId,
      match.id,
      action: 'start',
    );
    final teamIds = [
      if (match.teamA?.id.isNotEmpty == true) match.teamA!.id,
      if (match.teamB?.id.isNotEmpty == true) match.teamB!.id,
    ];
    if (teamIds.isNotEmpty) {
      await _bestEffortAnnouncement(
        message:
            '${match.teamA?.name ?? 'Team A'} vs ${match.teamB?.name ?? 'Team B'} is starting now.',
        audience: 'specific_teams',
        teamIds: teamIds,
      );
    }
    return started;
  }, success: 'Match started');

  Future<HostMatchEvidence?> uploadMatchEvidence(CommunityMatch match) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2200,
    );
    if (picked == null) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to upload match evidence.');
    final analysis = await _evidenceService.analyze(
      picked.path,
      match,
      game: tournament.value?.game,
    );
    final recordId = await _evidenceService.store(
      tournamentId: tournamentId,
      match: match,
      submittedAs: 'host',
      analysis: analysis,
    );
    return HostMatchEvidence(assetId: recordId, analysis: analysis);
  }

  Future<void> completeMatch({
    required CommunityMatch match,
    required String winnerTeamId,
    required int teamAScore,
    required int teamBScore,
    required String reason,
  }) => _mutate(
    () async {
      await _api.updateTournament(tournamentId, {'dispute_window_minutes': 15});
      return _api.operateMatch(
        tournamentId,
        match.id,
        action: 'override_result',
        fields: {
          'winner_team_id': winnerTeamId,
          'team_a_score': teamAScore,
          'team_b_score': teamBScore,
          'reason': reason,
        },
      );
    },
    success: 'Result uploaded · 15-minute dispute window started',
    errorTitle: 'Could not complete match',
  );

  Future<void> createManualMatch({
    required String teamAId,
    required String teamBId,
    DateTime? scheduledAt,
  }) => _mutate(
    () => _api.createMatch(tournamentId, {
      'team_a_id': teamAId,
      'team_b_id': teamBId,
      if (scheduledAt != null)
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
    }),
    success: 'Match created',
    errorTitle: 'Could not create match',
  );

  Future<void> publishAnnouncement({
    required String message,
    required String audience,
  }) => _mutate(
    () => _api.publishAnnouncement(
      tournamentId,
      message: message,
      audience: audience,
    ),
    success: 'Announcement published',
    errorTitle: 'Could not publish announcement',
  );

  Future<void> _bestEffortAnnouncement({
    required String message,
    required String audience,
    List<String> teamIds = const [],
  }) async {
    try {
      await _api.publishAnnouncement(
        tournamentId,
        message: message,
        audience: audience,
        teamIds: teamIds,
      );
    } catch (_) {
      // The lifecycle mutation remains authoritative if communication fails.
    }
  }

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
    String errorTitle = 'Could not update tournament',
    String errorFallback = 'Action could not be completed.',
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
      error.value = _message(e, fallback: errorFallback);
      _showSnackbar(errorTitle, error.value!);
    } catch (_) {
      if (isClosed) return;
      error.value = errorFallback;
    } finally {
      if (!isClosed) acting.value = false;
    }
  }

  void _showSnackbar(
    String title,
    String message, {
    SnackPosition snackPosition = SnackPosition.TOP,
  }) {
    final overlayContext = Get.overlayContext;
    if (isClosed ||
        overlayContext == null ||
        Overlay.maybeOf(overlayContext) == null) {
      return;
    }
    Get.snackbar(title, message, snackPosition: snackPosition);
  }

  String _message(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map) {
      for (final key in ['message', 'detail', 'error']) {
        final value = data[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
    }
    return fallback;
  }
}
