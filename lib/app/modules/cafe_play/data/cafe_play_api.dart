import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/app/modules/cafe_play/models/cafe_play_models.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/service_locator.dart';

/// Gamer-side client for the cafe scan & play contract.
///
/// The Hash login JWT is only used to exchange for a short-lived cafe gamer
/// token (`scope=cafe_gamer`), which authorizes every `/api/cafe/*` call.
class CafePlayApi {
  CafePlayApi._();
  static final CafePlayApi instance = CafePlayApi._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      // Status is checked explicitly: cafe errors are `{"error": "..."}`.
      validateStatus: (_) => true,
    ),
  );

  String? _cafeToken;
  DateTime? _cafeTokenExpiry;
  String? _tokenOwner;

  /// Extracts the signed QR token from a scanned `checkout_url?qr=...`.
  /// Returns null for legacy / unrelated codes.
  static String? extractQrToken(String raw) {
    final text = raw.trim();
    final uri = Uri.tryParse(text);
    final qr = uri?.queryParameters['qr'];
    if (qr != null && qr.isNotEmpty) return qr;
    return null;
  }

  static String newIdempotencyKey() {
    final rnd = Random.secure();
    final b = List<int>.generate(16, (_) => rnd.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  void clear() {
    _cafeToken = null;
    _cafeTokenExpiry = null;
    _tokenOwner = null;
  }

  Future<String> _token({bool force = false}) async {
    final hashDio = await locator<NetworkProvider>().auth();
    final owner = hashDio.options.headers['Authorization']?.toString();
    final valid =
        _cafeToken != null &&
        _tokenOwner == owner &&
        _cafeTokenExpiry != null &&
        DateTime.now().isBefore(_cafeTokenExpiry!);
    if (valid && !force) return _cafeToken!;

    final Response res;
    try {
      res = await hashDio.post(
        ApiEndpoints.cafeCheckoutToken,
        options: Options(validateStatus: (_) => true),
      );
    } on DioException catch (e) {
      throw CafePlayException(_transportMessage(e));
    }
    _throwIfError(res);
    final data = res.data;
    final token = data is Map ? data['token']?.toString() : null;
    if (token == null || token.isEmpty) {
      throw const CafePlayException('Could not sign in to the cafe.');
    }
    final expiresIn = data is Map
        ? (data['expires_in'] as num?)?.toInt()
        : null;
    _cafeToken = token;
    _tokenOwner = owner;
    // Refresh a minute early so an in-flight call doesn't expire mid-way.
    _cafeTokenExpiry = DateTime.now().add(
      Duration(seconds: max(60, (expiresIn ?? 1800) - 60)),
    );
    return token;
  }

  Future<Response> _send(
    String method,
    String url, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    Future<Response> attempt(String token) async {
      try {
        return await _dio.request(
          url,
          queryParameters: query,
          data: body,
          options: Options(
            method: method,
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      } on DioException catch (e) {
        throw CafePlayException(_transportMessage(e));
      }
    }

    var res = await attempt(await _token());
    if (res.statusCode == 401) {
      res = await attempt(await _token(force: true));
    }
    _throwIfError(res);
    return res;
  }

  Future<CafeCheckout> getCheckout(String qr) async {
    final res = await _send(
      'GET',
      ApiEndpoints.cafeCheckout,
      query: {'qr': qr},
    );
    return CafeCheckout.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CafeSession> buyWalletTime({
    required String qr,
    required CafeDuration duration,
    required String idempotencyKey,
  }) async {
    final res = await _send(
      'POST',
      ApiEndpoints.cafeCheckout,
      body: {
        'qr': qr,
        'minutes': duration.minutes,
        'expected_amount': duration.amount,
        'payment_method': 'cafe_wallet',
        'idempotency_key': idempotencyKey,
      },
    );
    return CafeSession.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CafeSession> startBooking({
    required String qr,
    required int bookingId,
    required String idempotencyKey,
  }) async {
    final res = await _send(
      'POST',
      ApiEndpoints.cafeCheckout,
      body: {
        'qr': qr,
        'booking_id': bookingId,
        'payment_method': 'existing_booking',
        'idempotency_key': idempotencyKey,
      },
    );
    return CafeSession.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CafeSession> getSession(String sessionId) async {
    final res = await _send('GET', ApiEndpoints.cafeSession(sessionId));
    return CafeSession.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Balance at one cafe; zeros (not 404) when the gamer has no wallet there.
  Future<CafeWallet> getWallet(int vendorId) async {
    final res = await _send('GET', ApiEndpoints.cafeWallet(vendorId));
    return CafeWallet.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  /// Ledger entries at one cafe, newest first.
  Future<CafePage<CafeWalletEntry>> getWalletHistory(
    int vendorId, {
    int limit = 20,
    int? before,
  }) async {
    final res = await _send(
      'GET',
      ApiEndpoints.cafeWalletHistory(vendorId),
      query: {'limit': limit, if (before != null) 'before': before},
    );
    return CafePage.fromJson(
      Map<String, dynamic>.from(res.data as Map),
      CafeWalletEntry.fromJson,
    );
  }

  void _throwIfError(Response res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300 && res.data is Map) return;
    if (status >= 200 && status < 300) {
      throw CafePlayException(
        'Unexpected response from the cafe.',
        statusCode: status,
      );
    }
    final data = res.data;
    String? msg;
    if (data is Map) {
      msg = (data['error'] ?? data['message'] ?? data['msg'])?.toString();
    }
    debugPrint('CafePlay error $status: $data');
    throw CafePlayException(
      (msg == null || msg.trim().isEmpty) ? _fallback(status) : msg.trim(),
      statusCode: status,
    );
  }

  static String _fallback(int status) => switch (status) {
    401 => 'Your cafe session expired. Please try again.',
    403 => 'This action isn\'t allowed at this cafe.',
    404 => 'Not found.',
    409 => 'Something changed. Please review and try again.',
    410 => 'This QR has expired. Scan the fresh code on the PC.',
    _ => 'Something went wrong. Please try again.',
  };

  static String _transportMessage(DioException e) =>
      'Network problem. Check your connection and try again.';
}
