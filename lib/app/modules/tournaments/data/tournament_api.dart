import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/encrypt_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../host/models/host_program.dart';
import '../host/models/host_verification.dart';
import 'tournament_models.dart';

/// A readable API failure. [status] is the HTTP code (null when offline).
class TournamentApiException implements Exception {
  final int? status;
  final String message;
  const TournamentApiException(this.message, {this.status});

  bool get isConflict => status == 409;
  bool get isForbidden => status == 403;
  bool get isAuth => status == 401;

  static TournamentApiException from(Object e) {
    if (e is TournamentApiException) return e;
    if (e is DioException) {
      final data = e.response?.data;
      String? msg;
      if (data is Map) {
        msg = (data['message'] ?? data['error_description'] ?? data['error'])
            ?.toString();
      } else if (data is String && data.length < 300 && !data.contains('<')) {
        msg = data;
      }
      final status = e.response?.statusCode;
      if (status == null) {
        return const TournamentApiException(
          'Network problem. Check your connection and try again.',
        );
      }
      return TournamentApiException(
        (msg == null || msg.trim().isEmpty || msg == 'validation_error')
            ? switch (status) {
                401 => 'Please sign in again.',
                403 => 'You do not have access to this.',
                409 => 'This changed in the meantime. Refreshing.',
                503 => 'Service is busy. Please retry in a moment.',
                _ => 'Something went wrong ($status).',
              }
            : msg[0].toUpperCase() + msg.substring(1),
        status: status,
      );
    }
    final text = e.toString().replaceFirst('Exception: ', '');
    return TournamentApiException(text);
  }

  @override
  String toString() => message;
}

class DisputeChatCredentials {
  final String customToken;
  final String firebaseUid;
  const DisputeChatCredentials(this.customToken, this.firebaseUid);
}

/// Client for `/api/v1/community`. One instance can be shared app-wide.
class TournamentApi {
  TournamentApi._();
  static final TournamentApi instance = TournamentApi._();
  factory TournamentApi() => instance;

  static final _rng = Random.secure();

