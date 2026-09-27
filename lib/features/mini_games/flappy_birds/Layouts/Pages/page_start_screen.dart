import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_invite_friends_sheet.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_page.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import '../../Database/database.dart';
import '../../Global/constant.dart';
import '../../Resources/strings.dart';
import '../../online/bird_match.dart';
import '../../online/bird_match_service.dart';
import '../Widgets/bird_skins.dart';

enum _Phase {
  menu,
  ready,
  playing,
  paused,
  over,
  // Online race.
  lobby,
  countdown,
  spectate,
  raceOver,
}

/// Difficulty presets. `level` is the legacy value persisted under "level".
enum _Difficulty {
  easy('Easy', 0.05, 0.40, 0.29),
  medium('Medium', 0.08, 0.50, 0.26),
  hard('Hard', 0.1, 0.60, 0.235);

  const _Difficulty(this.label, this.level, this.speed, this.gap);
  final String label;
  final double level;

  /// Pipe speed in screen widths per second.
  final double speed;

  /// Pipe gap as a fraction of the sky height.
  final double gap;

  static _Difficulty fromLevel(Object? v) {
    final d = (v is num) ? v.toDouble() : 0.05;
    if (d >= 0.095) return hard;
    if (d >= 0.065) return medium;
    return easy;
  }

  static _Difficulty fromName(String name) =>
      values.firstWhere((d) => d.name == name, orElse: () => easy);
}

class _Pipe {
  _Pipe(this.x, this.gapTop);
  final double x;
  final double gapTop;
}

/// Bird physics in sky-relative units (y is a fraction of the sky height) on a
/// fixed 120 Hz step, so a flap log replays to the identical path anywhere.
class _Physics {
  static const hz = 120;
  static const step = 1 / hz;
  static const startY = 0.42;
  static const ceil = 0.045;
  static const flapV = -0.78;
  static const gravity = 2.6;
  static const maxFall = 1.3;

  /// Run-time ms of step [n] (what gets logged for a flap on that step).
  static int msOf(int n) => (n * 1000 / hz).round();

  static (double, double) advance(double y, double v, bool flap) {
    if (flap) v = flapV;
    v = min(v + gravity * step, maxFall);
    y += v * step;
    if (y < ceil) {
      y = ceil;
      v = 0;
    }
    return (y, v);
  }
}

/// An opponent replayed from their flap log.
class _Ghost {
  _Ghost(this.uid);

  final String uid;
  List<int> flaps = const [];
  int steps = 0;
  int _next = 0;
  double y = _Physics.startY;
  double v = 0;
  double shownY = _Physics.startY;

  /// Step at which the local replay hit something (fallback if their crash
  /// report never arrives, e.g. they closed the app).
  int? localCrashStep;

  void setFlaps(List<int> f) {
    if (listEquals(f, flaps)) return;
    flaps = f;
    // A late flap may predate where we've replayed to; rewind and catch up.
    steps = 0;
    _next = 0;
    y = _Physics.startY;
    v = 0;
    localCrashStep = null;
  }

  void advanceTo(int target, bool Function(double y, int step) hits) {
    while (steps < target && localCrashStep == null) {
      steps++;
      final ms = _Physics.msOf(steps);
      var flap = false;
      while (_next < flaps.length && flaps[_next] <= ms) {
        flap = true;
        _next++;
      }
      final next = _Physics.advance(y, v, flap);
      y = next.$1;
      v = next.$2;
      if (hits(y, steps)) localCrashStep = steps;
    }
  }
}

/// Laggy Bird: tap to flap through the pipes, solo or racing friends online
/// (opponents fly as ghost birds on the same course). One vsync ticker drives
/// the fixed-step simulation; menu, lobby and results use the game panels.
class FlappyBirds extends StatefulWidget {
  const FlappyBirds({super.key, this.matchId});

  /// Opens straight into this online race (from an invite link).
  final String? matchId;

  @override
  State<FlappyBirds> createState() => _FlappyBirdsState();
}

