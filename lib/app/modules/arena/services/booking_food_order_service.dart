import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/arena/controllers/booking_controller.dart';
import 'package:hash/app/modules/arena/views/menu_view.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/repositories/model/capture_payment_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/widgets/loader.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

enum BookingMealPaymentMode { upi, card, credit }

class BookingFoodOrderService {
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();

  Future<void> orderForActiveSession({
    required BuildContext context,
    required Map<String, dynamic> booking,
  }) async {
    final bookingId = _resolveBookingId(booking);
    final vendorId = _resolveVendorId(booking);
    if (bookingId == null || vendorId == null) {
      _showSnack(
        context,
        title: 'Order unavailable',
        message: 'Missing booking or vendor details for this session.',
        isError: true,
      );
      return;
    }

    final cartItems = await _pickMenuItems(
      vendorId: vendorId,
      continueLabel: 'Add To Session',
    );
    if (cartItems == null || cartItems.isEmpty) return;

    final meals = _buildMealsPayload(cartItems);
    final totalAmount = _cartTotal(cartItems);
    _showLoadingDialog('Adding meals to live session...');

    try {
      await _segmentService.onMealSelected(
        email: _resolveUserEmail(),
        selectedMeal: cartItems,
      );
      await _remoteRepo.addMealsToBooking(
        bookingId: bookingId,
        meals: meals,
        settleOnRelease: true,
        modeOfPayment: 'pending',
      );
      _refreshBookings();
      _hideLoadingDialog();
      if (!context.mounted) return;
      Haptics.criticalSuccess();
      _showSnack(
        context,
        title: 'Food added',
        message:
            'Order placed for Rs ${totalAmount.toStringAsFixed(0)}. It will be settled when the session ends.',
      );
      unawaited(
        _fbEventsService.logEvent('Booking Meal Added', {
          'booking_id': bookingId,
          'flow': 'live_session',
          'settle_on_release': true,
          'amount': totalAmount,
          'meal_count': meals.length,
        }),
      );
    } catch (e) {
      _hideLoadingDialog();
      if (!context.mounted) return;
      Haptics.error();
      _showSnack(
        context,
        title: 'Order failed',
        message: _errorText(e),
        isError: true,
      );
    }
  }

  Future<void> orderForUpcomingSession({
    required BuildContext context,
    required Map<String, dynamic> booking,
  }) async {
    final bookingId = _resolveBookingId(booking);
    final vendorId = _resolveVendorId(booking);
    if (bookingId == null || vendorId == null) {
      _showSnack(
        context,
        title: 'Order unavailable',
        message: 'Missing booking or vendor details for this booking.',
        isError: true,
      );
      return;
    }

    final cartItems = await _pickMenuItems(
      vendorId: vendorId,
      continueLabel: 'Review Order',
    );
    if (cartItems == null || cartItems.isEmpty) return;

    final paymentMode = await _pickImmediatePaymentMode(
      context: context,
      cartItems: cartItems,
      arenaName: _resolveArenaName(booking),
    );
    if (paymentMode == null) return;

    final meals = _buildMealsPayload(cartItems);
    final totalAmount = _cartTotal(cartItems);
    await _segmentService.onMealSelected(
      email: _resolveUserEmail(),
      selectedMeal: cartItems,
    );
    final paymentId = await _collectMealPayment(
      context: context,
      bookingId: bookingId,
      amountRupees: totalAmount,
      description: 'Food order for ${_resolveArenaName(booking)}',
    );
    if (paymentId == null) return;

    _showLoadingDialog('Confirming meal order...');
    try {
      await _remoteRepo.addMealsToBooking(
        bookingId: bookingId,
        meals: meals,
        settleOnRelease: false,
        modeOfPayment: paymentMode.apiValue,
      );
      _refreshBookings();
      _hideLoadingDialog();
      if (!context.mounted) return;
      await _segmentService.onPaymentSuccess(
        transactionId: paymentId,
        bookingId: bookingId,
        paymentGateway: 'razorpay',
      );
      await _fbEventsService.onPaymentSuccess(
        transactionId: paymentId,
        bookingId: bookingId,
        paymentGateway: 'razorpay',
      );
      Haptics.criticalSuccess();
      _showSnack(
        context,
        title: 'Food ordered',
        message:
            'Payment captured and your order for Rs ${totalAmount.toStringAsFixed(0)} has been placed.',
      );
      unawaited(
        _fbEventsService.logEvent('Booking Meal Added', {
          'booking_id': bookingId,
          'flow': 'upcoming_session',
          'settle_on_release': false,
          'mode_of_payment': paymentMode.apiValue,
          'payment_id': paymentId,
          'amount': totalAmount,
          'meal_count': meals.length,
        }),
      );
    } catch (e) {
      _hideLoadingDialog();
      if (!context.mounted) return;
      Haptics.error();
      _showSnack(
        context,
        title: 'Order failed',
        message:
            'Payment succeeded, but meal confirmation failed. Please contact support with payment id $paymentId.',
        isError: true,
      );
    }
  }

