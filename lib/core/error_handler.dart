import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'services/service_locator.dart';
import 'services/amplitude_service.dart';

class ErrorHandler {
  static final _amplitudeService = serviceLocator<AmplitudeService>();

  static void initialize() {
    FlutterError.onError = (FlutterErrorDetails details) async {
      await _amplitudeService.trackAppCrash(
        stacktrace: details.stack.toString(),
        screen: Get.currentRoute,
      );
      FlutterError.presentError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) async {
      await _amplitudeService.trackAppCrash(
        stacktrace: stack.toString(),
        screen: Get.currentRoute,
      );
      return true;
    };
  }

  static Future<void> trackApiError(String endpoint, String errorMessage) async {
    await _amplitudeService.trackApiError(
      endpoint: endpoint,
      errorMessage: errorMessage,
    );
  }

  static Future<void> trackUnexpectedLogout(String reason) async {
    await _amplitudeService.trackUnexpectedLogout(
      reason: reason,
    );
  }
} 