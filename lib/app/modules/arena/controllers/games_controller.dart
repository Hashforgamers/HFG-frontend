import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/game_pass/model/get_vendor_passes_model.dart';
import 'package:hash/app/modules/game_pass/model/vendor_passes_response.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class _VendorGamesCacheEntry {
  const _VendorGamesCacheEntry({
    required this.games,
    required this.shopOpen,
    required this.cachedAt,
  });

  final List<Map<String, dynamic>> games;
  final bool shopOpen;
  final DateTime cachedAt;
}

class _VendorPassesCacheEntry {
  const _VendorPassesCacheEntry({
    required this.response,
    required this.cachedAt,
  });

  final VendorPassesResponse response;
  final DateTime cachedAt;
}

class CafeGamesController extends GetxController {
  static const Duration _gamesCacheTtl = Duration(minutes: 15);
  static const Duration _passesCacheTtl = Duration(minutes: 15);
  static const int _gamesCacheSchemaVersion = 2;
  static const int _passesCacheSchemaVersion = 2;
  static final Map<int, _VendorGamesCacheEntry> _gamesCache =
      <int, _VendorGamesCacheEntry>{};
  static final Map<int, _VendorPassesCacheEntry> _passesCache =
      <int, _VendorPassesCacheEntry>{};
  static final Map<int, Future<void>> _gamesRequests = <int, Future<void>>{};
  static final Map<int, Future<void>> _passesRequests = <int, Future<void>>{};
  static int _activeGamesCacheSchemaVersion = 0;
  static int _activePassesCacheSchemaVersion = 0;

  var games =
      <Map<String, dynamic>>[].obs; // Observable list to store games data
  var isLoading = false.obs; // Observable to manage loading state
  var shopOpen = false.obs; // Observable to track shop status
  final _remoteRepo = locator<RemoteRepoInterface>();
  var passes = <GetVendorPassesModel>[].obs;
  final vendorPassesResponse = Rxn<VendorPassesResponse>();
  var isPassesLoading = false.obs;

  String _prettyJson(dynamic value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }

  CafeGamesController() {
    _ensureGamesCacheSchema();
    _ensurePassesCacheSchema();
  }

  void _ensureGamesCacheSchema() {
    if (_activeGamesCacheSchemaVersion == _gamesCacheSchemaVersion) return;
    _gamesCache.clear();
    _gamesRequests.clear();
    _activeGamesCacheSchemaVersion = _gamesCacheSchemaVersion;
  }

  void _ensurePassesCacheSchema() {
    if (_activePassesCacheSchemaVersion == _passesCacheSchemaVersion) return;
    _passesCache.clear();
    _passesRequests.clear();
    _activePassesCacheSchemaVersion = _passesCacheSchemaVersion;
  }

  Future<void> fetchGames(int vendorId, {bool forceRefresh = false}) {
    final cached = _gamesCache[vendorId];
    final hasFreshCache =
        !forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _gamesCacheTtl;
    if (hasFreshCache) {
      _restoreGamesFromCache(vendorId);
      return Future.value();
    }

    final inFlight = _gamesRequests[vendorId];
    if (inFlight != null) {
      return inFlight.then((_) => _restoreGamesFromCache(vendorId));
    }

    final request = _loadGames(vendorId);
    _gamesRequests[vendorId] = request;
    return request.whenComplete(() {
      if (identical(_gamesRequests[vendorId], request)) {
        _gamesRequests.remove(vendorId);
      }
    });
  }

