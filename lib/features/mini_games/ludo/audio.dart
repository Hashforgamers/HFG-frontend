import 'package:just_audio/just_audio.dart';

class Audio {
  // Dedicated player for the countdown clock so it doesn't interrupt move/roll
  // sounds. It plays once when the turn enters its final 15 seconds.
  static final AudioPlayer _tickPlayer = AudioPlayer();
  static bool _tickLoaded = false;
  static bool _ticking = false;

  /// Start the clock-ticking sound for the final seconds of a turn. Idempotent:
  /// calling it again while already ticking does nothing. Best-effort.
  static Future<void> startTicking() async {
    if (_ticking) return;
    _ticking = true;
    try {
      if (!_tickLoaded) {
        await _tickPlayer.setAsset('assets/ludo/sounds/clock_ticking.mp3');
        _tickLoaded = true;
      }
      await _tickPlayer.seek(Duration.zero);
      _tickPlayer.play();
    } catch (_) {
      _ticking = false;
    }
  }

  /// Stop the clock-ticking sound (turn ended, moved, or left the red zone).
  static Future<void> stopTicking() async {
    if (!_ticking) return;
    _ticking = false;
    try {
      await _tickPlayer.stop();
    } catch (_) {}
  }

  /// One preloaded player per sound so a roll, a step and a capture (ours or
  /// the opponent's, arriving together online) never interrupt each other.
  static final Map<String, AudioPlayer> _players = {};
  static final Set<String> _loaded = {};

  /// Plays a bundled sound, fire-and-forget. Never blocks gameplay: loading is
  /// capped at 2s and every failure is swallowed. The returned future only
  /// waits for [pace] (default: nothing), never for the audio itself.
  static Future<void> _play(String asset, {Duration? pace}) {
    () async {
      try {
        final player = _players[asset] ??= AudioPlayer();
        if (!_loaded.contains(asset)) {
          await player.setAsset(asset).timeout(const Duration(seconds: 2));
          _loaded.add(asset);
        }
        await player.seek(Duration.zero);
        await player.play();
      } catch (_) {
        // Audio is non-essential to game logic.
      }
    }();
    return Future.delayed(pace ?? Duration.zero);
  }

  static Future<void> playMove() => _play(
    'assets/ludo/sounds/move.wav',
    pace: const Duration(milliseconds: 220),
  );

  static Future<void> playKill() => _play('assets/ludo/sounds/laugh.mp3');

  static Future<void> rollDice() =>
      _play('assets/ludo/sounds/roll_the_dice.mp3');
}
