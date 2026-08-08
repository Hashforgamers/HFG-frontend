import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/community/services/community_api.dart';
import 'package:hash/app/modules/tournaments_section/services/tournament_payment_service.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/app/modules/tournaments_section/cubit/tournament_home_cubit.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tournaments_register_state.dart';

class TournamentsRegisterCubit extends Cubit<TournamentsRegisterState> {
  TournamentsRegisterCubit() : super(TournamentsRegisterInitial()) {
    AppLogger.d('🟩 TournamentsRegisterCubit created');
  }

  final remoteRepo = locator<RemoteRepoInterface>();
  final squadMissionsService = locator<SquadMissionsService>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final analyticsService = locator<AnalyticsService>();
  final CommunityApi communityApi = CommunityApi();
  final TournamentPaymentService paymentService = TournamentPaymentService();

  Future<void> registerTeam({
    required String eventId,
    required String leaderName,
    required String teamName,
    String source = 'cafe',
    String teamMode = 'team',
    String captainGameId = '',
    List<String> players = const [],
    TournamentPaymentResult? payment,
  }) async {
    emit(TournamentsRegisterLoading());
    try {
      if (source.trim().toLowerCase() == 'community') {
        final isCommunityTeam = teamMode.trim().toLowerCase() != 'solo';
        if (isCommunityTeam && teamName.trim().isEmpty) {
          throw Exception('Team name is required.');
        }
        final registration = await communityApi.registerForTournament(
          eventId,
          paymentReference: payment?.paymentReference.isNotEmpty == true
              ? payment!.paymentReference
              : null,
          razorpayOrderId: payment?.orderId,
        );
        final registrationId = registration.id;
        final isPaidRegistration = payment?.paymentReference.isNotEmpty == true;
        Map<String, dynamic> verification = const <String, dynamic>{};

        if (isPaidRegistration) {
          if (payment?.requiresVerification != true) {
            throw Exception('Razorpay returned an incomplete payment result.');
          }
          try {
            verification = await paymentService.verifyRegistrationPayment(
              payment: payment!,
              registrationId: registrationId,
              tournamentId: eventId,
              community: true,
            );
          } on DioException catch (error) {
            if (!_isNetworkFailure(error)) rethrow;
            verification = await _refreshCommunitySettlement(
              registrationId: registrationId,
            );
          }

          if (!_isPaidAndConfirmed(verification)) {
            final refreshed = await _refreshCommunitySettlement(
              registrationId: registrationId,
            );
            if (refreshed.isNotEmpty) verification = refreshed;
          }

          if (!_isPaidAndConfirmed(verification)) {
            TournamentHomeCubit.invalidateCache();
            emit(
              TournamentsRegisterSettlementPending(
                registrationId: registrationId,
                message:
                    'Payment was received. We are confirming your tournament spot automatically.',
              ),
            );
            return;
          }
        } else if (registration.status.toLowerCase() != 'confirmed') {
          throw Exception('Free registration was not confirmed by the server.');
        }
        String? communityTeamId;
        if (isCommunityTeam) {
          final userId = await _resolveUserId();
          if (userId == null || userId <= 0) {
            throw Exception('User not found. Please login again.');
          }
          final profileGameId = Get.isRegistered<UserController>()
              ? (Get.find<UserController>().user.value.gameUserName ?? '')
                    .trim()
              : '';
          final gameId = captainGameId.trim().isNotEmpty
              ? captainGameId.trim()
              : profileGameId;
          if (gameId.isEmpty) {
            throw Exception('Captain in-game ID is required.');
          }
          final team = await communityApi.createTeam(
            eventId,
            name: teamName.trim(),
            members: [
              {'user_id': userId, 'game_id': gameId, 'role': 'captain'},
            ],
          );
          communityTeamId = team.id;
          await analyticsService.log(
            'team_created',
            parameters: {
              'tournament_id': eventId,
              'tournament_mode': teamMode,
              'team_status': 'pending',
              'source_screen': 'tournament_registration',
            },
          );
        }
        squadMissionsService.trackAction(
          action: SquadMissionAction.joinTournament,
        );
        final lifecycleParams = <String, Object?>{
          'tournament_id': eventId,
          'tournament_mode': teamMode,
          'team_status': isCommunityTeam ? 'pending' : 'solo',
          'source_screen': 'tournament_registration',
        };
        if (isPaidRegistration) {
          await analyticsService.log(
            'payment_success',
            parameters: lifecycleParams,
          );
        }
        await analyticsService.log(
          'tournament_joined',
          parameters: lifecycleParams,
        );
        segmentService.onCustomEvent('Tournament Joined', {
          'event_id': eventId,
          'registration_id': registrationId,
          'source': 'community',
        });
        fbEventsService.onTournamentJoined(
          eventId: eventId,
          teamId: communityTeamId ?? registrationId,
        );
        TournamentHomeCubit.invalidateCache();
        emit(
          TournamentsRegisterSuccess(
            data: <String, dynamic>{
              'registration_id': registrationId,
              // Legacy screens read team_id even for solo registrations.
              'team_id': communityTeamId ?? registrationId,
              if (communityTeamId != null) 'team_name': teamName.trim(),
              'status': _readPaymentField(
                verification,
                'status',
                isPaidRegistration ? 'pending_payment' : registration.status,
              ),
              'payment_status': _readPaymentField(
                verification,
                'payment_status',
                isPaidRegistration ? 'unpaid' : registration.paymentStatus,
              ),
              'source': 'community',
              'payment_reference': registration.paymentReference ?? '',
            },
          ),
        );
        return;
      }

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
      await analyticsService.log(
        'team_created',
        parameters: {
          'tournament_id': eventId,
          'tournament_mode': teamMode,
          'team_status': 'created',
          'source_screen': 'tournament_registration',
        },
      );

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
        "payment_reference": payment?.paymentReference ?? '',
      };

      if (payment != null) {
        final verification = await paymentService.verifyRegistrationPayment(
          payment: payment,
          registrationId: teamId,
          tournamentId: eventId,
          community: false,
        );
        result['status'] = _readPaymentField(
          verification,
          'status',
          result['status']?.toString() ?? '',
        );
        result['payment_status'] = _readPaymentField(
          verification,
          'payment_status',
          result['payment_status']?.toString() ?? '',
        );
        if (_isPaidAndConfirmed(verification)) {
          await analyticsService.log(
            'payment_success',
            parameters: {
              'tournament_id': eventId,
              'tournament_mode': teamMode,
              'team_status': 'created',
              'source_screen': 'tournament_registration',
            },
          );
        }
      }

      await squadMissionsService.setActiveSquad(
        squadKey: teamId,
        squadName: teamName.trim(),
      );
      squadMissionsService.trackAction(
        action: SquadMissionAction.joinTournament,
      );
      segmentService.onCustomEvent('Tournament Joined', {
        'event_id': eventId,
        'team_id': teamId,
      });
      fbEventsService.onTournamentJoined(eventId: eventId, teamId: teamId);
      await analyticsService.log(
        'tournament_joined',
        parameters: {
          'tournament_id': eventId,
          'tournament_mode': teamMode,
          'team_status': 'created',
          'source_screen': 'tournament_registration',
        },
      );
      segmentService.onCustomEvent('Party Created', {
        'party_id': teamId,
        'game_id': eventId,
      });
      fbEventsService.onPartyCreated(partyId: teamId, gameId: eventId);

      TournamentHomeCubit.invalidateCache();
      emit(TournamentsRegisterSuccess(data: result));
    } catch (e) {
      if (payment != null) {
        await analyticsService.log(
          'payment_failed',
          parameters: {
            'tournament_id': eventId,
            'tournament_mode': teamMode,
            'source_screen': 'tournament_registration',
            'failure_reason': AnalyticsService.normalizeFailureReason(e),
          },
        );
      }
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

      await squadMissionsService.setActiveSquad(squadKey: teamId.trim());
      squadMissionsService.trackAction(
        action: SquadMissionAction.joinTournament,
      );
      segmentService.onCustomEvent('Tournament Joined', {
        'event_id': eventId,
        'team_id': teamId.trim(),
      });
      fbEventsService.onTournamentJoined(
        eventId: eventId,
        teamId: teamId.trim(),
      );
      segmentService.onCustomEvent('Party Joined', {
        'party_id': teamId.trim(),
        'game_id': eventId,
      });
      fbEventsService.onPartyJoined(partyId: teamId.trim(), gameId: eventId);

      TournamentHomeCubit.invalidateCache();
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

  Future<void> registerWithExistingTeam({
    required String eventId,
    required String teamId,
    String? paymentReference,
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
      final response = await remoteRepo.registerEventTeam(
        eventId: eventId,
        userId: userId,
        teamId: teamId.trim(),
      );
      await squadMissionsService.setActiveSquad(squadKey: teamId.trim());
      squadMissionsService.trackAction(
        action: SquadMissionAction.joinTournament,
      );
      segmentService.onCustomEvent('Tournament Joined', {
        'event_id': eventId,
        'team_id': teamId.trim(),
      });
      fbEventsService.onTournamentJoined(
        eventId: eventId,
        teamId: teamId.trim(),
      );
      TournamentHomeCubit.invalidateCache();
      emit(
        TournamentsRegisterSuccess(
          data: <String, dynamic>{
            ...response,
            'team_id': teamId.trim(),
            'action': 'register_existing_team',
            'payment_reference': paymentReference ?? '',
          },
        ),
      );
    } catch (e) {
      emit(TournamentsRegisterError(message: _cleanError(e)));
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyTeamsForEvent(
    String eventId,
  ) async {
    final userId = await _resolveUserId();
    if (userId == null || userId <= 0) {
      throw Exception('User not found. Please login again.');
    }
    final teams = await remoteRepo.fetchUserTeams(userId: userId);
    final normalizedEventId = eventId.trim().toLowerCase();
    final filtered = teams.where((team) {
      final teamEventId =
          (team['event_id'] ??
                  team['eventId'] ??
                  (team['event'] is Map<String, dynamic>
                      ? team['event']['id']
                      : null) ??
                  (team['tournament'] is Map<String, dynamic>
                      ? team['tournament']['id']
                      : null) ??
                  '')
              .toString()
              .trim()
              .toLowerCase();
      return teamEventId == normalizedEventId;
    }).toList();

    if (filtered.isNotEmpty) return filtered;
    return teams;
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

  String _readPaymentField(
    Map<String, dynamic> payload,
    String key,
    String fallback,
  ) {
    final direct = payload[key]?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final data = payload['data'];
    if (data is Map) {
      final nested = data[key]?.toString();
      if (nested != null && nested.isNotEmpty) return nested;
    }
    final registration = payload['registration'];
    if (registration is Map) {
      final nested = registration[key]?.toString();
      if (nested != null && nested.isNotEmpty) return nested;
    }
    return fallback;
  }

  bool _isPaidAndConfirmed(Map<String, dynamic> payload) {
    final status = _readPaymentField(payload, 'status', '').toLowerCase();
    final paymentStatus = _readPaymentField(
      payload,
      'payment_status',
      '',
    ).toLowerCase();
    return status == 'confirmed' && paymentStatus == 'paid';
  }

  bool _isNetworkFailure(DioException error) {
    return error.response == null ||
        error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.unknown;
  }

  Future<Map<String, dynamic>> _refreshCommunitySettlement({
    required String registrationId,
  }) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) await Future<void>.delayed(const Duration(seconds: 2));
      try {
        final joined = await communityApi.myTournaments(role: 'joined');
        for (final item in joined) {
          final registration = item.registration;
          if (registration == null) continue;
          final matches = registration.id == registrationId;
          if (!matches) continue;
          final result = <String, dynamic>{
            'registration_id': registration.id,
            'status': registration.status,
            'payment_status': registration.paymentStatus,
            'payment_reference': registration.paymentReference ?? '',
          };
          if (_isPaidAndConfirmed(result)) return result;
        }
      } catch (_) {
        // The backend settlement queue remains the source of truth. Retry the
        // joined-tournaments read briefly, then surface a non-failure state.
      }
    }
    return const <String, dynamic>{};
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
