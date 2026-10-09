import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Feature flags and tunables from Firebase Remote Config.
///
/// [init] registers in-app defaults and fetches in the background, so startup
/// never waits on the network. Every getter falls back to its default (and
/// clamps to a sane range) when Remote Config is unavailable, e.g. in tests.
abstract final class AppRemoteConfig {
  // Keys. Add each new key to [defaults] too.
  static const String ludoBotFillSecondsKey = 'ludo_bot_fill_seconds';
  static const String ludoQuickModeEnabledKey = 'ludo_quick_mode_enabled';
  static const String ludoQuitCooldownSecondsKey = 'ludo_quit_cooldown_seconds';
  static const String ludoQuitCooldownThresholdKey =
      'ludo_quit_cooldown_threshold';
  static const String onboardingFirstMatchEnabledKey =
      'onboarding_first_match_enabled';

  @visibleForTesting
  static const Map<String, Object> defaults = {
    ludoBotFillSecondsKey: 20,
    ludoQuickModeEnabledKey: false,
    ludoQuitCooldownSecondsKey: 0,
    ludoQuitCooldownThresholdKey: 2,
    onboardingFirstMatchEnabledKey: true,
  };

  static bool _ready = false;

  static Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setDefaults(defaults);
      _ready = true;
      unawaited(
        rc.fetchAndActivate().catchError((Object e) {
          debugPrint('[AppRemoteConfig] fetch failed: $e');
          return false;
        }),
      );
    } catch (e) {
      debugPrint('[AppRemoteConfig] init failed: $e');
    }
  }

  static bool _bool(String key) {
    final fallback = defaults[key]! as bool;
    if (!_ready) return fallback;
    try {
      return FirebaseRemoteConfig.instance.getBool(key);
    } catch (_) {
      return fallback;
    }
  }

  static int _int(String key, {required int min, required int max}) {
    final fallback = defaults[key]! as int;
    if (!_ready) return fallback;
    try {
      final v = FirebaseRemoteConfig.instance.getInt(key);
      return v <= 0 ? fallback : v.clamp(min, max);
    } catch (_) {
      return fallback;
    }
  }

  /// How long a Quick Match Ludo room waits for real players before a bot
  /// fills the empty seat.
  static int get ludoBotFillSeconds =>
      _int(ludoBotFillSecondsKey, min: 5, max: 60);

  /// Shows the Quick Ludo (2 tokens, 1v1 vs AI) mode card.
  static bool get ludoQuickModeEnabled => _bool(ludoQuickModeEnabledKey);

  /// Quick Match lockout after repeated early quits from online matches.
  static int get ludoQuitCooldownSeconds =>
      _int(ludoQuitCooldownSecondsKey, min: 0, max: 1800);

  /// Early quits within 30 minutes that trigger the lockout.
  static int get ludoQuitCooldownThreshold =>
      _int(ludoQuitCooldownThresholdKey, min: 1, max: 10);

  /// New users go straight from signup into an easy 1v1 Ludo match.
  static bool get onboardingFirstMatchEnabled =>
      _bool(onboardingFirstMatchEnabledKey);
}
