import 'dart:async';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:image_picker/image_picker.dart';

import '../models/tournament.dart';
import '../models/tournament_operations.dart';
import '../models/tournament_domain.dart';
import '../services/community_api.dart';
import '../services/tournament_result_evidence_service.dart';
import '../services/tournament_analytics.dart';
import '../../chat/views/chat_room_view.dart';

typedef EvidenceUploadProgress = void Function(double progress, String status);

/// Tournament detail + registration.
/// Uses authed detail when a session exists (for room_details), else public.
class TournamentDetailController extends GetxController {
  static final Map<String, List<CommunityMatch>> _matchCache = {};
  static final Map<String, String> _matchFingerprints = {};

  final CommunityApi _api = CommunityApi();
  final ImagePicker _imagePicker = ImagePicker();
  final TournamentResultEvidenceService _evidenceService =
      TournamentResultEvidenceService();

  final Rxn<Tournament> tournament = Rxn<Tournament>();
  final RxBool loading = true.obs;
  final RxBool acting = false.obs; // register / cancel in flight
  final RxBool canManage = false.obs;
  final RxBool hasJoined = false.obs;
  final matches = <CommunityMatch>[].obs;
  final resultStates = <String, Map<String, dynamic>>{}.obs;
  final RxnString resultSubmissionError = RxnString();
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
    _restoreCachedMatches(private: canManage.value);
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
      await TournamentAnalytics.log(
        'tournament_viewed',
        t,
        sourceScreen: 'community_tournaments',
        teamStatus: hasJoined.value ? 'joined' : 'not_joined',
        deduplicationKey: t.id,
      );
      if (t.statusValue == TournamentStatus.completed) {
        await TournamentAnalytics.log(
          'result_viewed',
          t,
          sourceScreen: 'tournament_detail',
          teamStatus: hasJoined.value ? 'joined' : 'spectator',
          deduplicationKey: t.id,
        );
      }
      if (hasJoined.value) {
        await refreshLiveData();
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
      final nextMatches = await _api.tournamentMatches(
        _id,
        private: hasJoined.value || canManage.value,
      );
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
      _updateMatchesIfChanged(
        nextMatches,
        private: hasJoined.value || canManage.value,
      );
      await _refreshResultStates(nextMatches);
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

  Future<void> _refreshResultStates(List<CommunityMatch> nextMatches) async {
    if (!hasJoined.value) return;
    final reviewMatches = nextMatches.where(
      (match) =>
          {'result_pending', 'disputed', 'completed'}.contains(match.status),
    );
    for (final match in reviewMatches) {
      try {
        final state = await _api.matchResultState(_id, match.id);
        state['_fetched_at'] = DateTime.now().toUtc().toIso8601String();
        resultStates[match.id] = state;
      } catch (error) {
        debugPrint('[RESULT_STATE_ERROR] match=${match.id} error=$error');
      }
    }
    resultStates.removeWhere(
      (matchId, _) => !nextMatches.any(
        (match) =>
            match.id == matchId &&
            {'result_pending', 'disputed', 'completed'}.contains(match.status),
      ),
    );
    resultStates.refresh();
  }

  Map<String, dynamic>? resultStateFor(CommunityMatch match) =>
      resultStates[match.id];

  MatchResultProposal? proposalFor(CommunityMatch match) {
    final state = resultStateFor(match);
    final raw = state?['proposal'] ?? state?['result_proposal'];
    if (raw is Map) {
      return MatchResultProposal.fromJson(Map<String, dynamic>.from(raw));
    }
    return match.resultProposal;
  }

  bool resultPermission(CommunityMatch match, String permission) {
    final state = resultStateFor(match);
    final permissions = state?['permissions'];
    final aliases = permission == 'can_accept'
        ? const ['can_accept', 'can_approve', 'may_accept']
        : const ['can_dispute', 'may_dispute'];
    return aliases.any(
      (key) =>
          state?[key] == true ||
          (permissions is Map && permissions[key] == true),
    );
  }

  List<String> resultEvidenceUrls(CommunityMatch match) {
    final state = resultStateFor(match);
    final proposal = state?['proposal'] ?? state?['result_proposal'];
    final raw = proposal is Map
        ? proposal['evidence_urls']
        : state?['evidence_urls'];
    return raw is List
        ? raw
              .map((item) => item.toString())
              .where((url) => url.isNotEmpty)
              .toList()
        : const [];
  }

  Duration? resultTimeRemaining(CommunityMatch match) {
    final state = resultStateFor(match);
    if (state == null) return null;
    final expiresAt = DateTime.tryParse(
      (state['expires_at'] ??
              (state['proposal'] is Map
                  ? state['proposal']['expires_at']
                  : null) ??
              (state['result_proposal'] is Map
                  ? state['result_proposal']['expires_at']
                  : null) ??
              '')
          .toString(),
    );
    final serverTime = DateTime.tryParse(
      (state['server_time'] ?? '').toString(),
    );
    final fetchedAt = DateTime.tryParse(
      (state['_fetched_at'] ?? '').toString(),
    );
    if (expiresAt == null || serverTime == null || fetchedAt == null) {
      return null;
    }
    final estimatedServerNow = serverTime.toUtc().add(
      DateTime.now().toUtc().difference(fetchedAt.toUtc()),
    );
    final remaining = expiresAt.toUtc().difference(estimatedServerNow);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _restoreCachedMatches({required bool private}) {
    if (_id.isEmpty) return;
    final cached =
        _matchCache[_cacheKey(private)] ?? _matchCache[_cacheKey(false)];
    if (cached != null && cached.isNotEmpty) {
      matches.assignAll(cached);
    }
  }

  void _updateMatchesIfChanged(
    List<CommunityMatch> nextMatches, {
    required bool private,
  }) {
    final key = _cacheKey(private);
    final fingerprint = _matchesFingerprint(nextMatches);
    if (_matchFingerprints[key] == fingerprint &&
        _matchesFingerprint(matches) == fingerprint) {
      return;
    }
    final snapshot = List<CommunityMatch>.unmodifiable(nextMatches);
    _matchCache[key] = snapshot;
    _matchFingerprints[key] = fingerprint;
    matches.assignAll(snapshot);
  }

  String _cacheKey(bool private) => '$_id:${private ? 'private' : 'public'}';

  String _matchesFingerprint(List<CommunityMatch> values) {
    final sorted = [...values]..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .map(
          (match) => [
            match.id,
            match.round,
            match.roundName,
            match.status,
            match.scheduledAt?.millisecondsSinceEpoch,
            match.teamA?.id,
            match.teamA?.name,
            match.teamA?.members
                .map(
                  (member) =>
                      '${member.userId}:${member.displayName}:${member.role}',
                )
                .join(','),
            match.teamB?.id,
            match.teamB?.name,
            match.teamB?.members
                .map(
                  (member) =>
                      '${member.userId}:${member.displayName}:${member.role}',
                )
                .join(','),
            match.winnerTeamId,
            match.teamAScore,
            match.teamBScore,
            match.lobbyId,
            match.accessCode,
          ].join('|'),
        )
        .join('||');
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

  CommunityTeam? get currentTeam => participantTeams
      .where((team) => team.id == currentTeamId.value)
      .firstOrNull;

  bool get isCurrentUserCaptain =>
      currentTeam?.members.any(
        (member) =>
            member.userId == currentUserId.value && member.role == 'captain',
      ) ??
      false;

  Future<String?> pickAndUploadEvidence(
    String matchId, {
    String purpose = 'result_evidence',
    EvidenceUploadProgress? onProgress,
  }) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 2000,
    );
    if (picked == null) return null;
    onProgress?.call(0.05, 'Preparing screenshot…');
    if (FirebaseAuth.instance.currentUser == null) {
      throw Exception('Sign in to upload match evidence.');
    }
    final match = matches.where((item) => item.id == matchId).firstOrNull;
    if (match == null) throw Exception('Match details are unavailable.');
    final analysis = await _evidenceService.analyze(
      picked.path,
      match,
      game: tournament.value?.game,
    );
    onProgress?.call(0.15, 'Checking screenshot…');
    await _evidenceService.store(
      tournamentId: _id,
      match: match,
      submittedAs: canManage.value ? 'host' : 'participant',
      analysis: analysis,
    );
    final mimeType = picked.mimeType ?? 'image/jpeg';
    final upload = await _api.uploadCommunityEvidence(
      tournamentId: _id,
      purpose: purpose,
      filePath: picked.path,
      fileName: picked.name,
      mimeType: mimeType,
      metadata: {'match_id': match.id, 'submitter_type': 'participant'},
      onSendProgress: (sent, total) {
        final fraction = total <= 0 ? 0.0 : sent / total;
        final percent = (fraction * 100).round();
        onProgress?.call(
          0.2 + (fraction.clamp(0.0, 1.0) * 0.7),
          'Uploading screenshot… $percent%',
        );
      },
    );
    onProgress?.call(1, 'Screenshot added');
    return upload.asset.id;
  }

  Future<bool> submitMatchResult({
    required CommunityMatch match,
    required String winnerTeamId,
    required int teamAScore,
    required int teamBScore,
    required List<String> evidenceAssetIds,
    String? notes,
  }) async {
    if (!{'active', 'in_progress', 'awaiting_results'}.contains(match.status)) {
      resultSubmissionError.value = match.status == 'result_pending'
          ? 'Review the host proposal. Do not submit a second result.'
          : 'Result submission is not available for this match state.';
      return false;
    }
    acting.value = true;
    resultSubmissionError.value = null;
    final endpoint = '/tournaments/$_id/matches/${match.id}/result-submissions';
    final payload = <String, dynamic>{
      'winner_team_id': winnerTeamId,
      'team_a_score': teamAScore,
      'team_b_score': teamBScore,
      if (evidenceAssetIds.isNotEmpty) 'evidence_asset_ids': evidenceAssetIds,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };
    debugPrint('[RESULT_SUBMISSION] POST $endpoint payload=$payload');
    try {
      final submitted = await _api.submitCaptainResult(
        _id,
        match.id,
        winnerTeamId: winnerTeamId,
        teamAScore: teamAScore,
        teamBScore: teamBScore,
        evidenceAssetIds: evidenceAssetIds,
        notes: notes,
      );
      debugPrint(
        '[RESULT_SUBMISSION] success match_id=${submitted.id} '
        'status=${submitted.status}',
      );
      await refreshLiveData();
      return true;
    } catch (error) {
      if (error is DioException) {
        debugPrint(
          '[RESULT_SUBMISSION_ERROR] POST $endpoint '
          'status=${error.response?.statusCode} '
          'response=${error.response?.data} '
          'type=${error.type} message=${error.message}',
        );
      } else {
        debugPrint('[RESULT_SUBMISSION_ERROR] POST $endpoint error=$error');
      }
      resultSubmissionError.value = _reason(error);
      return false;
    } finally {
      acting.value = false;
    }
  }

  Future<bool> respondToHostResultProposal({
    required CommunityMatch match,
    required String action,
    String? description,
    List<String> evidenceAssetIds = const [],
  }) async {
    final proposal = proposalFor(match);
    if (proposal == null || proposal.id.isEmpty) return false;
    acting.value = true;
    try {
      final response = await _api.respondToHostResultProposal(
        _id,
        match.id,
        proposal.id,
        action: action,
        description: description,
        evidenceAssetIds: evidenceAssetIds,
      );
      await refreshLiveData();
      Get.snackbar(
        action == 'accept' ? 'Result accepted' : 'Result disputed',
        action == 'accept'
            ? 'Your captain confirmation has been recorded.'
            : 'The proposal was sent to platform-admin review.',
        snackPosition: SnackPosition.BOTTOM,
      );
      if (action == 'dispute') {
        await _openDisputeChat(
          roomId: response['chat_room_id']?.toString(),
          roomStatus: response['chat_room_status']?.toString(),
        );
      }
      return true;
    } catch (error) {
      Get.snackbar(
        'Result response failed',
        _reason(error),
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      acting.value = false;
    }
  }

  Future<void> openMatchDispute({
    required CommunityMatch match,
    required String reason,
    required String description,
    required List<String> evidenceAssetIds,
  }) async {
    acting.value = true;
    try {
      final dispute = await _api.createDispute(
        _id,
        reason: reason,
        description: description,
        evidenceAssetIds: evidenceAssetIds,
      );
      Get.snackbar(
        'Dispute opened',
        dispute.chatRoomStatus == 'ready'
            ? 'Opening the dispute chat.'
            : 'The platform admin review team has been notified.',
        snackPosition: SnackPosition.BOTTOM,
      );
      await _openDisputeChat(
        roomId: dispute.chatRoomId,
        roomStatus: dispute.chatRoomStatus,
      );
    } catch (error) {
      if (error is DioException) {
        debugPrint(
          '[DISPUTE_ERROR] status=${error.response?.statusCode} data=${error.response?.data}',
        );
      }
      Get.snackbar(
        'Could not open dispute',
        _reason(error),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      acting.value = false;
    }
  }

  Future<void> _openDisputeChat({
    required String? roomId,
    required String? roomStatus,
  }) async {
    final normalizedRoomId = roomId?.trim() ?? '';
    if (normalizedRoomId.isEmpty || roomStatus != 'ready') return;
    final customToken = await _api.firebaseChatToken();
    await FirebaseAuth.instance.signInWithCustomToken(customToken);
    await Get.to<void>(
      () => ChatRoomView(
        roomId: normalizedRoomId,
        roomCollection: 'communityDisputeRooms',
      ),
    );
  }

  String _reason(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        for (final key in ['message', 'detail', 'error']) {
          final value = data[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }
      }
    }
    final s = e.toString();
    if (s.contains('409')) return 'Already registered or tournament is full.';
    if (s.contains('403')) return 'Not allowed for this tournament.';
    if (s.contains('400')) return 'Check the scores and required evidence.';
    return 'Please try again.';
  }

  @override
  void onClose() {
    _liveTimer?.cancel();
    super.onClose();
  }
}
