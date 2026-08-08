import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/app/modules/tournaments_section/models/gamer_profile_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tournament_home_state.dart';

class TournamentHomeCubit extends Cubit<TournamentHomeState> {
  static const Duration _cacheTtl = Duration(minutes: 5);
  static final Map<String, _TournamentHomeCacheEntry> _cacheByScope = {};
  static final Set<TournamentHomeCubit> _activeInstances =
      <TournamentHomeCubit>{};

  TournamentHomeCubit() : super(TournamentHomeInitial()) {
    _activeInstances.add(this);
  }

  final remoteRepo = locator<RemoteRepoInterface>();
  final Map<String, List<TournamentModel>> _joinedByTab = {
    'All': const [],
    'Live': const [],
    'Upcoming': const [],
    'Completed': const [],
  };

  List<TournamentModel> _allJoinableTournaments = [];
  List<Map<String, dynamic>> _myTeams = const [];
  GamerProfileModel? _gamerProfile;
  String _selectedCategory = 'All';
  Future<void>? _fetchTournamentsRequest;
  int _fetchGeneration = 0;

  void _emitIfOpen(TournamentHomeState state) {
    if (!isClosed) emit(state);
  }

  static void invalidateCache({bool refreshActive = true}) {
    _cacheByScope.clear();
    if (!refreshActive) return;

    for (final cubit in List<TournamentHomeCubit>.from(_activeInstances)) {
      if (cubit.isClosed) continue;
      cubit._fetchGeneration++;
      cubit._fetchTournamentsRequest = null;
      unawaited(cubit.fetchTournaments(forceRefresh: true));
    }
  }

  Future<void> fetchTournaments({bool forceRefresh = true}) async {
    final cacheScope = await _resolveCacheScope();
    final cachedSnapshot = _cacheByScope[cacheScope];

    if (!forceRefresh && cachedSnapshot != null) {
      _applyCacheSnapshot(cachedSnapshot);
      _emitLoadedForSelectedCategory();
      if (cachedSnapshot.isFresh) return;
    }

    if (_fetchTournamentsRequest != null) {
      return _fetchTournamentsRequest;
    }

    if (state is! TournamentHomeLoaded && cachedSnapshot == null) {
      _emitIfOpen(TournamentHomeLoading());
    }

    final requestGeneration = ++_fetchGeneration;
    final request = _loadTournaments(
      requestGeneration: requestGeneration,
      cacheScope: cacheScope,
      fallbackSnapshot: cachedSnapshot,
    );
    _fetchTournamentsRequest = request;

    try {
      await request;
    } finally {
      if (identical(_fetchTournamentsRequest, request)) {
        _fetchTournamentsRequest = null;
      }
    }
  }

