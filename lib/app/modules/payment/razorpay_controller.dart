import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';

import '../arena/views/past_booking_screen.dart';

class RazorpayController extends GetxController {
  late Razorpay _razorpay;
  final _remoteRepo = locator<RemoteRepoInterface>();

  // Store multiple booking IDs after booking API response
  RxList<int> bookingIdList = <int>[].obs;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  /// Open Razorpay Checkout
  void openCheckout({
    required String orderId,
    required String name,
    required String description,
    required double amount, // in rupees
    required String contact,
    required String email,
  }) {
    var options = {
      'key': ApiEndpoints.razorpayKey,
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {
        'contact': contact,
        'email': email,
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print('Error while opening Razorpay Checkout: $e');
      Get.snackbar(
        'Checkout Error',
        'Failed to open Razorpay Checkout.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Handle Successful Payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("✅ Payment successful: ${response.paymentId}");

    if (bookingIdList.isEmpty) {
      print("⚠️ No booking IDs to confirm.");
      return;
    }

    await confirmBooking(
      bookingIds: bookingIdList.toList(),
      paymentId: response.paymentId!,
    );
  }

  /// Handle Payment Error
  void _handlePaymentError(PaymentFailureResponse response) {
    print('❌ Payment failed: ${response.code} - ${response.message}');
    Get.snackbar(
      'Payment Failed',
      'Error: ${response.message}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Handle External Wallet Selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    print('📦 External wallet selected: ${response.walletName}');
    Get.snackbar(
      'External Wallet',
      'Wallet: ${response.walletName}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Confirm Booking with Backend
  Future<void> confirmBooking({
    required List<int> bookingIds,
    required String paymentId,
  }) async {
    try {
      await _remoteRepo.confirmBooking(
        bookingIds: bookingIds,
        paymentId: paymentId,
        bookDate: DateTime.now().toIso8601String(),
      );
      print('✅ Booking confirmation successful!');
      Get.to(() => PastBookingsScreen());
    } catch (e) {
      print('🔥 Error confirming booking: $e');
      Get.snackbar(
        'Error',
        'Failed to confirm booking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
