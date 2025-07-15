import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/service/segment_sdk_service.dart';
import '../../../../core/service_locator.dart';
import 'wallet_controller.dart';

class RazorpayWalletController extends GetxController {
  late Razorpay _razorpay;
  final isPaying = false.obs;
  int? _tempAmount;
  final segmentService = locator<SegmentSdkService>();

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    // 🔍 Optional: Set log level for debugging (only in dev builds)
    // _razorpay.setLogLevel(Razorpay.Loglevel.verbose); // Uncomment if needed
    print("[Razorpay] Initialized");
  }

  /// Opens the Razorpay checkout with provided amount
  void openCheckout(int amountRupees) {
    if (isPaying.value) return;

    if (ApiEndpoints.razorpayKey.isEmpty) {
      Get.snackbar("Error", "Razorpay key is missing");
      print("[Razorpay] Missing Razorpay Key");
      return;
    }

    final amountPaise = amountRupees * 100;
    final options = {
      'key': ApiEndpoints.razorpayKey,
      'amount': amountPaise,
      'name': 'HashforGamers',
      'description': 'Wallet Top-up',
      'prefill': {
        'contact': '9137757935', // Optional: populate if available
        'email': 'zeyanansari10@gmail.com'
      },
      'theme': {'color': '#1E88E5'},
    };

    try {
      print("[Razorpay] Opening checkout with options: $options");
      _razorpay.open(options);
      isPaying.value = true;
    } catch (e) {
      print("[Razorpay] Error during openCheckout: $e");
      Get.snackbar("Error", e.toString());
      isPaying.value = false;
    }
  }

  /// Safe method to start payment with stored amount
  void pay(int amount) {
    _tempAmount = amount;
    print("[Razorpay] Starting payment for ₹$amount");
    
    // Track add money initiated event
    segmentService.onAddMoneyInitiated(amountEntered: amount.toDouble());
    
    openCheckout(amount);
  }

  /// Called when payment is successful
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId ?? 'Unknown';
    print("[Razorpay] ✅ Payment Success: $paymentId");

    // Track add money success event
    segmentService.onAddMoneySuccess(
      amountAdded: _tempAmount?.toDouble() ?? 0.0,
      txnId: paymentId,
    );

    Get.find<WalletController>().confirmTopUp(
      amount: _tempAmount ?? 0,
      paymentId: paymentId,
    );

    isPaying.value = false;
  }

  /// Called when payment fails
  void _handlePaymentError(PaymentFailureResponse response) {
    print(
        "[Razorpay] ❌ Payment Failed → Code: ${response.code}, Message: ${response.message}");
    Get.snackbar("Payment Failed", response.message ?? "Try again later");
    isPaying.value = false;
  }

  /// Called when user selects external wallet like Paytm
  void _handleExternalWallet(ExternalWalletResponse response) {
    print("[Razorpay] 👜 External Wallet Selected: ${response.walletName}");
    Get.snackbar("Wallet", response.walletName ?? "External Wallet");
    isPaying.value = false;
  }

  @override
  void onClose() {
    print("[Razorpay] Disposing & clearing event listeners");
    _razorpay.clear();
    super.onClose();
  }
}
