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
  int? _tempAmount;
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
      Haptics.error();
      Get.snackbar("Error", e.toString());
      isPaying.value = false;
    }
  }

  /// Safe method to start payment with stored amount
  void pay(int amount) async {
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

    final dio = locator<NetworkProvider>().noAuth();
    final response = await dio.post(url, data: payload);

    if (response.statusCode == 200) {
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      openCheckout(amount, data['id']);
      return;
    }

    Get.snackbar("Error", "Failed to create payment order");
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
      Haptics.error();
      Get.snackbar(
        "Error",
        "Failed to credit wallet. Please contact support.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    isPaying.value = false;
  }

  /// Called when payment fails
  void _handlePaymentError(PaymentFailureResponse response) {
    Haptics.criticalError();
    Get.snackbar("Payment Failed", response.message ?? "Try again later");
    isPaying.value = false;
  }

  /// Called when user selects external wallet like Paytm
  void _handleExternalWallet(ExternalWalletResponse response) {
    Haptics.warning();
    Get.snackbar("Wallet", response.walletName ?? "External Wallet");
    isPaying.value = false;
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
