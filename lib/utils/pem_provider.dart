import 'package:flutter/services.dart';

class PemLoader {
  static const _channel = MethodChannel('pem_channel');

  static Future<String> getPrivateKey() async {
    return await _channel.invokeMethod('getPrivateKey');
  }

  static Future<String> getPublicKey() async {
    return await _channel.invokeMethod('getPublicKey');
  }
}
