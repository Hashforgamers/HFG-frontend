import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/arena/views/payment_success.dart';
import 'package:hash/core/repositories/model/capture_payment_model.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/home/controllers/home_controller.dart';
import 'package:hash/app/modules/arena/views/past_booking_screen.dart';
import 'package:hash/core/repositories/model/purchase_pass_model.dart';
import 'package:hash/core/repositories/model/booking_model.dart';
import 'package:hash/core/repositories/model/extra_services_model.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:intl/intl.dart';

enum PaymentType { slotBooking, passPurchase }

class RazorpayController extends GetxController {
  late Razorpay _razorpay;
  final _remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final userController = Get.find<UserController>();

  RxList<int> bookingIdList = <int>[].obs;
  RxList<int> slotIdsList = <int>[].obs; // Add this line to store slot IDs
  RxList<Map<String, dynamic>> cartItemsList =
      <Map<String, dynamic>>[].obs; // Add this line to store cart items
  RxBool isPaymentInProgress = false.obs;
  RxString paymentStatus = ''.obs;
  PaymentType? _currentPaymentType;

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
    PaymentType paymentType =
        PaymentType.slotBooking, // Default to slot booking
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
      _currentPaymentType = paymentType; // Store the payment type

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
      _currentPaymentType = null;
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

    // capture payment
    final capturePaymentModel = CapturePaymentModel(
      razorpayPaymentId: r.paymentId,
      razorpayOrderId: r.orderId,
      razorpaySignature: r.signature,
    );
    await _remoteRepo.capturePayment(capturePaymentModel: capturePaymentModel);

    // Handle different payment types
    if (_currentPaymentType == PaymentType.slotBooking) {
      // Call confirm booking only for slot bookings
      await _confirmBooking(
        bookingIds: bookingIdList.toList(),
        paymentId: r.paymentId!,
        paymentMode: 'gateway',
        slotIds: slotIdsList.toList(),
      );
    } else if (_currentPaymentType == PaymentType.passPurchase) {
      final user = await _remoteRepo.getUserFromPreferences();

      await _remoteRepo.purchasePass(
        userId: user?['id'].toString() ?? '',
        passModel: PurchasePassModel(
          cafePassId: bookingIdList.first.toString(),
          paymentId: r.paymentId!,
          paymentMode: 'gateway',
        ),
      );
      paymentStatus.value = 'Payment successful! Pass purchased successfully!';
      _reset();
      Get.snackbar(
        'Success!',
        'Pass purchased successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
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
    required String paymentMode,
    required List<int> slotIds,
    String? userPassId,
  }) async {
    try {
      // Parse cart items to ExtraServiceItem format
      List<ExtraServiceItem> extraServices = [];
      if (cartItemsList.isNotEmpty) {
        extraServices = cartItemsList.map((item) {
          return ExtraServiceItem(
            categoryId: (item['category_id'] ?? 0) as int,
            itemId: (item['id'] ?? 0) as int,
            quantity: (item['qty'] ?? 1) as int,
          );
        }).toList();
      }

      await _remoteRepo.confirmBooking(
        bookingIds: bookingIds,
        paymentId: paymentId,
        bookDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        paymentMode: paymentMode, // ★ pass it
        voucherCode: null,
        extraServices: extraServices.isNotEmpty ? extraServices : null,
        userPassId: userPassId,
      );

      // Clear selected slots after successful payment
      final bookingController = Get.find<BookingController>();
      bookingController.clearSelectedSlots();

      _reset();

      // Navigate to past bookings
      // await Get.to(() => const PastBookingsScreen());

      // Then home (arena tab)
      // Get.find<HomeController>().onItemTapped(1);
      // Get.offAllNamed('/home');
      await Get.to(
          () => PaymentSuccessScreen(
            method: paymentMode,
            dateText: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            timeText: "",
            totalText: "",
            email: "",
            onViewInvoice: () {
              Get.to(const PastBookingsScreen());
              final homeController = Get.find<HomeController>();
              homeController.onItemTapped(2);
              Get.offAllNamed('/home', arguments: {'tabIndex':2});
            },
          )
      );
    } catch (e) {
      // here call the release booking api
      await _remoteRepo.releaseBooking(
        bookings: BookingModel(
          slotId: slotIds.first,
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
    _currentPaymentType = null;
    bookingIdList.clear();
    slotIdsList.clear();
    cartItemsList.clear();
  }
}
