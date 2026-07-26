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
import 'package:hash/core/repositories/model/purchase_pass_model.dart';
import 'package:hash/core/repositories/model/booking_model.dart';
import 'package:hash/core/repositories/model/extra_services_model.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/wallet/controllers/wallet_controller.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:intl/intl.dart';

enum PaymentType { slotBooking, passPurchase }

class RazorpayController extends GetxController {
  Razorpay? _razorpay;
  final _remoteRepo = locator<RemoteRepoInterface>();
  final segmentService = locator<SegmentSdkService>();
  final fbEventsService = locator<FbEventsService>();
  final userController = Get.find<UserController>();

  RxList<int> bookingIdList = <int>[].obs;
  RxList<int> slotIdsList = <int>[].obs; // Add this line to store slot IDs
  RxList<Map<String, dynamic>> cartItemsList =
      <Map<String, dynamic>>[].obs; // Add this line to store cart items
  RxString voucherCode = ''.obs;
  RxString bookingDate = ''.obs;
  RxBool isPaymentInProgress = false.obs;
  RxString paymentStatus = ''.obs;
  PaymentType? _currentPaymentType;
  String? _passIdForPurchase;
  double _pendingWalletContribution = 0;
  String? _pendingWalletDebitReferenceId;
  String? _pendingWalletRefundReferenceId;

  @override
  void onInit() {
    super.onInit();
    _initializeRazorpayIfNeeded();
  }

  @override
  void onClose() {
    _razorpay?.clear();
    _razorpay = null;
    super.onClose();
  }

