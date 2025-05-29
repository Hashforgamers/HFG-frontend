import 'package:get/get.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

class CybercafesController extends GetxController {
  var cybercafes = [].obs; // Observable list to store cybercafes data
  var isLoading = false.obs; // Observable to manage loading state
  final _remoteRepo = locator<RemoteRepoInterface>();

  @override
  void onInit() {
    super.onInit();
    fetchCybercafes(); // Fetch cafes on initialization
  }

  Future<void> fetchCybercafes() async {
    isLoading.value = true;
    try {
      final cafes = await _remoteRepo.fetchCybercafes();
      cybercafes.value = cafes;
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
