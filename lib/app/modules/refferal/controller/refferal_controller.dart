import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/core/repositories/model/get_voucher_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/app/data/services/user_controller.dart';

class ReferralController extends GetxController {
  final _remoteRepo = locator<RemoteRepoInterface>();
  final _userController = Get.find<UserController>();

  // Observable variables
  var isLoading = false.obs;
  var voucherCreated = false.obs;
  var errorMessage = ''.obs;
  var successMessage = ''.obs;
  var voucherData = Rxn<Map<String, dynamic>>();
  var vouchers = <Voucher>[].obs;
  var isLoadingVouchers = false.obs;

  /// Show snackbar with fallback to ScaffoldMessenger
  void _showSnackbar(String title, String message, Color backgroundColor) {
    try {
      // Try Get.snackbar first
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: backgroundColor,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
      );
    } catch (e) {
      // Fallback to ScaffoldMessenger if Get.snackbar fails
      print('Get.snackbar failed, using ScaffoldMessenger: $e');
      if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  /// Clear error and success messages
  void clearMessages() {
    errorMessage.value = '';
    successMessage.value = '';
  }

  /// Create a voucher for the current user
  Future<void> createVoucher() async {
    if (isLoading.value) return; // Prevent multiple simultaneous calls

    isLoading(true);
    clearMessages(); // Clear any previous messages

    try {
      // Get user ID from user controller
      final user = _userController.user.value;
      final prefUser = await _remoteRepo.getUserFromPreferences();
      final userId = prefUser?['id'].toString();

      // Extract user ID from user data (assuming it's stored in user model)
      // You might need to adjust this based on how user ID is stored

      if (userId == null) {
        throw Exception('User ID not found. Please complete your profile.');
      }

      // Call the create voucher API (no authentication required)
      await _remoteRepo.createVoucher(userId: userId);

      // Handle successful response
      voucherCreated(true);
      successMessage.value = 'Voucher created successfully!';

      // Refresh the vouchers list
      await getVoucher();

      // Show success message
      _showSnackbar('Success', 'Voucher created successfully!', const Color(0xff4CAF50));
    } catch (e) {
      errorMessage.value = 'Failed to create voucher: $e';
      voucherCreated(false);

      print('=== VOUCHER CREATION ERROR ===');
      print('Original error: $e');
      
      // Extract user-friendly error message
      String errorMsg = e.toString();
      String errorTitle = 'Error';
      Color backgroundColor = const Color(0xffF44336);
      
      // Remove "Exception: " prefix if present
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.replaceAll('Exception: ', '');
      }
      
      // Handle specific error cases
      if (errorMsg.contains('Not enough referral points')) {
        errorTitle = 'Insufficient Points';
        backgroundColor = const Color(0xffff9800); // Orange for insufficient points
        errorMsg = 'You need more referral points to create a voucher. Share your referral code with friends to earn points!';
      } else if (errorMsg.contains('network') || errorMsg.contains('connection')) {
        errorTitle = 'Network Error';
        backgroundColor = const Color(0xff2196F3); // Blue for network issues
        errorMsg = 'Network error. Please check your internet connection and try again.';
      }

      print('Error title: $errorTitle');
      print('Error message: $errorMsg');
      print('Background color: $backgroundColor');

      // Only show snackbar for non-retryable errors
      // Retryable errors (500, 502, 503, 504) will be handled by the retry interceptor
      _showSnackbar(errorTitle, errorMsg, backgroundColor);

      print('Error creating voucher: $e');
    } finally {
      isLoading(false);
    }
  }

  /// Reset the controller state
  void resetState() {
    isLoading(false);
    voucherCreated(false);
    errorMessage.value = '';
    successMessage.value = '';
    voucherData.value = null;
  }

  /// Get current user's referral code
  String getReferralCode() {
    final user = _userController.user.value;
    return user.referralCode ?? 'HASH1234'; // Default fallback
  }

  /// Get current user's referral rewards
  int getReferralRewards() {
    final user = _userController.user.value;
    return user.referralRewards ?? 0;
  }

  /// Get current user's referral count
  int getReferralCount() {
    final user = _userController.user.value;
    return user.referralCount ?? 0;
  }

  /// Check if user has referral code
  bool hasReferralCode() {
    final user = _userController.user.value;
    return user.referralCode != null && user.referralCode!.isNotEmpty;
  }

  /// Share referral code
  void shareReferralCode() {
    final code = getReferralCode();
    // This will be handled by the view using share_plus package
    // The view can call this method and then use Share.share()
  }

  Future<List<GetVoucherModel>> getVoucher() async {
    isLoadingVouchers(true);
    try {
      final prefUser = await _remoteRepo.getUserFromPreferences();
      final userId = prefUser?['id'].toString();

      if (userId == null) {
        throw Exception('User ID not found. Please complete your profile.');
      }

      final voucherResponse = await _remoteRepo.getVoucher(userId: userId);
      
      // Update the vouchers list in the controller
      if (voucherResponse.isNotEmpty) {
        vouchers.value = voucherResponse.first.vouchers;
      } else {
        vouchers.value = [];
      }
      
      return voucherResponse;
    } catch (e) {
      print('Error fetching vouchers: $e');
      vouchers.value = [];
      rethrow;
    } finally {
      isLoadingVouchers(false);
    }
  }
}
