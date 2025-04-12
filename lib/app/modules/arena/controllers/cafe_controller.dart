import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CybercafesController extends GetxController {
  var cybercafes = [].obs; // Observable list to store cybercafes data
  var isLoading = false.obs; // Observable to manage loading state

  @override
  void onInit() {
    super.onInit();
    fetchCybercafes(); // Fetch cafes on initialization
  }

  Future<void> fetchCybercafes() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse('https://hfg-onboard.onrender.com/api/vendor/dashboard'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(json.encode(data)); // Log the entire API response for inspection

        // Ensure the data is properly cast to List<Map<String, dynamic>>
        cybercafes.value = List<Map<String, dynamic>>.from(data['vendors']);
      } else {
        Get.snackbar('Error', 'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch data: $e');
    } finally {
      isLoading.value = false;
    }
  }

}
