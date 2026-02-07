import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/game_pass/model/get_vendor_passes_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class CafeGamesController extends GetxController {
  var games = [].obs; // Observable list to store games data
  var isLoading = false.obs; // Observable to manage loading state
  var shopOpen = false.obs; // Observable to track shop status
  final _remoteRepo = locator<RemoteRepoInterface>();
  var passes = <GetVendorPassesModel>[].obs;
  var isPassesLoading = false.obs;

  Future<void> fetchGames(int vendorId) async {
    isLoading.value = true;
    try {
      final data = await _remoteRepo.fetchVendorGames(vendorId);
      games.value = data['games'];
      shopOpen.value = data['shop_open'];
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch games: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPasses(int vendorId) async {
    isPassesLoading.value = true;
    try {
      passes.value = await _remoteRepo.getAllAvailablePasses(
        vendorId: vendorId.toString(),
      );
      debugPrint('passes loaded: ${passes.length}');
    } catch (e) {
      // Avoid overlay errors if view not mounted
      debugPrint('Failed to fetch passes: $e');
    } finally {
      isPassesLoading.value = false;
    }
  }
}
