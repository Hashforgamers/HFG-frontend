import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/config/app_keys.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/game.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/widgets/arena_background.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';

import 'core/configs/assets/app_images.dart';
import 'core/configs/assets/app_sfx.dart';
import 'core/configs/constants/app_configs.dart';
import 'data/models/fruit_model.dart';

/// Overlay keys shown by [FruitCuttingScreen] on top of the Flame canvas.
class FruitOverlay {
  static const menu = 'menu';
  static const hud = 'hud';
  static const pause = 'pause';
  static const result = 'result';
}

/// Outcome of a finished run, shown on the result overlay.
class FruitResult {
  const FruitResult({
    required this.win,
    required this.score,
    required this.level,
    required this.mode,
    this.isNewBest = false,
    this.saving = true,
    this.synced = true,
  });

  final bool win;
  final int score;
  final int level;
  final int mode;
  final bool isNewBest;

  /// True while the score is still being saved to the leaderboard.
  final bool saving;

  /// False when the leaderboard sync failed (offline / signed out).
  final bool synced;

  FruitResult copyWith({bool? isNewBest, bool? saving, bool? synced}) =>
      FruitResult(
        win: win,
        score: score,
        level: level,
        mode: mode,
        isNewBest: isNewBest ?? this.isNewBest,
        saving: saving ?? this.saving,
        synced: synced ?? this.synced,
      );
}

/// Fruit Cutting game. Flame runs the board; menus and HUD are Flutter
/// overlays driven by the notifiers below.
class MainRouterGame extends FlameGame with KeyboardEvents {
  static const gameId = 'fruit_cutting';
  static const maxLives = 3;
  static const modeNames = ['Easy', 'Medium', 'Hard'];
  static const double _hudHeight = 110;

  final Random random = Random();
  late double maxVerticalVelocity;

  final List<FruitModel> fruits = [
    FruitModel(image: AppImages.apple),
    FruitModel(image: AppImages.banana),
    FruitModel(image: AppImages.kiwi),
    FruitModel(image: AppImages.orange),
    FruitModel(image: AppImages.peach),
    FruitModel(image: AppImages.pineapple),
    FruitModel(image: AppImages.watermelon),
    FruitModel(image: AppImages.cherry),
    FruitModel(image: AppImages.bomb, isBomb: true),
    FruitModel(image: AppImages.bomb, isBomb: true),
  ];

  bool isDesktop = false;

  // HUD state.
  final ValueNotifier<int> scoreListenable = ValueNotifier(0);
  final ValueNotifier<int> livesListenable = ValueNotifier(maxLives);
  final ValueNotifier<int> levelListenable = ValueNotifier(1);
  final ValueNotifier<String?> bannerListenable = ValueNotifier(null);
  final ValueNotifier<FruitResult?> resultListenable = ValueNotifier(null);
  final ValueNotifier<int> modeListenable = ValueNotifier(0);

  GamePage? _page;

  /// Pre-loaded slice sound pools (see [GamePage.playRandomSliceSound]).
  final List<AudioPool> slicePools = [];
  bool _playing = false;
  bool get isPlaying => _playing;

  /// PRIVATE score — prevent tampering.
  int _score = 0;
  int get _mode => modeListenable.value;

  String _userId = '';
  int _sessionTimestamp = 0;

  static const String _secretKey = AppKeys.fruitNinjaSecretKey;

  void incrementScore([int points = 1]) {
    _score += points;
    scoreListenable.value = _score;
  }

  int getScore() => _score;
  int getMode() => _mode;
  void saveMode(int mode) => modeListenable.value = mode.clamp(0, 2);

