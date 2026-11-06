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
  static const String tournamentsEnabledKey = 'tournaments_enabled';

  @visibleForTesting
  static const Map<String, Object> defaults = {
    ludoBotFillSecondsKey: 20,
    ludoQuickModeEnabledKey: false,
    ludoQuitCooldownSecondsKey: 0,
    ludoQuitCooldownThresholdKey: 2,
    onboardingFirstMatchEnabledKey: true,
    // Off unless switched on from Push Studio (Play contest policy).
    tournamentsEnabledKey: false,
  };

  static bool _ready = false;
  static bool? _tournamentsSession;

  static Future<void> init() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setDefaults(defaults);
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          // Short so a Push Studio switch reaches users within minutes.
          minimumFetchInterval: const Duration(minutes: 5),
        ),
      );
      _ready = true;
      // Wait briefly so this launch can use a fresh value; never block long.
      await rc
          .fetchAndActivate()
          .timeout(const Duration(milliseconds: 1500))
          .catchError((Object e) {
            debugPrint('[AppRemoteConfig] fetch failed: $e');
            return false;
          });
      // Real-time updates are activated for the next launch.
      rc.onConfigUpdated.listen(
        (_) => rc.activate(),
        onError: (Object e) => debugPrint('[AppRemoteConfig] listen: $e'),
      );
    } catch (e) {
      debugPrint('[AppRemoteConfig] init failed: $e');
    }
    _tournamentsSession = _bool(tournamentsEnabledKey);
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

  /// Tournaments, hosting and tournament invites. Fixed for the app session
  /// (read once at startup) so tabs never appear or vanish mid-use.
  static bool get tournamentsEnabled =>
      _tournamentsSession ?? (defaults[tournamentsEnabledKey]! as bool);

  /// New users go straight from signup into an easy 1v1 Ludo match.
  static bool get onboardingFirstMatchEnabled =>
      _bool(onboardingFirstMatchEnabledKey);
}