  void _initializeRazorpayIfNeeded() {
    if (_razorpay != null) return;
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void setPassIdForPurchase(String passId) {
    final normalized = passId.trim();
    _passIdForPurchase = normalized.isEmpty ? null : normalized;
  }

  void configureWalletSplit({
    required double walletAmount,
    required String debitReferenceId,
    String? refundReferenceId,
  }) {
    final normalizedRefundReference = refundReferenceId?.trim();
    _pendingWalletContribution = walletAmount > 0 ? walletAmount : 0;
    _pendingWalletDebitReferenceId = debitReferenceId.trim().isEmpty
        ? null
        : debitReferenceId.trim();
    _pendingWalletRefundReferenceId =
        normalizedRefundReference == null || normalizedRefundReference.isEmpty
        ? null
        : normalizedRefundReference;
  }

  Future<void> refundPendingWalletContribution() async {
    if (_pendingWalletContribution <= 0) return;
    if (!Get.isRegistered<WalletController>()) {
      _clearWalletSplit();
      return;
    }

    final walletController = Get.find<WalletController>();
    final refundReferenceId =
        _pendingWalletRefundReferenceId ??
        'wallet_refund_${_pendingWalletDebitReferenceId ?? DateTime.now().millisecondsSinceEpoch}';

    final refunded = await walletController.refundBookingAmount(
      amount: _pendingWalletContribution,
      referenceId: refundReferenceId,
    );

    if (!refunded) {
      Get.snackbar(
        'Wallet refund pending',
        'We could not auto-refund your wallet contribution. Please contact support if the balance does not update shortly.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    _clearWalletSplit();
  }

  Future<void> cancelPendingBookingPayment() async {
    if (_currentPaymentType == PaymentType.slotBooking) {
      await _releasePendingBookings();
    }
    await refundPendingWalletContribution();
    _reset();
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
    _initializeRazorpayIfNeeded();
    final normalizedContact = _normalizePhone(contact);
    final normalizedEmail = email.trim();
    final prefill = <String, dynamic>{};
    if (normalizedContact.isNotEmpty) {
      prefill['contact'] = normalizedContact;
    }
    if (normalizedEmail.isNotEmpty) {
      prefill['email'] = normalizedEmail;
    }

    final options = {
      'key': ApiEndpoints.razorpayKeyWallet,
      'amount': (amount * 100).toInt(),
      'name': name,
      'description': description,
      'order_id': orderId,
      if (prefill.isNotEmpty) 'prefill': prefill,
    };

    try {
      isPaymentInProgress(true); // ★ start spinner sooner
      paymentStatus.value = 'Opening payment gateway…';
      _currentPaymentType = paymentType; // Store the payment type
      Haptics.cta();

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

      _razorpay?.open(options);
    } catch (e) {
      isPaymentInProgress(false);
      paymentStatus.value = '';
      _currentPaymentType = null;
      Get.snackbar(
        'Checkout Error',
        'Failed to open Razorpay: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _normalizePhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    return digits;
  }

  // ─────────────────────────── Handlers ───────────────────────────
  void _handlePaymentSuccess(PaymentSuccessResponse r) async {
    paymentStatus.value = 'Payment successful! Confirming booking…';
    Haptics.criticalSuccess();
    try {
      // Track hash pass purchased event
      segmentService.onHashPassPurchased(
        email:
            userController.user.value.contact?.electronicAddress?.emailId ?? '',
        // amount: amount,
      );

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
      await _remoteRepo.capturePayment(
        capturePaymentModel: capturePaymentModel,
      );

      // Handle different payment types
      if (_currentPaymentType == PaymentType.slotBooking) {
        // Call confirm booking only for slot bookings
        await _confirmBooking(
          bookingIds: bookingIdList.toList(),
          paymentId: r.paymentId!,
          paymentMode: 'gateway',
          slotIds: slotIdsList.toList(),
          voucherCode: voucherCode.value.trim().isEmpty
              ? null
              : voucherCode.value.trim(),
        );
      } else if (_currentPaymentType == PaymentType.passPurchase) {
        final user = await _remoteRepo.getUserFromPreferences();
        final passId =
            _passIdForPurchase ??
            (bookingIdList.isNotEmpty ? bookingIdList.first.toString() : null);

        if (passId == null || passId.isEmpty) {
          throw Exception('Missing pass id for purchase.');
        }

        await _remoteRepo.purchasePass(
          userId: user?['id'].toString() ?? '',
          passModel: PurchasePassModel(
            cafePassId: passId,
            paymentId: r.paymentId!,
            paymentMode: 'gateway',
          ),
        );
        paymentStatus.value =
            'Payment successful! Pass purchased successfully!';
        _reset();
        Get.snackbar(
          'Success!',
          'Pass purchased successfully!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xff00DC00),
          colorText: Colors.white,
        );
      }
    } catch (e) {
      await refundPendingWalletContribution();
      _reset();
      Haptics.error();
      Get.snackbar(
        'Payment Error',
        'Failed to complete payment: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse r) async {
    Haptics.criticalError();
    // Track payment failed event
    segmentService.onPaymentFailed(
      reason: r.message ?? 'Unknown error',
      paymentGateway: 'razorpay',
    );
    fbEventsService.onPaymentFailed(
      reason: r.message ?? 'Unknown error',
      paymentGateway: 'razorpay',
    );

    await _releasePendingBookings();
    await refundPendingWalletContribution();
    _reset();
    Get.snackbar(
      'Payment Failed',
      r.message ?? 'Unknown error',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse r) {
    Haptics.medium();
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
    String? voucherCode,
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
        bookDate: bookingDate.value.trim().isEmpty
            ? DateFormat('yyyy-MM-dd').format(DateTime.now())
            : bookingDate.value.trim(),
        paymentMode: paymentMode, // ★ pass it
        voucherCode: voucherCode,
        extraServices: extraServices.isNotEmpty ? extraServices : null,
        userPassId: userPassId,
      );

      // Clear selected slots after successful payment
      final bookingController = Get.find<BookingController>();
      bookingController.clearSelectedSlots();
      await bookingController.fetchUserBookings(forceRefresh: true);

      final confirmedBookingDate = bookingDate.value.trim().isEmpty
          ? DateFormat('yyyy-MM-dd').format(DateTime.now())
          : bookingDate.value.trim();
      _reset();

      // Navigate to past bookings
      // await Get.to(() => const PastBookingsScreen());

      // Then home (arena tab)
      // Get.find<HomeController>().onItemTapped(1);
      // Get.offAllNamed('/home');
      await Get.off(
        () => PaymentSuccessScreen(
          method: paymentMode,
          dateText: confirmedBookingDate,
          timeText: "",
          totalText: "",
          email: "",
          onViewInvoice: () {
            Get.offAllNamed('/home', arguments: {'tabIndex': 3});
          },
        ),
      );
    } catch (e) {
      await _releaseBookings(bookingIds: bookingIds, slotIds: slotIds);
      await refundPendingWalletContribution();
      _reset();
      Haptics.error();
      Get.snackbar(
        'Error',
        'Failed to confirm booking: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _releasePendingBookings() async {
    await _releaseBookings(
      bookingIds: bookingIdList.toList(),
      slotIds: slotIdsList.toList(),
    );
  }

  Future<void> _releaseBookings({
    required List<int> bookingIds,
    required List<int> slotIds,
  }) async {
    for (var index = 0; index < bookingIds.length; index++) {
      if (slotIds.isEmpty) break;
      final slotId = index < slotIds.length ? slotIds[index] : slotIds.last;
      try {
        await _remoteRepo.releaseBooking(
          bookings: BookingModel(
            slotId: slotId,
            bookingId: bookingIds[index],
            bookDate: DateTime.now().toIso8601String(),
          ),
        );
      } catch (_) {
        // The backend may already have expired/released this reservation.
      }
    }
  }

  // ───────────────────────── helper ───────────────────────────────
  void _reset() {
    isPaymentInProgress(false);
    paymentStatus.value = '';
    _currentPaymentType = null;
    _passIdForPurchase = null;
    bookingIdList.clear();
    slotIdsList.clear();
    cartItemsList.clear();
    voucherCode.value = '';
    bookingDate.value = '';
    _clearWalletSplit();
  }

  void _clearWalletSplit() {
    _pendingWalletContribution = 0;
    _pendingWalletDebitReferenceId = null;
    _pendingWalletRefundReferenceId = null;
  }
}
