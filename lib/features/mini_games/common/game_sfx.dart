import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/core/utils/app_logger.dart';

/// Short sound effects for mini games.
///
/// Uses [PlayerMode.lowLatency] (Android SoundPool): the default media-player
/// mode runs a stop→prepare on playback completion that throws an uncaught
/// native IllegalStateException after a playback error, killing the app.
/// Each sound gets a few preloaded players used round-robin; every failure is
/// swallowed because a missing sound must never crash a game.
class GameSfx {
  GameSfx({required this.prefix, this.voices = 3});

  /// Asset folder, e.g. `assets/pacman/`.
  final String prefix;
  final int voices;

  final Map<String, List<AudioPlayer>> _players = {};
  final Map<String, int> _next = {};
  bool _disposed = false;

  Future<void> load(List<String> files) async {
    final cache = AudioCache(prefix: prefix);
    for (final file in files) {
      final list = <AudioPlayer>[];
      for (var i = 0; i < voices; i++) {
        try {
          final player = AudioPlayer()..audioCache = cache;
          await player.setPlayerMode(PlayerMode.lowLatency);
          await player.setReleaseMode(ReleaseMode.stop);
          await player.setSource(AssetSource(file));
          list.add(player);
        } catch (e) {
          if (kDebugMode) AppLogger.d('GameSfx: failed to load $file: $e');
        }
      }
      if (_disposed) {
        for (final p in list) {
          unawaited(p.dispose());
        }
        return;
      }
      _players[file] = list;
    }
  }

  void play(String file, {double volume = 0.5}) {
    if (_disposed) return;
    final list = _players[file];
    if (list == null || list.isEmpty) return;
    final i = (_next[file] ?? 0) % list.length;
    _next[file] = i + 1;
    final player = list[i];
    unawaited(() async {
      try {
        await player.stop();
        await player.setVolume(volume);
        await player.resume();
      } catch (_) {}
    }());
  }

  Future<void> dispose() async {
    _disposed = true;
    for (final list in _players.values) {
      for (final p in list) {
        try {
          await p.dispose();
        } catch (_) {}
      }
    }
    _players.clear();
  }
}