  Future<void> _loadGames(int vendorId) async {
    isLoading.value = true;
    try {
      final data = await _remoteRepo.fetchVendorGames(vendorId);
      debugPrint(
        'Available consoles source -> api=fetchVendorGames, vendor_id=$vendorId\n${_prettyJson(data)}',
      );
      final parsedGames = List<Map<String, dynamic>>.from(
        data['games'] as List? ?? const <Map<String, dynamic>>[],
      );
      final availabilitySummary = parsedGames.map((game) {
        final title =
            (game['game_name'] ??
                    game['name'] ??
                    game['title'] ??
                    game['console_type'] ??
                    'Unknown')
                .toString();
        final rawGameType =
            game['game_type'] ??
            game['gameType'] ??
            game['console_type'] ??
            game['game_platform'] ??
            game['platform_type'] ??
            game['type'];
        final available =
            game['available_slot'] ??
            game['available_slots'] ??
            game['count'] ??
            game['total_slots'];
        final consoleTypes = (game['consoles'] is List)
            ? (game['consoles'] as List)
                  .whereType<Map>()
                  .map(
                    (console) =>
                        (console['console_type'] ??
                                console['consoleType'] ??
                                console['type'] ??
                                '')
                            .toString(),
                  )
                  .where((value) => value.trim().isNotEmpty)
                  .toList()
            : const <String>[];
        return {
          'title': title,
          'game_type': rawGameType,
          'game_platform': game['game_platform'],
          'console_types': consoleTypes,
          'available': available,
          'consoles': game['consoles'],
        };
      }).toList();
      debugPrint(
        'Available consoles parsed summary -> vendor_id=$vendorId\n${_prettyJson(availabilitySummary)}',
      );
      final parsedShopOpen = _parseShopOpen(
        data['shop_open'],
        fallback: parsedGames.isNotEmpty,
      );
      games.assignAll(parsedGames);
      shopOpen.value = parsedShopOpen;
      _gamesCache[vendorId] = _VendorGamesCacheEntry(
        games: List<Map<String, dynamic>>.from(parsedGames),
        shopOpen: parsedShopOpen,
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      if (_gamesCache.containsKey(vendorId)) {
        _restoreGamesFromCache(vendorId);
      } else {
        Get.snackbar(
          'Error',
          'Failed to fetch games: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool _parseShopOpen(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    if (value is String) {
      final v = value.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'open' || v == 'yes') return true;
      if (v == 'false' || v == '0' || v == 'closed' || v == 'no') {
        return false;
      }
    }
    // Fallback: do not block booking flow when API omits this flag.
    return fallback;
  }

  Future<void> fetchPasses(int vendorId, {bool forceRefresh = false}) {
    final cached = _passesCache[vendorId];
    final hasFreshCache =
        !forceRefresh &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) < _passesCacheTtl;
    if (hasFreshCache) {
      _restorePassesFromCache(vendorId);
      return Future.value();
    }

    final inFlight = _passesRequests[vendorId];
    if (inFlight != null) {
      return inFlight.then((_) => _restorePassesFromCache(vendorId));
    }

    final request = _loadPasses(vendorId);
    _passesRequests[vendorId] = request;
    return request.whenComplete(() {
      if (identical(_passesRequests[vendorId], request)) {
        _passesRequests.remove(vendorId);
      }
    });
  }

  Future<void> _loadPasses(int vendorId) async {
    isPassesLoading.value = true;
    try {
      final loadedPasses = await _remoteRepo.getAllAvailablePasses(
        vendorId: vendorId.toString(),
      );
      vendorPassesResponse.value = loadedPasses;
      passes.assignAll(loadedPasses.visiblePasses);
      _passesCache[vendorId] = _VendorPassesCacheEntry(
        response: loadedPasses,
        cachedAt: DateTime.now(),
      );
      debugPrint('passes loaded: ${passes.length}');
    } catch (e) {
      if (_passesCache.containsKey(vendorId)) {
        _restorePassesFromCache(vendorId);
      } else {
        // Avoid overlay errors if view not mounted
        debugPrint('Failed to fetch passes: $e');
      }
    } finally {
      isPassesLoading.value = false;
    }
  }

  void _restoreGamesFromCache(int vendorId) {
    final cached = _gamesCache[vendorId];
    if (cached == null) return;
    games.assignAll(cached.games);
    shopOpen.value = cached.shopOpen;
  }

  void _restorePassesFromCache(int vendorId) {
    final cached = _passesCache[vendorId];
    if (cached == null) return;
    final response = cached.response;
    vendorPassesResponse.value = response;
    passes.assignAll(response.visiblePasses);
  }
}
