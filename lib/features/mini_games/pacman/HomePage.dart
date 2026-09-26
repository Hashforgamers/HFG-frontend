import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:hash/features/mini_games/common/game_sfx.dart';
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

import 'pacman_engine.dart';

enum _Phase { menu, ready, playing, dying, paused, over }

/// Pac-Man: swipe (or use the pad) to steer, eat every dot, dodge ghosts.
/// A single ticker drives [PacEngine]; the maze is painted once and cached.
class PacManHome extends StatefulWidget {
  const PacManHome({super.key});

  @override
  State<PacManHome> createState() => _PacManHomeState();
}

class _PacManHomeState extends State<PacManHome>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const gameId = 'pac_man';

  final PacEngine _engine = PacEngine();
  final MiniGameScoreService _scores = MiniGameScoreService();
  final ValueNotifier<int> _frame = ValueNotifier(0);

  /// Only changes when score/lives/level change, so the HUD's outlined text
  /// isn't rebuilt every frame.
  final ValueNotifier<(int, int, int)> _hudState = ValueNotifier((0, 3, 1));
  late final Ticker _ticker;

  _Phase _phase = _Phase.menu;
  _Phase _pausedFrom = _Phase.playing;
  Duration _last = Duration.zero;
  double _phaseTimer = 0;
  String? _banner;
  int _best = 0;

  // Result.
  bool _saving = false;
  bool _synced = true;
  bool _newBest = false;

  // Audio.
  final GameSfx _sfx = GameSfx(prefix: 'assets/pacman/', voices: 2);
  DateTime _lastChomp = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick);
    WidgetsBinding.instance.addObserver(this);
    _engine.newGame();
    unawaited(_loadBest());
    unawaited(_loadAudio());
  }

  Future<void> _loadBest() async {
    await _scores.ensureLoaded();
    if (mounted) setState(() => _best = _scores.bestScore(gameId));
  }

  Future<void> _loadAudio() => _sfx.load(const [
    'pacman_chomp.wav',
    'pacman_beginning.wav',
    'pacman_death.wav',
    'pacman_intermission.wav',
  ]);

  void _playFx(String file) => _sfx.play(file, volume: 0.6);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frame.dispose();
    _hudState.dispose();
    unawaited(_sfx.dispose());
    super.dispose();
  }

  // ------------------------------------------------------------------ flow

  void _start() {
    _engine.newGame();
    _saving = false;
    _newBest = false;
    _enterReady();
    _playFx('pacman_beginning.wav');
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _enterReady() {
    setState(() {
      _phase = _Phase.ready;
      _phaseTimer = 2.2;
      _banner = _engine.level == 1 ? 'READY!' : 'LEVEL ${_engine.level}';
    });
  }

  void _pause() {
    if (_phase != _Phase.playing && _phase != _Phase.ready) return;
    _pausedFrom = _phase;
    _ticker.stop();
    setState(() => _phase = _Phase.paused);
  }

  void _resume() {
    if (_phase != _Phase.paused) return;
    setState(() => _phase = _pausedFrom);
    _last = Duration.zero;
    _ticker.start();
  }

  void _toMenu() {
    _ticker.stop();
    _engine.newGame();
    setState(() {
      _phase = _Phase.menu;
      _banner = null;
    });
  }

  Future<void> _gameOver() async {
    _ticker.stop();
    await _scores.ensureLoaded();
    final score = _engine.score;
    final isNewBest = score > 0 && score > _scores.bestScore(gameId);
    setState(() {
      _phase = _Phase.over;
      _banner = null;
      _saving = true;
      _newBest = isNewBest;
    });
    var synced = false;
    try {
      synced = await _scores.recordScore(gameId, score);
    } catch (e) {
      if (kDebugMode) AppLogger.d('Pac-Man score save failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _synced = synced;
      _best = _scores.bestScore(gameId);
    });
  }

  void _steer(PacDir dir) {
    if (_phase != _Phase.playing && _phase != _Phase.ready) return;
    _engine.wanted = dir;
  }

  // ------------------------------------------------------------ simulation

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    if (dt == 0) return;

    switch (_phase) {
      case _Phase.ready:
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          setState(() {
            _phase = _Phase.playing;
            _banner = null;
          });
        }
      case _Phase.playing:
        final alive = _engine.update(dt);
        for (final e in _engine.events) {
          switch (e) {
            case 'dot':
              final now = DateTime.now();
              if (now.difference(_lastChomp).inMilliseconds > 140) {
                _lastChomp = now;
                _sfx.play('pacman_chomp.wav', volume: 0.35);
              }
            case 'pellet':
              Haptics.medium();
            case 'ghost':
              Haptics.success();
              _playFx('pacman_intermission.wav');
          }
        }
        if (!alive) {
          Haptics.heavy();
          _playFx('pacman_death.wav');
          setState(() {
            _phase = _Phase.dying;
            _phaseTimer = 1.4;
          });
        } else if (_engine.levelCleared) {
          Haptics.success();
          _engine.nextLevel();
          _enterReady();
        }
      case _Phase.dying:
        _phaseTimer -= dt;
        if (_phaseTimer <= 0) {
          if (_engine.lives <= 0) {
            unawaited(_gameOver());
            return;
          }
          _engine.resetPositions();
          _enterReady();
        }
      case _Phase.menu:
      case _Phase.paused:
      case _Phase.over:
        break;
    }
    _frame.value++;
    _hudState.value = (_engine.score, _engine.lives, _engine.level);
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
          case _Phase.ready:
          case _Phase.dying:
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
        body: SizedBox.expand(
          child: Stack(
            children: [
              const GameBackground(),
              SafeArea(
                child: Column(
                  children: [
                    RepaintBoundary(child: _hud()),
                    Expanded(child: _boardArea()),
                    RepaintBoundary(child: _pad()),
                  ],
                ),
              ),
              if (_phase == _Phase.menu) _menu(),
              if (_phase == _Phase.paused) _pausePanel(),
              if (_phase == _Phase.over) _resultPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hud() {
    final showControls = _phase != _Phase.menu;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: ValueListenableBuilder<(int, int, int)>(
        valueListenable: _hudState,
        builder: (context, _, _) => Row(
          children: [
            GameIconButton(
              icon: showControls
                  ? Icons.pause_rounded
                  : Icons.arrow_back_rounded,
              tooltip: showControls ? 'Pause' : 'Exit',
              onPressed: showControls
                  ? _pause
                  : () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 10),
            if (showControls)
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
                    for (var i = 0; i < PacEngine.startLives; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Opacity(
                          opacity: i < _engine.lives ? 1 : 0.25,
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CustomPaint(painter: _PacIconPainter()),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            const Spacer(),
            if (showControls) ...[
              GameBadge(label: 'LV ${_engine.level}'),
              const SizedBox(width: 8),
              GameText('${_engine.score}', size: 30),
            ],
          ],
        ),
      ),
    );
  }

  Widget _boardArea() {
    return LayoutBuilder(
      builder: (context, box) {
        final cell = min(
          (box.maxWidth - 24) / kPacCols,
          (box.maxHeight - 13) / kPacRows,
        ).floorToDouble();
        final w = cell * kPacCols, h = cell * kPacRows;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) {
            final v = d.delta;
            if (v.distance < 2.5) return;
            if (v.dx.abs() > v.dy.abs()) {
              _steer(v.dx > 0 ? PacDir.right : PacDir.left);
            } else {
              _steer(v.dy > 0 ? PacDir.down : PacDir.up);
            }
          },
          child: Center(
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 9),
              decoration: BoxDecoration(
                color: GameColors.outline,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x80000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: w,
                  height: h,
                  child: Stack(
                    children: [
                      Positioned.fill(child: _MazeImage(cell: cell)),
                      Positioned.fill(
                        child: RepaintBoundary(
                          child: CustomPaint(
                            painter: _ActorsPainter(
                              engine: _engine,
                              cell: cell,
                              repaint: _frame,
                              phase: () => _phase,
                              phaseTimer: () => _phaseTimer,
                            ),
                          ),
                        ),
                      ),
                      if (_banner != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: cell * 11,
                          height: cell,
                          child: Center(
                            child: GameText(
                              _banner!,
                              size: cell * 0.95,
                              color: GameColors.yellow.$1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pad() {
    if (_phase == _Phase.menu) return const SizedBox(height: 12);
    Widget b(IconData icon, PacDir dir) =>
        GameIconButton(icon: icon, size: 50, onPressed: () => _steer(dir));
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          b(Icons.keyboard_arrow_left_rounded, PacDir.left),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              b(Icons.keyboard_arrow_up_rounded, PacDir.up),
              const SizedBox(height: 4),
              b(Icons.keyboard_arrow_down_rounded, PacDir.down),
            ],
          ),
          const SizedBox(width: 10),
          b(Icons.keyboard_arrow_right_rounded, PacDir.right),
          const SizedBox(width: 16),
          Text('or swipe\non the maze', style: gameFont(12, GameColors.soft)),
        ],
      ),
    );
  }

  Widget _modal(Widget panel) => Positioned.fill(
    child: ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: panel,
          ),
        ),
      ),
    ),
  );

  Widget _menu() => _modal(
    GamePanel(
      headerColors: GameColors.yellow,
      headerHeight: 92,
      header: Row(
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CustomPaint(painter: _PacIconPainter()),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GameText('PAC-MAN', size: 32),
                Text(
                  'Eat the dots. Dodge the ghosts.',
                  style: gameFont(
                    13,
                    GameColors.outline.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Spacer(),
              GameBadge(label: '🏆 BEST $_best'),
            ],
          ),
          const SizedBox(height: 8),
          GameTray(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _rule('👆', 'Swipe', 'or use the arrows'),
                _rule('🟡', 'Dots', '+1 point each'),
                _rule('⚡', 'Power pellet', 'ghosts turn blue'),
                _rule('👻', 'Blue ghosts', '+20 · 40 · 80 · 160'),
                _rule('❤️', '3 lives', 'faster every level'),
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
  );

  Widget _rule(String emoji, String title, String detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
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
            'Score ${_engine.score} · Level ${_engine.level}',
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
      header: const Center(child: GameText('GAME OVER', size: 30)),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Text('SCORE', style: gameFont(13, GameColors.soft)),
                GameText(
                  '${_engine.score}',
                  size: 56,
                  color: GameColors.yellow.$1,
                ),
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
                  'Reached level ${_engine.level}',
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

// ---------------------------------------------------------------- painters

/// Walls with neon edges only where they meet open space; painted once.
class _MazePainter extends CustomPainter {
  const _MazePainter(this.cell);

  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFF05041A),
    );
    final fill = Paint()..color = const Color(0xFF1B1766);
    final edge = Paint()
      ..color = const Color(0xFF6E8BFF)
      ..strokeWidth = max(1.5, cell * 0.09)
      ..strokeCap = StrokeCap.round;
    final glow = Paint()
      ..color = const Color(0x556E8BFF)
      ..strokeWidth = max(3, cell * 0.28)
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, cell * 0.12);

    bool wall(int x, int y) {
      final c = PacEngine.cell(x, y);
      return c == '#' || c == 'X';
    }

    final edges = <(Offset, Offset)>[];
    for (var y = 0; y < kPacRows; y++) {
      for (var x = 0; x < kPacCols; x++) {
        final c = kPacMaze[y][x];
        if (c == 'X') continue;
        if (c == '-') {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, (y + 0.42) * cell, cell, cell * 0.16),
            Paint()..color = const Color(0xFFFF9EC7),
          );
          continue;
        }
        if (c != '#') continue;
        final r = Rect.fromLTWH(x * cell, y * cell, cell, cell);
        canvas.drawRect(r.inflate(0.5), fill);
        final inset = cell * 0.18;
        if (!wall(x, y - 1) && y > 0) {
          edges.add((
            Offset(r.left, r.top + inset),
            Offset(r.right, r.top + inset),
          ));
        }
        if (!wall(x, y + 1) && y < kPacRows - 1) {
          edges.add((
            Offset(r.left, r.bottom - inset),
            Offset(r.right, r.bottom - inset),
          ));
        }
        if (!wall(x - 1, y) && x > 0) {
          edges.add((
            Offset(r.left + inset, r.top),
            Offset(r.left + inset, r.bottom),
          ));
        }
        if (!wall(x + 1, y) && x < kPacCols - 1) {
          edges.add((
            Offset(r.right - inset, r.top),
            Offset(r.right - inset, r.bottom),
          ));
        }
      }
    }
    for (final (a, b) in edges) {
      canvas.drawLine(a, b, glow);
    }
    for (final (a, b) in edges) {
      canvas.drawLine(a, b, edge);
    }
  }

  @override
  bool shouldRepaint(_MazePainter old) => old.cell != cell;
}

class _ActorsPainter extends CustomPainter {
  _ActorsPainter({
    required this.engine,
    required this.cell,
    required Listenable repaint,
    required this.phase,
    required this.phaseTimer,
  }) : super(repaint: repaint);

  final PacEngine engine;
  final double cell;
  final _Phase Function() phase;
  final double Function() phaseTimer;

  static const _ghostColors = [
    Color(0xFFFF3B3B),
    Color(0xFFFF9EDB),
    Color(0xFF3BE8FF),
    Color(0xFFFFB347),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final e = engine;
    final pulse = 0.75 + 0.25 * sin(e.elapsed * 8);

    // Dots and pellets.
    final dot = Paint()..color = const Color(0xFFFFE0B0);
    for (final k in e.dots) {
      final c = _center(k % kPacCols + 0.0, k ~/ kPacCols + 0.0);
      canvas.drawCircle(c, cell * 0.11, dot);
    }
    final pellet = Paint()..color = const Color(0xFFFFE0B0);
    for (final k in e.pellets) {
      final c = _center(k % kPacCols + 0.0, k ~/ kPacCols + 0.0);
      canvas.drawCircle(c, cell * 0.3 * pulse, pellet);
    }

    final dying = phase() == _Phase.dying;
    if (!dying) {
      for (final g in e.ghosts) {
        _drawGhost(canvas, g);
      }
    }
    _drawPac(canvas, dying);
  }

  Offset _center(double x, double y) =>
      Offset((x + 0.5) * cell, (y + 0.5) * cell);

  Offset _wrapped(double px, double py) {
    var x = px;
    if (x < -0.5) x += kPacCols;
    if (x > kPacCols - 0.5) x -= kPacCols;
    return _center(x, py);
  }

  void _drawPac(Canvas canvas, bool dying) {
    final p = engine.player;
    final c = _wrapped(p.px, p.py);
    final r = cell * 0.46;
    double mouth;
    if (dying) {
      // Mouth opens all the way as it deflates.
      final t = (1 - phaseTimer() / 1.4).clamp(0.0, 1.0);
      mouth = pi * 0.05 + t * pi * 0.95;
    } else {
      final moving = p.dir != PacDir.none;
      final phaseT = moving ? (p.t * 2 * pi) : 0.0;
      mouth = 0.08 + 0.32 * (0.5 + 0.5 * sin(phaseT)).clamp(0.0, 1.0);
    }
    final facing = switch (p.dir == PacDir.none ? engine.wanted : p.dir) {
      PacDir.left => pi,
      PacDir.up => -pi / 2,
      PacDir.down => pi / 2,
      _ => 0.0,
    };
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(
      rect.inflate(cell * 0.05),
      facing + mouth,
      2 * pi - mouth * 2,
      true,
      Paint()..color = const Color(0xFF0B0B10),
    );
    canvas.drawArc(
      rect,
      facing + mouth,
      2 * pi - mouth * 2,
      true,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF27A), Color(0xFFFFC400)],
          center: Alignment(-0.3, -0.4),
        ).createShader(rect),
    );
  }

  void _drawGhost(Canvas canvas, PacGhost g) {
    final c = _wrapped(g.px, g.py);
    final w = cell * 0.9, h = cell * 0.92;
    final left = c.dx - w / 2, top = c.dy - h / 2;
    final frightened = g.mode == GhostMode.frightened;
    final flashing = frightened && engine.frightLeft < 2;
    final flashWhite = flashing && (engine.elapsed * 6).floor().isEven;
    final body = frightened
        ? (flashWhite ? const Color(0xFFF2F2FF) : const Color(0xFF2A3DFF))
        : _ghostColors[g.index];

    final path = Path()
      ..moveTo(left, top + h * 0.5)
      ..arcTo(Rect.fromLTWH(left, top, w, w), pi, pi, false)
      ..lineTo(left + w, top + h);
    const waves = 3;
    final seg = w / waves;
    final wobble = (engine.elapsed * 10).floor().isEven ? 0.0 : seg / 2;
    for (var i = 0; i < waves; i++) {
      final x0 = left + w - i * seg;
      path.quadraticBezierTo(
        x0 - seg * 0.25 - wobble * 0.2,
        top + h - cell * 0.14,
        x0 - seg * 0.5,
        top + h,
      );
      path.quadraticBezierTo(
        x0 - seg * 0.75,
        top + h - cell * 0.14,
        x0 - seg,
        top + h,
      );
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF0B0B10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * 0.08
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(path, Paint()..color = body);

    if (frightened) {
      final face = flashWhite
          ? const Color(0xFFFF3B3B)
          : const Color(0xFFFFE0B0);
      for (final s in [-1.0, 1.0]) {
        canvas.drawCircle(
          Offset(c.dx + s * w * 0.18, top + h * 0.4),
          cell * 0.07,
          Paint()..color = face,
        );
      }
      final mouth = Path()..moveTo(left + w * 0.2, top + h * 0.68);
      for (var i = 1; i <= 6; i++) {
        mouth.lineTo(
          left + w * (0.2 + i * 0.1),
          top + h * (i.isOdd ? 0.6 : 0.68),
        );
      }
      canvas.drawPath(
        mouth,
        Paint()
          ..color = face
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.05,
      );
      return;
    }

    final look = Offset(g.dir.dx * cell * 0.06, g.dir.dy * cell * 0.06);
    for (final s in [-1.0, 1.0]) {
      final eye = Offset(c.dx + s * w * 0.2, top + h * 0.4);
      canvas.drawOval(
        Rect.fromCenter(center: eye, width: w * 0.28, height: w * 0.34),
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        eye + look,
        w * 0.08,
        Paint()..color = const Color(0xFF1A2BFF),
      );
    }
  }

  @override
  bool shouldRepaint(_ActorsPainter old) => old.cell != cell;
}

