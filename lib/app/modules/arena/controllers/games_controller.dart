import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class CafeGamesController extends GetxController {
  var games = [].obs; // Observable list to store games data
  var isLoading = false.obs; // Observable to manage loading state
  var shopOpen = false.obs; // Observable to track shop status
  final _remoteRepo = locator<RemoteRepoInterface>();

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
}
