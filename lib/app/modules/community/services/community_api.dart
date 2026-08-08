import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/utils/encrypt_util.dart';

import '../models/community_entities.dart';
import '../models/host_program.dart';
import '../models/host_verification.dart';
import '../models/tournament.dart';
import '../models/tournament_operations.dart';

/// Client for the Community Tournament module
/// (`userOnboard :: /api/v1/community`). Covers every endpoint in the handoff:
/// public discovery, host onboarding/verification, tournament CRUD,
/// registrations, results, winners, disputes, file assets, and admin review.
class CommunityApi {
  Dio _publicDio() =>
      NetworkConfig.noAuth(hostUrl: ApiEndpoints.communityBaseUrl).dio;

  /// Login converts the token returned by `/api/users/fid/<firebaseUid>` into
  /// the API token stored as `jwt`: it decrypts the returned subject,
  /// re-encrypts it with the API public key, and signs a payload containing
  /// `uuid`. Community endpoints use that same API token format.
  String? _serverToken;
  DateTime? _serverTokenExp;

  Future<String?> _authToken() async {
    // Reuse cached server token if still valid.
    final exp = _serverTokenExp;
    if (_serverToken != null &&
        exp != null &&
        DateTime.now().isBefore(exp.subtract(const Duration(minutes: 1)))) {
      return _serverToken;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    if (token == null || token.isEmpty || isJwtExpired(token)) return null;

    _serverToken = token;
    _serverTokenExp = _expiryOf(token);
    return token;
  }

  DateTime? _expiryOf(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final norm = base64Url.normalize(payload);
      final map =
          jsonDecode(utf8.decode(base64Url.decode(norm)))
              as Map<String, dynamic>;
      final expSec = (map['exp'] as num?)?.toInt();
      if (expSec == null) return null;
      return DateTime.fromMillisecondsSinceEpoch(expSec * 1000);
    } catch (_) {
      return null;
    }
  }

