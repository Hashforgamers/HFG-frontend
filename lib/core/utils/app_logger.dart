import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _allowTag = 'Vendor amenities debug ->';

  static bool _shouldLog(Object? message) {
    if (kReleaseMode) return false;
    final text = message?.toString() ?? '';
    return text.contains(_allowTag);
  }

  static void d(Object? message) {
    if (!_shouldLog(message)) return;
    debugPrint(message?.toString());
  }

  static void i(Object? message) {
    if (!_shouldLog(message)) return;
    debugPrint(message?.toString());
  }

  static void w(Object? message) {
    if (!_shouldLog(message)) return;
    debugPrint(message?.toString());
  }

  static void e(Object? message, {Object? error, StackTrace? stackTrace}) {
    if (!_shouldLog(message)) return;
    debugPrint(message?.toString());
    if (error != null && _shouldLog(error)) {
      debugPrint(error.toString());
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
