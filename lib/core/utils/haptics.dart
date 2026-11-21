import 'package:flutter/services.dart';

class Haptics {
  static bool enabled = true;
  static int _lastTickMs = 0;

  static bool _canTrigger({int minGapMs = 35}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTickMs < minGapMs) return false;
    _lastTickMs = now;
    return true;
  }

  static Future<void> _trigger(
    Future<void> Function() action, {
    int minGapMs = 35,
  }) async {
    if (!enabled || !_canTrigger(minGapMs: minGapMs)) return;
    try {
      await action();
    } catch (_) {
      // Best-effort only; avoid crashing UI interactions.
    }
  }

  static Future<void> light() async {
    if (!enabled) return;
    await _trigger(() => HapticFeedback.lightImpact());
  }

  static Future<void> medium() async {
    if (!enabled) return;
    await _trigger(() => HapticFeedback.mediumImpact());
  }

  static Future<void> heavy() async {
    if (!enabled) return;
    await _trigger(() => HapticFeedback.heavyImpact());
  }

  static Future<void> selection() async {
    if (!enabled) return;
    await _trigger(() => HapticFeedback.selectionClick(), minGapMs: 20);
  }

  static Future<void> success() async {
    if (!enabled) return;
    await light();
  }

  static Future<void> warning() async {
    if (!enabled) return;
    await medium();
  }

  static Future<void> error() async {
    if (!enabled) return;
    await heavy();
  }

  // Long vibration is used only on critical outcomes (payment success/failure).
  static Future<void> long() async {
    if (!enabled) return;
    await _trigger(() => HapticFeedback.vibrate(), minGapMs: 150);
  }

  // Multi-pulse entry feedback: light -> medium -> heavy -> heavy -> medium -> light.
  static Future<void> liveEnterPulse() async {
    if (!enabled) return;
    resetThrottle();
    await _trigger(() => HapticFeedback.lightImpact(), minGapMs: 0);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await _trigger(() => HapticFeedback.mediumImpact(), minGapMs: 0);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await _trigger(() => HapticFeedback.heavyImpact(), minGapMs: 0);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await _trigger(() => HapticFeedback.heavyImpact(), minGapMs: 0);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await _trigger(() => HapticFeedback.mediumImpact(), minGapMs: 0);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    await _trigger(() => HapticFeedback.lightImpact(), minGapMs: 0);
  }

  // Repeats entry pulses for a short burst window (default 3 seconds).
  static Future<void> liveEnterBurst({
    Duration duration = const Duration(seconds: 3),
  }) async {
    if (!enabled) return;
    final endAt = DateTime.now().add(duration);
    while (DateTime.now().isBefore(endAt)) {
      await liveEnterPulse();
      if (DateTime.now().isAfter(endAt)) break;
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
  }

  // Semantic helpers
  static Future<void> tap() async => selection();
  static Future<void> navigation() async => light();
  static Future<void> cta() async => medium();
  static Future<void> criticalSuccess() async => long();
  static Future<void> criticalError() async => long();

  static void resetThrottle() {
    _lastTickMs = 0;
  }
}
