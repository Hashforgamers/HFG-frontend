import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hash/core/network/api_endpoints.dart';
import '../../../data/services/user_controller.dart';

class WalletController extends GetxController {
  final userController = Get.find<UserController>(); // Injected

  var balance = 0.obs;
  var isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    fetchWallet(); // 👈 Automatically fetch on controller load
  }

  /// Fetch wallet balance using userId
  Future<void> fetchWallet() async {
    isLoading.value = true;

    final userId = userController.userId?.trim();
    if (userId == null || userId.isEmpty) {
      Get.snackbar('User ID Missing', 'Cannot load wallet without a valid user ID');
      isLoading.value = false;
      return;
    }

    final url = Uri.parse(ApiEndpoints.walletByUserId(userId));
    print('📦 Wallet API: $url');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        balance.value = data['balance'];
      } else {
        print('❌ Wallet API Error: ${res.body}');
        Get.snackbar("Error", "Failed to load wallet • ${res.body}");
      }
    } catch (e) {
      print('❌ Wallet Exception: $e');
      Get.snackbar("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// Confirm top-up and refresh wallet
  Future<void> confirmTopUp({
    required int amount,
    required String paymentId,
  }) async {
    final userId = userController.userId?.trim();
    if (userId == null || userId.isEmpty) {
      Get.snackbar('Error', 'User ID missing, cannot confirm top-up.');
      return;
    }

    final url = Uri.parse(ApiEndpoints.addFundsByUserId(userId));
    print('💸 Confirm Top-Up URL: $url');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "amount": amount,
          "reference_id": paymentId,
        }),
      );

      if (res.statusCode == 200) {
        Get.snackbar("Success", "Wallet credited");
        await fetchWallet();
      } else {
        print('❌ Top-Up Error: ${res.body}');
        Get.snackbar("Error", "Top-up failed");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }
}
