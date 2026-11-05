import 'dart:async';

import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/payment/razorpay_branding.dart';
import 'package:hash/config/flavor_config.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'tournament_api.dart';
import 'tournament_models.dart';

enum PaymentOutcome { confirmed, processing, cancelled }

/// Paid entry: the registration exists first (`pending_payment`), checkout runs
/// against a server-owned order, and only `/api/payments/verify` (or the
/// webhook/worker) confirms the entry. A payment ID alone is never proof.
class TournamentPayment {
  static const _timeout = Duration(minutes: 5);
  final NetworkProvider _net = locator<NetworkProvider>();

  Future<PaymentOutcome> pay(Tournament t, Registration reg) async {
    final order = await _order(t, reg);
    final result = await _checkout(t, order);
    if (result == null) return PaymentOutcome.cancelled;
    try {
      final dio = await _net.auth();
      final res = await dio.post(
        ApiEndpoints.paymentVerify(community: true),
        data: {
          'registration_id': reg.id,
          'tournament_id': t.id,
          'razorpay_order_id': result.orderId ?? order.id,
          'razorpay_payment_id': result.paymentId,
          'razorpay_signature': result.signature,
        },
      );
      final data = jsonMap(res.data);
      final r = jsonMap(data['registration']).isNotEmpty
          ? jsonMap(data['registration'])
          : data;
      return r['status'] == 'confirmed'
          ? PaymentOutcome.confirmed
          : PaymentOutcome.processing;
    } catch (e) {
      // Captured but unverified: the webhook/worker settles it. Never charge
      // again; the caller reloads state and shows "processing".
      AppLogger.e('Tournament payment verify failed: $e');
      return PaymentOutcome.processing;
    }
  }

  Future<_Order> _order(Tournament t, Registration reg) async {
    final fromReg = _Order.parse(reg.checkout);
    if (fromReg != null) return fromReg;
    try {
      final dio = await _net.auth();
      final res = await dio.post(
        '${ApiEndpoints.communityHost}/api/payments/intent',
        data: {'registration_id': reg.id},
      );
      final data = jsonMap(res.data);
      final parsed =
          _Order.parse(
            jsonMap(data['payment']).isNotEmpty
                ? jsonMap(data['payment'])
                : data,
          ) ??
          _Order.parse(jsonMap(data['checkout']));
      if (parsed != null) return parsed;
    } catch (e) {
      AppLogger.d('payments/intent unavailable, using booking order: $e');
    }
    // shortcut: booking-service order (same Razorpay account) when the
    // registration carries no checkout; drop once every env returns one.
    final dio = await _net.auth();
    final res = await dio.post(
      '${FlavorConfig.getBaseUrl('booking')}/api/create_order',
      data: {
        'amount': (t.entryFee * 100).round(),
        'currency': t.currency,
        'receipt': 'trn_${reg.id}', // Razorpay caps receipts at 40 chars
      },
    );
    final parsed = _Order.parse(jsonMap(res.data));
    if (parsed == null) {
      throw const TournamentApiException('Could not start payment. Try again.');
    }
    return _Order(parsed.id, (t.entryFee * 100).round(), t.currency, null);
  }

  Future<_Result?> _checkout(Tournament t, _Order order) async {
    final razorpay = Razorpay();
    final done = Completer<_Result?>();
    razorpay
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (dynamic r) {
        final s = r as PaymentSuccessResponse;
        Haptics.criticalSuccess();
        if (!done.isCompleted) {
          done.complete(_Result(s.paymentId ?? '', s.orderId, s.signature));
        }
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (dynamic _) {
        Haptics.criticalError();
        if (!done.isCompleted) done.complete(null);
      })
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, (dynamic _) {});
    final user = Get.isRegistered<UserController>()
        ? Get.find<UserController>().user.value
        : null;
    final phone = user?.contact?.electronicAddress?.mobileNo ?? '';
    final email = user?.contact?.electronicAddress?.emailId ?? '';
    try {
      razorpay.open({
        'key': order.key ?? ApiEndpoints.razorpayKeyWallet,
        'amount': order.amountMinor > 0
            ? order.amountMinor
            : (t.entryFee * 100).round(),
        'currency': order.currency,
        'name': razorpayMerchantName,
        'description': 'Entry: ${t.title}',
        'order_id': order.id,
        'prefill': {
          if (phone.isNotEmpty) 'contact': phone,
          if (email.isNotEmpty) 'email': email,
        },
        'theme': razorpayTheme,
      });
      return await done.future.timeout(_timeout, onTimeout: () => null);
    } finally {
      try {
        razorpay.clear();
      } catch (_) {}
    }
  }
}

class _Order {
  final String id;
  final int amountMinor;
  final String currency;
  final String? key;
  const _Order(this.id, this.amountMinor, this.currency, this.key);

  static _Order? parse(Map<String, dynamic> m) {
    if (m.isEmpty) return null;
    final id = jsonStr(
      m['razorpay_order_id'] ??
          m['order_id'] ??
          m['provider_order_id'] ??
          m['id'],
    );
    if (id == null || !id.startsWith('order_')) return null;
    return _Order(
      id,
      jsonInt(m['amount'] ?? m['amount_minor'] ?? m['amount_paise']) ?? 0,
      jsonStr(m['currency']) ?? 'INR',
      jsonStr(m['key_id'] ?? m['key']),
    );
  }
}

class _Result {
  final String paymentId;
  final String? orderId;
  final String? signature;
  const _Result(this.paymentId, this.orderId, this.signature);
}
