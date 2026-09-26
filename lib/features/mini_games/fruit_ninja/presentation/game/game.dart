import 'dart:math';
import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/widgets/fruit_component.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/widgets/fruit_slice_component.dart';
import 'package:hash/features/mini_games/fruit_ninja/presentation/game/widgets/slice_component.dart';
import 'package:hash/core/utils/app_logger.dart';

import '../../core/configs/constants/app_configs.dart';
import '../../main_router_game.dart';

/// The playing field: spawns fruit per level and reports score, misses and
/// the outcome to [MainRouterGame]. The HUD is a Flutter overlay.
class GamePage extends PositionComponent
    with DragCallbacks, HasGameReference<MainRouterGame> {
  static const _levels = 3;

  final Random random = Random();
  final List<double> fruitsTime = [];

  double time = 0;
  double countDown = 3;
  double finishCountDown = 2.0;
  int level = 1;
  int mistakeCount = 0;
  bool _countdownFinished = false;
  bool _over = false;

  late SliceTrailComponent sliceTrail;
  bool _sliceSfxEnabled = true;
  DateTime _lastSliceSfxAt = DateTime.fromMillisecondsSinceEpoch(0);
  final Vector2 _samplePoint = Vector2.zero();

  @override
  void onMount() {
    super.onMount();
    position = Vector2.zero();
    size = game.size.clone();
    level = 1;
    mistakeCount = 0;
    _over = false;
    _startLevel(countdown: 3);
    sliceTrail = SliceTrailComponent();
    add(sliceTrail);
  }

  void _startLevel({required double countdown}) {
    fruitsTime.clear();
    time = 0;
    countDown = countdown;
    finishCountDown = 2.0;
    _countdownFinished = false;
    game.levelListenable.value = level;
    generateFruitTimings();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_over) return;

    if (!_countdownFinished) {
      countDown -= dt;
      game.bannerListenable.value = countDown > 1 ? 'LEVEL $level' : 'GO!';
      if (countDown < 0) {
        _countdownFinished = true;
        game.bannerListenable.value = null;
      }
    } else if (fruitsTime.isEmpty && !hasFruits()) {
      // Level cleared.
      game.bannerListenable.value = level == _levels
          ? 'FINAL!'
          : 'LEVEL $level CLEAR!';
      finishCountDown -= dt;
      if (finishCountDown <= 0) gameWin();
    } else {
      time += dt;
      fruitsTime.where((e) => e < time).toList().forEach((e) {
        spawnFruit();
        fruitsTime.remove(e);
      });
    }
  }

  void spawnFruit() {
    final gameSize = game.size;
    // Keep fruit fully on screen horizontally.
    final margin = AppConfig.objSize;
    final posX =
        margin + random.nextDouble() * (gameSize.x - margin * 2).clamp(1, 1e6);
    final randFruit = game.fruits.random();
    add(
      FruitComponent(
        this,
        Vector2(posX, gameSize.y),
        acceleration: AppConfig.acceleration,
        fruit: randFruit,
        size: AppConfig.shapeSize,
        image: game.images.fromCache(randFruit.image),
        pageSize: gameSize,
        velocity: Vector2(0, game.maxVerticalVelocity),
      ),
    );
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    sliceTrail.addPoint(event.canvasPosition);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final start = event.canvasStartPosition;
    final end = event.canvasEndPosition;
    sliceTrail.addPoint(end);

    if (_over) return;
    // Sample along the swipe so fast strokes don't skip fruit. Only fruit are
    // tested (componentsAtPoint walked every component, particles included).
    // A sliced fruit is only removed on the next tick, so each fruit is hit
    // at most once per swipe segment (otherwise one fruit scored ~7 points).
    final fruits = children
        .whereType<FruitComponent>()
        .where((f) => f.isMounted && !f.isRemoving)
        .toList();
    if (fruits.isEmpty) return;
    const samples = 6;
    for (var i = 0; i <= samples && fruits.isNotEmpty; i++) {
      final t = i / samples;
      _samplePoint.setValues(
        start.x + (end.x - start.x) * t,
        start.y + (end.y - start.y) * t,
      );
      for (final fruit in fruits.toList()) {
        if (fruit.containsPoint(_samplePoint)) {
          fruits.remove(fruit);
          _slice(fruit, _samplePoint.clone());
        }
      }
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    sliceTrail.clear();
  }

  void _slice(FruitComponent fruit, Vector2 point) {
    if (_over) return;
    onFruitSliced(sliceTrail);
    game.add(FruitSliceComponent(point));
    playRandomSliceSound();
    fruit.touchAtPoint(point);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  bool hasFruits() => children.any((c) => c is FruitComponent);

  void gameOver() {
    if (_over) return;
    _over = true;
    game.bannerListenable.value = null;
    unawaited(game.finish(win: false));
  }

  void gameWin() {
    if (level < _levels) {
      level++;
      _startLevel(countdown: 2);
    } else {
      _over = true;
      game.bannerListenable.value = null;
      unawaited(game.finish(win: true));
    }
  }

  void addScore() {
    if (_over) return;
    game.incrementScore();
  }

  void addMistake() {
    if (_over) return;
    mistakeCount++;
    game.livesListenable.value = (MainRouterGame.maxLives - mistakeCount).clamp(
      0,
      MainRouterGame.maxLives,
    );
    if (mistakeCount >= MainRouterGame.maxLives) gameOver();
  }

  void onFruitSliced(SliceTrailComponent trail) => trail.changeColor();

  /// Plays a slice sound from the game's pre-loaded pools (creating a new
  /// player per slice caused hitches).
  void playRandomSliceSound() {
    if (!_sliceSfxEnabled) return;
    final now = DateTime.now();
    if (now.difference(_lastSliceSfxAt).inMilliseconds < 70) return;
    _lastSliceSfxAt = now;
    final pools = game.slicePools;
    if (pools.isEmpty) return;
    try {
      unawaited(pools[random.nextInt(pools.length)].start(volume: 0.5));
    } catch (e) {
      _sliceSfxEnabled = false;
      if (kDebugMode) AppLogger.d('Slice SFX disabled after failure: $e');
    }
  }

  /// Spawn times for this level. Each gap is based on the level/mode interval
  /// (the old code multiplied it by `nextInt(1)`, which is always 0, so every
  /// mode played the same).
  void generateFruitTimings() {
    fruitsTime.clear();
    final count = getFruitCount(level, game.getMode());
    final interval = getMinInterval(level, game.getMode());
    var t = 0.0;
    for (var i = 0; i < count; i++) {
      t += interval * (0.35 + random.nextDouble() * 0.5);
      fruitsTime.add(t);
    }
  }

  int getFruitCount(int level, int mode) {
    const counts = [
      [15, 20, 30],
      [20, 30, 40],
      [30, 40, 60],
    ];
    return counts[level - 1][mode];
  }

  double getMinInterval(int level, int mode) {
    const intervals = [
      [1.5, 1.5, 1.2],
      [1.2, 1.0, 0.8],
      [0.8, 0.6, 0.5],
    ];
    return intervals[level - 1][mode];
  }
}
