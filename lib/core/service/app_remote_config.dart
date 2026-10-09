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

  @visibleForTesting
  static const Map<String, Object> defaults = {ludoBotFillSecondsKey: 20};

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
}
