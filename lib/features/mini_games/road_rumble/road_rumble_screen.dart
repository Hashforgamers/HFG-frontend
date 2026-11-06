import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:hash/core/app_orientation.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/features/mini_games/common/game_sfx.dart';
import 'package:hash/features/mini_games/html_games/services/html_game_asset_server.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_page.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'rr_engine.dart';
import 'rr_progress.dart';
import 'rr_renderer.dart';
import 'package:hash/features/mini_games/arcade_analytics.dart';

enum _Screen { title, tracks, shop, help, race, paused, results }

// Touch zones, also used as bits in the held-buttons mask.
const _zLeft = 1;
const _zRight = 2;
const _zGas = 4;
const _zBrake = 8;
const _zPunch = 16;
const _zKick = 32;

/// Road Rumble: a 16-bit style combat motorbike racer. Landscape only. The
/// whole game — menus included — is painted into a low-resolution frame by
/// [RrRenderer] and scaled up to the screen; this widget owns input, the race
/// loop, sound and the saved career.
class RoadRumbleScreen extends StatefulWidget {
  const RoadRumbleScreen({super.key, this.web3d = true});

  /// Draw the world with the bundled WebGL scene. When off, or if that
  /// scene fails to start, the built-in software renderer is used instead.
  final bool web3d;

  @override
  State<RoadRumbleScreen> createState() => _RoadRumbleScreenState();
}

