
import 'package:flame_audio/flame_audio.dart';

class AudioPlayer {
  AudioPlayer._();

  static Future playSound(String path) async {
    try {
      AudioCache cache = new AudioCache();
      return await cache.load(path);
    } catch (ex) {}
  }
}
