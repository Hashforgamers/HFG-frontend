import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'
    show visibleForTesting, kDebugMode, debugPrint;
import 'package:get/get.dart' hide Response, FormData, MultipartFile;
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/core/repositories/local/auth_data_repo.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Hash Store backed by Medusa 2.x. See HFG-STORE-API.md for the contract.
///
/// Only the base URL is build config (`--dart-define=MEDUSA_BASE_URL`, defaults
/// to the live store); pass an empty value to keep the store behind the
/// "Coming Soon" lock. The publishable
/// key, region and sales channel come from the public `GET /hash-store/config`
/// bootstrap and live in memory for the current store visit.
class MedusaStoreService {
  MedusaStoreService._();
  static final MedusaStoreService instance = MedusaStoreService._();

  static const String baseUrl = String.fromEnvironment(
    'MEDUSA_BASE_URL',
    defaultValue: 'https://hash-medusa.onrender.com',
  );

  static bool get isConfigured => baseUrl.isNotEmpty;

  // Plain Dio on purpose: the app's AuthInterceptor would overwrite the
  // Medusa bearer with the HFG token.
  late final Dio _dio =
      Dio(
          BaseOptions(
            baseUrl: baseUrl,
            // The free Render server can take a minute to wake up.
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            headers: {'Content-Type': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              if (!options.path.startsWith('/store')) {
                return handler.next(options);
              }
              try {
                final config = await _config();
                options.headers['x-publishable-api-key'] = config.key;
                handler.next(options);
              } on StoreException catch (e) {
                handler.reject(
                  DioException(requestOptions: options, error: e),
                  true,
                );
              }
            },
            onError: (e, handler) async {
              if (kDebugMode) {
                debugPrint(
                  '[HashStore] ${e.requestOptions.method} ${e.requestOptions.path} status=${e.response?.statusCode} error=${e.type.name}',
                );
              }
              // A rotated key: refetch the config once and retry, reads only.
              // Checkout, payment and other writes are never replayed.
              final o = e.requestOptions;
              final message = e.response?.data is Map
                  ? '${(e.response!.data as Map)['message']}'
                  : '';
              if (o.method == 'GET' &&
                  o.extra['configRetried'] != true &&
                  message.toLowerCase().contains('publishable')) {
                _configFuture = null;
                o.extra['configRetried'] = true;
                try {
                  return handler.resolve(await _dio.fetch(o));
                } on DioException catch (retry) {
                  return handler.next(retry);
                }
              }
              handler.next(e);
            },
          ),
        );

  Future<({String key, String regionId, String? salesChannelId})>?
  _configFuture;

  /// The store bootstrap, fetched once per store visit.
  Future<({String key, String regionId, String? salesChannelId})> _config() =>
      _configFuture ??= _fetchConfig().catchError((Object e) {
        // Never keep a failure; the next request tries again.
        _configFuture = null;
        throw e;
      });

