import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hash/app/modules/arena/models/nearby_teammate.dart';
import 'package:hash/app/modules/arena/services/nearby_teammates_firebase_service.dart';

class NearbyTeammatesController extends GetxController {
  NearbyTeammatesController({NearbyTeammatesFirebaseService? service})
    : _service = service ?? NearbyTeammatesFirebaseService();

  final NearbyTeammatesFirebaseService _service;

  final RxList<NearbyTeammate> teammates = <NearbyTeammate>[].obs;
  final RxList<NearbyTeammate> filteredTeammates = <NearbyTeammate>[].obs;
  final RxList<NearbyTeammate> squad = <NearbyTeammate>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool locationVisible = true.obs;
  final RxDouble discoveryRadiusKm = 12.0.obs;

  final RxnString selectedGame = RxnString();
  final RxnString selectedRank = RxnString();
  final RxnString selectedLanguage = RxnString();
  final RxnString selectedPlayStyle = RxnString();
  final RxBool micRequired = false.obs;
  final RxDouble minimumCompatibility = 0.0.obs;

  Future<void> loadNearby(LatLng userLocation) async {
    isLoading.value = true;
    try {
      await _service.upsertCurrentUserLocation(
        userLocation: userLocation,
        shareLocation: locationVisible.value,
      );
      final data = await _service.fetchNearbyTeammates(
        userLocation: userLocation,
        radiusKm: discoveryRadiusKm.value,
      );
      teammates.assignAll(data);
      applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setLocationVisibility({
    required bool visible,
    required LatLng userLocation,
  }) async {
    locationVisible.value = visible;
    await _service.upsertCurrentUserLocation(
      userLocation: userLocation,
      shareLocation: visible,
    );
  }

  void applyFilters() {
    final game = selectedGame.value;
    final rank = selectedRank.value;
    final language = selectedLanguage.value;
    final playStyle = selectedPlayStyle.value;
    final minimumScore = minimumCompatibility.value;

    final filtered =
        teammates.where((teammate) {
          if (game != null && !teammate.games.contains(game)) return false;
          if (rank != null && teammate.rank != rank) return false;
          if (language != null && !teammate.languages.contains(language)) {
            return false;
          }
          if (micRequired.value && !teammate.micEnabled) return false;
          if (playStyle != null && teammate.playStyle != playStyle) {
            return false;
          }
          return teammate.compatibilityScore >= minimumScore;
        }).toList()..sort(
          (a, b) => b.compatibilityScore.compareTo(a.compatibilityScore),
        );

    filteredTeammates.assignAll(filtered);
  }

  void clearFilters() {
    selectedGame.value = null;
    selectedRank.value = null;
    selectedLanguage.value = null;
    selectedPlayStyle.value = null;
    micRequired.value = false;
    minimumCompatibility.value = 0;
    applyFilters();
  }

  List<NearbyTeammate> findSquad() {
    // TODO: Replace this mock scoring with backend matchmaking once available.
    final candidates = List<NearbyTeammate>.from(filteredTeammates)
      ..sort((a, b) {
        final onlineCompare = (b.online ? 1 : 0).compareTo(a.online ? 1 : 0);
        if (onlineCompare != 0) return onlineCompare;
        final micCompare = (b.micEnabled ? 1 : 0).compareTo(
          a.micEnabled ? 1 : 0,
        );
        if (micCompare != 0) return micCompare;
        return b.compatibilityScore.compareTo(a.compatibilityScore);
      });

    final selected = candidates.take(4).toList();
    squad.assignAll(selected);
    return selected;
  }

  List<String> get availableGames =>
      teammates.expand((t) => t.games).toSet().toList()..sort();

  List<String> get availableRanks =>
      teammates.map((t) => t.rank).toSet().toList()..sort();

  List<String> get availableLanguages =>
      teammates.expand((t) => t.languages).toSet().toList()..sort();

  List<String> get availablePlayStyles =>
      teammates.map((t) => t.playStyle).toSet().toList()..sort();
}
