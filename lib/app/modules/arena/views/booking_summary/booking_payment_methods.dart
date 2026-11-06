import 'package:dio/dio.dart';
import 'package:hash/core/network/api_endpoints.dart';
import 'package:hash/core/network/network_config.dart';
import 'package:hash/core/service_locator.dart';

/// Payment methods a cafe currently accepts, as switched on in its dashboard.
///
/// The backend is the only source: there is no hard-coded fallback, so a
/// failed load means nothing can be selected until it is retried.
class CafePaymentMethods {
  const CafePaymentMethods(this.enabled);

  static const hashWallet = 'hash_wallet';
  static const cafeWallet = 'cafe_wallet';
  static const hashGlobalPass = 'hash_global_pass';
  static const cafeSpecificPass = 'cafe_specific_pass';
  static const paymentGateway = 'payment_gateway';
  static const payAtCafe = 'pay_at_cafe';

  final Set<String> enabled;

  bool has(String key) => enabled.contains(key);
  bool get hasPass => has(hashGlobalPass) || has(cafeSpecificPass);

  static Future<CafePaymentMethods> fetch(int vendorId) async {
    final dio = await locator<NetworkProvider>().auth();
    final response = await dio.get(
      ApiEndpoints.vendorPaymentMethods(vendorId),
      options: Options(headers: {'Cache-Control': 'no-cache'}),
    );
    final data = response.data;
    if (data is! Map) throw const FormatException('Unexpected response');

    final enabledList = data['enabled_payment_methods'];
    if (enabledList is List) {
      return CafePaymentMethods(enabledList.map((e) => e.toString()).toSet());
    }
    final methods = data['payment_methods'];
    if (methods is! List) throw const FormatException('Unexpected response');
    return CafePaymentMethods({
      for (final method in methods)
        if (method is Map && method['is_enabled'] == true)
          method['method_name'].toString(),
    });
  }
}