class _RoadRumbleScreenState extends State<RoadRumbleScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const gameId = 'road_rumble';

  final RrRenderer _renderer = RrRenderer();
  // Lazy: only touched when a race is scored or the ranks are opened.
  late final MiniGameScoreService _scores = MiniGameScoreService();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final ValueNotifier<int> _held = ValueNotifier(0);
  final GameSfx _sfx = GameSfx(prefix: 'assets/road_rumble/', voices: 2);
  final FocusNode _focus = FocusNode();
  late final Ticker _ticker;

  RrProgress _progress = RrProgress();
  RrEngine? _engine;

  // The WebGL view of the world, once its page reports ready.
  InAppWebViewController? _web;
  Uri? _webUrl;
  static const _gfxKey = 'road_rumble_gfx_tier_v2';
  int _gfxTier = 0;

  /// The bike on show in the shop.
  int _shopView = 0;
  bool _webReady = false;

  /// A frozen moment just after a start, shown behind the menus.
  late final RrEngine _demo = _buildDemo();
  RrResult? _result;
  _Screen _screen = _Screen.title;
  Duration _last = Duration.zero;
  Duration _lastSent = Duration.zero;
  double _clock = 0;
  // The engine is one looping sample whose playback rate follows the revs.
  String _syncLine = '';
  bool _menuLocked = false;
  Timer? _menuLock;

  // Input.
  final Map<int, int> _pointers = {};
  final Set<LogicalKeyboardKey> _keys = {};

  // Where the last frame landed on screen, for mapping taps to game pixels.
  ui.Image? _lastFrame;
  int _gameW = 320;
  double _scale = 1;
  Offset _origin = Offset.zero;

  @override
  void initState() {
    super.initState();
    ArcadeAnalytics.opened(gameId);
    _ticker = createTicker(_tick);
    WidgetsBinding.instance.addObserver(this);
    unawaited(_enterGameMode());
    unawaited(_load());
    if (widget.web3d) unawaited(_startWeb());
    unawaited(_loadDash());
  }

  RrEngine _buildDemo() {
    final track = rrTracks[DateTime.now().millisecond % rrTracks.length];
    final demo = RrEngine(track: track, level: 1, bike: rrBikes[0]);
    for (var i = 0; i < 330; i++) {
      demo.update(1 / 60, steer: 0, gas: true, brake: false);
    }
    return demo;
  }

  Future<void> _startWeb() async {
    try {
      final url = await HtmlGameAssetServer.instance.urlFor(
        'assets/html_games/road_rumble/index.html',
      );
      // Open at the quality step this phone settled on last time.
      _gfxTier = (await SharedPreferences.getInstance()).getInt(_gfxKey) ?? 0;
      if (mounted) {
        setState(
          () => _webUrl = _gfxTier > 0
              ? url.replace(queryParameters: {'tier': '$_gfxTier'})
              : url,
        );
      }
    } catch (e) {
      if (kDebugMode) AppLogger.d('Road Rumble 3D view unavailable: $e');
    }
  }

  void _js(String source) {
    final web = _web;
    if (web == null || !_webReady) return;
    unawaited(
      web.evaluateJavascript(source: source).catchError((Object _) => null),
    );
  }

  /// Hands the WebGL scene the road it has to build for this race.
  void _sendTrack(RrEngine e) {
    String list(Iterable<num> values) =>
        values.map((v) => v.toStringAsFixed(2)).join(',');
    final curves = list([for (var i = 0; i < e.segCount; i++) e.curveAt(i)]);
    final heights = list([for (var i = 0; i <= e.segCount; i++) e.pointY(i)]);
    final props = StringBuffer();
    for (var i = 0; i < e.segCount; i++) {
      for (final prop in e.props[i] ?? const <RrRoadside>[]) {
        if (prop.kind == RrProp.tuft) continue;
        if (props.isNotEmpty) props.write(',');
        props.write('[$i,"${prop.kind.name}",${prop.x.toStringAsFixed(2)}]');
      }
    }
    _js(
      'RR.load({theme:"${e.track.theme.name}",curves:[$curves],heights:[$heights],props:[$props]})',
    );
  }

  static int _poseOf(RrRider r) {
    if (r.attackT <= 0) return 0;
    final left = r.attackSide < 0;
    return r.attackKick ? (left ? 3 : 4) : (left ? 1 : 2);
  }

  /// Tells the WebGL scene where everyone is this tick.
  void _sendFrame(RrEngine e, double revs, double loud) {
    final p = e.player;
    final b = StringBuffer('RR.frame([');
    void n(num v) => b
      ..write(v.toStringAsFixed(3))
      ..write(',');
    n(_clock);
    n(p.z);
    n(p.x);
    n(p.lean);
    n(e.crashed ? (e.tumbling ? 1 : 2) : 0);
    n(e.crashAge);
    n(e.riderOffset);
    n(_poseOf(p));
    n(revs);
    n(loud);
    // Numbered by their place in the field, which never changes, so the
    // scene can follow each one from frame to frame.
    final riders = [
      for (final (i, r) in [...e.rivals, ...e.cops].indexed)
        if (r.z > p.z - 4000 && r.z < p.z + 110000) (i, r),
    ];
    n(riders.length);
    for (final (i, r) in riders) {
      n(i);
      n(r.x);
      n(r.z);
      n(r.lean);
      n(_poseOf(r));
      n(r.down ? 1 : 0);
      n(r.look);
    }
    final cars = [
      for (final (i, c) in e.cars.indexed)
        if (c.z > p.z - 4000 && c.z < p.z + 130000) (i, c),
    ];
    n(cars.length);
    for (final (i, c) in cars) {
      n(i);
      n(c.x);
      n(c.z);
      n(c.look);
      n(c.oncoming ? 1 : 0);
    }
    b.write('0])');
    _js(b.toString());
  }

  Future<void> _loadDash() async {
    try {
      await _renderer.loadDash();
      if (mounted) _frame.value++;
      await _renderer.loadModels();
      if (mounted) _frame.value++;
      await _renderer.loadArt();
      if (mounted) _frame.value++;
    } catch (e) {
      if (kDebugMode) AppLogger.d('Road Rumble dashboard failed to load: $e');
    }
  }

  Future<void> _load() async {
    final progress = await RrProgress.load();
    if (!mounted) return;
    setState(() => _progress = progress);
    _frame.value++;
    await _sfx.load(const [
      'punch2.wav',
      'thud.wav',
      'swing.wav',
      'punch.wav',
      'crash.wav',
      'siren.wav',
      'beep.wav',
      'go.wav',
      'finish.wav',
    ]);
  }

  Future<void> _enterGameMode() async {
    await AppOrientation.landscape();
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  Future<void> _exitGameMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await AppOrientation.portrait();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _pause();
  }

  @override
  void dispose() {
    ArcadeAnalytics.closed(gameId);
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _menuLock?.cancel();
    _frame.dispose();
    _held.dispose();
    _focus.dispose();
    _lastFrame?.dispose();
    _renderer.dispose();
    unawaited(_sfx.dispose());
    unawaited(_exitGameMode());
    super.dispose();
  }

  /// The engine note is made by the 3D view, which can bend its pitch
  /// smoothly; this only turns it on for a race and off again.
  void _setEngine(bool on) => _js('RR.sound(${on && _progress.sound})');

  void _play(String file, [double volume = 0.5]) {
    if (_progress.sound) _sfx.play(file, volume: volume);
  }

  // ------------------------------------------------------------------ flow

  void _show(_Screen screen) {
    // Briefly ignore taps so a thumb still mashing a button when the menu
    // appears doesn't pick a row.
    _menuLocked = true;
    _menuLock?.cancel();
    _menuLock = Timer(
      const Duration(milliseconds: 450),
      () => _menuLocked = false,
    );
    if (screen == _Screen.shop) {
      _shopView = _progress.bike;
      _js('RR.shop($_shopView)');
    } else if (_screen == _Screen.shop) {
      _js('RR.shop(-1)');
    }
    setState(() => _screen = screen);
    // With no race loaded, the 3D view flies along a demo road.
    if (_engine == null) _js('RR.idle()');
    _setEngine(screen == _Screen.race);
    _frame.value++;
  }

  void _startRace(RrTrack track) {
    ArcadeAnalytics.started(gameId, level: _progress.level);
    _engine = RrEngine(
      track: track,
      level: _progress.level,
      bike: rrBikes[_progress.bike],
    );
    _result = null;
    _pointers.clear();
    _keys.clear();
    _held.value = 0;
    if (_webReady) _sendTrack(_engine!);
    _show(_Screen.race);
    _last = Duration.zero;
    _lastSent = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  void _pause() {
    if (_screen != _Screen.race) return;
    _ticker.stop();
    _show(_Screen.paused);
  }

  void _resume() {
    if (_screen != _Screen.paused) return;
    _pointers.clear();
    _held.value = 0;
    _show(_Screen.race);
    _last = Duration.zero;
    _lastSent = Duration.zero;
    _ticker.start();
  }

  void _quitRace() {
    _ticker.stop();
    _engine = null;
    _show(_Screen.title);
  }

  Future<void> _finishRace() async {
    final e = _engine!;
    _ticker.stop();
    final result = _progress.apply(e);
    _result = result;
    _syncLine = 'SAVING SCORE...';
    _show(_Screen.results);
    if (result.outcome == RrOutcome.finished) Haptics.success();
    unawaited(_progress.save());
    var synced = false;
    try {
      synced = await _scores.recordScore(gameId, result.score);
    } catch (err) {
      if (kDebugMode) AppLogger.d('Road Rumble score save failed: $err');
    }
    if (!mounted) return;
    _syncLine = synced ? 'SAVED TO LEADERBOARD' : 'SCORE NOT SYNCED';
    _frame.value++;
  }

  Future<void> _openRanks() async {
    await _exitGameMode();
    await Get.to(
      () => MiniGameLeaderboardPage(
        scoreService: _scores,
        leaderboardService: MiniGameLeaderboardService(),
      ),
    );
    if (mounted) await _enterGameMode();
  }

  // ----------------------------------------------------------------- menus

  /// Which backdrop goes behind the current menu.
  int _art() => switch (_screen) {
    _Screen.title || _Screen.race => 0,
    _Screen.tracks => 4,
    _Screen.shop => 1,
    _Screen.help => 7,
    _Screen.paused => 5,
    _Screen.results => _result?.outcome == RrOutcome.finished ? 6 : 3,
  };

  RrMenu _menu() {
    final p = _progress;
    switch (_screen) {
      case _Screen.tracks:
        return RrMenu(
          title: 'LEVEL ${p.level}',
          info: const ['FINISH TOP 4 ON ALL FIVE TRACKS TO LEVEL UP'],
          items: [
            for (final t in rrTracks)
              RrMenuItem(
                t.name,
                right: p.qualified.contains(t.id) ? 'QUALIFIED' : 'RACE >',
                tone: p.qualified.contains(t.id) ? 2 : 0,
              ),
            const RrMenuItem('< BACK'),
          ],
        );
      case _Screen.shop:
        return RrMenu(
          title: 'BIKE SHOP',
          info: [
            'CASH \$${p.cash}',
            '${rrBikes[_shopView].name}: ${rrBikes[_shopView].mph} MPH',
            'TAP A BIKE TO SEE IT.',
            'TAP IT AGAIN TO ${p.owned.contains(_shopView) ? 'RIDE IT' : 'BUY IT'}.',
          ],
          items: [
            for (var i = 0; i < rrBikes.length; i++)
              RrMenuItem(
                '${rrBikes[i].name}  ${rrBikes[i].mph} MPH',
                right: p.bike == i
                    ? 'RIDING'
                    : p.owned.contains(i)
                    ? (i == _shopView ? 'RIDE >' : 'OWNED')
                    : (i == _shopView && p.cash < rrBikes[i].price
                          ? 'NEED \$${rrBikes[i].price}'
                          : '\$${rrBikes[i].price}'),
                // The bike on show is lit; the rest say whether they are owned.
                tone: i == _shopView ? 1 : (p.owned.contains(i) ? 2 : 0),
              ),
            const RrMenuItem('< BACK'),
          ],
        );
      case _Screen.help:
        return const RrMenu(
          title: 'HOW TO PLAY',
          info: [
            'HOLD GAS TO RIDE. STEER WITH THE ARROWS.',
            'PUNCH AND KICK RIDERS ALONGSIDE YOU.',
            'PUNCH A SWINGING RIDER TO GRAB THE CLUB.',
            'DODGE TRAFFIC. CRASHES DAMAGE THE BIKE.',
            'CRASH NEAR A COP AND YOU ARE BUSTED.',
            'FINISH TOP 4 TO QUALIFY AND WIN CASH.',
            'SPEND CASH ON FASTER BIKES.',
            '',
            '3D MODELS (CC BY 4.0): FUTUREALITI, LOLIPOP,',
            'DAVE LOVE, KEVIN_K_5124, ATRIKUMAR DAS,',
            'COMRADE1280. TEXTURES: POLY HAVEN.',
          ],
          items: [RrMenuItem('< BACK')],
        );
      case _Screen.paused:
        return const RrMenu(
          title: 'PAUSED',
          items: [
            RrMenuItem('RESUME', tone: 1),
            RrMenuItem('RESTART'),
            RrMenuItem('QUIT RACE'),
          ],
        );
      case _Screen.results:
        final r = _result!;
        return RrMenu(
          title: switch (r.outcome) {
            RrOutcome.busted => 'BUSTED',
            RrOutcome.wrecked => 'WRECKED',
            _ => '${RrRenderer.ordinal(r.place)} PLACE',
          },
          info: [
            if (r.outcome == RrOutcome.finished)
              'PRIZE MONEY \$${r.prize}'
            else
              r.outcome == RrOutcome.busted
                  ? 'FINE \$${r.fine}'
                  : 'REPAIRS \$${r.fine}',
            if (r.bonus > 0) 'BONUS +\$${r.bonus}',
            'KNOCKOUTS ${r.kos}',
            'ARCADE SCORE ${r.score}',
            'CASH \$${_progress.cash}',
            if (r.levelUp)
              'LEVEL COMPLETE! THE PACK GETS FASTER'
            else if (r.qualified)
              'QUALIFIED! ${_progress.qualified.length}/${rrTracks.length} TRACKS'
            else
              'FINISH TOP 4 TO QUALIFY',
            _syncLine,
            '',
            for (final (i, rider) in _engine!.standings.take(5).indexed)
              '${i + 1}. ${rider.name}',
          ],
          items: const [
            RrMenuItem('CONTINUE', tone: 1),
            RrMenuItem('RACE AGAIN'),
          ],
        );
      case _Screen.title:
      case _Screen.race:
        return RrMenu(
          title: 'ROAD RUMBLE',
          info: ['LEVEL ${p.level}    CASH \$${p.cash}', rrBikes[p.bike].name],
          items: [
            const RrMenuItem('RACE', tone: 1),
            const RrMenuItem('BIKE SHOP'),
            const RrMenuItem('HOW TO PLAY'),
            const RrMenuItem('RANKS'),
            RrMenuItem('SOUND', right: p.sound ? 'ON' : 'OFF'),
            const RrMenuItem('EXIT'),
          ],
        );
    }
  }

  void _onMenu(int index) {
    Haptics.selection();
    final p = _progress;
    switch (_screen) {
      case _Screen.title:
        switch (index) {
          case 0:
            _show(_Screen.tracks);
          case 1:
            _show(_Screen.shop);
          case 2:
            _show(_Screen.help);
          case 3:
            unawaited(_openRanks());
          case 4:
            p.sound = !p.sound;
            unawaited(p.save());
            _frame.value++;
          case 5:
            Navigator.of(context).maybePop();
        }
      case _Screen.tracks:
        if (index < rrTracks.length) {
          _startRace(rrTracks[index]);
        } else {
          _show(_Screen.title);
        }
      case _Screen.shop:
        if (index >= rrBikes.length) {
          _show(_Screen.title);
          return;
        }
        if (index != _shopView) {
          // The first tap wheels the bike out; the second is the deal.
          _shopView = index;
          _js('RR.shop($index)');
          _frame.value++;
          return;
        }
        if (!p.owned.contains(index)) {
          if (p.cash < rrBikes[index].price) return;
          p.cash -= rrBikes[index].price;
          p.owned.add(index);
        }
        p.bike = index;
        unawaited(p.save());
        _frame.value++;
      case _Screen.help:
        _show(_Screen.title);
      case _Screen.paused:
        switch (index) {
          case 0:
            _resume();
          case 1:
            _startRace(_engine!.track);
          case 2:
            _quitRace();
        }
      case _Screen.results:
        final track = _engine!.track;
        if (index == 1) {
          _startRace(track);
        } else {
          _engine = null;
          _show(_Screen.tracks);
        }
      case _Screen.race:
        break;
    }
  }

  // ----------------------------------------------------------------- input

  int _zoneAt(Offset pos, Size size) {
    final x = pos.dx / size.width;
    final y = pos.dy / size.height;
    if (x < 0.36) {
      if (y < 0.3) return 0;
      return x < 0.18 ? _zLeft : _zRight;
    }
    if (x > 0.64) {
      if (y < 0.15) return 0;
      final outer = x > 0.82;
      if (y > 0.57) return outer ? _zGas : _zBrake;
      return outer ? _zPunch : _zKick;
    }
    return 0;
  }

  void _pointer(PointerEvent event, Size size, {bool up = false}) {
    if (_screen != _Screen.race) {
      if (event is! PointerDownEvent) return;
      if (_menuLocked) return;
      final g = (event.localPosition - _origin) / _scale;
      final hit = RrRenderer.menuHit(_menu(), _gameW, g.dx, g.dy);
      if (hit != null) _onMenu(hit);
      return;
    }
    if (up) {
      _pointers.remove(event.pointer);
    } else {
      if (event is PointerDownEvent) {
        final g = (event.localPosition - _origin) / _scale;
        if (g.dx < 26 && g.dy < RrRenderer.hudH + 6) {
          _pause();
          return;
        }
      }
      final zone = _zoneAt(event.localPosition, size);
      final before = _pointers[event.pointer];
      _pointers[event.pointer] = zone;
      if (zone != before) {
        if (zone == _zPunch) _engine?.punch();
        if (zone == _zKick) _engine?.kick();
      }
    }
    _held.value = _pointers.values.fold(0, (mask, zone) => mask | zone);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (event is KeyDownEvent) {
      _keys.add(key);
      if (_screen == _Screen.race) {
        if (key == LogicalKeyboardKey.keyZ) _engine?.punch();
        if (key == LogicalKeyboardKey.keyX) _engine?.kick();
      }
    } else if (event is KeyUpEvent) {
      _keys.remove(key);
    }
    return KeyEventResult.handled;
  }

  // ------------------------------------------------------------ simulation

  void _tick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 0.0
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = elapsed;
    final e = _engine;
    if (dt == 0 || e == null || _screen != _Screen.race) return;
    _clock += dt;

    final held = _held.value;
    bool key(LogicalKeyboardKey k) => _keys.contains(k);
    final left = held & _zLeft != 0 || key(LogicalKeyboardKey.arrowLeft);
    final right = held & _zRight != 0 || key(LogicalKeyboardKey.arrowRight);
    // Sliding the thumb up to punch or kick keeps the throttle open.
    final gas =
        held & (_zGas | _zPunch | _zKick) != 0 ||
        key(LogicalKeyboardKey.arrowUp);
    final brake = held & _zBrake != 0 || key(LogicalKeyboardKey.arrowDown);

    // Holding a strike button keeps swinging, one blow after another.
    if (held & _zPunch != 0 || key(LogicalKeyboardKey.keyZ)) {
      e.punch();
    } else if (held & _zKick != 0 || key(LogicalKeyboardKey.keyX)) {
      e.kick();
    }

    e.update(
      dt,
      steer: (right ? 1.0 : 0.0) - (left ? 1.0 : 0.0),
      gas: gas,
      brake: brake,
    );

    for (final event in e.events) {
      switch (event) {
        case 'beep':
          _play('beep.wav');
        case 'go':
          _play('go.wav');
        case 'swing':
          _play('swing.wav', 0.4);
        case 'hit':
          Haptics.medium();
          _play(e.player.attackKick ? 'thud.wav' : 'punch.wav', 0.8);
        case 'hurt':
          Haptics.heavy();
          _play('punch2.wav', 0.8);
        case 'ko':
          Haptics.success();
        case 'crash':
          Haptics.heavy();
          _play('crash.wav', 0.8);
        case 'siren':
          _play('siren.wav', 0.45);
        case 'whoosh':
          _play('swing.wav', 0.5);
        case 'finish':
          _play('finish.wav', 0.7);
      }
    }

    // The engine's note is one held rev that rises with speed, dipping a
    // little at each gear change; off the throttle it sags and quietens.
    final pct = (e.player.speed / e.bike.topSpeed).clamp(0.0, 1.0);
    final inGear = pct >= 0.999 ? 1.0 : (pct * 5) - (pct * 5).floorToDouble();
    final revs = e.player.speed < 50
        ? (gas ? 0.35 : 0.04)
        : (0.15 + 0.63 * pct + 0.22 * inGear) * (gas ? 1.0 : 0.88);
    final loud = e.crashed || e.outcome != RrOutcome.none
        ? 0.0
        : (gas ? 0.75 + 0.25 * pct : 0.45);

    if (_webReady) {
      // The scene carries motion forward between frames, so thirty a second
      // is plenty, and spares the web view's thread and the HUD's repaints.
      if (elapsed - _lastSent >= const Duration(milliseconds: 30)) {
        _lastSent = elapsed;
        _sendFrame(e, revs, loud);
        _frame.value++;
      }
    } else {
      _frame.value++;
    }
    if (e.outcome != RrOutcome.none && e.endT > 2.6) {
      unawaited(_finishRace());
    }
  }

  // -------------------------------------------------------------------- UI

  void _paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    const h = RrRenderer.height;
    final w = (h * size.width / size.height).round().clamp(320, 520);
    final scale = min(size.width / w, size.height / h);
    _gameW = w;
    _scale = scale;
    _origin = Offset(
      (size.width - w * scale) / 2,
      (size.height - h * scale) / 2,
    );

    final recorder = ui.PictureRecorder();
    const ps = RrRenderer.pixelScale;
    final frame = Canvas(recorder)..scale(ps.toDouble());
    final e = _engine;
    if (_screen == _Screen.race && e != null) {
      _renderer.race(frame, w, e, _clock, world: !_webReady);
    } else {
      _renderer.menu(
        frame,
        w,
        _menu(),
        scene: _webReady ? null : (e ?? _demo),
        artIndex: _art(),
        clear: _webReady,
      );
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(w * ps, h * ps);
    picture.dispose();
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, w * ps.toDouble(), h * ps.toDouble()),
      _origin & Size(w * scale, h * scale),
      Paint()
        // Over the WebGL world the HUD is scaled smoothly; the software
        // renderer keeps its chunky, washed-out look.
        ..filterQuality = _webReady ? FilterQuality.medium : FilterQuality.none
        ..colorFilter = _webReady ? null : RrRenderer.wash,
    );
    _lastFrame?.dispose();
    _lastFrame = image;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        switch (_screen) {
          case _Screen.race:
            _pause();
          case _Screen.paused:
            _resume();
          case _Screen.title:
            Navigator.of(context).pop();
          case _Screen.results:
            _engine = null;
            _show(_Screen.tracks);
          case _Screen.tracks:
          case _Screen.shop:
          case _Screen.help:
            _show(_Screen.title);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Focus(
            focusNode: _focus,
            autofocus: true,
            onKeyEvent: _key,
            child: LayoutBuilder(
              builder: (context, box) {
                final size = box.biggest;
                return Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) => _pointer(e, size),
                  onPointerMove: (e) => _pointer(e, size),
                  onPointerUp: (e) => _pointer(e, size, up: true),
                  onPointerCancel: (e) => _pointer(e, size, up: true),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_webUrl != null)
                        InAppWebView(
                          initialUrlRequest: URLRequest(
                            url: WebUri(_webUrl.toString()),
                          ),
                          initialSettings: InAppWebViewSettings(
                            transparentBackground: true,
                            // Drawn into a texture: Flutter's HUD on top
                            // then repaints without stalling the web view.
                            useHybridComposition: false,
                            supportZoom: false,
                            disableContextMenu: true,
                            mediaPlaybackRequiresUserGesture: false,
                          ),
                          onWebViewCreated: (controller) {
                            _web = controller;
                            controller.addJavaScriptHandler(
                              handlerName: 'rrStats',
                              callback: (args) {
                                // Frame rate, quality tier and triangle
                                // count from the 3D view, for tuning.
                                debugPrint(
                                  'Road Rumble 3D: fps=${args[0]} tier=${args[1]} tris=${args[2]}',
                                );
                                final tier = args[1];
                                if (tier is int && tier > _gfxTier) {
                                  _gfxTier = tier;
                                  unawaited(
                                    SharedPreferences.getInstance().then(
                                      (p) => p.setInt(_gfxKey, tier),
                                    ),
                                  );
                                }
                              },
                            );
                            controller.addJavaScriptHandler(
                              handlerName: 'rrAudio',
                              callback: (args) => debugPrint(
                                'Road Rumble audio: ${args.join(' ')}',
                              ),
                            );
                            controller.addJavaScriptHandler(
                              handlerName: 'rrReady',
                              callback: (_) {
                                if (!mounted) return;
                                setState(() => _webReady = true);
                                // A race may already be under way.
                                final e = _engine;
                                if (e != null && _screen == _Screen.race)
                                  _sendTrack(e);
                                _frame.value++;
                              },
                            );
                          },
                        ),
                      RepaintBoundary(
                        child: CustomPaint(
                          painter: _FramePainter(_paint, _frame),
                        ),
                      ),
                      if (_screen == _Screen.race)
                        IgnorePointer(child: _pad(size)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Translucent on-screen buttons, laid out over the touch zones.
  Widget _pad(Size size) {
    final unit = min(size.height * 0.2, 76.0);
    Widget button(int zone, String label, double cx, double cy, Color tint) {
      return Positioned(
        left: size.width * cx - unit / 2,
        top: size.height * cy - unit / 2,
        width: unit,
        height: unit,
        child: ValueListenableBuilder<int>(
          valueListenable: _held,
          builder: (context, held, _) {
            final down = held & zone != 0;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: tint.withValues(alpha: down ? 0.6 : 0.22),
                borderRadius: BorderRadius.circular(unit * 0.28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: down ? 0.9 : 0.45),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: unit * (label.length > 1 ? 0.2 : 0.42),
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Stack(
      children: [
        button(_zLeft, '◀', 0.09, 0.76, Colors.white),
        button(_zRight, '▶', 0.27, 0.76, Colors.white),
        button(_zKick, 'KICK', 0.73, 0.44, const Color(0xFFFFB81A)),
        button(_zPunch, 'PUNCH', 0.91, 0.44, const Color(0xFFE8392C)),
        button(_zBrake, 'BRAKE', 0.73, 0.78, Colors.white),
        button(_zGas, 'GAS', 0.91, 0.78, const Color(0xFF2FBF3A)),
      ],
    );
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.draw, Listenable repaint) : super(repaint: repaint);

  final void Function(Canvas canvas, Size size) draw;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size);

  @override
  bool shouldRepaint(_FramePainter old) => false;
}
