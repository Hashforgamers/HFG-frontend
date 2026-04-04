import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/model/capture_payment_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/service/segment_sdk_service.dart';
import '../../../../core/service_locator.dart';
import '../../../../core/utils/haptics.dart';
import '../../../data/services/user_controller.dart';
import 'wallet_controller.dart';

class RazorpayWalletController extends GetxController {
  late Razorpay _razorpay;
  final isPaying = false.obs;
  final RxString lastPaymentError = ''.obs;
  int? _tempAmount;
  Completer<bool>? _paymentCompleter;
  final segmentService = locator<SegmentSdkService>();
  final userController = Get.find<UserController>();
  final remoteRepo = locator<RemoteRepoInterface>();

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // 🔍 Optional: Set log level for debugging (only in dev builds)
    // _razorpay.setLogLevel(Razorpay.Loglevel.verbose); // Uncomment if needed
  }

  /// Opens the Razorpay checkout with provided amount
  void openCheckout(int amountRupees, String orderId) {
    if (isPaying.value) return;

    final amountPaise = amountRupees * 100;

    // Get dynamic user data
    final userName = userController.user.value.name ?? 'User';
    final userEmail =
        userController.user.value.contact?.electronicAddress?.emailId ?? '';
    final userPhone =
        userController.user.value.contact?.electronicAddress?.mobileNo ?? '';
    final normalizedPhone = userPhone.replaceAll(RegExp(r'[^0-9+]'), '').trim();
    final normalizedEmail = userEmail.trim();
    final prefill = <String, dynamic>{};
    if (normalizedPhone.isNotEmpty) {
      prefill['contact'] = normalizedPhone;
    }
    if (normalizedEmail.isNotEmpty) {
      prefill['email'] = normalizedEmail;
    }

    final options = {
      'key': ApiEndpoints.razorpayKeyWallet,
      'amount': amountPaise,
      'name': userName,
      'description': 'Wallet Top-up',
      if (prefill.isNotEmpty) 'prefill': prefill,
      'theme': {'color': '#1E88E5'},
      'order_id': orderId,
    };

    try {
      _razorpay.open(options);
      isPaying.value = true;
      Haptics.cta();
    } catch (e) {
      lastPaymentError.value = e.toString();
      _completePayment(false);
      Haptics.error();
      _showSnackbarSafely("Error", e.toString());
      isPaying.value = false;
    }
  }

  /// Safe method to start payment with stored amount
  Future<bool> pay(int amount) async {
    if (isPaying.value) {
      return _paymentCompleter?.future ?? Future.value(false);
    }

    lastPaymentError.value = '';
    _tempAmount = amount;
    // Track add money initiated event
    segmentService.onAddMoneyInitiated(amountEntered: amount.toDouble());
    String receiptId = "wallet_rcpt_${DateTime.now().millisecondsSinceEpoch}";
    final url = '${FlavorConfig.getBaseUrl('booking')}/api/create_order';
    final payload = {
      "amount": amount * 100,
      "currency": "INR",
      "receipt": receiptId,
    };

    try {
      final dio = locator<NetworkProvider>().noAuth();
      final response = await dio.post(url, data: payload);

      if (response.statusCode == 200) {
        final data = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        _paymentCompleter = Completer<bool>();
        openCheckout(amount, data['id']);
        return _paymentCompleter!.future;
      }

      lastPaymentError.value = 'Failed to create payment order';
      _showSnackbarSafely("Error", "Failed to create payment order");
      return false;
    } catch (e) {
      lastPaymentError.value = e.toString();
      _showSnackbarSafely("Error", "Failed to create payment order");
      return false;
    }
  }

  /// Called when payment is successful
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? 'Unknown';
    Haptics.criticalSuccess();

    // Track add money success event
    segmentService.onAddMoneySuccess(
      amountAdded: _tempAmount?.toDouble() ?? 0.0,
      txnId: paymentId,
    );
    final capturePaymentModel = CapturePaymentModel(
      razorpayPaymentId: paymentId,
      razorpayOrderId: response.orderId,
      razorpaySignature: response.signature,
    );
    remoteRepo.capturePayment(capturePaymentModel: capturePaymentModel);
    final success = await Get.find<WalletController>().confirmTopUp(
      amount: (_tempAmount ?? 0).toDouble(),
      paymentId: paymentId,
    );

    if (!success) {
      lastPaymentError.value =
          Get.find<WalletController>().errorMessage.isNotEmpty
          ? Get.find<WalletController>().errorMessage
          : "Failed to credit wallet. Please contact support.";
      Haptics.error();
    }

    isPaying.value = false;
    _completePayment(success);

    if (!success) {
      _showSnackbarSafely(
        "Error",
        "Failed to credit wallet. Please contact support.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Called when payment fails
  void _handlePaymentError(PaymentFailureResponse response) {
    lastPaymentError.value = response.message ?? "Try again later";
    Haptics.criticalError();
    isPaying.value = false;
    _completePayment(false);
    _showSnackbarSafely(
      "Payment Failed",
      response.message ?? "Try again later",
    );
  }

  /// Called when user selects external wallet like Paytm
  void _handleExternalWallet(ExternalWalletResponse response) {
    Haptics.warning();
    _showSnackbarSafely("Wallet", response.walletName ?? "External Wallet");
    isPaying.value = false;
  }

  void _showSnackbarSafely(
    String title,
    String message, {
    Color? backgroundColor,
    Color? colorText,
  }) {
    void show() {
      try {
        Get.snackbar(
          title,
          message,
          backgroundColor: backgroundColor,
          colorText: colorText,
        );
      } catch (e) {
        debugPrint(
          'Wallet snackbar skipped -> title=$title, message=$message, error=$e',
        );
      }
    }

    if (Get.overlayContext != null) {
      show();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.overlayContext != null) {
        show();
        return;
      }
      debugPrint(
        'Wallet snackbar skipped -> title=$title, message=$message, overlay unavailable',
      );
    });
  }

  void _completePayment(bool success) {
    final completer = _paymentCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(success);
    }
    _paymentCompleter = null;
  }

  @override
  void onClose() {
    _completePayment(false);
    _razorpay.clear();
    super.onClose();
  }
}
