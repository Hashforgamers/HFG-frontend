import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/tournaments_section/models/tournament_model.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class TournamentPaymentResult {
  final String paymentReference;
  final String? orderId;
  final String? signature;

  const TournamentPaymentResult({
    required this.paymentReference,
    this.orderId,
    this.signature,
  });

  bool get requiresVerification =>
      orderId?.isNotEmpty == true && signature?.isNotEmpty == true;
}

class TournamentPaymentService {
  final NetworkProvider _networkProvider = locator<NetworkProvider>();
  static const Duration _checkoutTimeout = Duration(minutes: 4);

  Future<TournamentPaymentResult?> payRegistrationFee({
    required BuildContext context,
    required TournamentModel tournament,
  }) async {
    Razorpay? razorpay;
    final amountRupees = _extractAmount(tournament.entryFee);
    if (amountRupees <= 0) {
      return const TournamentPaymentResult(paymentReference: '');
    }

    try {
      final orderId = await _createRazorpayOrder(amountRupees);
      final user = _getUserDetails();
      final completer = Completer<TournamentPaymentResult?>();
      razorpay = Razorpay();
      final prefill = <String, dynamic>{};
      final normalizedPhone = user.$1.replaceAll(RegExp(r'[^0-9+]'), '').trim();
      final normalizedEmail = user.$2.trim();
      if (normalizedPhone.isNotEmpty) {
        prefill['contact'] = normalizedPhone;
      }
      if (normalizedEmail.isNotEmpty) {
        prefill['email'] = normalizedEmail;
      }

      void completeOnce(TournamentPaymentResult? result) {
        if (!completer.isCompleted) completer.complete(result);
      }

      razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (dynamic response) {
        final success = response as PaymentSuccessResponse;
        AppLogger.d(
          'Tournament payment success: paymentId=${success.paymentId}, orderId=${success.orderId}',
        );
        Haptics.criticalSuccess();
        final paymentReference = success.paymentId?.isNotEmpty == true
            ? success.paymentId!
            : (success.orderId ?? '');
        completeOnce(
          TournamentPaymentResult(
            paymentReference: paymentReference,
            orderId: success.orderId,
            signature: success.signature,
          ),
        );
      });
      razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (dynamic response) {
        final error = response as PaymentFailureResponse;
        AppLogger.d(
          'Tournament payment error: code=${error.code}, message=${error.message}',
        );
        Haptics.criticalError();
        _showToast(context, error.message ?? 'Payment cancelled');
        completeOnce(null);
      });
      razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (dynamic response) {
        Haptics.warning();
        final wallet =
            (response as ExternalWalletResponse).walletName ?? 'Wallet';
        _showToast(context, '$wallet selected. Complete payment to continue.');
      });

      razorpay.open({
        'key': ApiEndpoints.razorpayKeyWallet,
        'amount': (amountRupees * 100).toInt(),
        'name': user.$3,
        'description': 'Tournament Registration - ${tournament.title}',
        'order_id': orderId,
        if (prefill.isNotEmpty) 'prefill': prefill,
        'theme': {'color': '#C06701'},
      });
      Haptics.cta();

      return await completer.future.timeout(
        _checkoutTimeout,
        onTimeout: () {
          if (context.mounted) {
            _showToast(context, 'Payment timed out. Please try again.');
          }
          return null;
        },
      );
    } catch (e) {
      AppLogger.e('Tournament payment init failed: $e');
      rethrow;
    } finally {
      try {
        razorpay?.clear();
      } catch (_) {}
    }
  }

  Future<Map<String, dynamic>> verifyRegistrationPayment({
    required TournamentPaymentResult payment,
    required String registrationId,
    required String tournamentId,
    required bool community,
  }) async {
    if (!payment.requiresVerification) return const <String, dynamic>{};
    final dio = await _networkProvider.auth();
    final response = await dio.post(
      ApiEndpoints.paymentVerify(community: community),
      data: {
        'razorpay_payment_id': payment.paymentReference,
        'razorpay_order_id': payment.orderId,
        'razorpay_signature': payment.signature,
        'registration_id': registrationId,
        // Cafe callbacks historically identify registrations as teams.
        'team_id': registrationId,
        'tournament_id': tournamentId,
      },
    );
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw Exception('Payment verification returned an invalid response.');
  }

  Future<String> _createRazorpayOrder(double amount) async {
    final receiptId =
        "tournament_rcpt_${DateTime.now().millisecondsSinceEpoch}";
    final url = '${FlavorConfig.getBaseUrl('booking')}/api/create_order';
    final payload = {
      'amount': (amount * 100).toInt(),
      'currency': 'INR',
      'receipt': receiptId,
    };

    final dio = _networkProvider.noAuth();
    final response = await dio.post(url, data: payload);
    if (response.statusCode == 200) {
      final data = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final id = (data['id'] ?? '').toString();
      if (id.isNotEmpty) return id;
    }
    final code = response.statusCode;
    throw Exception('Failed to create payment order (status: $code)');
  }

  (String, String, String) _getUserDetails() {
    if (!Get.isRegistered<UserController>()) return ('', '', 'HashForGamers');
    final user = Get.find<UserController>().user.value;
    final contact = user.contact?.electronicAddress?.mobileNo ?? '';
    final email = user.contact?.electronicAddress?.emailId ?? '';
    final name = (user.name ?? '').trim().isEmpty
        ? 'HashForGamers'
        : user.name!;
    return (contact, email, name);
  }

  double _extractAmount(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty || lower == 'free') return 0;
    final parsed = raw.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(parsed) ?? 0;
  }

  void _showToast(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }
}
