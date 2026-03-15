import 'package:flutter/services.dart';

class MetaAppEvents {
  static const MethodChannel _channel = MethodChannel(
    'com.hfg.hash/meta_app_events',
  );

  Future<void> activateApp({String? applicationId}) async {
    await _channel.invokeMethod<void>('activateApp', {
      'applicationId': applicationId,
    });
  }

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
    double? valueToSum,
  }) async {
    await _channel.invokeMethod<void>('logEvent', {
      'name': name,
      'parameters': parameters ?? <String, dynamic>{},
      '_valueToSum': valueToSum,
    });
  }

  Future<void> setAdvertiserTracking({
    required bool enabled,
    bool collectId = true,
  }) async {
    await _channel.invokeMethod<void>('setAdvertiserTracking', {
      'enabled': enabled,
      'collectId': collectId,
    });
  }

  Future<void> setGraphApiVersion(String version) async {
    await _channel.invokeMethod<void>('setGraphApiVersion', version);
  }
}
