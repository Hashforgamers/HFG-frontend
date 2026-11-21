import 'package:firebase_auth/firebase_auth.dart';
import 'package:hash/core/service/app_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pure rule: [threshold] early quits inside [window] lock Quick Match for
/// [cooldown] after the most recent one.
class LudoQuitPolicy {
  const LudoQuitPolicy({
    required this.threshold,
    required this.cooldown,
    this.window = const Duration(minutes: 30),
  });

  final int threshold;
  final Duration cooldown;
  final Duration window;

  /// Quits still inside the window, oldest first.
  List<int> recent(List<int> quitsMs, int nowMs) =>
      quitsMs.where((t) => nowMs - t < window.inMilliseconds).toList()..sort();

  Duration remaining(List<int> quitsMs, int nowMs) {
    final r = recent(quitsMs, nowMs);
    if (r.length < threshold) return Duration.zero;
    final leftMs = r.last + cooldown.inMilliseconds - nowMs;
    return leftMs <= 0 ? Duration.zero : Duration(milliseconds: leftMs);
  }
}

/// Remembers early quits on this device, per signed-in user.
abstract final class LudoQuitCooldown {
  /// Leaving within this long counts as an early quit.
  static const Duration earlyQuitWithin = Duration(minutes: 3);

  static LudoQuitPolicy get policy => LudoQuitPolicy(
    threshold: AppRemoteConfig.ludoQuitCooldownThreshold,
    cooldown: Duration(seconds: AppRemoteConfig.ludoQuitCooldownSeconds),
  );

  static String? get _key {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : 'ludo_early_quits_$uid';
  }

  static Future<List<int>> _load(SharedPreferences prefs, String key) async =>
      (prefs.getStringList(key) ?? const [])
          .map(int.tryParse)
          .whereType<int>()
          .toList();

  static Future<void> recordEarlyQuit() async {
    final key = _key;
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final quits = policy.recent([...await _load(prefs, key), now], now);
    await prefs.setStringList(key, quits.map((t) => '$t').toList());
  }

  /// Time left before this user may Quick Match again (zero if none).
  static Future<Duration> remaining() async {
    final key = _key;
    if (key == null) return Duration.zero;
    final prefs = await SharedPreferences.getInstance();
    return policy.remaining(
      await _load(prefs, key),
      DateTime.now().millisecondsSinceEpoch,
    );
  }
}
