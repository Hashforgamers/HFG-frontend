import 'dart:async';
import 'dart:math';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_page.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import '../Constant/assets.dart';

enum _Phase { menu, playing, paused, over }

class _Zombie {
  _Zombie({required this.lane, required this.speed}) : x = 1.08;
  final int lane;
  final double speed; // fraction of field width per second
  double x; // 0 = house edge, 1 = right edge
}

class _Bullet {
  _Bullet(this.lane, this.x);
  final int lane;
  double x;
}

class _Pop {
  _Pop(this.lane, this.x);
  final int lane;
  final double x;
  double age = 0;
}

/// Plant vs Zombie: a five-lane shooter. Tap a lane to move the plant there
/// and fire; hold Fire for auto-fire. Zombies that reach the house cost a
/// life. One ticker drives the whole simulation.
class PlantVsZombie extends StatefulWidget {
  const PlantVsZombie({super.key});

  @override
  State<PlantVsZombie> createState() => _PlantVsZombieState();
}

class _PlantVsZombieState extends State<PlantVsZombie>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const gameId = 'plant_vs_zombie';
  static const _lanes = 5;
  static const _maxLives = 3;
  static const _plantX = 0.07;
  static const _bulletSpeed = 0.95;
  static const _fireCooldown = 0.32;
  static const _hitReach = 0.06;

  final Random _random = Random();
  final MiniGameScoreService _scores = MiniGameScoreService();
  // Created in initState: a lazy ticker would first be created in dispose()
  // when the player leaves from the menu, which isn't allowed.
  late final Ticker _ticker;

  _Phase _phase = _Phase.menu;
  Duration _lastTick = Duration.zero;

  int _plantLane = 2;
  int _score = 0;
  int _lives = _maxLives;
  int _best = 0;
  double _spawnIn = 1.2;
  double _cooldown = 0;
  bool _holdingFire = false;
  final List<_Zombie> _zombies = [];
  final List<_Bullet> _bullets = [];
  final List<_Pop> _pops = [];

  /// Bumped every tick; only the moving layer and HUD listen, so the garden,
  /// lanes and controls don't rebuild 60×/s.
  final ValueNotifier<int> _frame = ValueNotifier(0);

  // Result state.
  bool _saving = false;
  bool _synced = true;
  bool _newBest = false;

  // Audio.
  final AudioCache _audioCache = AudioCache(
    prefix: 'assets/plant_vs_zombies/sounds/',
  );
  AudioPool? _shotPool;
  AudioPlayer? _overPlayer;

  int get _wave => 1 + _score ~/ 10;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadBest());
    unawaited(_loadAudio());
  }

  Future<void> _loadBest() async {
    await _scores.ensureLoaded();
    if (mounted) setState(() => _best = _scores.bestScore(gameId));
  }

  Future<void> _loadAudio() async {
    try {
      _shotPool = await AudioPool.create(
        source: AssetSource('bullet.wav'),
        audioCache: _audioCache,
        maxPlayers: 4,
      );
      _overPlayer = AudioPlayer()..audioCache = _audioCache;
    } catch (e) {
      if (kDebugMode) AppLogger.d('PvZ audio preload failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _phase == _Phase.playing) {
      _pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frame.dispose();
    unawaited(_shotPool?.dispose());
    unawaited(_overPlayer?.dispose());
    super.dispose();
  }

  // ------------------------------------------------------------------ flow

  void _start() {
    setState(() {
      _phase = _Phase.playing;
      _plantLane = 2;
      _score = 0;
      _lives = _maxLives;
      _spawnIn = 1.2;
      _cooldown = 0;
      _zombies.clear();
      _bullets.clear();
      _pops.clear();
      _saving = false;
      _newBest = false;
    });
    _lastTick = Duration.zero;
    if (_ticker.isActive) _ticker.stop();
    _ticker.start();
  }

  void _pause() {
    if (_phase != _Phase.playing) return;
    _ticker.stop();
    setState(() {
      _phase = _Phase.paused;
      _holdingFire = false;
    });
  }

  void _resume() {
    if (_phase != _Phase.paused) return;
    _lastTick = Duration.zero;
    setState(() => _phase = _Phase.playing);
    _ticker.start();
  }

  void _toMenu() {
    _ticker.stop();
    setState(() => _phase = _Phase.menu);
  }

  Future<void> _gameOver() async {
    _ticker.stop();
    Haptics.heavy();
    unawaited(_playOver());
    await _scores.ensureLoaded();
    final isNewBest = _score > 0 && _score > _scores.bestScore(gameId);
    setState(() {
      _phase = _Phase.over;
      _holdingFire = false;
      _saving = true;
      _newBest = isNewBest;
    });
    var synced = false;
    try {
      synced = await _scores.recordScore(gameId, _score);
    } catch (e) {
      if (kDebugMode) AppLogger.d('PvZ score save failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _synced = synced;
      _best = _scores.bestScore(gameId);
    });
  }

  Future<void> _playOver() async {
    try {
      await _overPlayer?.play(AssetSource('game_over.mp3'), volume: 0.7);
    } catch (_) {}
  }

  // ------------------------------------------------------------ simulation

  void _tick(Duration elapsed) {
    final dt = _lastTick == Duration.zero
        ? 0.0
        : ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastTick = elapsed;
    if (dt == 0 || _phase != _Phase.playing) return;

    // Spawning gets faster each wave.
    _spawnIn -= dt;
    if (_spawnIn <= 0) {
      final speed = (0.075 + _wave * 0.012 + _random.nextDouble() * 0.02).clamp(
        0.075,
        0.24,
      );
      _zombies.add(_Zombie(lane: _random.nextInt(_lanes), speed: speed));
      _spawnIn =
          (2.6 - _wave * 0.22).clamp(0.75, 2.6) *
          (0.7 + _random.nextDouble() * 0.6);
    }

    // Auto-fire while Fire is held.
    _cooldown = max(0, _cooldown - dt);
    if (_holdingFire) _fire();

    for (final z in _zombies) {
      z.x -= z.speed * dt;
    }
    for (final b in _bullets) {
      b.x += _bulletSpeed * dt;
    }
    for (final p in _pops) {
      p.age += dt;
    }
    _pops.removeWhere((p) => p.age > 0.35);

    // Bullet ↔ zombie hits: the front-most zombie in the lane takes it.
    for (final b in List.of(_bullets)) {
      _Zombie? target;
      for (final z in _zombies) {
        if (z.lane == b.lane &&
            b.x >= z.x - _hitReach &&
            b.x <= z.x + _hitReach &&
            (target == null || z.x < target.x)) {
          target = z;
        }
      }
      if (target != null) {
        _bullets.remove(b);
        _zombies.remove(target);
        _pops.add(_Pop(target.lane, target.x));
        _score++;
        Haptics.light();
      } else if (b.x > 1.1) {
        _bullets.remove(b);
      }
    }

    // Zombies reaching the house cost a life.
    final arrived = _zombies.where((z) => z.x <= 0.02).toList();
    if (arrived.isNotEmpty) {
      _zombies.removeWhere(arrived.contains);
      _lives -= arrived.length;
      Haptics.medium();
      if (_lives <= 0) {
        _lives = 0;
        unawaited(_gameOver());
        return;
      }
    }
    _frame.value++;
  }

  void _fire() {
    if (_phase != _Phase.playing || _cooldown > 0) return;
    _cooldown = _fireCooldown;
    _bullets.add(_Bullet(_plantLane, _plantX + 0.05));
    try {
      unawaited(_shotPool?.start(volume: 0.35));
    } catch (_) {}
  }

  void _moveTo(int lane) {
    if (_phase != _Phase.playing) return;
    setState(() => _plantLane = lane.clamp(0, _lanes - 1));
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        switch (_phase) {
          case _Phase.playing:
            _pause();
          case _Phase.paused:
            _resume();
          case _Phase.over:
            _toMenu();
          case _Phase.menu:
            Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: GameColors.bgBottom,
        // Expand so the Stack fills the screen instead of sizing to the HUD
        // (its only non-positioned child).
        body: SizedBox.expand(
          child: Stack(
            children: [
              Positioned.fill(child: _field()),
              if (_phase == _Phase.playing || _phase == _Phase.paused)
                RepaintBoundary(child: _hud()),
              if (_phase == _Phase.menu) RepaintBoundary(child: _menu()),
              if (_phase == _Phase.paused)
                RepaintBoundary(child: _pausePanel()),
              if (_phase == _Phase.over) RepaintBoundary(child: _resultPanel()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field() {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth;
              final h = box.maxHeight;
              final top = MediaQuery.of(context).padding.top + 70;
              final laneH = (h - top - 8) / _lanes;
              double laneY(int lane) => top + laneH * lane;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) {
                  final lane = ((d.localPosition.dy - top) / laneH).floor();
                  if (lane < 0 || lane >= _lanes) return;
                  _moveTo(lane);
                  _fire();
                },
                onVerticalDragUpdate: (d) {
                  final lane = ((d.localPosition.dy - top) / laneH).floor();
                  if (lane >= 0 && lane < _lanes && lane != _plantLane) {
                    _moveTo(lane);
                  }
                },
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Static layer: cached raster, decoded at screen size.
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: Image.asset(
                          Assets.garden,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                          cacheWidth:
                              (w * MediaQuery.devicePixelRatioOf(context) * 1.4)
                                  .round(),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.05),
                            ],
                            stops: const [0, 0.25],
                          ),
                        ),
                      ),
                    ),
                    // Lane strips (active lane highlighted).
                    for (var i = 0; i < _lanes; i++)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: laneY(i),
                        height: laneH,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          decoration: BoxDecoration(
                            color: i == _plantLane && _phase != _Phase.menu
                                ? Colors.white.withValues(alpha: 0.10)
                                : (i.isEven
                                      ? Colors.black.withValues(alpha: 0.06)
                                      : Colors.transparent),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // House edge.
                    Positioned(
                      left: 0,
                      top: top,
                      bottom: 8,
                      width: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              GameColors.red.$2.withValues(alpha: 0.9),
                              GameColors.red.$2.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Moving layer: rebuilt every tick, repainted on its own.
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: ValueListenableBuilder<int>(
                          valueListenable: _frame,
                          builder: (context, _, _) => Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (final z in _zombies)
                                Positioned(
                                  left: z.x * w - laneH * 0.45,
                                  top: laneY(z.lane) + laneH * 0.05,
                                  width: laneH * 0.9,
                                  height: laneH * 0.9,
                                  child: Image.asset(
                                    Assets.zombieMock,
                                    gaplessPlayback: true,
                                  ),
                                ),
                              for (final b in _bullets)
                                Positioned(
                                  left: b.x * w - 11,
                                  top: laneY(b.lane) + laneH / 2 - 11,
                                  width: 22,
                                  height: 22,
                                  child: Image.asset(
                                    Assets.bulletMock,
                                    cacheWidth: 64,
                                  ),
                                ),
                              for (final p in _pops)
                                Positioned(
                                  left: p.x * w - 24,
                                  top: laneY(p.lane) + laneH / 2 - 24,
                                  width: 48,
                                  height: 48,
                                  child: Opacity(
                                    opacity: (1 - p.age / 0.35).clamp(0, 1),
                                    child: Transform.scale(
                                      scale: 0.8 + p.age * 2,
                                      child: const Center(
                                        child: Text(
                                          '💥',
                                          style: TextStyle(fontSize: 34),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_phase != _Phase.menu)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 110),
                        curve: Curves.easeOut,
                        left: max(2.0, _plantX * w - laneH * 0.4),
                        top: laneY(_plantLane) + laneH * 0.1,
                        width: laneH * 0.8,
                        height: laneH * 0.8,
                        // Own layer: GIF frames shouldn't repaint the field.
                        child: RepaintBoundary(
                          child: Image.asset(
                            Assets.plantMock,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        if (_phase == _Phase.playing || _phase == _Phase.paused)
          RepaintBoundary(child: _controls()),
      ],
    );
  }

  Widget _controls() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [GameColors.bodyTop, GameColors.bodyBottom],
        ),
        border: Border(top: BorderSide(color: GameColors.outline, width: 3)),
      ),
      child: Row(
        children: [
          GameIconButton(
            icon: Icons.keyboard_arrow_up_rounded,
            size: 54,
            tooltip: 'Move up',
            onPressed: () => _moveTo(_plantLane - 1),
          ),
          const SizedBox(width: 8),
          GameIconButton(
            icon: Icons.keyboard_arrow_down_rounded,
            size: 54,
            tooltip: 'Move down',
            onPressed: () => _moveTo(_plantLane + 1),
          ),
          const SizedBox(width: 12),
          Expanded(
            // Hold to auto-fire.
            child: Listener(
              onPointerDown: (_) {
                _holdingFire = true;
                _fire();
              },
              onPointerUp: (_) => _holdingFire = false,
              onPointerCancel: (_) => _holdingFire = false,
              child: GameButton(
                label: 'Fire',
                subtitle: 'hold to auto-fire',
                icon: Icons.local_florist_rounded,
                tone: GameButtonTone.green,
                height: 58,
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hud() {
    return ValueListenableBuilder<int>(
      valueListenable: _frame,
      builder: (context, _, _) => _hudContent(),
    );
  }

  Widget _hudContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
        child: Row(
          children: [
            GameIconButton(
              icon: Icons.pause_rounded,
              tooltip: 'Pause',
              onPressed: _pause,
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
              decoration: BoxDecoration(
                color: GameColors.outline.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GameColors.outline, width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _maxLives; i++)
                    Opacity(
                      opacity: i < _lives ? 1 : 0.3,
                      child: Text(
                        i < _lives ? '❤️' : '🖤',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            GameBadge(label: 'WAVE $_wave'),
            const SizedBox(width: 8),
            Image.asset(Assets.zombieHead, width: 30, height: 36),
            const SizedBox(width: 4),
            GameText('$_score', size: 32),
          ],
        ),
      ),
    );
  }

  Widget _menu() {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  children: [
                    GameIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Exit',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    GameBadge(label: '🏆 BEST $_best'),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: GamePanel(
                        headerColors: GameColors.green,
                        headerHeight: 92,
                        header: Row(
                          children: [
                            Image.asset(
                              Assets.zombieHead,
                              width: 52,
                              height: 64,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const GameText('PLANT vs ZOMBIE', size: 26),
                                  Text(
                                    'Hold the lawn. Save the house.',
                                    style: gameFont(
                                      13,
                                      GameColors.outline.withValues(
                                        alpha: 0.72,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GameTray(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  _rule(
                                    '👆',
                                    'Tap a lane',
                                    'move there and shoot',
                                  ),
                                  _rule('🌱', 'Hold Fire', 'for auto-fire'),
                                  _rule('🧟', 'Stop zombies', '+1 point each'),
                                  _rule(
                                    '🏠',
                                    'One reaches home',
                                    'lose a heart',
                                  ),
                                  _rule(
                                    '🌊',
                                    'Every 10 kills',
                                    'a faster wave',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            GameButton(
                              label: 'Play',
                              icon: Icons.play_arrow_rounded,
                              tone: GameButtonTone.green,
                              height: 58,
                              onPressed: _start,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rule(String emoji, String title, String detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: gameFont(15, Colors.white)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            detail,
            overflow: TextOverflow.ellipsis,
            style: gameFont(13, GameColors.soft),
          ),
        ),
      ],
    ),
  );

  Widget _modal(Widget panel) => ColoredBox(
    color: Colors.black.withValues(alpha: 0.6),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: panel,
        ),
      ),
    ),
  );

  Widget _pausePanel() => _modal(
    GamePanel(
      headerColors: GameColors.purple,
      header: const Center(child: GameText('PAUSED', size: 28)),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Score $_score · Wave $_wave',
            textAlign: TextAlign.center,
            style: gameFont(16, GameColors.soft),
          ),
          const SizedBox(height: 14),
          GameButton(
            label: 'Resume',
            icon: Icons.play_arrow_rounded,
            tone: GameButtonTone.green,
            onPressed: _resume,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'Restart',
                  tone: GameButtonTone.yellow,
                  height: 46,
                  onPressed: _start,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: 'Quit',
                  tone: GameButtonTone.red,
                  height: 46,
                  onPressed: _toMenu,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _resultPanel() => _modal(
    GamePanel(
      headerColors: GameColors.red,
      headerHeight: 72,
      header: const Center(child: GameText('THE ZOMBIES WON', size: 26)),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text('ZOMBIES STOPPED', style: gameFont(13, GameColors.soft)),
                GameText('$_score', size: 56, color: GameColors.yellow.$1),
                const SizedBox(height: 4),
                if (_saving)
                  Text('Saving score…', style: gameFont(13, GameColors.soft))
                else if (_newBest)
                  const GameBadge(label: '⭐ NEW BEST!')
                else
                  Text(
                    _synced
                        ? 'Saved to leaderboard'
                        : 'Couldn’t sync. Check your connection.',
                    style: gameFont(
                      13,
                      _synced ? GameColors.soft : const Color(0xFFFF8A80),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  'Reached wave $_wave',
                  style: gameFont(13, GameColors.soft),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GameButton(
            label: 'Play Again',
            icon: Icons.refresh_rounded,
            tone: GameButtonTone.green,
            onPressed: _start,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'Menu',
                  tone: GameButtonTone.purple,
                  height: 46,
                  onPressed: _toMenu,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: 'Ranks',
                  icon: Icons.emoji_events_rounded,
                  tone: GameButtonTone.yellow,
                  height: 46,
                  onPressed: () => Get.to(
                    () => MiniGameLeaderboardPage(
                      scoreService: _scores,
                      leaderboardService: MiniGameLeaderboardService(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
