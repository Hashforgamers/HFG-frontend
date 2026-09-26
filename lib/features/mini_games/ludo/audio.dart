import 'package:just_audio/just_audio.dart';

class Audio {
  static AudioPlayer audioPlayer = AudioPlayer();

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

  /// Plays a bundled sound. Sounds are best-effort: any failure (missing asset,
  /// no audio device, player busy) is swallowed so it can never block or freeze
  /// gameplay. [pace] optionally caps how long the caller waits, keeping pawn
  /// stepping snappy instead of tied to the full clip length.
  static Future<void> _play(String asset, {Duration? pace}) async {
    try {
      final duration = await audioPlayer.setAsset(asset);
      audioPlayer.play();
      await Future.delayed(pace ?? duration ?? Duration.zero);
    } catch (_) {
      // Ignore: audio is non-essential to game logic.
    }
  }

  static Future<void> playMove() => _play(
    'assets/ludo/sounds/move.wav',
    pace: const Duration(milliseconds: 220),
  );

  static Future<void> playKill() => _play('assets/ludo/sounds/laugh.mp3');

  static Future<void> rollDice() =>
      _play('assets/ludo/sounds/roll_the_dice.mp3');
}
