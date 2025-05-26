import 'dart:convert';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;

import '../arena/views/past_booking_screen.dart';

class RazorpayController extends GetxController {
  late Razorpay _razorpay;

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
      'key': 'rzp_test_viVAhwtbVdu1X4',
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
    const String url = 'https://hfg-booking-hmnx.onrender.com/api/bookings/confirm';

    final body = {
      "booking_id": bookingIds,
      "payment_id": paymentId,
      "book_date":"2025-05-20"
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('✅ Booking confirmation successful!');
        Get.to(() => PastBookingsScreen());
      } else {
        print('❌ Booking confirmation failed: ${response.body}');
      }
    } catch (e) {
      print('🔥 Error confirming booking: $e');
    }
  }
}
