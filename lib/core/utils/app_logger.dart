import 'package:flutter/foundation.dart';

class AppLogger {
  static void d(Object? message) {
    if (kReleaseMode) return;
    debugPrint(message?.toString());
  }

  static void i(Object? message) {
    if (kReleaseMode) return;
    debugPrint(message?.toString());
  }

  static void w(Object? message) {
    if (kReleaseMode) return;
    debugPrint(message?.toString());
  }

  static void e(Object? message, {Object? error, StackTrace? stackTrace}) {
    if (kReleaseMode) return;
    debugPrint(message?.toString());
    if (error != null) {
      debugPrint(error.toString());
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
