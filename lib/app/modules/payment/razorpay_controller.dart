import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../arena/views/past_booking_screen.dart';

class RazorpayController extends GetxController {
  late Razorpay _razorpay;
  RxInt bookingId = (-1).obs; // Default to -1 to indicate no booking ID

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
    required double amount, // Pass amount in rupees
    required String contact,
    required String email,
  }) {
    var options = {
      'key': 'rzp_test_viVAhwtbVdu1X4', // Replace with your Razorpay API key
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': name,
      'description': description,
      'order_id': orderId, // Order ID from your backend
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
        'Failed to open Razorpay Checkout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Handle Successful Payment
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {


    // Get.snackbar(
    //   'Payment Successful',
    //   'Payment ID: ${response.paymentId}',
    //   snackPosition: SnackPosition.BOTTOM,
    // );

    // Confirm the booking with the stored bookingId
    await confirmBooking(
      bookingId: bookingId.value, // Use the stored bookingId
      paymentId: '1234', // Use the actual Razorpay payment ID
    );
    print(bookingId.value);
    print(bookingId.value);
  }

  /// Handle Payment Error
  void _handlePaymentError(PaymentFailureResponse response) {
    Get.snackbar(
      'Payment Failed',
      'Error: ${response.message}',
      snackPosition: SnackPosition.BOTTOM,
    );
    print('Payment failed: ${response.code} - ${response.message}');
  }

  /// Handle External Wallet Selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      'External Wallet',
      'Wallet Name: ${response.walletName}',
      snackPosition: SnackPosition.BOTTOM,
    );
    print('External wallet selected: ${response.walletName}');
  }

  /// Confirm Booking
  Future<void> confirmBooking({
    required int bookingId,
    required String paymentId,
  }) async {
    const String url = 'https://hfg-booking-service.onrender.com/api/bookings/confirm';
    print('Confirming booking with ID: $bookingId');

    final Map<String, dynamic> body = {
      "booking_id": bookingId,
      "payment_id": '1234',
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      print('Booking confirmation : ${response.body}');

      if (response.statusCode == 200) {
        print('Booking confirmation successful: ${response.body}');
        Get.to(PastBookingsScreen());


      } else {
        print('Failed to confirm booking: ${response.statusCode}, ${response.body}');

      }
    } catch (e) {
      print('Error occurred while confirming booking: $e');

    }
  }
}
