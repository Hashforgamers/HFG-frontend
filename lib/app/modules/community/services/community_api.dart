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