  Future<({String key, String regionId, String? salesChannelId})>
  _fetchConfig() async {
    try {
      final res = await Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      ).get('/hash-store/config');
      final data = res.data is Map ? res.data as Map : const {};
      final key = data['publishable_api_key'] as String?;
      final region = data['region_id'] as String?;
      if (key == null || key.isEmpty || region == null || region.isEmpty) {
        throw const StoreException('The store is not set up yet.');
      }
      return (
        key: key,
        regionId: region,
        salesChannelId: data['sales_channel_id'] as String?,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) {
        throw const StoreException(
          'The store is waking up. Please try again in a moment.',
          statusCode: 503,
        );
      }
      throw StoreException.from(e);
    }
  }

  /// Opening the store fetches a fresh config, per the bootstrap contract.
  void refreshConfig() => _configFuture = null;

  // Medusa token lives in memory only and is bound to the HFG token it was
  // exchanged from, so an account switch always re-exchanges.
  String? _medusaToken;
  String? _exchangedFrom;
  String? _customerId;

  /// Logout: forget the store session. Cart IDs live in SharedPreferences,
  /// which logout already clears.
  void clearSession() {
    _medusaToken = null;
    _exchangedFrom = null;
    _customerId = null;
  }

  // ---------------------------------------------------------------- session

  Future<String> _token() async {
    final hfgToken = await locator<AuthDataRepository>().getAccessToken();
    if (hfgToken == null || hfgToken.isEmpty) {
      throw const StoreException('Please log in to use the Hash Store.');
    }
    if (_medusaToken != null && _exchangedFrom == hfgToken) {
      return _medusaToken!;
    }

    var token = await _exchange(hfgToken);
    if (actorIdOf(token).isEmpty) {
      // First use: register the store customer once, then re-exchange to get
      // a token carrying the linked customer id.
      try {
        await _dio.post(
          '/store/customers',
          data: _registrationContact(),
          options: _bearer(token),
        );
      } on DioException catch (e) {
        // A concurrent first use may have registered already; the re-exchange
        // below tells us. Anything else is a real failure.
        final code = e.response?.statusCode ?? 0;
        if (code < 400 || code >= 500) throw StoreException.from(e);
      }
      token = await _exchange(hfgToken);
      if (actorIdOf(token).isEmpty) {
        throw const StoreException(
          'We could not set up your store account. Please try again.',
        );
      }
    }

    _medusaToken = token;
    _exchangedFrom = hfgToken;
    _customerId = actorIdOf(token);
    return token;
  }

  Future<String> _exchange(String hfgToken) async {
    try {
      final res = await _dio.post(
        '/auth/customer/hfg',
        data: {'token': hfgToken},
      );
      final token = res.data is Map ? res.data['token'] as String? : null;
      if (token == null || token.isEmpty) {
        throw const StoreException('Store sign-in failed.');
      }
      return token;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const StoreException(
          'Your session has expired. Please log in again.',
        );
      }
      throw StoreException.from(e);
    }
  }

  /// Decoded only to pick the registration path, never as proof of auth.
  @visibleForTesting
  static String actorIdOf(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return '';
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return (payload is Map ? payload['actor_id']?.toString() : null) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Real contact fields from the HFG profile only; empty is allowed.
  Map<String, dynamic> _registrationContact() {
    if (!Get.isRegistered<UserController>()) return {};
    final user = Get.find<UserController>().user.value;
    final name = (user.name ?? '').trim();
    final email = (user.contact?.electronicAddress?.emailId ?? '').trim();
    final phone = (user.contact?.electronicAddress?.mobileNo ?? '').trim();
    return {
      if (name.isNotEmpty) 'first_name': name,
      if (email.contains('@')) 'email': email,
      if (phone.isNotEmpty) 'phone': phone,
    };
  }

  /// Email from the HFG profile, for prefilling checkout.
  String? get profileEmail => _registrationContact()['email'] as String?;

  Options _bearer(String token) =>
      Options(headers: {'Authorization': 'Bearer $token'});

  /// Customer request; on 401 drops the cached token and retries once.
  Future<Map<String, dynamic>> _customer(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
  }) async {
    for (var attempt = 0; ; attempt++) {
      final token = await _token();
      try {
        final res = await _dio.request(
          path,
          data: data,
          queryParameters: query,
          options: _bearer(token).copyWith(method: method),
        );
        if (kDebugMode) {
          debugPrint('[HashStore] $method $path status=${res.statusCode}');
        }
        return Map<String, dynamic>.from(res.data as Map);
      } on DioException catch (e) {
        if (kDebugMode) {
          final body = e.response?.data;
          final errorType = body is Map ? body['type'] : null;
          debugPrint(
            '[HashStore] $method $path status=${e.response?.statusCode} error=${e.type.name} backendType=$errorType',
          );
        }
        if (e.response?.statusCode == 401 && attempt == 0) {
          _medusaToken = null;
          continue;
        }
        throw StoreException.from(e);
      }
    }
  }

  Future<Map<String, dynamic>> _public(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await _dio.get(path, queryParameters: query);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw StoreException.from(e);
    }
  }

  // ---------------------------------------------------------------- catalog

  Future<String> regionId() async => (await _config()).regionId;

  /// `{products, count, offset, limit}` from the approved Hash catalog.
  Future<Map<String, dynamic>> catalog({
    int offset = 0,
    int limit = 20,
    String? vendorId,
  }) => _public(
    '/store/hash/products',
    query: {
      'limit': limit,
      'offset': offset,
      if (vendorId != null) 'vendor_id': vendorId,
    },
  );

  // ------------------------------------------------------------------- cart

  String get _cartKey => 'hash_store_cart_$_customerId';

  /// The account's open cart, stored as `{cart_id, vendor_id}`.
  Future<({String cartId, String vendorId})?> _savedCart() async {
    await _token();
    final raw = locator<SharedPreferences>().getString(_cartKey);
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map;
    return (
      cartId: map['cart_id'] as String,
      vendorId: map['vendor_id'] as String,
    );
  }

  Future<void> _saveCart(String cartId, String vendorId) =>
      locator<SharedPreferences>().setString(
        _cartKey,
        jsonEncode({'cart_id': cartId, 'vendor_id': vendorId}),
      );

  Future<void> forgetCart() async {
    await _token();
    await locator<SharedPreferences>().remove(_cartKey);
  }

  Future<String?> cartVendorId() async => (await _savedCart())?.vendorId;

  /// Current cart or null. A completed or missing cart is forgotten.
  Future<Map<String, dynamic>?> cart() async {
    final saved = await _savedCart();
    if (saved == null) return null;
    try {
      final data = await _customer('GET', '/store/carts/${saved.cartId}');
      final cart = Map<String, dynamic>.from(data['cart'] as Map);
      if (cart['completed_at'] != null) {
        await forgetCart();
        return null;
      }
      return cart;
    } on StoreException catch (e) {
      if (e.statusCode == 404) {
        await forgetCart();
        return null;
      }
      rethrow;
    }
  }

  /// Adds a variant. Throws [VendorMismatch] when the open cart belongs to a
  /// different vendor; pass `replaceCart: true` to start a fresh one.
  Future<Map<String, dynamic>> addItem({
    required String variantId,
    required String vendorId,
    int quantity = 1,
    bool replaceCart = false,
  }) async {
    final saved = await _savedCart();
    if (saved != null && !replaceCart) {
      if (saved.vendorId != vendorId) throw const VendorMismatch();
      try {
        final data = await _customer(
          'POST',
          '/store/carts/${saved.cartId}/line-items',
          data: {'variant_id': variantId, 'quantity': quantity},
        );
        return Map<String, dynamic>.from(data['cart'] as Map);
      } on StoreException catch (e) {
        if (e.statusCode != 404) rethrow;
        // Cart vanished server side; fall through and create a new one.
      }
    }
    final email = _registrationContact()['email'];
    final data = await _customer(
      'POST',
      '/store/carts',
      data: {
        'region_id': await regionId(),
        if ((await _config()).salesChannelId case final channel?)
          'sales_channel_id': channel,
        if (email != null) 'email': email,
        'items': [
          {'variant_id': variantId, 'quantity': quantity},
        ],
      },
    );
    final cart = Map<String, dynamic>.from(data['cart'] as Map);
    await _saveCart(cart['id'] as String, vendorId);
    return cart;
  }

  Future<Map<String, dynamic>> setQuantity(
    String cartId,
    String itemId,
    int quantity,
  ) async {
    final data = await _customer(
      'POST',
      '/store/carts/$cartId/line-items/$itemId',
      data: {'quantity': quantity},
    );
    return Map<String, dynamic>.from(data['cart'] as Map);
  }

  /// Returns the parent cart, or null when the cart is now empty.
  Future<Map<String, dynamic>?> removeItem(String cartId, String itemId) async {
    final data = await _customer(
      'DELETE',
      '/store/carts/$cartId/line-items/$itemId',
    );
    final parent = data['parent'];
    final cart = parent is Map ? Map<String, dynamic>.from(parent) : null;
    if (cart == null || (cart['items'] as List? ?? []).isEmpty) {
      await forgetCart();
      return null;
    }
    return cart;
  }

  // --------------------------------------------------------------- checkout

  Future<List<Map<String, dynamic>>> savedAddresses() async {
    final data = await _customer('GET', '/store/customers/me/addresses');
    return (data['addresses'] as List? ?? [])
        .map((a) => Map<String, dynamic>.from(a as Map))
        .toList();
  }

  Future<Map<String, dynamic>> updateCart(
    String cartId, {
    required String email,
    required Map<String, dynamic> address,
  }) async {
    final data = await _customer(
      'POST',
      '/store/carts/$cartId',
      data: {
        'email': email,
        'shipping_address': address,
        'billing_address': address,
      },
    );
    return Map<String, dynamic>.from(data['cart'] as Map);
  }

  Future<List<Map<String, dynamic>>> shippingOptions(String cartId) async {
    final data = await _customer(
      'GET',
      '/store/shipping-options',
      query: {'cart_id': cartId},
    );
    return (data['shipping_options'] as List? ?? [])
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
  }

  Future<Map<String, dynamic>> selectShipping(
    String cartId,
    String optionId,
  ) async {
    final data = await _customer(
      'POST',
      '/store/carts/$cartId/shipping-methods',
      data: {'option_id': optionId},
    );
    return Map<String, dynamic>.from(data['cart'] as Map);
  }

  Future<List<Map<String, dynamic>>> paymentProviders() async {
    final data = await _customer(
      'GET',
      '/store/payment-providers',
      query: {'region_id': await regionId()},
    );
    return (data['payment_providers'] as List? ?? [])
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();
  }

  /// Creates (or reuses) the cart's payment collection and starts a session.
  Future<Map<String, dynamic>> startPayment(
    Map<String, dynamic> cart,
    String providerId,
  ) async {
    var collectionId = (cart['payment_collection'] as Map?)?['id'] as String?;
    if (collectionId == null) {
      final data = await _customer(
        'POST',
        '/store/payment-collections',
        data: {'cart_id': cart['id']},
      );
      collectionId = (data['payment_collection'] as Map)['id'] as String;
    }
    final data = await _customer(
      'POST',
      '/store/payment-collections/$collectionId/payment-sessions',
      data: {'provider_id': providerId, 'data': <String, dynamic>{}},
    );
    return Map<String, dynamic>.from(data['payment_collection'] as Map);
  }

  /// Only `type: "order"` is success. On failure the cart is kept for retry.
  /// On a timeout the cart is re-read instead of resubmitting.
  Future<Map<String, dynamic>> completeCart(String cartId) async {
    try {
      final data = await _customer('POST', '/store/carts/$cartId/complete');
      if (data['type'] == 'order') {
        await forgetCart();
        return Map<String, dynamic>.from(data['order'] as Map);
      }
      final error = data['error'];
      throw StoreException(
        (error is Map ? error['message']?.toString() : error?.toString()) ??
            'Payment is required to place this order.',
      );
    } on StoreException catch (e) {
      if (!e.isTimeout) rethrow;
      final orders = await this.orders(limit: 1);
      final latest = orders.isEmpty ? null : orders.first;
      final current = await cart();
      if (current == null && latest != null) return latest;
      throw const StoreException(
        'We could not confirm your order yet. Check Orders before retrying.',
      );
    }
  }

  // ----------------------------------------------------------------- orders

  Future<List<Map<String, dynamic>>> orders({
    int offset = 0,
    int limit = 20,
  }) async {
    final data = await _customer(
      'GET',
      '/store/orders',
      query: {'limit': limit, 'offset': offset, 'order': '-created_at'},
    );
    return (data['orders'] as List? ?? [])
        .map((o) => Map<String, dynamic>.from(o as Map))
        .toList();
  }

  Future<Map<String, dynamic>> order(String orderId) async {
    final data = await _customer('GET', '/store/orders/$orderId');
    return Map<String, dynamic>.from(data['order'] as Map);
  }

  /// `{paid, completed_at, completion_eligible}`. Reconciliation can lag a
  /// fresh order, so a 404 is retried with a bounded backoff.
  Future<Map<String, dynamic>?> completionStatus(String orderId) async {
    for (final delay in const [0, 1, 2, 4]) {
      if (delay > 0) await Future.delayed(Duration(seconds: delay));
      try {
        final data = await _customer('GET', '/store/hash/orders/$orderId');
        return Map<String, dynamic>.from(data['order'] as Map);
      } on StoreException catch (e) {
        if (e.statusCode != 404) rethrow;
      }
    }
    return null;
  }

  /// `{code, expires_at, instruction}`. Never call in a loop.
  Future<Map<String, dynamic>> requestCompletionOtp(String orderId) =>
      _customer('POST', '/store/hash/orders/$orderId/otp', data: {});
}

class StoreException implements Exception {
  final String message;
  final int? statusCode;
  final bool isTimeout;
  const StoreException(this.message, {this.statusCode, this.isTimeout = false});

  /// Prefers the server's message, which carries OTP cooldowns, mixed-vendor
  /// and availability rejections.
  factory StoreException.from(DioException e) {
    // Config failures raised in the interceptor keep their own message.
    if (e.error case final StoreException inner) return inner;
    final data = e.response?.data;
    final serverMessage = data is Map ? data['message']?.toString() : null;
    final timeout =
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
    return StoreException(
      serverMessage ??
          (timeout
              ? 'The store is taking too long to respond.'
              : e.response == null
              ? 'Could not reach the store. Check your connection.'
              : 'Something went wrong (${e.response!.statusCode}).'),
      statusCode: e.response?.statusCode,
      isTimeout: timeout,
    );
  }

  @override
  String toString() => message;
}

/// The open cart holds another vendor's items.
class VendorMismatch implements Exception {
  const VendorMismatch();
}
