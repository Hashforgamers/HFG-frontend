import 'package:flutter/services.dart';

class KeyProvider {
  static const _channel = MethodChannel('secure_channel');

  static Future<String> getPrivateKey() async {
    return await _channel.invokeMethod('getPrivateKey');
  }

  static Future<String> getPublicKey() async {
    return await _channel.invokeMethod('getPublicKey');
  }
}