  String getScoreHash() {
    final raw = '$_score|$_mode|$_userId|$_sessionTimestamp|$_secretKey';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  Map<String, dynamic> getScorePayload() => {
    'userId': _userId,
    'score': _score,
    'mode': _mode,
    'timestamp': _sessionTimestamp,
    'hash': getScoreHash(),
  };

  // ------------------------------------------------------------------ flow

  void startGame() {
    _page?.removeFromParent();
    _score = 0;
    _userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _sessionTimestamp = DateTime.now().millisecondsSinceEpoch;
    scoreListenable.value = 0;
    livesListenable.value = maxLives;
    levelListenable.value = 1;
    bannerListenable.value = null;
    resultListenable.value = null;
    _playing = true;

    _page = GamePage();
    add(_page!);
    resumeEngine();
    overlays
      ..remove(FruitOverlay.menu)
      ..remove(FruitOverlay.result)
      ..remove(FruitOverlay.pause)
      ..add(FruitOverlay.hud);
    _startMusic();
  }

  void pauseGame() {
    if (!_playing || paused) return;
    pauseEngine();
    FlameAudio.bgm.pause();
    overlays.add(FruitOverlay.pause);
  }

  void resumeGame() {
    if (!_playing) return;
    overlays.remove(FruitOverlay.pause);
    resumeEngine();
    FlameAudio.bgm.resume();
  }

  /// Ends the run once (a bomb and a third miss can land together).
  Future<void> finish({required bool win}) async {
    if (!_playing) return;
    _playing = false;
    stopMusic();
    final result = FruitResult(
      win: win,
      score: _score,
      level: levelListenable.value,
      mode: _mode,
    );
    resultListenable.value = result;
    overlays
      ..remove(FruitOverlay.hud)
      ..remove(FruitOverlay.pause)
      ..add(FruitOverlay.result);
    // Let the last slice/explosion render, then freeze the board.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!_playing) pauseEngine();
    });

    // recordScore returns whether the score synced, not whether it's a new
    // best, so compare against the stored best first.
    final scores = MiniGameScoreService();
    var isNewBest = false;
    var synced = false;
    try {
      await scores.ensureLoaded();
      isNewBest = _score > 0 && _score > scores.bestScore(gameId);
      synced = await scores.recordScore(gameId, _score);
    } catch (e) {
      if (kDebugMode) AppLogger.d('Fruit score save failed: $e');
    }
    if (resultListenable.value == result) {
      resultListenable.value = result.copyWith(
        isNewBest: isNewBest,
        saving: false,
        synced: synced,
      );
    }
  }

  void backToMenu() {
    _playing = false;
    stopMusic();
    _page?.removeFromParent();
    _page = null;
    bannerListenable.value = null;
    resumeEngine();
    overlays
      ..remove(FruitOverlay.hud)
      ..remove(FruitOverlay.pause)
      ..remove(FruitOverlay.result)
      ..add(FruitOverlay.menu);
  }

  Future<void> _loadAudio() async {
    try {
      await FlameAudio.audioCache.load(AppSfx.musicBG);
      for (final sfx in [AppSfx.sfxChopping, AppSfx.sfxCut]) {
        slicePools.add(
          await FlameAudio.createPool(sfx, minPlayers: 1, maxPlayers: 3),
        );
      }
    } catch (e) {
      if (kDebugMode) AppLogger.d('Fruit audio preload failed: $e');
    }
  }

  void _startMusic() {
    try {
      FlameAudio.bgm.initialize();
      FlameAudio.bgm.play(AppSfx.musicBG, volume: 0.3);
    } catch (e) {
      if (kDebugMode) AppLogger.d('Fruit BGM failed: $e');
    }
  }

  void stopMusic() {
    try {
      FlameAudio.bgm.stop();
    } catch (_) {}
  }

  // ------------------------------------------------------------- lifecycle

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final fruit in fruits) {
      await images.load(fruit.image);
    }
    add(ArenaBackground());
    unawaited(_loadAudio());
    // Added here rather than via GameWidget.initialActiveOverlays, which is
    // re-applied if the widget re-initialises and would pop the menu over a
    // finished run.
    overlays.add(FruitOverlay.menu);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    isDesktop = size.x > 600 && size.y > 400;
    getMaxVerticalVelocity(size);
  }

  void getMaxVerticalVelocity(Vector2 size) {
    maxVerticalVelocity = sqrt(
      2 *
          (AppConfig.gravity.abs() + AppConfig.acceleration.abs()) *
          // Peak below the HUD (pause/lives/score row).
          (size.y - AppConfig.objSize * 2 - _hudHeight).clamp(
            1,
            double.infinity,
          ),
    );
  }

  @override
  void onRemove() {
    stopMusic();
    for (final pool in slicePools) {
      unawaited(pool.dispose());
    }
    slicePools.clear();
    super.onRemove();
  }
}
