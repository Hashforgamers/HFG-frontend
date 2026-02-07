import 'package:flutter/services.dart';

class Haptics {
  static bool enabled = true;

  static Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  static Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }

  static Future<void> success() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  static Future<void> warning() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  static Future<void> error() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  // Long vibration: best-effort on iOS via heavy impact; Android can use vibrate channel if added later.
  static Future<void> long() async {
    if (!enabled) return;
    await HapticFeedback.vibrate();
  }
}
