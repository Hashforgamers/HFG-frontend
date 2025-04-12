import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CafeGamesController extends GetxController {
  var games = [].obs; // Observable list to store games data
  var isLoading = false.obs; // Observable to manage loading state
  var shopOpen = false.obs; // Observable to track shop status

  Future<void> fetchGames(int vendorId) async {
    isLoading.value = true; // Set loading to true
    try {
      final response = await http.get(
        Uri.parse('https://hfg-booking-service.onrender.com/api/games/vendor/$vendorId'),
      );
      print(response.body); // Debugging API response
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        games.value = data['games'] ?? []; // Safely set the list of games
        shopOpen.value = data['shop_open'] ?? false; // Safely set shop status
      } else {
        Get.snackbar(
          'Error',
          'Failed to fetch games. Status code: ${response.statusCode}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to fetch games: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false; // Set loading to false
    }
  }
}
