import 'dart:async';

import 'package:hash/app/modules/hash_store/data/medusa_store_service.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

bool isRazorpayProvider(String? providerId) =>
    providerId?.contains('razorpay') ?? false;

/// Razorpay checkout options for the Medusa session's Razorpay order. Null
/// when the session carries no order id (the provider is misconfigured).
Map<String, dynamic>? razorpayOptions(
  Map<String, dynamic> paymentCollection,
  String providerId, {
  String? email,
  String? phone,
}) {
  final sessions = (paymentCollection['payment_sessions'] as List? ?? []).map(
    (s) => Map<String, dynamic>.from(s as Map),
  );
  final session = sessions
      .where((s) => s['provider_id'] == providerId)
      .lastOrNull;
  final data = Map<String, dynamic>.from(session?['data'] as Map? ?? {});
  final orderId = (data['razorpay_order_id'] ?? data['id'])?.toString();
  if (orderId == null || !orderId.startsWith('order_')) return null;
  return {
    // The order is created with the backend's Razorpay account, so its public
    // key wins when the session exposes it.
    'key': data['key_id'] ?? data['key'] ?? ApiEndpoints.razorpayKeyWallet,
    'order_id': orderId,
    // Provider data is already in paise; Medusa's session amount is rupees.
    'amount':
        data['amount'] ??
        data['amount_paise'] ??
        (session?['amount'] is num
            ? ((session!['amount'] as num) * 100).round()
            : null),
    'currency': (data['currency'] ?? 'INR').toString().toUpperCase(),
    'name': 'Hash Store',
    'prefill': {'email': ?email, 'contact': ?phone},
    'theme': {'color': '#00DC00'},
  };
}

/// Opens Razorpay and completes when the shopper pays. Throws
/// [StoreException] on failure or cancel. Success here is not proof of
/// payment: completing the cart makes the backend verify it with Razorpay.
Future<void> payWithRazorpay(Map<String, dynamic> options) {
  final razorpay = Razorpay();
  final done = Completer<void>();
  razorpay
    ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (_) {
      if (!done.isCompleted) done.complete();
    })
    ..on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse r) {
      if (done.isCompleted) return;
      done.completeError(
        StoreException(
          r.code == Razorpay.PAYMENT_CANCELLED
              ? 'Payment cancelled.'
              : (r.message?.isNotEmpty ?? false)
              ? r.message!
              : 'Payment failed. Please try again.',
        ),
      );
    })
    ..on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {
      if (done.isCompleted) return;
      done.completeError(
        const StoreException('External wallets are not supported here.'),
      );
    });
  try {
    razorpay.open(options);
  } catch (e) {
    done.completeError(StoreException('Could not open Razorpay: $e'));
  }
  return done.future.whenComplete(razorpay.clear);
}
