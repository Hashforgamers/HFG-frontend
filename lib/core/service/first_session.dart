import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hash/app/routes/app_routes.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service/app_remote_config.dart';
import 'package:hash/core/service/deeplink_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/features/mini_games/ludo/ludo_provider.dart';
import 'package:hash/features/mini_games/ludo/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gets a brand-new user from signup into their first match fast: home is
/// placed underneath and a short, winnable Ludo game opens on top.
///
/// `onboarding_step` events carry `seconds_since_first_open` so time-to-first-
/// match can be measured against the 60s goal.
abstract final class FirstSession {
  static const _firstOpenKey = 'first_open_at_ms';
  static int? _firstOpenMs;

  /// Call once at app start (splash). Remembers the very first launch.
  static Future<void> markAppOpened() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var ms = prefs.getInt(_firstOpenKey);
      if (ms == null) {
        ms = DateTime.now().millisecondsSinceEpoch;
        await prefs.setInt(_firstOpenKey, ms);
        step('app_first_open');
      }
      _firstOpenMs = ms;
    } catch (_) {}
  }

  static void step(String name, [Map<String, Object?> extra = const {}]) {
    final first = _firstOpenMs;
    try {
      unawaited(
        locator<AnalyticsService>().log(
          'onboarding_step',
          parameters: {
            'step': name,
            if (first != null)
              'seconds_since_first_open':
                  (DateTime.now().millisecondsSinceEpoch - first) ~/ 1000,
            ...extra,
          },
          deduplicationKey: name,
        ),
      );
    } catch (_) {}
  }

  /// Replaces `Get.offAllNamed(HOME)` at the end of every new-user signup.
  /// A pending deep link (e.g. a match invite) still wins.
  static Future<void> finishSignup({required String via}) async {
    step('signup_completed', {'via': via});
    if (await DeepLinkService.resumePendingAfterAuth()) return;
    Get.offAllNamed(AppRoutes.HOME);
    if (!AppRemoteConfig.onboardingFirstMatchEnabled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      step('first_match_started');
      Get.to(
        () => ChangeNotifierProvider(
          create: (_) => LudoProvider.firstMatch()..startGame(),
          child: const MainScreen(),
        ),
      );
    });
  }
}
