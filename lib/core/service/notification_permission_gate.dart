import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When to show the in-app pre-prompt, as a pure rule.
class PermissionAskPolicy {
  const PermissionAskPolicy({
    this.maxAsks = 2,
    this.retryAfter = const Duration(days: 3),
  });

  final int maxAsks;
  final Duration retryAfter;

  bool shouldAsk({
    required int asks,
    required int lastAskedMs,
    required int nowMs,
  }) {
    if (asks >= maxAsks) return false;
    if (asks == 0) return true;
    return nowMs - lastAskedMs >= retryAfter.inMilliseconds;
  }
}

/// Asks for push permission after a finished match instead of at launch, when
/// the value (rematch invites, rewards) is obvious. A short in-app pre-prompt
/// comes first so the one-shot OS dialog is only shown to people who said yes.
abstract final class NotificationPermissionGate {
  static const _asksKey = 'push_permission_asks';
  static const _lastAskedKey = 'push_permission_last_asked_ms';
  static const policy = PermissionAskPolicy();
  static bool _inFlight = false;

  /// Call when any match or game run finishes. Cheap and idempotent.
  static void onMatchCompleted(String game) => unawaited(_maybeAsk(game));

  static Future<void> _maybeAsk(String game) async {
    if (_inFlight || !Get.isRegistered<NotificationController>()) return;
    _inFlight = true;
    try {
      final controller = Get.find<NotificationController>();
      if (await controller.permissionStatus() !=
          AuthorizationStatus.notDetermined) {
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final asks = prefs.getInt(_asksKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (!policy.shouldAsk(
        asks: asks,
        lastAskedMs: prefs.getInt(_lastAskedKey) ?? 0,
        nowMs: now,
      )) {
        return;
      }

      // Let the result screen land before interrupting it.
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (Get.overlayContext == null) return;
      await prefs.setInt(_asksKey, asks + 1);
      await prefs.setInt(_lastAskedKey, now);
      final context = Get.overlayContext;
      if (context == null || !context.mounted) return;
      final yes = await showGameDialog(
        context,
        title: 'GET REMATCH INVITES?',
        message:
            'We’ll let you know when friends challenge you, rewards land in '
            'your wallet, or someone takes your rank. No spam.',
        cancelLabel: 'Not now',
        confirmLabel: 'Turn On',
      );
      _log('notification_permission_prompt', {
        'game': game,
        'ask_number': asks + 1,
        'accepted': yes == true ? 'true' : 'false',
      });
      if (yes != true) return;

      final granted = await controller.requestPermissionNow();
      _log('notification_permission_result', {
        'game': game,
        'granted': granted ? 'true' : 'false',
      });
    } catch (e) {
      debugPrint('[NotificationPermissionGate] $e');
    } finally {
      _inFlight = false;
    }
  }

  static void _log(String name, Map<String, Object?> params) {
    try {
      unawaited(locator<AnalyticsService>().log(name, parameters: params));
    } catch (_) {}
  }
}
