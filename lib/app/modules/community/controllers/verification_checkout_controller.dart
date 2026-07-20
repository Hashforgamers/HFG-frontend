import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/repositories/model/capture_payment_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_routes.dart';
import '../models/host_program.dart';
import '../services/community_api.dart';

/// Backs the "Official Host Verification" checkout screen.
/// The program (fee) is passed via Get.arguments from onboarding, or fetched.
class VerificationCheckoutController extends GetxController {
  static const pendingPaymentPreferenceKey =
      'community_host_verification_payment_reference';
  final CommunityApi _api = CommunityApi();
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  Razorpay? _razorpay;
  String? _activeOrderId;

  final Rxn<HostProgram> program = Rxn<HostProgram>();
  final RxBool loading = false.obs;
  final RxBool processing = false.obs;

  @override
  void onInit() {
    super.onInit();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    final arg = Get.arguments;
    if (arg is HostProgram) {
      program.value = arg;
    } else {
      _fetch();
    }
  }

  Future<void> _fetch() async {
    loading.value = true;
    try {
      program.value = await _api.getHostProgram();
    } catch (_) {
      // leave null; view shows a graceful fallback
    }
    loading.value = false;
  }

  String get amountText {
    final fee = program.value?.verificationFee;
    if (fee == null) return '';
    final a = fee.amount;
    final s = a == a.roundToDouble()
        ? a.toStringAsFixed(0)
        : a.toStringAsFixed(2);
    return '₹$s';
  }

  Future<void> pay() async {
    if (processing.value) return;
    final fee = program.value?.verificationFee;
    if (fee == null) {
      Get.snackbar('Unable to continue', 'Verification fee is unavailable.');
      return;
    }

    processing.value = true;
    try {
      final existingReference = await _pendingPaymentReference();
      if (existingReference != null) {
        processing.value = false;
        _continueToVerification(existingReference);
        return;
      }

      if (fee.amount <= 0) {
        final reference = 'FREE_${DateTime.now().millisecondsSinceEpoch}';
        await _savePendingPayment(reference);
        processing.value = false;
        _continueToVerification(reference);
        return;
      }

      final amountInPaisa = (fee.amount * 100).round();
      if (amountInPaisa <= 0) {
        throw Exception('Invalid verification fee.');
      }
      _activeOrderId = await _remoteRepo.createRazorpayOrder(
        amountInPaisa: amountInPaisa,
        receiptPrefix: 'host_verification',
      );
      final user = Get.isRegistered<UserController>()
          ? Get.find<UserController>().user.value
          : null;
      final phone = (user?.contact?.electronicAddress?.mobileNo ?? '')
          .replaceAll(RegExp(r'[^0-9+]'), '');
      final email = (user?.contact?.electronicAddress?.emailId ?? '').trim();
      final name = (user?.name ?? '').trim();
      final prefill = <String, dynamic>{
        if (phone.isNotEmpty) 'contact': phone,
        if (email.isNotEmpty) 'email': email,
      };

      _razorpay?.open({
        'key': ApiEndpoints.razorpayKeyWallet,
        'amount': amountInPaisa,
        'currency': fee.currency,
        'name': name.isEmpty ? 'HashForGamers' : name,
        'description': 'Official Host Verification',
        'order_id': _activeOrderId,
        if (prefill.isNotEmpty) 'prefill': prefill,
        'theme': {'color': '#00DC00'},
        'retry': {'enabled': true, 'max_count': 2},
      });
      Haptics.cta();
    } catch (e, st) {
      processing.value = false;
      _activeOrderId = null;
      AppLogger.e(
        'Host verification checkout failed',
        error: e,
        stackTrace: st,
      );
      Get.snackbar(
        'Payment unavailable',
        'Could not start the payment. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final paymentId = response.paymentId?.trim() ?? '';
      final orderId = response.orderId?.trim() ?? _activeOrderId ?? '';
      final signature = response.signature?.trim() ?? '';
      if (paymentId.isEmpty || orderId.isEmpty || signature.isEmpty) {
        throw Exception('Incomplete Razorpay success response.');
      }
      await _remoteRepo.capturePayment(
        capturePaymentModel: CapturePaymentModel(
          razorpayPaymentId: paymentId,
          razorpayOrderId: orderId,
          razorpaySignature: signature,
        ),
      );
      await _savePendingPayment(paymentId);
      processing.value = false;
      _activeOrderId = null;
      Haptics.criticalSuccess();
      _continueToVerification(paymentId);
    } catch (e, st) {
      processing.value = false;
      AppLogger.e(
        'Host verification payment confirmation failed',
        error: e,
        stackTrace: st,
      );
      Get.snackbar(
        'Payment confirmation pending',
        'Payment was received but could not be confirmed. Please contact support before paying again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    processing.value = false;
    _activeOrderId = null;
    Haptics.criticalError();
    Get.snackbar(
      'Payment failed',
      response.message?.trim().isNotEmpty == true
          ? response.message!
          : 'Payment was cancelled or could not be completed.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Get.snackbar(
      'External wallet selected',
      'Complete the payment in ${response.walletName ?? 'your wallet'}.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<String?> _pendingPaymentReference() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(pendingPaymentPreferenceKey)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _savePendingPayment(String reference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(pendingPaymentPreferenceKey, reference);
  }

  void _continueToVerification(String paymentReference) {
    Get.offNamed(
      AppRoutes.HOST_VERIFICATION,
      arguments: {'payment_reference': paymentReference},
    );
  }

  @override
  void onClose() {
    _razorpay?.clear();
    _razorpay = null;
    super.onClose();
  }
}
