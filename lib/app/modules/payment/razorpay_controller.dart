import 'package:get/get.dart';
import 'package:hash/core/repositories/model/booking_model.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';

import '../arena/views/past_booking_screen.dart';
import '../home/controllers/home_controller.dart';
import '../arena/controllers/booking_controller.dart';

class RazorpayController extends GetxController {
  late Razorpay _razorpay;
  final _remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();

  RxList<int> bookingIdList = <int>[].obs;
  RxBool isPaymentInProgress = false.obs;
  RxString paymentStatus = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }

  // ─────────────────────────── Checkout ───────────────────────────
  void openCheckout({
    required String orderId,
    required String name,
    required String description,
    required double amount, // in ₹
    required String contact,
    required String email,
  }) {
    final options = {
      'key': ApiEndpoints.razorpayKeyWallet,
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'order_id': orderId,
      'prefill': {'contact': contact, 'email': email},
    };

    try {
      isPaymentInProgress(true); // ★ start spinner sooner
      paymentStatus.value = 'Opening payment gateway…';

      // Track payment initiated event
      segmentService.onPaymentInitiated(
        bookingId: orderId,
        amount: amount,
        paymentMethodSelected: 'razorpay',
      );
      fbEventsService.onPaymentInitiated(
        bookingId: orderId,
        amount: amount,
        paymentMethodSelected: 'razorpay',
      );

      _razorpay.open(options);
    } catch (e) {
      isPaymentInProgress(false);
      paymentStatus.value = '';
      Get.snackbar(
        'Checkout Error',
        'Failed to open Razorpay.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ─────────────────────────── Handlers ───────────────────────────
  void _handlePaymentSuccess(PaymentSuccessResponse r) async {
    paymentStatus.value = 'Payment successful! Confirming booking…';

    if (bookingIdList.isEmpty) {
      _reset();
      return;
    }

    // Track payment success event
    segmentService.onPaymentSuccess(
      transactionId: r.paymentId ?? '',
      bookingId: bookingIdList.first.toString(),
      paymentGateway: 'razorpay',
    );
    fbEventsService.onPaymentSuccess(
      transactionId: r.paymentId ?? '',
      bookingId: bookingIdList.first.toString(),
      paymentGateway: 'razorpay',
    );

    await _confirmBooking(
      bookingIds: bookingIdList.toList(),
      paymentId: r.paymentId!,
      paymentMode: 'gateway', // ★
    );
  }

  void _handlePaymentError(PaymentFailureResponse r) {
    // Track payment failed event
    segmentService.onPaymentFailed(
      reason: r.message ?? 'Unknown error',
      paymentGateway: 'razorpay',
    );
    fbEventsService.onPaymentFailed(
      reason: r.message ?? 'Unknown error',
      paymentGateway: 'razorpay',
    );

    _reset();
    Get.snackbar(
      'Payment Failed',
      r.message ?? 'Unknown error',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse r) {
    Get.snackbar(
      'External Wallet',
      r.walletName ?? '',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  // ───────────────────────── Confirm booking ──────────────────────
  Future<void> _confirmBooking({
    required List<int> bookingIds,
    required String paymentId,
    required String paymentMode, // ★ now required
  }) async {
    try {
      await _remoteRepo.confirmBooking(
        bookingIds: bookingIds,
        paymentId: paymentId,
        bookDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        paymentMode: paymentMode, // ★ pass it
        voucherCode: null,
      );

      // Clear selected slots after successful payment
      final bookingController = Get.find<BookingController>();
      bookingController.clearSelectedSlots();

      _reset();

      // Navigate to past bookings
      await Get.to(() => const PastBookingsScreen());

      // Then home (arena tab)
      Get.find<HomeController>().onItemTapped(1);
      Get.offAllNamed('/home');
    } catch (e) {
      // here call the release booking api
      await _remoteRepo.releaseBooking(
        bookings: BookingModel(
          slotId: bookingIds.first,
          bookingId: bookingIds.first,
          bookDate: DateTime.now().toIso8601String(),
        ),
      );
      _reset();
      Get.snackbar(
        'Error',
        'Failed to confirm booking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ───────────────────────── helper ───────────────────────────────
  void _reset() {
    isPaymentInProgress(false);
    paymentStatus.value = '';
  }
}
