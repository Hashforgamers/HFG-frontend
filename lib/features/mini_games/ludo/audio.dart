import 'package:just_audio/just_audio.dart';

class Audio {
  static AudioPlayer audioPlayer = AudioPlayer();

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