  /// Authenticated Dio for the community module.
  ///
  /// We deliberately build a bare Dio here instead of NetworkConfig.auth(),
  /// because NetworkConfig.dio attaches an AuthInterceptor that overwrites the
  /// Authorization header on every request with the (stale) token from secure
  /// storage — which would clobber the freshly re-minted token below.
  Future<Dio> _authedDio() async {
    final token = await _authToken();
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        error: 'No access token available',
      );
    }
    return Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.communityBaseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  Dio _adminDio(String adminToken, {String? adminId}) {
    final dio = NetworkConfig.noAuth(
      hostUrl: ApiEndpoints.communityBaseUrl,
    ).dio;
    dio.options.headers['X-Admin-Token'] = adminToken;
    if (adminId != null) dio.options.headers['X-Admin-Id'] = adminId;
    return dio;
  }

  Map<String, dynamic> _map(dynamic d) =>
      d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};

  // ---------------------------------------------------------------------------
  // Public
  // ---------------------------------------------------------------------------

  /// GET /health
  Future<bool> health() async {
    try {
      final res = await _publicDio().get('/health');
      return _map(res.data)['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  /// GET /hosts/program (public)
  Future<HostProgram> getHostProgram() async {
    final res = await _publicDio().get('/hosts/program');
    return HostProgram.fromJson(_map(res.data));
  }

  /// GET /tournaments (public) — discovery list with filters.
  Future<Paginated<Tournament>> listTournaments({
    int page = 1,
    int perPage = 20,
    String? view, // featured | free | paid | upcoming | popular | admin
    String? game,
    String? search,
    String? sort, // soonest | popular | newest | fee_low
  }) async {
    final res = await _publicDio().get(
      '/tournaments',
      queryParameters: {
        'page': page,
        'per_page': perPage,
        if (view != null) 'view': view,
        if (game != null && game.isNotEmpty) 'game': game,
        if (search != null && search.isNotEmpty) 'search': search,
        if (sort != null) 'sort': sort,
      },
    );
    return Paginated<Tournament>.fromJson(_map(res.data), Tournament.fromJson);
  }

  /// GET /tournaments/public/<id> (public) — anonymous detail, no room_details.
  Future<Tournament> getPublicTournament(String id) async {
    final res = await _publicDio().get('/tournaments/public/$id');
    return Tournament.fromJson(_map(res.data));
  }

  /// GET /tournaments/public/<id>/status (public).
  Future<TournamentLifecycleStatus> getTournamentStatus(
    String id, {
    String? inviteCode,
  }) async {
    final res = await _publicDio().get(
      '/tournaments/public/$id/status',
      queryParameters: {
        if (inviteCode != null && inviteCode.trim().isNotEmpty)
          'invite_code': inviteCode.trim(),
      },
    );
    return TournamentLifecycleStatus.fromJson(_map(res.data));
  }

  // ---------------------------------------------------------------------------
  // Host onboarding / verification
  // ---------------------------------------------------------------------------

  /// GET /hosts/me/verification (auth) — null when never applied / no session.
  Future<HostVerification?> getMyHostVerification() async {
    try {
      final dio = await _authedDio();
      final res = await dio.get('/hosts/me/verification');
      if (res.data == null) return null;
      final data = _map(res.data);
      final record = data['verification'] ?? data['data'] ?? data;
      if (record is! Map || record.isEmpty) return null;
      return HostVerification.fromJson(Map<String, dynamic>.from(record));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 401) {
        return null;
      }
      rethrow;
    } catch (e) {
      AppLogger.d('[CommunityApi] getMyHostVerification (no session): $e');
      return null;
    }
  }

  /// POST /hosts/verification (auth)
  Future<HostVerification> submitHostVerification({
    required String name,
    required String email,
    required String phone,
    required String upiId,
    required String address,
    String? governmentId,
    String? governmentIdAssetId,
    String? paymentReference,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/hosts/verification',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'upi_id': upiId,
        'address': address,
        if (governmentId != null) 'government_id': governmentId,
        if (governmentIdAssetId != null)
          'government_id_asset_id': governmentIdAssetId,
        if (paymentReference != null) 'payment_reference': paymentReference,
      },
    );
    return HostVerification.fromJson(_map(res.data));
  }

  // ---------------------------------------------------------------------------
  // Tournaments (auth)
  // ---------------------------------------------------------------------------

  /// GET /tournaments/<id> (auth) — includes room_details for host/participant.
  Future<Tournament> getTournament(String id) async {
    final dio = await _authedDio();
    final res = await dio.get('/tournaments/$id');
    return Tournament.fromJson(_map(res.data));
  }

  /// GET /api/events/<id> with the current bearer token. This is the UI
  /// ownership gate; every management mutation still validates ownership.
  Future<bool> canManageTournament(String id) async {
    final token = await _authToken();
    if (token == null) return false;
    final res = await Dio().get(
      ApiEndpoints.eventById(id),
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    var data = _map(res.data);
    if (data['event'] is Map) data = _map(data['event']);
    if (data['data'] is Map) data = _map(data['data']);
    return data['source'] == 'community' && data['can_manage'] == true;
  }

  /// POST /tournaments (auth) — create. status: draft | published.
  Future<Tournament> createTournament(Map<String, dynamic> body) async {
    final dio = await _authedDio();
    final res = await dio.post('/tournaments', data: body);
    return Tournament.fromJson(_map(res.data));
  }

  /// PATCH /tournaments/<id> (auth host) — edit allowed fields.
  Future<Tournament> updateTournament(
    String id,
    Map<String, dynamic> body,
  ) async {
    final dio = await _authedDio();
    final res = await dio.patch('/tournaments/$id', data: body);
    return Tournament.fromJson(_map(res.data));
  }

  /// POST /tournaments/<id>/cancel (auth host)
  Future<Tournament> cancelTournament(String id, {String? reason}) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$id/cancel',
      data: {if (reason != null) 'reason': reason},
    );
    return Tournament.fromJson(_map(res.data));
  }

  /// POST /tournaments/<id>/registrations/close (auth host).
  Future<Tournament> closeRegistration(String id) async {
    final dio = await _authedDio();
    final res = await dio.post('/tournaments/$id/registrations/close');
    return Tournament.fromJson(_map(res.data));
  }

  /// POST /tournaments/<id>/start (auth host).
  Future<Tournament> startTournament(String id) async {
    final dio = await _authedDio();
    final res = await dio.post('/tournaments/$id/start');
    return Tournament.fromJson(_map(res.data));
  }

  /// GET /me/tournaments?role=joined|hosted (auth)
  Future<List<TournamentListItem>> myTournaments({
    String role = 'joined',
  }) async {
    final dio = await _authedDio();
    final res = await dio.get(
      '/me/tournaments',
      queryParameters: {'role': role},
    );
    final items = (_map(res.data)['items'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map((e) => TournamentListItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Registrations (auth)
  // ---------------------------------------------------------------------------

  /// POST /tournaments/<id>/registrations (auth)
  Future<Registration> registerForTournament(
    String tournamentId, {
    String? paymentReference,
    String? razorpayOrderId,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/registrations',
      data: {
        if (paymentReference != null) 'payment_reference': paymentReference,
        if (razorpayOrderId != null) 'razorpay_order_id': razorpayOrderId,
      },
    );
    return Registration.fromJson(_map(res.data));
  }

  /// DELETE /tournaments/<id>/registrations/me (auth)
  Future<void> cancelMyRegistration(String tournamentId) async {
    final dio = await _authedDio();
    await dio.delete('/tournaments/$tournamentId/registrations/me');
  }

  /// GET /tournaments/<id>/registrations (auth host).
  Future<List<ManagedRegistration>> tournamentRegistrations(
    String tournamentId, {
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final dio = await _authedDio();
    final res = await dio.get(
      '/tournaments/$tournamentId/registrations',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'per_page': perPage,
      },
    );
    return _items(res.data).map(ManagedRegistration.fromJson).toList();
  }

  /// PATCH /tournaments/<id>/registrations/<registrationId> (auth host).
  Future<ManagedRegistration> updateTournamentRegistration(
    String tournamentId,
    String registrationId, {
    required String action,
    String? paymentReference,
  }) async {
    final dio = await _authedDio();
    final res = await dio.patch(
      '/tournaments/$tournamentId/registrations/$registrationId',
      data: {
        'action': action,
        if (paymentReference != null) 'payment_reference': paymentReference,
      },
    );
    return ManagedRegistration.fromJson(_map(res.data));
  }

  // ---------------------------------------------------------------------------
  // Results / winners / disputes (auth)
  // ---------------------------------------------------------------------------

  /// POST /tournaments/<id>/results (auth host or confirmed participant)
  Future<MatchResult> submitResult(
    String tournamentId, {
    required int winnerUserId,
    int? rank,
    String? score,
    List<String>? evidenceAssetIds,
    String? streamUrl,
    String? notes,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/results',
      data: {
        'winner_user_id': winnerUserId,
        if (rank != null) 'rank': rank,
        if (score != null) 'score': score,
        if (evidenceAssetIds != null) 'evidence_asset_ids': evidenceAssetIds,
        if (streamUrl != null) 'stream_url': streamUrl,
        if (notes != null) 'notes': notes,
      },
    );
    return MatchResult.fromJson(_map(res.data));
  }

  /// GET /tournaments/<id>/results (auth host).
  Future<List<MatchResult>> tournamentResults(
    String tournamentId, {
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final dio = await _authedDio();
    final res = await dio.get(
      '/tournaments/$tournamentId/results',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'per_page': perPage,
      },
    );
    return _items(res.data).map(MatchResult.fromJson).toList();
  }

  /// PATCH /tournaments/<id>/results/<resultId> (auth host)
  Future<MatchResult> verifyResult(
    String tournamentId,
    String resultId, {
    required String status, // verified | rejected | admin_overridden
  }) async {
    final dio = await _authedDio();
    final res = await dio.patch(
      '/tournaments/$tournamentId/results/$resultId',
      data: {'status': status},
    );
    return MatchResult.fromJson(_map(res.data));
  }

  /// POST /tournaments/<id>/winners (auth host) -> list of payouts.
  Future<List<Payout>> submitWinners(
    String tournamentId,
    List<Map<String, dynamic>> winners,
  ) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/winners',
      data: {'winners': winners},
    );
    final items = (_map(res.data)['items'] as List?) ?? const [];
    return items
        .whereType<Map>()
        .map((e) => Payout.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// POST /tournaments/<id>/disputes (auth)
  Future<Dispute> createDispute(
    String tournamentId, {
    required String reason,
    required String description,
    String? resultId,
    List<String>? evidenceAssetIds,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/disputes',
      data: {
        'reason': reason,
        'description': description,
        if (resultId != null) 'result_id': resultId,
        if (evidenceAssetIds != null) 'evidence_asset_ids': evidenceAssetIds,
      },
    );
    return Dispute.fromJson(_map(res.data));
  }

  /// POST /chat/firebase-token (auth)
  Future<String> firebaseChatToken() async {
    final dio = await _authedDio();
    final res = await dio.post('/chat/firebase-token');
    final data = _map(res.data);
    final token =
        (data['custom_token'] ?? data['firebase_token'] ?? data['token'])
            ?.toString()
            .trim();
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: res.requestOptions,
        response: res,
        error: 'Firebase custom token missing from response',
      );
    }
    return token;
  }

  /// GET /tournaments/<id>/disputes (auth host, read-only).
  Future<List<Dispute>> tournamentDisputes(
    String tournamentId, {
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final dio = await _authedDio();
    final res = await dio.get(
      '/tournaments/$tournamentId/disputes',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'per_page': perPage,
      },
    );
    return _items(res.data).map(Dispute.fromJson).toList();
  }

  /// GET /tournaments/<id>/payouts (auth host, read-only).
  Future<List<Payout>> tournamentPayouts(
    String tournamentId, {
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final dio = await _authedDio();
    final res = await dio.get(
      '/tournaments/$tournamentId/payouts',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'per_page': perPage,
      },
    );
    return _items(res.data).map(Payout.fromJson).toList();
  }

  // ---------------------------------------------------------------------------
  // Esports operations extension
  // ---------------------------------------------------------------------------

  Future<TournamentReadiness> tournamentReadiness(String tournamentId) async {
    final dio = await _authedDio();
    final res = await dio.get('/tournaments/$tournamentId/readiness');
    return TournamentReadiness.fromJson(_map(res.data));
  }

  Future<List<CommunityTeam>> tournamentTeams(
    String tournamentId, {
    bool public = false,
  }) async {
    final path = public
        ? '/tournaments/public/$tournamentId/teams'
        : '/tournaments/$tournamentId/teams';
    final res = public
        ? await _publicDio().get(path)
        : await (await _authedDio()).get(path);
    return parseCommunityTeams(res.data);
  }

  Future<CommunityTeam> createTeam(
    String tournamentId, {
    required String name,
    required List<Map<String, dynamic>> members,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/teams',
      data: {'name': name, 'members': members},
    );
    return CommunityTeam.fromJson(_map(res.data));
  }

  Future<CommunityTeam> respondToTeamInvitation(
    String tournamentId,
    String teamId, {
    required String action,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/teams/$teamId/invitation',
      data: {'action': action},
    );
    return CommunityTeam.fromJson(_map(res.data));
  }

  Future<CommunityTeam> replaceTeamRoster(
    String tournamentId,
    String teamId, {
    required List<Map<String, dynamic>> members,
  }) async {
    final dio = await _authedDio();
    final res = await dio.put(
      '/tournaments/$tournamentId/teams/$teamId/roster',
      data: {'members': members},
    );
    return CommunityTeam.fromJson(_map(res.data));
  }

  Future<CommunityTeam> manageTeam(
    String tournamentId,
    String teamId, {
    required String action,
    String? reason,
    int? seed,
  }) async {
    final dio = await _authedDio();
    final res = await dio.patch(
      '/tournaments/$tournamentId/teams/$teamId',
      data: {
        'action': action,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        if (seed != null) 'seed': seed,
      },
    );
    return CommunityTeam.fromJson(_map(res.data));
  }

  Future<List<CommunityMatch>> tournamentMatches(
    String tournamentId, {
    bool private = false,
  }) async {
    final path =
        '/tournaments/$tournamentId/matches${private ? '/private' : ''}';
    final res = private
        ? await (await _authedDio()).get(path)
        : await _publicDio().get(path);
    return parseCommunityMatches(res.data);
  }

  Future<List<CommunityMatch>> generateMatches(String tournamentId) async {
    final dio = await _authedDio();
    final res = await dio.post('/tournaments/$tournamentId/matches/generate');
    return parseCommunityMatches(res.data);
  }

  Future<CommunityMatch> createMatch(
    String tournamentId,
    Map<String, dynamic> body,
  ) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/matches',
      data: body,
    );
    return CommunityMatch.fromJson(_map(res.data));
  }

  Future<Map<String, dynamic>> tournamentControlRoom(
    String tournamentId,
  ) async {
    final dio = await _authedDio();
    final res = await dio.get('/tournaments/$tournamentId/control-room');
    return _map(res.data);
  }

  Future<List<Map<String, dynamic>>> tournamentAuditLog(
    String tournamentId,
  ) async {
    final dio = await _authedDio();
    final res = await dio.get('/tournaments/$tournamentId/audit-log');
    return _items(res.data);
  }

  Future<List<Map<String, dynamic>>> tournamentAnnouncements(
    String tournamentId,
  ) async {
    final dio = await _authedDio();
    final res = await dio.get('/tournaments/$tournamentId/announcements');
    return _items(res.data);
  }

  Future<Map<String, dynamic>> publishAnnouncement(
    String tournamentId, {
    required String message,
    required String audience,
    List<String> teamIds = const [],
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/announcements',
      data: {
        'message': message.trim(),
        'audience': audience,
        if (audience == 'specific_teams') 'team_ids': teamIds,
      },
    );
    return _map(res.data);
  }

  Future<CommunityMatch> operateMatch(
    String tournamentId,
    String matchId, {
    required String action,
    Map<String, dynamic> fields = const {},
  }) async {
    final dio = await _authedDio();
    final res = await dio.patch(
      '/tournaments/$tournamentId/matches/$matchId',
      data: {'action': action, ...fields},
    );
    return CommunityMatch.fromJson(_map(res.data));
  }

  Future<CommunityMatch> submitCaptainResult(
    String tournamentId,
    String matchId, {
    required String winnerTeamId,
    required int teamAScore,
    required int teamBScore,
    List<String> evidenceAssetIds = const [],
    String? notes,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/matches/$matchId/result-submissions',
      data: {
        'winner_team_id': winnerTeamId,
        'team_a_score': teamAScore,
        'team_b_score': teamBScore,
        if (evidenceAssetIds.isNotEmpty) 'evidence_asset_ids': evidenceAssetIds,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return CommunityMatch.fromJson(_map(res.data));
  }

  Future<Map<String, dynamic>> submitHostResultProposal(
    String tournamentId,
    String matchId, {
    required String winnerTeamId,
    required int teamAScore,
    required int teamBScore,
    required List<String> evidenceAssetIds,
    required List<String> evidenceUrls,
    required Map<String, dynamic> ocrData,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/matches/$matchId/result-proposals',
      data: {
        'winner_team_id': winnerTeamId,
        'team_a_score': teamAScore,
        'team_b_score': teamBScore,
        if (evidenceAssetIds.isNotEmpty) 'evidence_asset_ids': evidenceAssetIds,
        if (evidenceUrls.isNotEmpty) 'evidence_urls': evidenceUrls,
        'ocr_data': ocrData,
      },
    );
    return _map(res.data);
  }

  Future<Map<String, dynamic>> respondToHostResultProposal(
    String tournamentId,
    String matchId,
    String proposalId, {
    required String action, // accept | dispute
  }) async {
    if (action != 'accept' && action != 'dispute') {
      throw ArgumentError.value(action, 'action', 'Must be accept or dispute');
    }
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/matches/$matchId/'
      'result-proposals/$proposalId/$action',
    );
    return _map(res.data);
  }

  Future<List<TournamentLeaderboardEntry>> tournamentLeaderboard(
    String tournamentId,
  ) async {
    final res = await _publicDio().get(
      '/tournaments/$tournamentId/leaderboard',
    );
    return parseTournamentLeaderboard(res.data);
  }

  Future<OrganizerProfile> organizerProfile(int hostUserId) async {
    final res = await _publicDio().get('/hosts/$hostUserId/profile');
    return OrganizerProfile.fromJson(_map(res.data));
  }

  Future<Map<String, dynamic>> submitOrganizerReview(
    String tournamentId, {
    required int managementRating,
    required int communicationRating,
    required int fairnessRating,
    required int schedulingRating,
    required int disputeHandlingRating,
    String? comment,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/tournaments/$tournamentId/reviews',
      data: {
        'management_rating': managementRating,
        'communication_rating': communicationRating,
        'fairness_rating': fairnessRating,
        'scheduling_rating': schedulingRating,
        'dispute_handling_rating': disputeHandlingRating,
        if (comment != null && comment.trim().isNotEmpty)
          'comment': comment.trim(),
      },
    );
    return _map(res.data);
  }

  List<Map<String, dynamic>> _items(dynamic payload) {
    final data = _map(payload);
    final raw = data['items'] ?? data['data'] ?? data['results'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  /// POST /files (auth) — register uploaded-file metadata, returns asset id.
  Future<FileAsset> createFileAsset({
    required String purpose, // banner | government_id | result_evidence | ...
    required String fileUrl,
    String? storageKey,
    String? mimeType,
    int? fileSizeBytes,
    String? checksum,
    String? tournamentId,
    Map<String, dynamic>? metadata,
  }) async {
    final dio = await _authedDio();
    final res = await dio.post(
      '/files',
      data: {
        'purpose': purpose,
        'file_url': fileUrl,
        if (storageKey != null) 'storage_key': storageKey,
        if (mimeType != null) 'mime_type': mimeType,
        if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
        if (checksum != null) 'checksum': checksum,
        if (tournamentId != null) 'tournament_id': tournamentId,
        if (metadata != null) 'metadata': metadata,
      },
    );
    return FileAsset.fromJson(_map(res.data));
  }

  // ---------------------------------------------------------------------------
  // Admin (X-Admin-Token)
  // ---------------------------------------------------------------------------

  /// PATCH /admin/hosts/<verificationId>/verification
  Future<HostVerification> adminReviewHostVerification(
    String verificationId, {
    required String adminToken,
    String? adminId,
    required String status,
    String? hostTier,
    double? averageRating,
    double? disputeRate,
    double? completionRate,
    double? onTimePayoutRate,
    int? policyViolationCount,
    String? rejectionReason,
  }) async {
    final dio = _adminDio(adminToken, adminId: adminId);
    final res = await dio.patch(
      '/admin/hosts/$verificationId/verification',
      data: {
        'status': status,
        if (hostTier != null) 'host_tier': hostTier,
        if (averageRating != null) 'average_rating': averageRating,
        if (disputeRate != null) 'dispute_rate': disputeRate,
        if (completionRate != null) 'completion_rate': completionRate,
        if (onTimePayoutRate != null) 'on_time_payout_rate': onTimePayoutRate,
        if (policyViolationCount != null)
          'policy_violation_count': policyViolationCount,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      },
    );
    return HostVerification.fromJson(_map(res.data));
  }

  /// PATCH /admin/disputes/<disputeId>
  Future<Dispute> adminReviewDispute(
    String disputeId, {
    required String adminToken,
    String? adminId,
    required String status, // under_review | approved | rejected | closed
    String? adminComment,
  }) async {
    final dio = _adminDio(adminToken, adminId: adminId);
    final res = await dio.patch(
      '/admin/disputes/$disputeId',
      data: {
        'status': status,
        if (adminComment != null) 'admin_comment': adminComment,
      },
    );
    return Dispute.fromJson(_map(res.data));
  }
}