  Future<List<Map<String, dynamic>>?> _pickMenuItems({
    required String vendorId,
    required String continueLabel,
  }) {
    final email = _resolveUserEmail();
    final future = Get.to<List<Map<String, dynamic>>>(
      () => MenuViewPage(
        vendorId: vendorId,
        email: email,
        continueLabel: continueLabel,
        onContinue: (_) {},
      ),
    );
    return future ?? Future<List<Map<String, dynamic>>?>.value(null);
  }

  Future<BookingMealPaymentMode?> _pickImmediatePaymentMode({
    required BuildContext context,
    required List<Map<String, dynamic>> cartItems,
    required String arenaName,
  }) async {
    final total = _cartTotal(cartItems);
    return showModalBottomSheet<BookingMealPaymentMode>(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        BookingMealPaymentMode selected = BookingMealPaymentMode.upi;
        return StatefulBuilder(
          builder: (context, setState) {
            Widget choiceChip(
              BookingMealPaymentMode mode,
              String label,
              IconData icon,
            ) {
              final selectedMode = selected == mode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selected = mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selectedMode
                          ? const Color(0xff00DC00).withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selectedMode
                            ? const Color(0xff00DC00)
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          color: selectedMode
                              ? const Color(0xff00DC00)
                              : Colors.white70,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Pay for food now',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$arenaName • ${cartItems.length} items • Rs ${total.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        choiceChip(
                          BookingMealPaymentMode.upi,
                          'UPI',
                          Icons.account_balance_wallet_outlined,
                        ),
                        const SizedBox(width: 10),
                        choiceChip(
                          BookingMealPaymentMode.card,
                          'Card',
                          Icons.credit_card_rounded,
                        ),
                        const SizedBox(width: 10),
                        choiceChip(
                          BookingMealPaymentMode.credit,
                          'Credit',
                          Icons.receipt_long_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.of(sheetContext).pop(selected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff00DC00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Pay Rs ${total.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _collectMealPayment({
    required BuildContext context,
    required String bookingId,
    required double amountRupees,
    required String description,
  }) async {
    Razorpay? razorpay;
    if (amountRupees <= 0) {
      return 'FREE_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      final orderId = await _remoteRepo.createRazorpayOrder(
        amountInPaisa: (amountRupees * 100).round(),
        receiptPrefix: 'meal_$bookingId',
      );
      final completer = Completer<String?>();
      final userName = _resolveUserName();
      final prefill = <String, dynamic>{};
      final contact = _resolveUserPhone();
      final email = _resolveUserEmail();
      if (contact.isNotEmpty) {
        prefill['contact'] = contact;
      }
      if (email.isNotEmpty) {
        prefill['email'] = email;
      }

      razorpay = Razorpay();

      void completeOnce(String? paymentId) {
        if (!completer.isCompleted) {
          completer.complete(paymentId);
        }
      }

      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (dynamic response) async {
        final success = response as PaymentSuccessResponse;
        Haptics.criticalSuccess();
        try {
          await _remoteRepo.capturePayment(
            capturePaymentModel: CapturePaymentModel(
              razorpayPaymentId: success.paymentId,
              razorpayOrderId: success.orderId,
              razorpaySignature: success.signature,
            ),
          );
        } catch (_) {}
        completeOnce(success.paymentId ?? success.orderId);
      });

      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (dynamic response) {
        final error = response as PaymentFailureResponse;
        Haptics.criticalError();
        _showSnack(
          context,
          title: 'Payment failed',
          message: error.message ?? 'Payment cancelled.',
          isError: true,
        );
        completeOnce(null);
      });

      razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (dynamic response) {
        final wallet =
            (response as ExternalWalletResponse).walletName ?? 'Wallet';
        _showSnack(
          context,
          title: 'External wallet',
          message: '$wallet selected. Complete payment to continue.',
        );
      });

      await _segmentService.onPaymentInitiated(
        bookingId: bookingId,
        amount: amountRupees,
        paymentMethodSelected: 'razorpay',
      );
      await _fbEventsService.onPaymentInitiated(
        bookingId: bookingId,
        amount: amountRupees,
        paymentMethodSelected: 'razorpay',
      );

      razorpay.open({
        'key': ApiEndpoints.razorpayKeyWallet,
        'amount': (amountRupees * 100).round(),
        'name': userName,
        'description': description,
        'order_id': orderId,
        if (prefill.isNotEmpty) 'prefill': prefill,
      });
      Haptics.cta();
      return completer.future.timeout(
        const Duration(minutes: 4),
        onTimeout: () => null,
      );
    } catch (e) {
      _showSnack(
        context,
        title: 'Payment setup failed',
        message: _errorText(e),
        isError: true,
      );
      return null;
    } finally {
      try {
        razorpay?.clear();
      } catch (_) {}
    }
  }

  List<Map<String, dynamic>> _buildMealsPayload(
    List<Map<String, dynamic>> cartItems,
  ) {
    return cartItems
        .map(
          (item) => {'menu_item_id': item['id'], 'quantity': item['qty'] ?? 1},
        )
        .where(
          (item) =>
              item['menu_item_id'] != null &&
              item['quantity'] is int &&
              (item['quantity'] as int) > 0,
        )
        .toList();
  }

  double _cartTotal(List<Map<String, dynamic>> cartItems) {
    return cartItems.fold<double>(0, (total, item) {
      final price = (item['price'] is num)
          ? (item['price'] as num).toDouble()
          : double.tryParse('${item['price']}') ?? 0;
      final qty = (item['qty'] is int)
          ? item['qty'] as int
          : int.tryParse('${item['qty']}') ?? 1;
      return total + (price * qty);
    });
  }

  String? _resolveBookingId(Map<String, dynamic> booking) {
    final value = booking['booking_id'] ?? booking['id'];
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  String? _resolveVendorId(Map<String, dynamic> booking) {
    final slot = _asMap(booking['slot']);
    final gamingType = _asMap(slot['gaming_type_id']);
    final cafe = _asMap(gamingType['cafe_name']);
    final candidates = [
      booking['vendor_id'],
      booking['vendorId'],
      booking['cafe_id'],
      slot['vendor_id'],
      slot['vendorId'],
      slot['cafe_id'],
      gamingType['vendor_id'],
      gamingType['vendorId'],
      gamingType['cafe_id'],
      cafe['vendor_id'],
      cafe['vendorId'],
      cafe['id'],
    ];

    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return null;
  }

  String _resolveArenaName(Map<String, dynamic> booking) {
    final slot = _asMap(booking['slot']);
    final gamingType = _asMap(slot['gaming_type_id']);
    final cafe = _asMap(gamingType['cafe_name']);
    final candidates = [
      cafe['cafe_name'],
      slot['cafe_name'],
      gamingType['cafe'],
      booking['cafe_name'],
    ];
    for (final candidate in candidates) {
      final text = candidate?.toString().trim() ?? '';
      if (text.isNotEmpty) {
        return text;
      }
    }
    return 'Arena Session';
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _resolveUserEmail() {
    if (!Get.isRegistered<UserController>()) return '';
    return Get.find<UserController>()
            .user
            .value
            .contact
            ?.electronicAddress
            ?.emailId
            ?.trim() ??
        '';
  }

  String _resolveUserPhone() {
    if (!Get.isRegistered<UserController>()) return '';
    return Get.find<UserController>()
            .user
            .value
            .contact
            ?.electronicAddress
            ?.mobileNo
            ?.replaceAll(RegExp(r'[^0-9+]'), '')
            .trim() ??
        '';
  }

  String _resolveUserName() {
    if (!Get.isRegistered<UserController>()) return 'HashForGamers';
    final name = Get.find<UserController>().user.value.name?.trim() ?? '';
    return name.isEmpty ? 'HashForGamers' : name;
  }

  void _showLoadingDialog(String message) {
    Get.dialog<void>(
      PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: const Color(0xFF111111),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLinearLoader.screen(),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _hideLoadingDialog() {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _showSnack(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = false,
  }) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.redAccent : const Color(0xff00DC00),
        content: Text('$title\n$message'),
      ),
    );
  }

  String _errorText(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  void _refreshBookings() {
    if (Get.isRegistered<BookingController>()) {
      unawaited(Get.find<BookingController>().fetchUserBookings());
    }
  }
}

extension on BookingMealPaymentMode {
  String get apiValue {
    switch (this) {
      case BookingMealPaymentMode.upi:
        return 'upi';
      case BookingMealPaymentMode.card:
        return 'card';
      case BookingMealPaymentMode.credit:
        return 'credit';
    }
  }
}
