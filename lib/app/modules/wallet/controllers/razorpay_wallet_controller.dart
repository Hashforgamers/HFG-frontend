import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/service/segment_sdk_service.dart';
import '../../../../core/service_locator.dart';
import '../../../data/services/user_controller.dart';
import 'wallet_controller.dart';

class RazorpayWalletController extends GetxController {
  late Razorpay _razorpay;
  final isPaying = false.obs;
  int? _tempAmount;
  final segmentService = locator<SegmentSdkService>();
  final userController = Get.find<UserController>();

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
  void openCheckout(int amountRupees) {
    if (isPaying.value) return;

    final amountPaise = amountRupees * 100;
    
    // Get dynamic user data
    final userName = userController.user.value.name ?? 'User';
    final userEmail = userController.user.value.contact?.electronicAddress?.emailId ?? '';
    final userPhone = userController.user.value.contact?.electronicAddress?.mobileNo ?? '';
    
    final options = {
      'key': ApiEndpoints.razorpayKeyWallet,
      'amount': amountPaise,
      'name': userName,
      'description': 'Wallet Top-up',
      'prefill': {
        'contact': userPhone.isNotEmpty ? userPhone : null,
        'email': userEmail.isNotEmpty ? userEmail : null,
      },
      'theme': {'color': '#1E88E5'},
    };

    try {
      _razorpay.open(options);
      isPaying.value = true;
    } catch (e) {
      Get.snackbar("Error", e.toString());
      isPaying.value = false;
    }
  }

  /// Safe method to start payment with stored amount
  void pay(int amount) {
    _tempAmount = amount;

    // Track add money initiated event
    segmentService.onAddMoneyInitiated(amountEntered: amount.toDouble());

    openCheckout(amount);
  }

  /// Called when payment is successful
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final paymentId = response.paymentId ?? 'Unknown';

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
    Get.snackbar("Payment Failed", response.message ?? "Try again later");
    isPaying.value = false;
  }

  /// Called when user selects external wallet like Paytm
  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar("Wallet", response.walletName ?? "External Wallet");
    isPaying.value = false;
  }

  @override
  void onClose() {
    _razorpay.clear();
    super.onClose();
  }
}