class _PacIconPainter extends CustomPainter {
  const _PacIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    canvas.drawArc(
      rect,
      0.55,
      2 * pi - 1.1,
      true,
      Paint()..color = const Color(0xFF0B0B10),
    );
    canvas.drawArc(
      rect.deflate(r * 0.12),
      0.55,
      2 * pi - 1.1,
      true,
      Paint()..color = const Color(0xFFFFD60A),
    );
  }

  @override
  bool shouldRepaint(_PacIconPainter old) => false;
}

/// Renders [_MazePainter] to an image once per size: the glow blur is too
/// costly to replay every frame on renderers without a raster cache.
class _MazeImage extends StatefulWidget {
  const _MazeImage({required this.cell});

  final double cell;

  @override
  State<_MazeImage> createState() => _MazeImageState();
}

class _MazeImageState extends State<_MazeImage> {
  ui.Image? _image;
  double _for = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _render();
  }

  @override
  void didUpdateWidget(_MazeImage old) {
    super.didUpdateWidget(old);
    if (old.cell != widget.cell) _render();
  }

  Future<void> _render() async {
    final cell = widget.cell;
    if (cell <= 0 || cell == _for) return;
    _for = cell;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final size = Size(cell * kPacCols, cell * kPacRows);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(dpr);
    _MazePainter(cell).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (size.width * dpr).ceil(),
      (size.height * dpr).ceil(),
    );
    picture.dispose();
    if (!mounted || cell != widget.cell) {
      image.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = image;
    });
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const ColoredBox(color: Color(0xFF05041A));
    }
    return RawImage(image: image, fit: BoxFit.fill);
  }
}