  Future<void> _loadTournaments({
    required int requestGeneration,
    required String cacheScope,
    _TournamentHomeCacheEntry? fallbackSnapshot,
  }) async {
    try {
      final userId = await _resolveUserId();
      if (!_isRequestCurrent(requestGeneration)) return;

      final events = await remoteRepo.fetchPublicEvents();
      if (!_isRequestCurrent(requestGeneration)) return;

      _allJoinableTournaments = events.map(TournamentModel.fromJson).toList();
      _resetJoinedTabs();

      if (userId != null && userId > 0) {
        final joinedPayload = await remoteRepo.fetchJoinedTournaments(
          userId: userId,
        );
        if (!_isRequestCurrent(requestGeneration)) return;

        _joinedByTab['All'] = (joinedPayload['all'] ?? const [])
            .map((e) => TournamentModel.fromJson({...e, 'is_joined': true}))
            .toList();
        _joinedByTab['Live'] = (joinedPayload['live'] ?? const [])
            .map((e) => TournamentModel.fromJson({...e, 'is_joined': true}))
            .toList();
        _joinedByTab['Upcoming'] = (joinedPayload['upcoming'] ?? const [])
            .map((e) => TournamentModel.fromJson({...e, 'is_joined': true}))
            .toList();
        _joinedByTab['Completed'] = (joinedPayload['completed'] ?? const [])
            .map((e) => TournamentModel.fromJson({...e, 'is_joined': true}))
            .toList();

        final joinedTournamentIds = _joinedByTab.values
            .expand((tournaments) => tournaments)
            .map((tournament) => tournament.id.trim().toLowerCase())
            .where((id) => id.isNotEmpty)
            .toSet();
        _allJoinableTournaments = _allJoinableTournaments
            .map(
              (tournament) =>
                  joinedTournamentIds.contains(
                    tournament.id.trim().toLowerCase(),
                  )
                  ? tournament.copyWith(isJoined: true)
                  : tournament,
            )
            .toList();
      }

      final myTeams = await _fetchMyTeamsSafe(userId: userId);
      if (!_isRequestCurrent(requestGeneration)) return;
      _myTeams = _enrichTeamsWithJoinedTournaments(myTeams);
      _gamerProfile = await _fetchGamerProfileSafe(userId);
      if (!_isRequestCurrent(requestGeneration)) return;

      _cacheByScope[cacheScope] = _TournamentHomeCacheEntry(
        fetchedAt: DateTime.now(),
        joinableTournaments: List<TournamentModel>.from(
          _allJoinableTournaments,
        ),
        joinedByTab: _cloneJoinedByTab(_joinedByTab),
        myTeams: _cloneMyTeams(_myTeams),
        gamerProfile: _gamerProfile,
      );

      _emitLoadedForSelectedCategory();
    } catch (e) {
      if (!_isRequestCurrent(requestGeneration)) return;
      if (fallbackSnapshot != null) {
        _applyCacheSnapshot(fallbackSnapshot);
        _emitLoadedForSelectedCategory();
        return;
      }
      _emitIfOpen(TournamentHomeError(message: e.toString()));
    }
  }

  void filterTournaments(String category) {
    _selectedCategory = category;
    if (state is! TournamentHomeLoaded) return;
    _emitLoadedForSelectedCategory();
  }