  /// A fresh key per logical write; the server replays the original response
  /// when the same key + payload is retried after a timeout.
  static String newIdempotencyKey() => List.generate(
    16,
    (_) => _rng.nextInt(256),
  ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  final Dio _public = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.communityBaseUrl,
      connectTimeout: const Duration(seconds: 45),
      receiveTimeout: const Duration(seconds: 45),
    ),
  );

  String? _token;
  DateTime? _tokenExp;
  static Future<String?>? _refresh;

  /// Clear cached identity on logout/account switch so private lobby data is
  /// never reused for another account.
  void clearSession() {
    _token = null;
    _tokenExp = null;
  }

  Future<String?> _authToken() async {
    final exp = _tokenExp;
    if (_token != null &&
        exp != null &&
        DateTime.now().isBefore(exp.subtract(const Duration(minutes: 1)))) {
      return _token;
    }
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('jwt');
    if (token == null || token.isEmpty || isJwtExpired(token)) {
      _refresh ??= _refreshBackendToken().whenComplete(() => _refresh = null);
      token = await _refresh;
    }
    if (token == null || token.isEmpty || isJwtExpired(token)) return null;
    _token = token;
    _tokenExp = _expiryOf(token);
    return token;
  }

  static Future<String?> _refreshBackendToken() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    await user.getIdToken(true);
    await locator<RemoteRepoInterface>().checkUserExistsInAPI(user.uid);
    return (await SharedPreferences.getInstance()).getString('jwt');
  }

  DateTime? _expiryOf(String jwt) {
    try {
      final payload = base64Url.normalize(jwt.split('.')[1]);
      final map = jsonDecode(utf8.decode(base64Url.decode(payload))) as Map;
      final sec = (map['exp'] as num?)?.toInt();
      return sec == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(sec * 1000);
    } catch (_) {
      return null;
    }
  }

  Future<bool> get isSignedIn async => (await _authToken()) != null;

  /// A bare Dio: the shared NetworkConfig interceptor would overwrite the
  /// freshly minted Authorization header with a stale stored token.
  Future<Dio> _authed({String? idempotencyKey}) async {
    final token = await _authToken();
    if (token == null) {
      throw const TournamentApiException(
        'Please sign in to continue.',
        status: 401,
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
          'Idempotency-Key': ?idempotencyKey,
        },
      ),
    );
  }

  Future<dynamic> _get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    try {
      final dio = auth ? await _authed() : _public;
      final q = {...?query}..removeWhere((_, v) => v == null || v == '');
      return (await dio.get(path, queryParameters: q)).data;
    } catch (e) {
      throw TournamentApiException.from(e);
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    bool idempotent = false,
  }) async {
    try {
      final dio = await _authed(
        idempotencyKey: idempotent ? newIdempotencyKey() : null,
      );
      final res = await dio.request(
        path,
        data: body ?? const <String, dynamic>{},
        options: Options(method: method),
      );
      return res.data;
    } catch (e) {
      throw TournamentApiException.from(e);
    }
  }

  // ---------------------------------------------------------------- discovery

  Future<Paginated<Tournament>> list({
    String? view, // upcoming | live | completed
    String? game,
    String? search,
    int page = 1,
    int perPage = 20,
    String? sort,
  }) async => Paginated.fromJson(
    await _get(
      '/tournaments',
      auth: false,
      query: {
        'view': view,
        'game': game,
        'search': search,
        'page': page,
        'per_page': perPage,
        'sort': sort,
      },
    ),
    Tournament.new,
  );

  /// Signed-in detail (includes `can_manage` and room details when allowed);
  /// falls back to the public read for guests.
  Future<Tournament> tournament(String id, {String? inviteCode}) async {
    final q = {'invite_code': inviteCode};
    if (await isSignedIn) {
      return Tournament.fromJson(
        jsonMap(await _get('/tournaments/$id', query: q)),
      );
    }
    return Tournament.fromJson(
      jsonMap(await _get('/tournaments/public/$id', query: q, auth: false)),
    );
  }

  Future<MyTournamentState> me(String id, {String? inviteCode}) async =>
      MyTournamentState(
        jsonMap(
          await _get('/tournaments/$id/me', query: {'invite_code': inviteCode}),
        ),
      );

  Future<List<Team>> publicTeams(String id, {String? inviteCode}) async =>
      jsonList(
        await _get(
          '/tournaments/public/$id/teams',
          auth: false,
          query: {'invite_code': inviteCode},
        ),
      ).map(Team.new).toList();

  Future<List<Team>> teams(String id, {String? status}) async => jsonList(
    await _get('/tournaments/$id/teams', query: {'status': status}),
  ).map(Team.new).toList();

  Future<List<MatchRow>> matches(String id, {String? inviteCode}) async =>
      jsonList(
        await _get(
          '/tournaments/$id/matches',
          auth: false,
          query: {'invite_code': inviteCode},
        ),
      ).map(MatchRow.new).toList();

  Future<List<MatchRow>> privateMatches(String id) async => jsonList(
    await _get('/tournaments/$id/matches/private'),
  ).map(MatchRow.new).toList();

  Future<List<MatchRow>> myMatches(String id, {String? status}) async =>
      jsonList(
        await _get('/tournaments/$id/matches/me', query: {'status': status}),
      ).map(MatchRow.new).toList();

  Future<List<LeaderboardRow>> leaderboard(
    String id, {
    String? inviteCode,
  }) async => jsonList(
    await _get(
      '/tournaments/$id/leaderboard',
      auth: false,
      query: {'invite_code': inviteCode},
    ),
  ).map(LeaderboardRow.new).toList();

  Future<List<Announcement>> announcements(String id) async => jsonList(
    await _get('/tournaments/$id/announcements'),
  ).map(Announcement.new).toList();

  Future<HostProfile> hostProfile(int hostUserId) async => HostProfile(
    jsonMap(await _get('/hosts/$hostUserId/profile', auth: false)),
  );

  // ------------------------------------------------------------------- player

  Future<Paginated<Tournament>> myTournaments(
    String role, {
    int page = 1,
  }) async => Paginated.fromJson(
    await _get(
      '/me/tournaments',
      query: {'role': role, 'page': page, 'per_page': 50},
    ),
    Tournament.new,
  );

  Future<Registration> register(String id, {String? inviteCode}) async =>
      Registration(
        jsonMap(
          await _send(
            'POST',
            '/tournaments/$id/registrations',
            body: {'invite_code': ?inviteCode},
          ),
        ),
      );

  Future<Map<String, dynamic>> cancelMyRegistration(String id) async =>
      jsonMap(await _send('DELETE', '/tournaments/$id/registrations/me'));

  Future<Map<String, dynamic>> checkIn(String id) async => jsonMap(
    await _send('POST', '/tournaments/$id/check-in', idempotent: true),
  );

  Future<Team> createTeam(
    String id, {
    required String name,
    required List<Map<String, dynamic>> members,
  }) async => Team(
    jsonMap(
      await _send(
        'POST',
        '/tournaments/$id/teams',
        body: {'name': name, 'members': members},
        idempotent: true,
      ),
    ),
  );

  Future<Map<String, dynamic>> inviteMember(
    String id,
    String teamId, {
    required int userId,
    required String gameId,
    String role = 'player',
  }) async => jsonMap(
    await _send(
      'POST',
      '/tournaments/$id/teams/$teamId/members',
      body: {'user_id': userId, 'game_id': gameId, 'role': role},
      idempotent: true,
    ),
  );

  Future<Team> replaceRoster(
    String id,
    String teamId, {
    String? name,
    required List<Map<String, dynamic>> members,
  }) async => Team(
    jsonMap(
      await _send(
        'PUT',
        '/tournaments/$id/teams/$teamId/roster',
        body: {'name': ?name, 'members': members},
        idempotent: true,
      ),
    ),
  );

  Future<Map<String, dynamic>> respondInvitation(
    String id,
    String teamId, {
    required bool accept,
  }) async => jsonMap(
    await _send(
      'POST',
      '/tournaments/$id/teams/$teamId/invitation',
      body: {'action': accept ? 'accept' : 'decline'},
      idempotent: true,
    ),
  );

  Future<Paginated<TeamInvitation>> myInvitations() async => Paginated.fromJson(
    await _get('/me/team-invitations', query: {'per_page': 50}),
    TeamInvitation.new,
  );

  Future<Paginated<Dispute>> myDisputes({String? status}) async =>
      Paginated.fromJson(
        await _get('/me/disputes', query: {'status': status, 'per_page': 50}),
        Dispute.new,
      );

  Future<Dispute> dispute(String disputeId) async =>
      Dispute(jsonMap(await _get('/disputes/$disputeId')));

  Future<Paginated<Payout>> myPayouts({String? status}) async =>
      Paginated.fromJson(
        await _get('/me/payouts', query: {'status': status, 'per_page': 50}),
        Payout.new,
      );

  Future<ResultState> resultState(String id, String matchId) async =>
      ResultState(
        jsonMap(await _get('/tournaments/$id/matches/$matchId/result-state')),
      );

  Future<Map<String, dynamic>> submitCaptainResult(
    String id,
    String matchId, {
    required String winnerTeamId,
    required int scoreA,
    required int scoreB,
    List<String> evidenceAssetIds = const [],
    String? notes,
  }) async => jsonMap(
    await _send(
      'POST',
      '/tournaments/$id/matches/$matchId/result-submissions',
      body: {
        'winner_team_id': winnerTeamId,
        'team_a_score': scoreA,
        'team_b_score': scoreB,
        'evidence_asset_ids': evidenceAssetIds,
        'notes': ?notes,
      },
    ),
  );

  Future<Map<String, dynamic>> acceptProposal(
    String id,
    String matchId,
    String proposalId,
  ) async => jsonMap(
    await _send(
      'POST',
      '/tournaments/$id/matches/$matchId/result-proposals/$proposalId/accept',
      idempotent: true,
    ),
  );

  Future<Map<String, dynamic>> disputeProposal(
    String id,
    String matchId,
    String proposalId, {
    required String description,
    List<String> evidenceAssetIds = const [],
  }) async => jsonMap(
    await _send(
      'POST',
      '/tournaments/$id/matches/$matchId/result-proposals/$proposalId/dispute',
      body: {
        'description': description,
        'evidence_asset_ids': evidenceAssetIds,
      },
    ),
  );

  Future<Dispute> openDispute(
    String id, {
    required String matchId,
    required String reason,
    String? description,
    List<String> evidenceAssetIds = const [],
  }) async => Dispute(
    jsonMap(
      await _send(
        'POST',
        '/tournaments/$id/disputes',
        body: {
          'match_id': matchId,
          'reason': reason,
          'description': ?description,
          'evidence_asset_ids': evidenceAssetIds,
        },
      ),
    ),
  );

  Future<void> review(String id, Map<String, int> ratings, {String? comment}) =>
      _send(
        'POST',
        '/tournaments/$id/reviews',
        body: {...ratings, 'comment': ?comment},
        idempotent: true,
      );

  Future<DisputeChatCredentials> chatCredentials() async {
    final top = jsonMap(await _send('POST', '/chat/firebase-token'));
    final j = {...top, ...jsonMap(top['data']), ...jsonMap(top['credentials'])};
    String pick(List<String> keys) =>
        keys
            .map((k) => jsonStr(j[k]))
            .firstWhere((v) => v != null, orElse: () => '') ??
        '';
    return DisputeChatCredentials(
      pick(const [
        'custom_token',
        'customToken',
        'firebase_custom_token',
        'firebase_token',
        'token',
      ]),
      pick(const ['fid', 'firebase_uid', 'firebaseUid', 'firebase_id', 'uid']),
    );
  }

  /// Signed upload straight to Cloudinary, then registered as an asset.
  Future<FileAsset> uploadEvidence(
    String id, {
    required String purpose, // result_evidence | dispute_evidence
    required String filePath,
    required String fileName,
  }) async {
    try {
      final sig = jsonMap(
        await _send(
          'POST',
          '/tournaments/$id/evidence/upload-signature',
          body: {'purpose': purpose},
        ),
      );
      String s(String k) => sig[k]?.toString() ?? '';
      final uploadUrl = s('upload_url');
      if (uploadUrl.isEmpty || s('signature').isEmpty) {
        throw const TournamentApiException('Upload is unavailable right now.');
      }
      final res =
          await Dio(
            BaseOptions(
              sendTimeout: const Duration(seconds: 90),
              receiveTimeout: const Duration(seconds: 90),
            ),
          ).post(
            uploadUrl,
            data: FormData.fromMap({
              'file': await MultipartFile.fromFile(
                filePath,
                filename: fileName,
              ),
              for (final k in const [
                'api_key',
                'timestamp',
                'signature',
                'folder',
                'public_id',
                'allowed_formats',
              ])
                if (s(k).isNotEmpty) k: s(k),
            }),
          );
      final up = jsonMap(res.data);
      final url = up['secure_url']?.toString() ?? '';
      if (!url.startsWith('https://')) {
        throw const TournamentApiException('Upload failed. Try another image.');
      }
      final format = up['format']?.toString().toLowerCase() ?? 'jpeg';
      return createFileAsset(
        purpose: purpose,
        tournamentId: id,
        fileUrl: url,
        storageKey: s('storage_key').isEmpty
            ? up['public_id']?.toString()
            : s('storage_key'),
        mimeType: format == 'jpg' ? 'image/jpeg' : 'image/$format',
        sizeBytes: jsonInt(up['bytes']),
        metadata: {'width': ?up['width'], 'height': ?up['height']},
      );
    } catch (e) {
      throw TournamentApiException.from(e);
    }
  }

  Future<FileAsset> createFileAsset({
    required String purpose,
    required String fileUrl,
    String? tournamentId,
    String? storageKey,
    String? mimeType,
    int? sizeBytes,
    Map<String, dynamic>? metadata,
  }) async => FileAsset.fromJson(
    jsonMap(
      await _send(
        'POST',
        '/files',
        body: {
          'purpose': purpose,
          'file_url': fileUrl,
          'tournament_id': ?tournamentId,
          'storage_key': ?storageKey,
          'mime_type': ?mimeType,
          'file_size_bytes': ?sizeBytes,
          'metadata': ?metadata,
        },
      ),
    ),
  );

  // --------------------------------------------------------------------- host

  Future<HostProgram> hostProgram() async =>
      HostProgram.fromJson(jsonMap(await _get('/hosts/program', auth: false)));

  /// Null when the user never applied (the API returns JSON `null`).
  Future<HostVerification?> myHostVerification() async {
    try {
      final j = jsonMap(await _get('/hosts/me/verification'));
      return j.isEmpty ? null : HostVerification.fromJson(j);
    } on TournamentApiException catch (e) {
      if (e.status == 404 || e.isAuth) return null;
      rethrow;
    }
  }

  Future<HostVerification> submitHostVerification(
    Map<String, dynamic> body,
  ) async => HostVerification.fromJson(
    jsonMap(await _send('POST', '/hosts/verification', body: body)),
  );

  Future<Map<String, dynamic>> hostDashboard() async =>
      jsonMap(await _get('/hosts/me/dashboard'));

  Future<Map<String, dynamic>> ruleTemplate(String game) async => jsonMap(
    await _get('/rules/template', auth: false, query: {'game': game}),
  );

  Future<Tournament> createTournament(Map<String, dynamic> body) async =>
      Tournament.fromJson(
        jsonMap(
          await _send('POST', '/tournaments', body: body, idempotent: true),
        ),
      );

  Future<Tournament> updateTournament(
    String id,
    Map<String, dynamic> body,
  ) async => Tournament.fromJson(
    jsonMap(
      await _send('PATCH', '/tournaments/$id', body: body, idempotent: true),
    ),
  );

  Future<Readiness> readiness(String id) async =>
      Readiness.fromJson(jsonMap(await _get('/tournaments/$id/readiness')));

  Future<Map<String, dynamic>> cancelTournament(
    String id,
    String reason,
  ) async => jsonMap(
    await _send('POST', '/tournaments/$id/cancel', body: {'reason': reason}),
  );

  Future<Map<String, dynamic>> closeRegistration(String id) async => jsonMap(
    await _send(
      'POST',
      '/tournaments/$id/registrations/close',
      idempotent: true,
    ),
  );

  Future<Map<String, dynamic>> startTournament(String id) async =>
      jsonMap(await _send('POST', '/tournaments/$id/start', idempotent: true));

  Future<Map<String, dynamic>> controlRoom(String id) async =>
      jsonMap(await _get('/tournaments/$id/control-room'));

  Future<List<Registration>> registrations(String id, {String? status}) async =>
      jsonList(
        await _get(
          '/tournaments/$id/registrations',
          query: {'status': status, 'per_page': 100},
        ),
      ).map(Registration.new).toList();

  /// check_in | undo_check_in | remove_participant
  Future<Map<String, dynamic>> manageRegistration(
    String id,
    String registrationId,
    String action,
  ) async => jsonMap(
    await _send(
      'PATCH',
      '/tournaments/$id/registrations/$registrationId',
      body: {'action': action},
    ),
  );

  /// approve | reject | request_information | lock_roster | check_in |
  /// undo_check_in | seed | warn | disqualify | refund
  Future<Map<String, dynamic>> manageTeam(
    String id,
    String teamId,
    String action, {
    String? reason,
    int? seed,
  }) async => jsonMap(
    await _send(
      'PATCH',
      '/tournaments/$id/teams/$teamId',
      body: {'action': action, 'reason': ?reason, 'seed_number': ?seed},
    ),
  );

  Future<List<MatchRow>> generateMatches(String id) async => jsonList(
    await _send('POST', '/tournaments/$id/matches/generate', idempotent: true),
  ).map(MatchRow.new).toList();

  Future<MatchRow> createMatch(String id, Map<String, dynamic> body) async =>
      MatchRow(
        jsonMap(
          await _send(
            'POST',
            '/tournaments/$id/matches',
            body: body,
            idempotent: true,
          ),
        ),
      );

  /// start | reschedule | set_lobby | record_standings | restart | cancel
  Future<MatchRow> manageMatch(
    String id,
    String matchId,
    Map<String, dynamic> body,
  ) async => MatchRow(
    jsonMap(
      await _send('PATCH', '/tournaments/$id/matches/$matchId', body: body),
    ),
  );

  Future<Map<String, dynamic>> proposeResult(
    String id,
    String matchId, {
    required String winnerTeamId,
    required int scoreA,
    required int scoreB,
    List<String> evidenceAssetIds = const [],
  }) async => jsonMap(
    await _send(
      'POST',
      '/tournaments/$id/matches/$matchId/result-proposals',
      body: {
        'winner_team_id': winnerTeamId,
        'team_a_score': scoreA,
        'team_b_score': scoreB,
        'evidence_asset_ids': evidenceAssetIds,
      },
      idempotent: true,
    ),
  );

  Future<Map<String, dynamic>> resultsOverview(String id) async => jsonMap(
    await _get('/tournaments/$id/results/overview', query: {'per_page': 100}),
  );

  Future<List<Dispute>> tournamentDisputes(String id) async => jsonList(
    await _get('/tournaments/$id/disputes', query: {'per_page': 100}),
  ).map(Dispute.new).toList();

  Future<FinalizationPreview> finalizationPreview(String id) async =>
      FinalizationPreview(
        jsonMap(await _get('/tournaments/$id/finalization-preview')),
      );

  Future<Map<String, dynamic>> submitWinners(
    String id,
    List<Map<String, dynamic>> winners,
  ) async => jsonMap(
    await _send(
      'POST',
      '/tournaments/$id/winners',
      body: {'winners': winners},
      idempotent: true,
    ),
  );

  Future<List<Payout>> tournamentPayouts(String id) async => jsonList(
    await _get('/tournaments/$id/payouts', query: {'per_page': 100}),
  ).map(Payout.new).toList();

  Future<void> announce(
    String id, {
    required String title,
    required String message,
    String audience = 'all_participants',
  }) => _send(
    'POST',
    '/tournaments/$id/announcements',
    body: {'title': title, 'message': message, 'audience': audience},
    idempotent: true,
  );
}
