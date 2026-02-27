import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/game_pass/model/get_vendor_passes_model.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/repositories/model/capture_payment_model.dart';
import 'package:hash/core/repositories/model/purchase_pass_model.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'dart:convert';

class VendorPassesWidget extends StatefulWidget {
  final List<GetVendorPassesModel> vendorPasses;
  const VendorPassesWidget({super.key, required this.vendorPasses});

  @override
  State<VendorPassesWidget> createState() => _VendorPassesWidgetState();
}

class _VendorPassesWidgetState extends State<VendorPassesWidget> {
  final RemoteRepoInterface _remoteRepo = locator<RemoteRepoInterface>();
  final NetworkProvider _networkProvider = locator<NetworkProvider>();
  final UserController _userController = Get.find<UserController>();
  late final Razorpay _razorpay;
  String? _activePassId;
  bool _isPaying = false;
  String? _lastOrderId;
  String? _lastPassId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _buyPass(GetVendorPassesModel pass) async {
    if (_isPaying) return;
    final passId = (pass.id ?? '').trim();
    final amount = pass.price ?? 0;
    if (passId.isEmpty || amount <= 0) {
      _showError(context, 'Invalid pass data.');
      return;
    }

    setState(() {
      _isPaying = true;
      _activePassId = passId;
      _lastPassId = passId;
    });
    await Haptics.cta();

    try {
      final orderId = await _createOrder((amount * 100).toInt());
      _lastOrderId = orderId;
      _razorpay.open({
        'key': ApiEndpoints.razorpayKeyWallet,
        'amount': (amount * 100).toInt(),
        'name': _userController.user.value.name?.trim().isNotEmpty == true
            ? _userController.user.value.name
            : 'HashForGamers',
        'description': 'Purchase Pass - ${pass.name ?? 'Game Pass'}',
        'order_id': orderId,
        'prefill': {
          'contact':
              _userController.user.value.contact?.electronicAddress?.mobileNo ??
              '',
          'email':
              _userController.user.value.contact?.electronicAddress?.emailId ??
              '',
        },
      });
    } catch (e) {
      _endPayment();
      _showError(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String> _createOrder(int amountInPaisa) async {
    final url = '${FlavorConfig.getBaseUrl('booking')}/api/create_order';
    final payload = {
      'amount': amountInPaisa,
      'currency': 'INR',
      'receipt': 'vendor_pass_${DateTime.now().millisecondsSinceEpoch}',
    };
    final dio = _networkProvider.noAuth();
    final response = await dio.post(url, data: payload);
    if (response.statusCode == 200) {
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final orderId = (data['id'] ?? '').toString();
      if (orderId.isNotEmpty) return orderId;
    }
    throw Exception('Failed to create payment order.');
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await Haptics.criticalSuccess();
      await _remoteRepo.capturePayment(
        capturePaymentModel: CapturePaymentModel(
          razorpayPaymentId: response.paymentId,
          razorpayOrderId: response.orderId ?? _lastOrderId,
          razorpaySignature: response.signature,
        ),
      );

      final passId = (_lastPassId ?? '').trim();
      if (passId.isEmpty) {
        throw Exception('Missing pass id for purchase.');
      }

      await _remoteRepo.purchasePass(
        userId: _userController.userId,
        passModel: PurchasePassModel(
          cafePassId: passId,
          paymentId: response.paymentId ?? 'PAY_${DateTime.now().millisecondsSinceEpoch}',
          paymentMode: 'gateway',
        ),
      );

      if (!mounted) return;
      Get.snackbar(
        'Success',
        'Pass purchased successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xff00DC00),
        colorText: Colors.white,
      );
    } catch (e) {
      _showError(Get.context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      _endPayment();
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    Haptics.criticalError();
    _endPayment();
    _showError(Get.context, response.message ?? 'Payment failed.');
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    Haptics.warning();
    Get.snackbar(
      'Wallet',
      response.walletName ?? 'External wallet',
      snackPosition: SnackPosition.BOTTOM,
      colorText: Colors.white,
    );
  }

  void _endPayment() {
    if (!mounted) return;
    setState(() {
      _isPaying = false;
      _activePassId = null;
    });
  }

  void _showError(BuildContext? context, String message) {
    final safeMessage = message.isEmpty ? 'Something went wrong.' : message;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(safeMessage), backgroundColor: Colors.redAccent),
      );
      return;
    }
    if (!mounted) return;
    Get.snackbar(
      'Error',
      safeMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: widget.vendorPasses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, index) {
        final pass = widget.vendorPasses[index];
        final passId = (pass.id ?? '').trim();
        final isProcessing = _isPaying && _activePassId == passId;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pass.name ?? 'Game Pass',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${(pass.price ?? 0).toStringAsFixed(0)} • ${pass.daysValid ?? 0} days',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
              ),
              if ((pass.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  pass.description!,
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : () => _buyPass(pass),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC06701),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isProcessing ? 'Processing...' : 'Buy Pass',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