class _FlappyBirdsState extends State<FlappyBirds>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const gameId = 'laggy_bird';
  static const _pngBirds = [
    'assets/flappy_birds/pics/bird.png',
    'assets/flappy_birds/pics/blue.png',
    'assets/flappy_birds/pics/green.png',
  ];
  static final _birds = [
    ..._pngBirds,
    for (final skin in BirdSkin.all) skin.key,
  ];
  static const _themes = ['0', '1', '2'];

  // Course layout, in sky widths.
  static const _startX = 1.25;
  static const _spacingN = 0.62;
  static const _pipeWN = 0.19;
  static const _birdXN = 0.28;

  final MiniGameScoreService _scores = MiniGameScoreService();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;

  _Phase _phase = _Phase.menu;
  _Difficulty _difficulty = _Difficulty.easy;
  bool _music = true;

  // Run state. `_steps` counts fixed physics steps since the run began.
  Size _sky = Size.zero;
  int _steps = 0;
  double _acc = 0;
  double _y = _Physics.startY;
  double _v = 0;
  bool _flapQueued = false;
  double _bob = 0;
  Random _course = Random();
  final List<double> _gaps = [];
  int _score = 0;

  int _best = 0;
  bool _saving = false;
  bool _synced = true;
  bool _newBest = false;

  // Online race.
  final BirdMatchService _net = BirdMatchService();
  String? _matchId;
  BirdMatch? _match;
  StreamSubscription<BirdMatch?>? _matchSub;
  StreamSubscription<Map<String, BirdRun>>? _runsSub;
  final Map<String, _Ghost> _ghosts = {};
  final Set<String> _reportedForOthers = {};
  BirdFlapUploader? _uploader;
  int _round = 0;
  double _viewT = 0;
  bool _busy = false;

  bool get _online => _matchId != null;
  double get _t => _steps * _Physics.step;
  double get _birdX => _sky.width * _birdXN;
  double get _birdSize => _sky.width * 0.15;
  double get _pipeW => _sky.width * _pipeWN;
  double get _gapPx => _sky.height * _difficulty.gap;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _ticker.start(); // idle bob on the menu
    unawaited(_loadBest());
    final invite = widget.matchId;
    if (invite != null && invite.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _joinRace(invite));
    }
  }

  void _loadSettings() {
    final bird = read('bird');
    if (bird is String && _birds.contains(bird)) Str.bird = bird;
    final bg = read('background');
    if (bg is String && _themes.contains(bg)) Str.image = bg;
    _difficulty = _Difficulty.fromLevel(read('level'));
    barrierMovement = _difficulty.level;
    final audio = read('audio');
    _music = audio is bool ? audio : true;
    play = _music;
    unawaited(_applyMusic());
  }

  Future<void> _applyMusic() async {
    try {
      if (_music) {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('flappy_birds/audio/Tintin.mp3'));
      } else {
        await player.stop();
      }
    } catch (e) {
      if (kDebugMode) AppLogger.d('Laggy Bird music failed: $e');
    }
  }

  Future<void> _loadBest() async {
    await _scores.ensureLoaded();
    if (mounted) setState(() => _best = _scores.bestScore(gameId));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final b in _pngBirds) {
      precacheImage(AssetImage(b), context);
    }
    precacheImage(_bgImage, context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_online) _pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _frame.dispose();
    _matchSub?.cancel();
    _runsSub?.cancel();
    final id = _matchId;
    if (id != null) unawaited(_net.leaveMatch(id).catchError((_) {}));
    unawaited(player.stop().catchError((_) {}));
    super.dispose();
  }

  AssetImage get _bgImage =>
      AssetImage('assets/flappy_birds/pics/${Str.image}.png');

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------- course

  /// Gap top (fraction of sky height) of pipe [i], drawn in order from the
  /// run's seeded RNG so every racer gets the same course.
  double _gapAt(int i) {
    while (_gaps.length <= i) {
      const minTop = 0.12;
      final maxTop = 0.88 - _difficulty.gap;
      _gaps.add(minTop + _course.nextDouble() * max(0, maxTop - minTop));
    }
    return _gaps[i];
  }

  double _pipeXN(int i, double t) =>
      _startX + i * _spacingN - _difficulty.speed * t;

  int _passedAt(double t) {
    final v =
        (_difficulty.speed * t + _birdXN - 0.045 - _pipeWN - _startX) /
        _spacingN;
    return v <= 0 ? 0 : v.ceil();
  }

  /// Does a bird at sky fraction [yN] hit the ground or a pipe at time [t]?
  bool _hits(double yN, double t) {
    if (_sky.isEmpty) return false;
    final by = yN * _sky.height;
    final r = _birdSize * 0.36; // forgiving hitbox
    if (by + r >= _sky.height) return true;
    final first = max(
      0,
      ((_difficulty.speed * t - _startX + _birdXN - _pipeWN) / _spacingN)
              .floor() -
          1,
    );
    for (var i = first; i < first + 3; i++) {
      final left = _pipeXN(i, t) * _sky.width;
      final right = left + _pipeW;
      final nx = _birdX.clamp(left, right);
      final dx = nx - _birdX;
      if (dx.abs() > r) continue;
      final gapTop = _gapAt(i) * _sky.height;
      final gapBottom = gapTop + _gapPx;
      final dyTop = by - by.clamp(-1e6, gapTop);
      final dyBottom = by - by.clamp(gapBottom, 1e6);
      if (dx * dx + dyTop * dyTop < r * r) return true;
      if (dx * dx + dyBottom * dyBottom < r * r) return true;
    }
    return false;
  }

  List<_Pipe> _visiblePipes(double t) {
    final pipes = <_Pipe>[];
    final first = max(
      0,
      ((_difficulty.speed * t - _startX - _pipeWN) / _spacingN).floor(),
    );
    for (var i = first; ; i++) {
      final x = _pipeXN(i, t);
      if (x > 1.05) break;
      if (x + _pipeWN < 0) continue;
      pipes.add(_Pipe(x * _sky.width, _gapAt(i) * _sky.height));
    }
    return pipes;
  }

  void _resetRun({int? seed}) {
    _course = Random(seed);
    _gaps.clear();
    _steps = 0;
    _acc = 0;
    _y = _Physics.startY;
    _v = 0;
    _flapQueued = false;
    _score = 0;
    _viewT = 0;
  }

  // -------------------------------------------------------------- solo flow

  void _toReady() {
    _resetRun();
    setState(() {
      _phase = _Phase.ready;
      _saving = false;
      _newBest = false;
    });
    _ensureTicking();
  }

  void _ensureTicking() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _onTap() {
    switch (_phase) {
      case _Phase.ready:
        setState(() => _phase = _Phase.playing);
        _flapQueued = true;
      case _Phase.playing:
        _flapQueued = true;
      default:
        break;
    }
  }

  void _pause() {
    if (_phase != _Phase.playing && _phase != _Phase.ready) return;
    if (_online) return;
    _ticker.stop();
    setState(() => _phase = _Phase.paused);
  }

  void _resume() {
    if (_phase != _Phase.paused) return;
    setState(() => _phase = _Phase.ready);
    _ensureTicking();
  }

  void _toMenu() {
    _resetRun();
    setState(() => _phase = _Phase.menu);
    _ensureTicking();
  }

  Future<void> _recordScore() async {
    await _scores.ensureLoaded();
    final isNewBest = _score > 0 && _score > _scores.bestScore(gameId);
    if (!mounted) return;
    setState(() {
      _saving = true;
      _newBest = isNewBest;
    });
    var synced = false;
    try {
      synced = await _scores.recordScore(gameId, _score);
    } catch (e) {
      if (kDebugMode) AppLogger.d('Laggy Bird score save failed: $e');
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _synced = synced;
      _best = _scores.bestScore(gameId);
    });
  }

  void _crash() {
    Haptics.selection();
    if (_online) {
      final id = _matchId!;
      setState(() => _phase = _Phase.spectate);
      unawaited(_uploader?.close());
      unawaited(
        _net
            .reportCrash(
              id,
              round: _round,
              score: _score,
              deadAtMs: _Physics.msOf(_steps),
            )
            .catchError((_) {}),
      );
      unawaited(_recordScore());
      return;
    }
    _ticker.stop();
    setState(() => _phase = _Phase.over);
    unawaited(_recordScore());
  }

  // ------------------------------------------------------------ online flow

  Future<void> _createRace() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final id = await _net.createMatch(
        skin: Str.bird,
        difficulty: _difficulty.name,
      );
      _enterRace(id);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _joinRace(String id) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _net.joinMatch(id, skin: Str.bird);
      _enterRace(id);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _enterRace(String id) {
    if (!mounted) return;
    _matchSub?.cancel();
    setState(() {
      _matchId = id;
      _phase = _Phase.lobby;
      _round = 0;
    });
    _matchSub = _net.watch(id).listen(_onMatch);
  }

  void _onMatch(BirdMatch? m) {
    if (!mounted) return;
    if (m == null) {
      _exitRace();
      _snack('The race was closed.');
      return;
    }
    final me = _net.uid;
    if (me != null && !m.players.containsKey(me)) {
      _exitRace();
      return;
    }
    final prev = _match;
    _match = m;

    if (m.status == BirdMatchStatus.active && m.round != _round) {
      _startRound(m);
    } else if (m.status == BirdMatchStatus.waiting && _phase != _Phase.lobby) {
      _runsSub?.cancel();
      _ghosts.clear();
      _resetRun();
      setState(() => _phase = _Phase.lobby);
    } else if (m.status == BirdMatchStatus.finished &&
        m.round == _round &&
        (_phase == _Phase.playing ||
            _phase == _Phase.spectate ||
            _phase == _Phase.countdown)) {
      final wasFlying = _phase == _Phase.playing;
      setState(() => _phase = _Phase.raceOver);
      if (wasFlying) unawaited(_recordScore());
    } else if (prev == null || prev != m) {
      setState(() {});
    }
  }

  void _startRound(BirdMatch m) {
    _round = m.round;
    _difficulty = _Difficulty.fromName(m.difficulty);
    _resetRun(seed: m.seed);
    _ghosts
      ..clear()
      ..addAll({
        for (final p in m.players.values)
          if (p.uid != _net.uid) p.uid: _Ghost(p.uid),
      });
    _reportedForOthers.clear();
    unawaited(_uploader?.close());
    _uploader = BirdFlapUploader(_net, m.id, m.round);
    _runsSub?.cancel();
    _runsSub = _net.watchRuns(m.id, m.round).listen((runs) {
      runs.forEach((uid, run) => _ghosts[uid]?.setFlaps(run.flaps));
    });
    setState(() {
      _phase = _Phase.countdown;
      _saving = false;
      _newBest = false;
    });
    _ensureTicking();
  }

  Future<void> _hostStart() async {
    final id = _matchId;
    if (id == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _net.startRound(id, difficulty: _difficulty.name);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leaveRace() async {
    final id = _matchId;
    if (id == null) return;
    final flying = _phase == _Phase.playing || _phase == _Phase.countdown;
    _exitRace();
    try {
      await _net.leaveMatch(
        id,
        score: flying ? _score : null,
        deadAtMs: flying ? _Physics.msOf(_steps) : null,
      );
    } catch (_) {}
  }

  void _exitRace() {
    _matchSub?.cancel();
    _runsSub?.cancel();
    _matchSub = null;
    _runsSub = null;
    unawaited(_uploader?.close());
    _uploader = null;
    _ghosts.clear();
    _match = null;
    _matchId = null;
    _round = 0;
    _toMenu();
  }

  Future<void> _invite() async {
    final id = _matchId;
    if (id == null) return;
    final chat = Get.find<ChatService>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LudoInviteFriendsSheet(
        matchId: id,
        sendInvite: (friend, matchId) =>
            chat.sendBirdInviteMessage(friend: friend, matchId: matchId),
      ),
    );
  }

  // ------------------------------------------------------------ simulation

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    if (_sky.isEmpty) return;
    _bob += dt;

    if (_online) {
      _tickOnline(dt);
    } else if (_phase == _Phase.playing) {
      _acc += dt;
      final target = _steps + (_acc / _Physics.step).floor();
      _acc -= (target - _steps) * _Physics.step;
      if (_advanceSelf(target)) return;
    } else if (_phase != _Phase.over && _phase != _Phase.paused) {
      _hover();
    }
    _frame.value++;
  }

  /// Menu / ready: bird bobs in place.
  void _hover() {
    _y = _Physics.startY + sin(_bob * 5) * 0.015;
    _v = 0;
  }

  /// Steps my bird up to [target]. Returns true if it crashed.
  bool _advanceSelf(int target) {
    while (_steps < target) {
      _steps++;
      final flap = _flapQueued;
      _flapQueued = false;
      if (flap) _uploader?.add(_Physics.msOf(_steps));
      final next = _Physics.advance(_y, _v, flap);
      _y = next.$1;
      _v = next.$2;
      _score = _passedAt(_t);
      if (_hits(_y, _t)) {
        _frame.value++;
        _crash();
        return true;
      }
    }
    return false;
  }

  void _tickOnline(double dt) {
    final m = _match;
    if (m == null || _phase == _Phase.lobby || m.startAtMs == 0) {
      _hover();
      return;
    }
    final runT = (_net.serverNowMs - m.startAtMs) / 1000;
    final target = max(0, (runT / _Physics.step).floor());

    switch (_phase) {
      case _Phase.countdown:
        _hover();
        _viewT = 0;
        if (runT >= 0) {
          setState(() => _phase = _Phase.playing);
          _y = _Physics.startY;
          _v = 0;
        }
      case _Phase.playing:
        // Cap catch-up so a stall can't freeze the frame.
        if (_advanceSelf(min(target, _steps + _Physics.hz ~/ 4))) return;
        _viewT = _t;
      case _Phase.spectate:
      case _Phase.raceOver:
        if (_phase == _Phase.spectate) _viewT = max(_viewT, runT);
      default:
        break;
    }

    // Replay opponents on the same course.
    final ghostTarget = (_viewT / _Physics.step).floor();
    for (final g in _ghosts.values) {
      final result = m.results[g.uid];
      final limit = result == null
          ? ghostTarget
          : min(ghostTarget, (result.deadAtMs * _Physics.hz / 1000).ceil());
      g.advanceTo(limit, (y, step) => _hits(y, step * _Physics.step));
      g.shownY += (g.y - g.shownY) * min(1.0, dt * 18);

      // Their crash report never came (app closed?) — close it out for them.
      final crashedAt = g.localCrashStep;
      if (result == null &&
          crashedAt != null &&
          m.hostUid == _net.uid &&
          runT - crashedAt * _Physics.step > 4 &&
          _reportedForOthers.add(g.uid)) {
        unawaited(
          _net
              .reportCrash(
                m.id,
                round: m.round,
                score: _passedAt(crashedAt * _Physics.step),
                deadAtMs: _Physics.msOf(crashedAt),
                forUid: g.uid,
              )
              .catchError((_) {}),
        );
      }
    }
  }

  // ------------------------------------------------------------------- UI

  void _onBack() {
    if (_online) {
      unawaited(_leaveRace());
      return;
    }
    switch (_phase) {
      case _Phase.playing:
      case _Phase.ready:
        _pause();
      case _Phase.paused:
        _resume();
      case _Phase.over:
        _toMenu();
      default:
        Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: GameColors.bgBottom,
        body: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  _sky = Size(box.maxWidth, box.maxHeight);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => _onTap(),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: Image(
                              image: _bgImage,
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: RepaintBoundary(child: _world()),
                        ),
                        if (_phase == _Phase.ready) _readyHint(),
                        if (_phase == _Phase.countdown) _countdown(),
                        if (_phase == _Phase.spectate) _spectateBanner(),
                        _panelLayer(),
                        // Above the panels so Back / Leave stay tappable.
                        SafeArea(bottom: false, child: _hud()),
                      ],
                    ),
                  );
                },
              ),
            ),
            RepaintBoundary(child: _ground()),
          ],
        ),
      ),
    );
  }

  bool get _showCourse => _phase != _Phase.menu && _phase != _Phase.lobby;

  double get _courseT => _online ? _viewT : _t;

  Widget _world() {
    return ValueListenableBuilder<int>(
      valueListenable: _frame,
      builder: (context, _, _) {
        final flying =
            _phase == _Phase.playing ||
            _phase == _Phase.over ||
            _phase == _Phase.spectate;
        final tilt = flying
            ? (_v / _Physics.maxFall).clamp(-0.45, 1.0) * 1.2
            : 0.0;
        final m = _match;
        return Stack(
          children: [
            if (_showCourse)
              Positioned.fill(
                child: CustomPaint(
                  painter: _PipesPainter(
                    pipes: _visiblePipes(_courseT),
                    width: _pipeW,
                    gap: _gapPx,
                    frame: _frame.value,
                  ),
                ),
              ),
            if (m != null && _showCourse)
              for (final g in _ghosts.values)
                if (m.players[g.uid] != null &&
                    !(m.results.containsKey(g.uid) &&
                        g.steps * _Physics.step >= _viewT))
                  _ghostBird(g, m.players[g.uid]!),
            if (_phase != _Phase.spectate && _phase != _Phase.raceOver)
              Positioned(
                left: _birdX - _birdSize / 2,
                top: _y * _sky.height - _birdSize / 2,
                width: _birdSize,
                height: _birdSize,
                child: Transform.rotate(
                  angle: tilt,
                  child: Center(
                    child: _BirdSprite(
                      Str.bird,
                      width: _birdSize,
                      flap: wingFlap(
                        _bob,
                        speed: _phase == _Phase.playing && _v < 0 ? 7 : 3,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _ghostBird(_Ghost g, BirdPlayer p) {
    final size = _birdSize;
    final crashed = g.localCrashStep != null;
    return Positioned(
      left: _birdX - size / 2,
      top: g.shownY * _sky.height - size / 2 - 22,
      width: size,
      height: size + 22,
      child: IgnorePointer(
        child: Opacity(
          opacity: crashed ? 0.25 : 0.5,
          child: Column(
            children: [
              Container(
                height: 20,
                constraints: BoxConstraints(maxWidth: size * 1.6),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: GameColors.outline.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gameFont(11, Colors.white),
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Transform.rotate(
                  angle: (g.v / _Physics.maxFall).clamp(-0.45, 1.0) * 1.2,
                  child: Center(
                    child: _BirdSprite(
                      p.skin.isEmpty ? _pngBirds.first : p.skin,
                      width: size,
                      flap: wingFlap(_bob + g.uid.hashCode % 7, speed: 4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _ground() {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SizedBox(
      width: double.infinity,
      height: 64 + bottom,
      child: ValueListenableBuilder<int>(
        valueListenable: _frame,
        builder: (context, _, _) {
          final moving = _showCourse && _phase != _Phase.over;
          final offset = moving
              ? (_difficulty.speed * _courseT * _sky.width) % 48
              : (_bob * _sky.width * 0.25) % 48;
          return CustomPaint(painter: _GroundPainter(offset: offset));
        },
      ),
    );
  }

  Widget _hud() {
    final flying =
        _phase == _Phase.playing ||
        _phase == _Phase.ready ||
        _phase == _Phase.spectate ||
        _phase == _Phase.countdown;
    final m = _match;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameIconButton(
                icon: _online
                    ? Icons.close_rounded
                    : (flying ? Icons.pause_rounded : Icons.arrow_back_rounded),
                tooltip: _online ? 'Leave race' : (flying ? 'Pause' : 'Exit'),
                colors: _online ? GameColors.red : GameColors.purple,
                onPressed: _phase == _Phase.paused ? _toMenu : _onBack,
              ),
              Expanded(
                child: flying && _phase != _Phase.countdown
                    ? Center(
                        heightFactor: 1,
                        child: ValueListenableBuilder<int>(
                          valueListenable: _frame,
                          builder: (context, _, _) =>
                              GameText('$_score', size: 52),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: GameBadge(
                  label: _online ? '👥 ${m?.players.length ?? 1}' : '🏆 $_best',
                ),
              ),
            ],
          ),
          if (_online && m != null && _showCourse) ...[
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: _frame,
              builder: (context, _, _) => _roster(m),
            ),
          ],
        ],
      ),
    );
  }

  /// Live scores for everyone in the race.
  Widget _roster(BirdMatch m) {
    final me = _net.uid;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final p in m.ordered)
          () {
            final result = m.results[p.uid];
            final isMe = p.uid == me;
            final g = _ghosts[p.uid];
            final score =
                result?.score ??
                (isMe ? _score : _passedAt((g?.steps ?? 0) * _Physics.step));
            final out = result != null;
            return Container(
              padding: const EdgeInsets.fromLTRB(4, 3, 9, 4),
              decoration: BoxDecoration(
                color: GameColors.outline.withValues(alpha: out ? 0.4 : 0.65),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMe ? GameColors.green.$1 : GameColors.outline,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: out ? 0.4 : 1,
                    child: _BirdSprite(
                      p.skin.isEmpty ? _pngBirds.first : p.skin,
                      width: 24,
                    ),
                  ),
                  const SizedBox(width: 5),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 70),
                    child: Text(
                      isMe ? 'You' : p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: gameFont(12, out ? Colors.white54 : Colors.white),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    out ? '💀 $score' : '$score',
                    style: gameFont(13, GameColors.yellow.$1),
                  ),
                ],
              ),
            );
          }(),
      ],
    );
  }

  Widget _pill(Widget child) => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
    decoration: BoxDecoration(
      color: GameColors.outline.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: GameColors.outline, width: 2),
    ),
    child: child,
  );

  Widget _readyHint() => Positioned.fill(
    child: IgnorePointer(
      child: Align(
        alignment: const Alignment(0, 0.35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameText('GET READY!', size: 38),
            const SizedBox(height: 10),
            _pill(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const GameIcon(icon: Icons.touch_app_rounded, size: 22),
                  const SizedBox(width: 8),
                  Text('Tap to flap', style: gameFont(18, Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _countdown() => Positioned.fill(
    child: IgnorePointer(
      child: ValueListenableBuilder<int>(
        valueListenable: _frame,
        builder: (context, _, _) {
          final m = _match;
          final left = m == null
              ? 3.0
              : (m.startAtMs - _net.serverNowMs) / 1000;
          final label = left > 0 ? '${left.ceil().clamp(1, 9)}' : 'GO!';
          return Align(
            alignment: const Alignment(0, 0.3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameText(label, size: 84, color: GameColors.yellow.$1),
                const SizedBox(height: 8),
                _pill(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const GameIcon(icon: Icons.touch_app_rounded, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Tap to flap at GO',
                        style: gameFont(18, Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );

  Widget _spectateBanner() => Positioned(
    left: 0,
    right: 0,
    bottom: 18,
    child: IgnorePointer(
      child: Center(
        child: _pill(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('💥', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'You crashed at $_score · watching the ghosts',
                style: gameFont(15, Colors.white),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  // ---------------------------------------------------------------- panels

  Widget _modal(Widget panel) => Positioned.fill(
    child: ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 64, 20, 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: panel,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _panelLayer() {
    switch (_phase) {
      case _Phase.menu:
        return _modal(_menu());
      case _Phase.paused:
        return _modal(_pausePanel());
      case _Phase.over:
        return _modal(_resultPanel());
      case _Phase.lobby:
        return _modal(_lobbyPanel());
      case _Phase.raceOver:
        return _modal(_racePanel());
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _menu() => GamePanel(
    headerColors: GameColors.yellow,
    headerHeight: 92,
    header: Row(
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: Center(child: _BirdSprite(Str.bird, width: 56)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FittedBox(child: GameText('LAGGY BIRD', size: 32)),
              Text(
                'Flap through the pipes.',
                style: gameFont(13, GameColors.outline.withValues(alpha: 0.72)),
              ),
            ],
          ),
        ),
      ],
    ),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('BIRD · ${_birdName(Str.bird).toUpperCase()}'),
        GameTray(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              for (var row = 0; row < _birds.length; row += 5) ...[
                if (row > 0) const SizedBox(height: 8),
                Row(
                  children: [
                    for (final b in _birds.skip(row).take(5))
                      Expanded(
                        child: _choice(
                          selected: Str.bird == b,
                          onTap: () {
                            Str.bird = b;
                            write('bird', b);
                          },
                          child: SizedBox(
                            height: 44,
                            child: Center(child: _BirdSprite(b, width: 44)),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        _label('THEME'),
        GameTray(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              for (final t in _themes)
                Expanded(
                  child: _choice(
                    selected: Str.image == t,
                    onTap: () {
                      Str.image = t;
                      write('background', t);
                      precacheImage(_bgImage, context);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        'assets/flappy_birds/pics/$t.png',
                        height: 56,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _label('DIFFICULTY'),
        _difficultyRow(),
        const SizedBox(height: 14),
        Row(
          children: [
            GameIconButton(
              icon: _music ? Icons.music_note_rounded : Icons.music_off_rounded,
              tooltip: _music ? 'Music on' : 'Music off',
              size: 54,
              colors: _music ? GameColors.purple : GameColors.grey,
              onPressed: () {
                setState(() => _music = !_music);
                play = _music;
                write('audio', _music);
                unawaited(_applyMusic());
              },
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GameButton(
                label: 'Play',
                icon: Icons.play_arrow_rounded,
                tone: GameButtonTone.green,
                height: 58,
                onPressed: _toReady,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GameButton(
          label: _busy ? 'Creating race…' : 'Race Friends Online',
          icon: Icons.groups_rounded,
          subtitle: 'Rivals fly as ghost birds',
          tone: GameButtonTone.purple,
          height: 54,
          onPressed: _busy ? null : _createRace,
        ),
      ],
    ),
  );

  String _birdName(String key) {
    final skin = BirdSkin.fromKey(key);
    if (skin != null) return skin.name;
    return switch (_pngBirds.indexOf(key)) {
      1 => 'Bluey',
      2 => 'Leafy',
      _ => 'Classic',
    };
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(text, style: gameFont(13, GameColors.soft)),
  );

  Widget _choice({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        setState(onTap);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected
              ? GameColors.green.$2.withValues(alpha: 0.25)
              : GameColors.socket,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? GameColors.green.$1 : GameColors.trayEdge,
            width: 2.5,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _pausePanel() => GamePanel(
    headerColors: GameColors.purple,
    header: const Center(child: GameText('PAUSED', size: 28)),
    padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GameTray(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text('SCORE', style: gameFont(13, GameColors.soft)),
              GameText('$_score', size: 44, color: GameColors.yellow.$1),
            ],
          ),
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
                onPressed: _toReady,
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
  );

  Widget _resultPanel() => GamePanel(
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
              GameText('$_score', size: 56, color: GameColors.yellow.$1),
              const SizedBox(height: 4),
              if (_saving)
                Text('Saving score…', style: gameFont(13, GameColors.soft))
              else if (_newBest)
                const GameBadge(label: '⭐ NEW BEST!')
              else
                Text(
                  _synced
                      ? 'Best $_best · saved to leaderboard'
                      : 'Couldn’t sync. Check your connection.',
                  style: gameFont(
                    13,
                    _synced ? GameColors.soft : const Color(0xFFFF8A80),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GameButton(
          label: 'Play Again',
          icon: Icons.refresh_rounded,
          tone: GameButtonTone.green,
          onPressed: _toReady,
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
  );

  Widget _lobbyPanel() {
    final m = _match;
    final me = _net.uid;
    final isHost = m != null && m.hostUid == me;
    final players = m?.ordered ?? const <BirdPlayer>[];
    final canStart = isHost && players.length >= 2 && !_busy;
    return GamePanel(
      headerColors: GameColors.green,
      headerHeight: 72,
      header: Row(
        children: [
          const Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: GameText('BIRD RACE', size: 30),
            ),
          ),
          GameBadge(
            label: '${players.length}/${BirdMatch.maxPlayers}',
            dot: GameColors.green.$1,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Same pipes for everyone. Rivals fly as ghost birds. '
            'Highest score wins.',
            textAlign: TextAlign.center,
            style: gameFont(13, GameColors.soft),
          ),
          const SizedBox(height: 10),
          GameTray(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (var i = 0; i < BirdMatch.maxPlayers; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                    child: i < players.length
                        ? _lobbyRow(
                            players[i],
                            isMe: players[i].uid == me,
                            isHost: players[i].uid == m?.hostUid,
                          )
                        : _emptyRow(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'Invite',
                  icon: Icons.person_add_alt_1_rounded,
                  tone: GameButtonTone.purple,
                  height: 46,
                  onPressed: _invite,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GameButton(
                  label: 'Copy Link',
                  icon: Icons.link_rounded,
                  tone: GameButtonTone.yellow,
                  height: 46,
                  onPressed: () async {
                    final id = _matchId;
                    if (id == null) return;
                    await Clipboard.setData(
                      ClipboardData(text: BirdMatchService.inviteLink(id)),
                    );
                    _snack('Invite link copied');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isHost) ...[
            _label('DIFFICULTY'),
            _difficultyRow(),
            const SizedBox(height: 10),
          ],
          GameButton(
            label: isHost ? 'Start Race' : 'Waiting for host…',
            icon: isHost ? Icons.flag_rounded : Icons.hourglass_top_rounded,
            subtitle: isHost && players.length < 2
                ? 'Need at least 2 birds'
                : null,
            tone: canStart ? GameButtonTone.green : GameButtonTone.grey,
            height: 58,
            onPressed: canStart ? _hostStart : null,
          ),
        ],
      ),
    );
  }

  Widget _lobbyRow(BirdPlayer p, {required bool isMe, required bool isHost}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isMe
            ? GameColors.green.$2.withValues(alpha: 0.18)
            : GameColors.socket,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe ? GameColors.green.$1 : GameColors.trayEdge,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          _BirdSprite(p.skin.isEmpty ? _pngBirds.first : p.skin, width: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gameFont(16, Colors.white),
            ),
          ),
          if (isHost) ...[
            const GameBadge(label: '👑 HOST'),
            const SizedBox(width: 6),
          ],
          if (isMe) const GameBadge(label: 'YOU'),
        ],
      ),
    );
  }

  Widget _emptyRow() => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: GameColors.socket.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: GameColors.trayEdge, width: 2),
    ),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GameColors.trayEdge,
            border: Border.all(color: GameColors.outline, width: 2),
          ),
        ),
        const SizedBox(width: 10),
        Text('Waiting for a bird…', style: gameFont(14, GameColors.soft)),
      ],
    ),
  );

  Widget _racePanel() {
    final m = _match;
    final me = _net.uid;
    final standings = m?.standings ?? const <BirdPlayer>[];
    final won = standings.isNotEmpty && standings.first.uid == me;
    final isHost = m != null && m.hostUid == me;
    const medals = ['🥇', '🥈', '🥉', '4'];
    return GamePanel(
      headerColors: won ? GameColors.yellow : GameColors.red,
      headerHeight: 72,
      header: Center(child: GameText(won ? 'YOU WIN!' : 'RACE OVER', size: 30)),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (final (i, p) in standings.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: p.uid == me
                            ? GameColors.green.$2.withValues(alpha: 0.18)
                            : GameColors.socket,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: p.uid == me
                              ? GameColors.green.$1
                              : GameColors.trayEdge,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              medals[i.clamp(0, 3)],
                              textAlign: TextAlign.center,
                              style: i < 3
                                  ? const TextStyle(fontSize: 22)
                                  : gameFont(18, GameColors.soft),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _BirdSprite(
                            p.skin.isEmpty ? _pngBirds.first : p.skin,
                            width: 34,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p.uid == me ? 'You' : p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: gameFont(16, Colors.white),
                            ),
                          ),
                          GameText(
                            '${m?.results[p.uid]?.score ?? 0}',
                            size: 26,
                            color: GameColors.yellow.$1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          if (_newBest)
            const Center(child: GameBadge(label: '⭐ NEW PERSONAL BEST!')),
          const SizedBox(height: 10),
          GameButton(
            label: isHost ? 'Rematch' : 'Waiting for host…',
            icon: isHost ? Icons.refresh_rounded : Icons.hourglass_top_rounded,
            tone: isHost && !_busy ? GameButtonTone.green : GameButtonTone.grey,
            onPressed: isHost && !_busy ? _hostStart : null,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (isHost) ...[
                Expanded(
                  child: GameButton(
                    label: 'Lobby',
                    tone: GameButtonTone.purple,
                    height: 46,
                    onPressed: () {
                      final id = _matchId;
                      if (id != null) {
                        unawaited(_net.backToLobby(id).catchError((_) {}));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: GameButton(
                  label: 'Leave',
                  tone: GameButtonTone.red,
                  height: 46,
                  onPressed: _leaveRace,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _difficultyRow() => Row(
    children: [
      for (final (i, d) in _Difficulty.values.indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(
          child: GameButton(
            label: d.label,
            height: 44,
            tone: _difficulty == d
                ? switch (d) {
                    _Difficulty.easy => GameButtonTone.green,
                    _Difficulty.medium => GameButtonTone.yellow,
                    _Difficulty.hard => GameButtonTone.red,
                  }
                : GameButtonTone.grey,
            onPressed: () {
              setState(() => _difficulty = d);
              barrierMovement = d.level;
              write('level', d.level);
            },
          ),
        ),
      ],
    ],
  );
}

// ---------------------------------------------------------------- painters

/// Chunky outlined pipes with a glossy highlight and a lipped cap.
class _PipesPainter extends CustomPainter {
  _PipesPainter({
    required this.pipes,
    required this.width,
    required this.gap,
    required this.frame,
  });

  final List<_Pipe> pipes;
  final double width;
  final double gap;
  final int frame;

  static const _outline = Color(0xFF0B0B10);
  static const _light = Color(0xFF8CF27A);
  static const _mid = Color(0xFF3CCB46);
  static const _dark = Color(0xFF1F8A2C);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pipes) {
      if (p.x > size.width || p.x + width < 0) continue;
      _pipe(canvas, p.x, -8, p.gapTop, capAtBottom: true);
      _pipe(canvas, p.x, p.gapTop + gap, size.height + 8, capAtBottom: false);
    }
  }

  void _pipe(
    Canvas canvas,
    double x,
    double top,
    double bottom, {
    required bool capAtBottom,
  }) {
    if (bottom - top <= 0) return;
    const capH = 26.0;
    const inset = 6.0;
    final body = Rect.fromLTRB(x + inset, top, x + width - inset, bottom);
    final cap = capAtBottom
        ? Rect.fromLTRB(x, bottom - capH, x + width, bottom)
        : Rect.fromLTRB(x, top, x + width, top + capH);

    _block(canvas, body, 6);
    _block(canvas, cap, 8);
  }

  void _block(Canvas canvas, Rect r, double radius) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(radius));
    canvas.drawRRect(rr.inflate(3), Paint()..color = _outline);
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          colors: [_light, _mid, _mid, _dark],
          stops: [0, 0.3, 0.7, 1],
        ).createShader(r),
    );
    // Glossy highlight stripe.
    final stripe = Rect.fromLTWH(
      r.left + r.width * 0.14,
      r.top + 4,
      r.width * 0.12,
      max(0, r.height - 8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(stripe, const Radius.circular(4)),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(_PipesPainter old) => old.frame != frame;
}

/// Scrolling striped grass strip over a dirt base.
class _GroundPainter extends CustomPainter {
  _GroundPainter({required this.offset});

  final double offset;

  @override
  void paint(Canvas canvas, Size size) {
    const grassH = 18.0;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDDB86A), Color(0xFFB88A3E)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, grassH),
      Paint()..color = const Color(0xFF5FD35A),
    );
    final stripe = Paint()..color = const Color(0xFF3FB33F);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, grassH));
    for (double x = -offset - 48; x < size.width + 48; x += 48) {
      final path = Path()
        ..moveTo(x, grassH)
        ..lineTo(x + 20, 0)
        ..lineTo(x + 34, 0)
        ..lineTo(x + 14, grassH)
        ..close();
      canvas.drawPath(path, stripe);
    }
    canvas.restore();
    canvas.drawRect(
      Rect.fromLTWH(0, grassH, size.width, 4),
      Paint()..color = const Color(0xFF2E8B2E),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, 3),
      Paint()..color = const Color(0xFF0B0B10),
    );
  }

  @override
  bool shouldRepaint(_GroundPainter old) => old.offset != offset;
}

/// The bird PNGs are 512² with the sprite in the middle ~157×112 px; this
/// crops to the sprite so [width] is the bird's actual drawn width.
class _BirdSprite extends StatelessWidget {
  const _BirdSprite(this.asset, {required this.width, this.flap = 0});

  final String asset;
  final double width;
  final double flap;

  static const _spriteW = 157 / 512;
  static const _aspect = 157 / 112;

  @override
  Widget build(BuildContext context) {
    final skin = BirdSkin.fromKey(asset);
    if (skin != null) {
      // Painted birds fill their box edge to edge; nudge them up to match
      // the visual weight of the pixel-art sprites.
      return SizedBox(
        width: width,
        height: width / 1.4,
        child: OverflowBox(
          maxWidth: width * 1.15,
          maxHeight: width * 1.15 / 1.4,
          child: SizedBox(
            width: width * 1.15,
            height: width * 1.15 / 1.4,
            child: CustomPaint(painter: BirdSkinPainter(skin, flap: flap)),
          ),
        ),
      );
    }
    final full = width / _spriteW;
    return SizedBox(
      width: width,
      height: width / _aspect,
      child: OverflowBox(
        maxWidth: full,
        maxHeight: full,
        child: Image.asset(
          asset,
          width: full,
          height: full,
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
