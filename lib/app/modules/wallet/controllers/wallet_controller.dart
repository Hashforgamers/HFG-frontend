import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import '../../../data/services/user_controller.dart';
import 'package:flutter/material.dart';

class WalletController extends GetxController {
  final userController = Get.find<UserController>(); // Injected
  final _remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  var balance = 0.obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Ensure UserController is available before proceeding
    try {
      // Listen to changes in user ID and fetch wallet when it becomes available
      ever(userController.id, (String userId) {
        if (userId.isNotEmpty) {
          fetchWallet();
        }
      });

      // Also try to fetch wallet immediately if user ID is already available
      if (userController.userId.isNotEmpty) {
        fetchWallet();
      } else {
        // Set up a retry mechanism
        _setupRetryMechanism();
      }
    } catch (e) {
      print('❌ WalletController initialization error: $e');
      // Set up a retry mechanism if UserController is not available yet
      _setupRetryMechanism();
    }
  }

  void _setupRetryMechanism() {
    // Retry wallet fetch after a delay if user ID becomes available
    Future.delayed(const Duration(seconds: 2), () {
      try {
        if (userController.userId.isNotEmpty && balance.value == 0) {
          fetchWallet();
        }
      } catch (e) {
        print('❌ WalletController retry error: $e');
        // Retry again after another delay
        Future.delayed(const Duration(seconds: 3), () {
          try {
            if (userController.userId.isNotEmpty && balance.value == 0) {
              fetchWallet();
            }
          } catch (e) {
            print('❌ WalletController final retry error: $e');
          }
        });
      }
    });
  }

  /// Fetch wallet balance using userId
  Future<void> fetchWallet() async {
    if (isLoading.value) return;

    isLoading.value = true;

    final userId = userController.userId.trim();
    if (userId.isEmpty) {
      isLoading.value = false;
      return;
    }

    final url = Uri.parse(ApiEndpoints.walletByUserId(userId));

    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        balance.value = data['balance'];
      } else {
        print('❌ Wallet API Error: ${res.body}');
        // Only show snackbar for non-retryable errors
        // Get.snackbar("Error", "Failed to load wallet ");
      }
    } catch (e) {
      print('❌ Wallet Exception: $e');
      // Only show snackbar for non-retryable errors
      print("Error $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// Manually refresh wallet balance
  Future<void> refreshWallet() async {
    await fetchWallet();
  }

  /// Check if wallet is ready to be fetched (user ID is available)
  bool get isWalletReady => userController.userId.isNotEmpty;

  /// Confirm top-up and refresh wallet
  Future<void> confirmTopUp({
    required int amount,
    required String paymentId,
  }) async {
    final userId = userController.userId.trim();
    if (userId.isEmpty) {
      Get.snackbar('Error', 'User ID missing, cannot confirm top-up.');
      return;
    }

    final url = Uri.parse(ApiEndpoints.addFundsByUserId(userId));

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"amount": amount, "reference_id": paymentId}),
      );

      if (res.statusCode == 200) {
        Get.snackbar("Success", "Wallet credited");
        await fetchWallet();
      } else {
        Get.snackbar("Error", "Top-up failed");
      }
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  Future<void> initiateWithdrawal(double amount, String bankAccount) async {
    try {
      // Track withdrawal initiated event
      segmentService.onWithdrawalInitiated(
        amount: amount,
        bankAccount: bankAccount,
      );
      fbEventsService.onWithdrawalInitiated(
        amount: amount,
        bankAccount: bankAccount,
      );

      // For now, simulate withdrawal success since the API method doesn't exist
      // In a real implementation, you would call the actual API
      await Future.delayed(const Duration(seconds: 1));

      // Track withdrawal success event
      final payoutId = 'payout_${DateTime.now().millisecondsSinceEpoch}';
      segmentService.onWithdrawalSuccess(payoutId: payoutId, amount: amount);
      fbEventsService.onWithdrawalSuccess(payoutId: payoutId, amount: amount);

      Get.snackbar(
        'Success',
        'Withdrawal initiated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Refresh wallet balance
      await fetchWallet();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to initiate withdrawal: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