  void _emitLoadedForSelectedCategory() {
    _emitIfOpen(
      TournamentHomeLoaded(
        tournaments: List<TournamentModel>.from(
          (_joinedByTab[_selectedCategory] ?? const <TournamentModel>[]).where(
            (tournament) => tournament.matchesFilter(_selectedCategory),
          ),
        ),
        allJoinedTournaments: List<TournamentModel>.from(
          _joinedByTab['All'] ?? const <TournamentModel>[],
        ),
        joinableTournaments: List<TournamentModel>.from(
          _allJoinableTournaments.where(
            (tournament) => tournament.matchesFilter(_selectedCategory),
          ),
        ),
        myTeams: _cloneMyTeams(_myTeams),
        gamerProfile: _gamerProfile,
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchMyTeamsSafe({int? userId}) async {
    try {
      final resolvedUserId = userId ?? await _resolveUserId();
      if (resolvedUserId == null || resolvedUserId <= 0) return const [];
      return await remoteRepo.fetchUserTeams(userId: resolvedUserId);
    } catch (_) {
      return const [];
    }
  }

  Future<GamerProfileModel?> _fetchGamerProfileSafe(int? userId) async {
    if (userId == null || userId <= 0) return null;
    try {
      return GamerProfileModel.fromJson(
        await remoteRepo.fetchGamerProfile(userId: userId),
      );
    } catch (_) {
      return null;
    }
  }

  void _applyCacheSnapshot(_TournamentHomeCacheEntry snapshot) {
    _allJoinableTournaments = List<TournamentModel>.from(
      snapshot.joinableTournaments,
    );
    _myTeams = _cloneMyTeams(snapshot.myTeams);
    _gamerProfile = snapshot.gamerProfile;

    final clonedJoined = _cloneJoinedByTab(snapshot.joinedByTab);
    for (final key in _joinedByTab.keys) {
      _joinedByTab[key] = clonedJoined[key] ?? const <TournamentModel>[];
    }
  }

  void _resetJoinedTabs() {
    for (final key in _joinedByTab.keys) {
      _joinedByTab[key] = const <TournamentModel>[];
    }
  }

  Future<String> _resolveCacheScope() async {
    final firebaseUid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null && firebaseUid.isNotEmpty) {
      return 'firebase:$firebaseUid';
    }

    final userId = await _resolveUserId(allowNetwork: false);
    if (userId != null && userId > 0) {
      return 'user:$userId';
    }

    return 'guest';
  }

  Future<int?> _resolveUserId({bool allowNetwork = true}) async {
    if (Get.isRegistered<UserController>()) {
      final controller = Get.find<UserController>();
      final fromController = _parseUserIdFromDynamic(controller.userId);
      if (fromController != null && fromController > 0) {
        return fromController;
      }
    }

    if (!allowNetwork) {
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

  Map<String, List<TournamentModel>> _cloneJoinedByTab(
    Map<String, List<TournamentModel>> source,
  ) {
    return <String, List<TournamentModel>>{
      'All': List<TournamentModel>.from(source['All'] ?? const []),
      'Live': List<TournamentModel>.from(source['Live'] ?? const []),
      'Upcoming': List<TournamentModel>.from(source['Upcoming'] ?? const []),
      'Completed': List<TournamentModel>.from(source['Completed'] ?? const []),
    };
  }

  List<Map<String, dynamic>> _cloneMyTeams(List<Map<String, dynamic>> source) {
    return List<Map<String, dynamic>>.from(
      source.map((team) => Map<String, dynamic>.from(team)),
    );
  }

  List<Map<String, dynamic>> _enrichTeamsWithJoinedTournaments(
    List<Map<String, dynamic>> teams,
  ) {
    final joinedById = <String, TournamentModel>{};
    for (final tournament in _joinedByTab.values.expand((items) => items)) {
      final id = tournament.id.trim().toLowerCase();
      if (id.isNotEmpty) joinedById[id] = tournament;
    }

    return teams.map((rawTeam) {
      final team = Map<String, dynamic>.from(rawTeam);
      final existingValue = team['tournament'] ?? team['event'];
      final existing = existingValue is Map
          ? Map<String, dynamic>.from(existingValue)
          : <String, dynamic>{};
      final eventId =
          (team['event_id'] ?? existing['event_id'] ?? existing['id'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
      final joined = joinedById[eventId];
      if (joined == null) return team;

      team['event_id'] = team['event_id'] ?? joined.id;
      team['tournament'] = <String, dynamic>{
        'id': joined.id,
        'event_id': joined.id,
        'title': joined.title,
        'name': joined.title,
        'source': joined.source,
        'image_url': joined.imageUrl,
        'banner': joined.banner,
        'status': joined.statusLabel,
        ...existing,
      };
      return team;
    }).toList();
  }

  bool _isRequestCurrent(int requestGeneration) {
    return !isClosed && requestGeneration == _fetchGeneration;
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

  @override
  Future<void> close() {
    _activeInstances.remove(this);
    return super.close();
  }
}

class _TournamentHomeCacheEntry {
  const _TournamentHomeCacheEntry({
    required this.fetchedAt,
    required this.joinableTournaments,
    required this.joinedByTab,
    required this.myTeams,
    required this.gamerProfile,
  });

  final DateTime fetchedAt;
  final List<TournamentModel> joinableTournaments;
  final Map<String, List<TournamentModel>> joinedByTab;
  final List<Map<String, dynamic>> myTeams;
  final GamerProfileModel? gamerProfile;

  bool get isFresh =>
      DateTime.now().difference(fetchedAt) <= TournamentHomeCubit._cacheTtl;
}
