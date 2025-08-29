import 'dart:math';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/game.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game_over/game_over.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game_pause/game_pause.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game_victory/game_victory.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/home/home.dart';

import 'core/configs/assets/app_images.dart';
import 'core/configs/assets/app_sfx.dart';
import 'core/configs/constants/app_configs.dart';
import 'core/configs/constants/app_router.dart';
import 'data/models/fruit_model.dart';

class MainRouterGame extends FlameGame with KeyboardEvents {
  final Random random = Random();
  late final RouterComponent router;
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
    FruitModel(image: AppImages.flame, isBomb: true),
    FruitModel(image: AppImages.flutter, isBomb: true),
  ];

  void startBgmMusic() {
    FlameAudio.bgm.initialize();
    FlameAudio.bgm.play(AppSfx.musicBG, volume: 0.3);
  }

  bool isDesktop = false;

  /// PRIVATE score — prevent tampering
  int _score = 0;
  int _mode = 0;

  late final int sessionTimestamp;
  late final String userId;

  /// Secret used to hash (Should be obfuscated/moved to native ideally)
  static const String _secretKey = "hfg_protected_key";

  /// Set the user and start timestamp
  void initSession({required String userId}) {
    this.userId = userId;
    sessionTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  /// Increase score internally only
  void incrementScore([int points = 1]) {
    _score += points;
  }

  /// Read-only getter
  int getScore() => _score;
  int getMode() => _mode;

  void saveMode(int modeInput) {
    _mode = modeInput;
  }

  /// Generate secure hash of score
  String getScoreHash() {
    final raw = '$_score|$_mode|$userId|$sessionTimestamp|$_secretKey';
    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Generate score payload for API
  Map<String, dynamic> getScorePayload() {
    return {
      "userId": userId,
      "score": _score,
      "mode": _mode,
      "timestamp": sessionTimestamp,
      "hash": getScoreHash(),
    };
  }

  @override
  void onLoad() async {
    super.onLoad();

    for (final fruit in fruits) {
      await images.load(fruit.image);
    }

    await images.load(AppImages.homeBG);

    addAll(
      [
        ParallaxComponent(
          parallax: Parallax(
            [
              await ParallaxLayer.load(
                ParallaxImageData(AppImages.homeBG),
              ),
            ],
          ),
        ),
        router = RouterComponent(
          initialRoute: AppRouter.homePage,
          routes: {
            AppRouter.homePage: Route(HomePage.new),
            AppRouter.gamePage: Route(GamePage.new),
            AppRouter.gameVictory: VictoryRoute(),
            AppRouter.gameOver: GameOverRoute(),
            AppRouter.gamePause: PauseRoute(),
          },
        )
      ],
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    getMaxVerticalVelocity(size);
  }

  void getMaxVerticalVelocity(Vector2 size) {
    maxVerticalVelocity = sqrt(2 *
        (AppConfig.gravity.abs() + AppConfig.acceleration.abs()) *
        (size.y - AppConfig.objSize * 2));
  }
}
