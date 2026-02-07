import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/widgets/fruit_component.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/widgets/fruit_slice_component.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/widgets/slice_component.dart';

import '../../common/widgets/button/back_button.dart';
import '../../common/widgets/button/pause_button.dart';
import '../../core/configs/assets/app_sfx.dart';
import '../../core/configs/constants/app_configs.dart';
import '../../core/configs/constants/app_router.dart';
import '../../core/configs/theme/app_colors.dart';
import '../../main_router_game.dart';

/// [SECURE] GamePage — All score/mode logic now uses secure access
class GamePage extends Component
    with DragCallbacks, HasGameReference<MainRouterGame> {
  final Random random = Random();
  late List<double> fruitsTime;

  late double time;
  late double countDown;
  double finishCountDown = 2.0;

  late int level = 1;
  late int mistakeCount;
  bool _countdownFinished = false;

  TextComponent? _countdownTextComponent;
  TextComponent? _mistakeTextComponent;
  TextComponent? _scoreTextComponent;
  TextComponent? _modeTextComponent;

  late SliceTrailComponent sliceTrail;
  final List<String> sliceSounds = [AppSfx.sfxChopping, AppSfx.sfxCut];

  @override
  void onMount() {
    super.onMount();

    fruitsTime = [];
    countDown = 5;
    mistakeCount = 0;
    time = 0;
    _countdownFinished = false;
    level = 1;

    generateFruitTimings();
    initializeTextComponents();

    sliceTrail = SliceTrailComponent();
    add(sliceTrail);
  }

  void initializeTextComponents() {
    final scoreTextPaint = TextPaint(
      style: TextStyle(
        fontSize: game.isDesktop ? 32 : 25,
        color: AppColors.white,
        fontWeight: FontWeight.w100,
        fontFamily: 'Insan',
        letterSpacing: 2.0,
      ),
    );

    final countdownTextPaint = TextPaint(
      style: const TextStyle(
        fontSize: 45,
        color: AppColors.white,
        fontFamily: 'Insan',
        letterSpacing: 2.0,
      ),
    );

    final mistakeTextPaint = TextPaint(
      style: TextStyle(
        fontSize: game.isDesktop ? 32 : 25,
        color: AppColors.white,
        fontWeight: FontWeight.w100,
        fontFamily: 'Insan',
        letterSpacing: 2.0,
      ),
    );

    final modeTextPaint = TextPaint(
      style: const TextStyle(
        fontSize: 18,
        color: AppColors.white,
        fontWeight: FontWeight.w100,
        fontFamily: 'Insan',
        letterSpacing: 2.0,
      ),
    );

    final modeText = 'Mode ${_modeName(game.getMode())}';

    addAll([
      BackButtonCustom(
        onPressed: () {
          removeAll(children);
          game.router.pop();
        },
      ),
      PauseButtonCustom(),
      _countdownTextComponent = TextComponent(
        text: "- Level 1 -",
        size: Vector2.all(50),
        position: Vector2(game.size.x / 2, game.size.y / 2 - 10),
        anchor: Anchor.center,
        textRenderer: countdownTextPaint,
      ),
      _mistakeTextComponent = TextComponent(
        text: 'Mistake: $mistakeCount',
        position: Vector2(game.size.x - 15, 10),
        anchor: Anchor.topRight,
        textRenderer: mistakeTextPaint,
      ),
      _scoreTextComponent = TextComponent(
        text: 'Score: ${game.getScore()}',
        position: Vector2(game.size.x - 15, 50),
        anchor: Anchor.topRight,
        textRenderer: scoreTextPaint,
      ),
      _modeTextComponent = TextComponent(
        text: modeText,
        position: Vector2(game.size.x - 15, game.size.y - 15),
        anchor: Anchor.bottomRight,
        textRenderer: modeTextPaint,
      ),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (!_countdownFinished) {
      countDown -= dt;
      if (countDown < 2) {
        _countdownTextComponent?.text = (countDown.toInt() + 1).toString();
      }
      if (countDown < 0) {
        _countdownFinished = true;
      }
    } else if (fruitsTime.isEmpty && !hasFruits()) {
      if (_countdownTextComponent != null &&
          !_countdownTextComponent!.isMounted) {
        _countdownTextComponent?.addToParent(this);
      }

      _countdownTextComponent?.text = level == 3
          ? (finishCountDown.toInt() + 1).toString()
          : "- Level ${level + 1} -";

      if (finishCountDown <= 0) {
        gameWin();
      }

      finishCountDown -= dt;
      if (finishCountDown < 0) {
        finishCountDown = 0;
      }
    } else {
      _countdownTextComponent?.removeFromParent();

      time += dt;

      fruitsTime.where((e) => e < time).toList().forEach((e) {
        spawnFruit();
        fruitsTime.remove(e);
      });
    }
  }

  void spawnFruit() {
    final gameSize = game.size;
    double posX = random.nextInt(gameSize.x.toInt()).toDouble();
    Vector2 fruitPosition = Vector2(posX, gameSize.y);
    Vector2 velocity = Vector2(0, game.maxVerticalVelocity);

    final randFruit = game.fruits.random();
    add(
      FruitComponent(
        this,
        fruitPosition,
        acceleration: AppConfig.acceleration,
        fruit: randFruit,
        size: AppConfig.shapeSize,
        image: game.images.fromCache(randFruit.image),
        pageSize: gameSize,
        velocity: velocity,
      ),
    );
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    sliceTrail.addPoint(event.canvasStartPosition);

    componentsAtPoint(event.canvasStartPosition).forEach((element) {
      if (element is FruitComponent && element.canDragOnShape) {
        if (game.isDesktop) {
          onFruitSliced(sliceTrail);
          game.add(FruitSliceComponent(event.canvasStartPosition));
          playRandomSliceSound();
        }

        element.touchAtPoint(event.canvasStartPosition);
      }
    });
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    sliceTrail.clear();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);

    _countdownTextComponent?.position = game.size / 2;
    _mistakeTextComponent?.position = Vector2(game.size.x - 15, 10);
    _scoreTextComponent?.position = Vector2(
      game.size.x - 15,
      _mistakeTextComponent!.position.y + 40,
    );
    _modeTextComponent?.position = Vector2(game.size.x - 15, game.size.y - 15);
  }

  bool hasFruits() => children.any((c) => c is FruitComponent);

  void gameOver() {
    FlameAudio.bgm.stop();
    game.router.pushNamed(AppRouter.gameOver);
  }

  void gameWin() {
    if (level < 3) {
      level++;
      resetLevel();
    } else {
      FlameAudio.bgm.stop();
      game.router.pushNamed(AppRouter.gameVictory);
    }
  }

  void resetLevel() {
    fruitsTime.clear();
    time = 0;
    countDown = 3;
    finishCountDown = 2.0;
    _countdownFinished = false;
    generateFruitTimings();
  }

  void addScore() {
    game.incrementScore(); // Secure increment
    _scoreTextComponent?.text = 'Score: ${game.getScore()}';
  }

  void addMistake() {
    mistakeCount++;
    _mistakeTextComponent?.text = 'Mistake: $mistakeCount';
    if (mistakeCount >= 3) gameOver();
  }

  void onFruitSliced(SliceTrailComponent trail) {
    trail.changeColor();
  }

  void playRandomSliceSound() {
    String sound = sliceSounds[random.nextInt(sliceSounds.length)];
    FlameAudio.play(sound, volume: 0.5);
  }

  void generateFruitTimings() {
    fruitsTime.clear();
    double initTime = 0;
    int fruitCount = getFruitCount(level, game.getMode());
    double minInterval = getMinInterval(level, game.getMode());

    for (int i = 0; i < fruitCount; i++) {
      if (i != 0) initTime = fruitsTime.last;
      double msTime = random.nextInt(100) / 100;
      double compTime = random.nextInt(1) * minInterval + msTime + initTime;
      fruitsTime.add(compTime);
    }
  }

  int getFruitCount(int level, int mode) {
    const List<List<int>> fruitCounts = [
      [15, 20, 30],
      [20, 30, 40],
      [30, 40, 60],
    ];
    return fruitCounts[level - 1][mode];
  }

  double getMinInterval(int level, int mode) {
    const List<List<double>> intervals = [
      [1.5, 1.5, 1.2],
      [1.2, 1.0, 0.8],
      [0.8, 0.6, 0.5],
    ];
    return intervals[level - 1][mode];
  }

  String _modeName(int mode) {
    switch (mode) {
      case 0:
        return 'Easy';
      case 1:
        return 'Medium';
      default:
        return 'Hard';
    }
  }
}
