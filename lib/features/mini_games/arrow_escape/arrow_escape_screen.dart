import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/core/utils/app_logger.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/features/mini_games/common/cosmetics.dart';
import 'package:hash/features/mini_games/common/game_looks.dart';
import 'package:hash/features/mini_games/common/game_sfx.dart';
import 'package:hash/features/mini_games/common/game_shops.dart';
import 'package:hash/features/mini_games/common/mini_game_coins.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_invite_friends_sheet.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_page.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'arrow_escape_engine.dart';
import 'online/arrow_match.dart';
import 'online/arrow_match_service.dart';
import 'package:hash/features/mini_games/arcade_analytics.dart';

enum _Phase {
  menu,
  playing,
  levelClear,
  gameOver,
  lobby,
  countdown,
  waiting,
  raceOver,
}

/// Arrow Escape: tap an arrow to send it flying off the board. It only
/// escapes if nothing is in its way. Solo, a bump costs a life and cleared
/// boards get bigger; online, friends race to untangle the same board.
class ArrowEscapeScreen extends StatefulWidget {
  const ArrowEscapeScreen({super.key, this.matchId, this.rng});

  /// Opens straight into this online race (from an invite link).
  final String? matchId;

  /// Fixed board generation for tests.
  @visibleForTesting
  final Random? rng;

  @override
  State<ArrowEscapeScreen> createState() => _ArrowEscapeScreenState();
}

class _ArrowEscapeScreenState extends State<ArrowEscapeScreen>
    with SingleTickerProviderStateMixin {
  static const gameId = 'arrow_escape';

  /// How long a bump locks the board during a race.
  static const _freezeMs = 1500;
  static const _levelKey = 'arrow_escape_level';

  /// Firestore queues writes while offline, so cap how long a lobby may hang.
  static const _netTimeout = Duration(seconds: 12);

  late final MiniGameScoreService _scores = MiniGameScoreService();
  late final ArrowMatchService _net = ArrowMatchService();
  late final Ticker _ticker = createTicker(_tick);
  final GameSfx _sfx = GameSfx(prefix: 'assets/arrow_escape/');
  final ValueNotifier<double> _clock = ValueNotifier(0);
  Duration _lastElapsed = Duration.zero;

  _Phase _phase = _Phase.menu;
  late ArrowEscapeRun _run;
  final List<_Fx> _fx = [];
  final List<_Pop> _pops = [];
  double _introStart = 0;
  int? _hintId;
  int _best = 0;
  bool _locked = false;
  bool _recorded = false;

  /// Highest level reached so far; runs start here.
  int _unlocked = 1;
  bool _reviving = false;

  // Online race.
  StreamSubscription<ArrowMatch?>? _sub;
  Timer? _raceTimer;
  ArrowMatch? _match;
  String? _matchId;
  ArrowBoard? _raceBoard;
  int _round = 0;
  int _bumps = 0;
  int _frozenUntilMs = 0;
  int _finishedAtMs = 0;
  bool _raceDone = false;
  bool _publishing = false;
  bool _dirty = false;
  bool _busy = false;

  bool get _online => _matchId != null;
  ArrowBoard get _board => _online ? _raceBoard! : _run.board;
  bool get _frozen =>
      _online && DateTime.now().millisecondsSinceEpoch < _frozenUntilMs;

  @override
  void initState() {
    super.initState();
    ArcadeAnalytics.opened(
      gameId,
      source: widget.matchId == null ? null : 'invite',
    );
    _loadBest();
    _loadProgress();
    CosmeticStore.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    unawaited(
      _sfx.load(['woosh.mp3', 'bump.wav', 'clear.wav', 'over.wav', 'go.wav']),
    );
    final invite = widget.matchId;
    if (invite != null && invite.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _joinRace(invite));
    }
  }

  @override
  void dispose() {
    ArcadeAnalytics.closed(gameId);
    _ticker.dispose();
    unawaited(_sfx.dispose());
    _clock.dispose();
    _raceTimer?.cancel();
    _sub?.cancel();
    final id = _matchId;
    if (id != null) unawaited(_net.leaveMatch(id).catchError((_) {}));
    super.dispose();
  }

  Future<void> _loadBest() async {
    try {
      await _scores.ensureLoaded();
      if (mounted) setState(() => _best = _scores.bestScore(gameId));
    } catch (e) {
      if (kDebugMode) AppLogger.d('Arrow Escape best score load failed: $e');
    }
  }

  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final level = prefs.getInt(_levelKey) ?? 1;
      if (mounted) setState(() => _unlocked = max(1, level));
    } catch (e) {
      if (kDebugMode) AppLogger.d('Arrow Escape progress load failed: $e');
    }
  }

  Future<void> _unlock(int level) async {
    if (level <= _unlocked) return;
    _unlocked = level;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_levelKey, level);
    } catch (e) {
      if (kDebugMode) AppLogger.d('Arrow Escape progress save failed: $e');
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // The ticker only runs while something is animating.
  void _tick(Duration elapsed) {
    _clock.value += (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;
    final now = _clock.value;
    _fx.removeWhere((f) => now >= f.start + f.duration);
    _pops.removeWhere((p) => now >= p.start + _Pop.life);
    if (_fx.isEmpty &&
        _pops.isEmpty &&
        _hintId == null &&
        now > _introStart + 1.5) {
      _ticker.stop();
    }
  }

  void _animate() {
    if (_ticker.isActive) return;
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  /// Clears leftover effects and slides the new board's arrows in.
  void _dealBoard({bool hidden = false}) {
    _fx.clear();
    _pops.clear();
    _hintId = null;
    _locked = false;
    _introStart = hidden ? double.infinity : _clock.value;
    if (!hidden) _animate();
  }

  // ------------------------------------------------------------- solo flow

  void _startRun({int? level}) {
    ArcadeAnalytics.started(gameId, level: level ?? _unlocked);
    setState(() {
      _run = ArrowEscapeRun(rng: widget.rng, startLevel: level ?? _unlocked);
      _recorded = false;
      _phase = _Phase.playing;
      _dealBoard();
    });
  }

  void _onBoardTap(Offset local, double cell) {
    if (_phase != _Phase.playing || _locked || _frozen) return;
    final arrow = _board.arrowAt(local.dx ~/ cell, local.dy ~/ cell);
    if (arrow == null) return;
    // Let a bump finish before the same arrow can be tried again.
    if (_fx.any((f) => f.arrow == arrow)) return;
    if (_online) {
      _raceTap(arrow);
      return;
    }

    final before = _run.score;
    final (outcome, move) = _run.tap(arrow);
    final fx = _addFx(arrow, move);
    if (move.escaped) {
      final bonus = outcome == ArrowTapOutcome.levelCleared
          ? ArrowEscapeRun.clearBonus(_run.level)
          : 0;
      _pops.add(
        _Pop(
          cell: arrow.head,
          text: '+${_run.score - before - bonus}',
          start: _clock.value,
        ),
      );
    }

    switch (outcome) {
      case ArrowTapOutcome.escaped:
        Haptics.selection();
        _sfx.play('woosh.mp3');
      case ArrowTapOutcome.blocked:
        Haptics.heavy();
        _sfx.play('bump.wav');
      case ArrowTapOutcome.levelCleared:
        Haptics.medium();
        _sfx.play('clear.wav');
        _finish(_Phase.levelClear, fx);
      case ArrowTapOutcome.gameOver:
        Haptics.heavy();
        _sfx.play('over.wav');
        _finish(_Phase.gameOver, fx);
    }
  }

  _Fx _addFx(EscapeArrow arrow, ArrowMove move) {
    final fx = _Fx(
      arrow: arrow,
      escaped: move.escaped,
      steps: move.steps,
      start: _clock.value,
    );
    setState(() {
      _hintId = null;
      _fx.add(fx);
    });
    _animate();
    return fx;
  }

  /// Shows the level-clear / game-over panel once the last move has played.
  Future<void> _finish(_Phase phase, _Fx last) async {
    _locked = true;
    await Future<void>.delayed(
      Duration(milliseconds: (last.duration * 1000).round() + 150),
    );
    if (!mounted || _online) return;
    setState(() => _phase = phase);
    if (phase == _Phase.levelClear) unawaited(_unlock(_run.level + 1));
    if (phase == _Phase.gameOver) await _recordScore(_run.score);
  }

  Future<void> _recordScore(int score) async {
    if (_recorded) return;
    _recorded = true;
    if (score <= 0) {
      // Nothing to hand in, but the run still ended.
      ArcadeAnalytics.completed(gameId, score: 0);
      return;
    }
    try {
      await _scores.recordScore(gameId, score);
    } catch (e) {
      if (kDebugMode) AppLogger.d('Arrow Escape score save failed: $e');
    }
    if (mounted) setState(() => _best = _scores.bestScore(gameId));
  }

  void _nextLevel() {
    setState(() {
      _run.nextLevel();
      _phase = _Phase.playing;
      _dealBoard();
    });
  }

  void _showHint() {
    if (_phase != _Phase.playing || _locked || _run.hints <= 0) return;
    Haptics.selection();
    setState(() => _hintId = _run.useHint()?.id);
    _animate();
  }

  /// Spends HashCoins to refill the lives on the same board.
  Future<void> _continueWithCoins() async {
    if (_reviving) return;
    setState(() => _reviving = true);
    final paid = await MiniGameCoins.spend(
      context,
      amount: MiniGameCoins.arrowEscapeContinue,
      source: 'arrow_escape_continue',
    );
    if (!mounted) return;
    setState(() {
      _reviving = false;
      if (!paid) return;
      _run.revive();
      _locked = false;
      _recorded = false;
      _phase = _Phase.playing;
    });
  }

  /// Out of free hints: buy one.
  Future<void> _buyHint() async {
    if (_phase != _Phase.playing || _locked || _reviving) return;
    setState(() => _reviving = true);
    final paid = await MiniGameCoins.spend(
      context,
      amount: MiniGameCoins.arrowEscapeHint,
      source: 'arrow_escape_hint',
    );
    if (!mounted) return;
    setState(() {
      _reviving = false;
      if (paid) _run.hints++;
    });
    if (paid) _showHint();
  }

  // ------------------------------------------------------------ online flow

  Future<void> _createRace() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _enterRace(await _net.createMatch().timeout(_netTimeout));
    } on TimeoutException {
      _snack('No connection. Check your internet and try again.');
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
      await _net.joinMatch(id).timeout(_netTimeout);
      _enterRace(id);
    } on TimeoutException {
      _snack('No connection. Check your internet and try again.');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _enterRace(String id) {
    if (!mounted) return;
    _sub?.cancel();
    setState(() {
      _matchId = id;
      _phase = _Phase.lobby;
      _round = 0;
    });
    _sub = _net.watch(id).listen(_onMatch);
    _raceTimer?.cancel();
    _raceTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) _onClock();
    });
  }

  void _onMatch(ArrowMatch? m) {
    if (!mounted) return;
    final me = _net.uid;
    if (m == null || (me != null && !m.players.containsKey(me))) {
      _exitRace();
      if (m == null) _snack('The race was closed.');
      return;
    }
    _match = m;
    if (m.status == ArrowMatchStatus.active && m.round != _round) {
      _round = m.round;
      setState(() {
        _raceBoard = ArrowBoard.generate(
          cols: ArrowMatch.cols,
          rows: ArrowMatch.rows,
          rng: Random(m.seed),
          maxLength: ArrowMatch.maxLength,
        );
        _bumps = 0;
        _frozenUntilMs = 0;
        _finishedAtMs = 0;
        _raceDone = false;
        _recorded = false;
        _phase = _Phase.countdown;
        _dealBoard(hidden: true);
      });
      return;
    }
    if (m.status == ArrowMatchStatus.waiting && _phase != _Phase.lobby) {
      setState(() => _phase = _Phase.lobby);
      return;
    }
    if (m.status == ArrowMatchStatus.finished &&
        m.round == _round &&
        _phase != _Phase.raceOver &&
        _phase != _Phase.lobby) {
      final wasPlaying = _phase == _Phase.playing;
      setState(() => _phase = _Phase.raceOver);
      if (wasPlaying) _endMyRace();
      return;
    }
    setState(() {});
  }

  void _onClock() {
    final m = _match;
    if (m == null) return;
    final now = _net.serverNowMs;
    if (_phase == _Phase.countdown && now >= m.startAtMs) {
      _sfx.play('go.wav');
      ArcadeAnalytics.started(gameId, mode: 'online');
      setState(() {
        _phase = _Phase.playing;
        _dealBoard();
      });
    } else if (_phase == _Phase.playing && now >= m.endAtMs) {
      // Time's up: lock the board where it stands.
      setState(() => _phase = _Phase.waiting);
      _endMyRace();
      unawaited(_net.closeIfExpired(m.id, m.round).catchError((_) {}));
    } else if (_phase == _Phase.waiting && now >= m.endAtMs + 1500) {
      unawaited(_net.closeIfExpired(m.id, m.round).catchError((_) {}));
    }
    if (_phase == _Phase.countdown ||
        _phase == _Phase.playing ||
        _phase == _Phase.waiting) {
      setState(() {}); // tick the countdown / timer / freeze
    }
  }

  void _raceTap(EscapeArrow arrow) {
    final board = _board;
    final move = board.launch(arrow);
    _addFx(arrow, move);
    if (!move.escaped) {
      Haptics.heavy();
      _sfx.play('bump.wav');
      setState(() {
        _bumps++;
        _frozenUntilMs = DateTime.now().millisecondsSinceEpoch + _freezeMs;
      });
      unawaited(_publish());
      return;
    }
    Haptics.selection();
    if (board.cleared) {
      Haptics.medium();
      _sfx.play('clear.wav');
      setState(() => _phase = _Phase.waiting);
      _endMyRace();
    } else {
      _sfx.play('woosh.mp3');
      unawaited(_publish());
    }
  }

  /// Locks in my board for this round and banks the race score.
  void _endMyRace() {
    if (_raceDone) return;
    final m = _match;
    final board = _raceBoard;
    if (m == null || board == null) return;
    _raceDone = true;
    _finishedAtMs = _net.serverNowMs;
    unawaited(_publish());
    final secondsLeft = max(0, m.endAtMs - _finishedAtMs) ~/ 1000;
    unawaited(
      _recordScore(
        board.escapedCount * 10 + (board.cleared ? 100 + secondsLeft : 0),
      ),
    );
  }

  /// Publishes my progress; taps made while a write is in flight are folded
  /// into one follow-up write.
  Future<void> _publish() async {
    final id = _matchId;
    final board = _raceBoard;
    if (id == null || board == null) return;
    if (_publishing) {
      _dirty = true;
      return;
    }
    _publishing = true;
    try {
      do {
        _dirty = false;
        await _net.submitProgress(
          id,
          round: _round,
          progress: ArrowProgress(
            escaped: board.escapedCount,
            total: board.initialCount,
            bumps: _bumps,
            done: _raceDone,
            finishedAtMs: _raceDone ? _finishedAtMs : 0,
          ),
        );
      } while (_dirty && mounted);
    } catch (e) {
      if (kDebugMode) AppLogger.d('Arrow Escape progress sync failed: $e');
    } finally {
      _publishing = false;
    }
  }

  Future<void> _hostStart() async {
    final id = _matchId;
    if (id == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _net.startRound(id);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leaveRace() async {
    final id = _matchId;
    _exitRace();
    if (id != null) {
      try {
        await _net.leaveMatch(id);
      } catch (_) {}
    }
  }

  void _exitRace() {
    _sub?.cancel();
    _sub = null;
    _raceTimer?.cancel();
    _raceTimer = null;
    _match = null;
    _matchId = null;
    _raceBoard = null;
    _round = 0;
    if (mounted) setState(() => _phase = _Phase.menu);
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
        game: 'arrow',
        sendInvite: (friend, matchId) =>
            chat.sendArrowEscapeInviteMessage(friend: friend, matchId: matchId),
      ),
    );
  }

  // ------------------------------------------------------------------- UI

  /// The host backing out of the lobby closes the room for everyone they
  /// invited, so check first.
  Future<void> _confirmLeaveLobby() async {
    if (!await confirmCancelInvite(context)) return;
    if (!mounted) return;
    await _leaveRace();
  }

  void _onBack() {
    if (_online && _phase == _Phase.lobby && _match?.hostUid == _net.uid) {
      unawaited(_confirmLeaveLobby());
      return;
    }
    if (_online) {
      unawaited(_leaveRace());
    } else if (_phase == _Phase.playing || _phase == _Phase.levelClear) {
      // Leaving mid-run ends it, so bank whatever was scored.
      unawaited(_recordScore(_run.score));
      setState(() => _phase = _Phase.menu);
    } else {
      Navigator.of(context).pop();
    }
  }

  bool get _modalShown =>
      _phase == _Phase.menu ||
      _phase == _Phase.levelClear ||
      _phase == _Phase.gameOver ||
      _phase == _Phase.lobby ||
      _phase == _Phase.raceOver;

  bool get _showBoard =>
      _phase != _Phase.menu &&
      _phase != _Phase.lobby &&
      (!_online || _raceBoard != null);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
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
                    _hud(),
                    if (_showBoard) ...[
                      _online ? _raceStats() : _stats(),
                      Expanded(child: _boardArea()),
                      _footer(),
                    ],
                  ],
                ),
              ),
              if (_phase == _Phase.countdown) _countdown(),
              _panelLayer(),
              // Keep Back / Leave tappable above the panels' dim overlay.
              if (_modalShown) SafeArea(child: _hud()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hud() {
    final m = _match;
    String? timer;
    if (_online && m != null && _phase == _Phase.playing) {
      final left = max(0, m.endAtMs - _net.serverNowMs) ~/ 1000;
      timer = '⏱ ${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}';
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          GameIconButton(
            icon: _online ? Icons.close_rounded : Icons.arrow_back_rounded,
            tooltip: _online ? 'Leave race' : 'Back',
            colors: _online ? GameColors.red : GameColors.purple,
            onPressed: _onBack,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: GameText('ARROW ESCAPE', size: 26),
            ),
          ),
          const SizedBox(width: 8),
          GameBadge(label: timer ?? '🏆 $_best'),
        ],
      ),
    );
  }

  Widget _bar(double fraction, Color color, {double height = 10}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: GameColors.socket,
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: GameColors.outline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.centerLeft,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        widthFactor: fraction.clamp(0.0, 1.0),
        heightFactor: 1,
        child: ColoredBox(color: color),
      ),
    );
  }

  Widget _stats() {
    final board = _run.board;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: GameBadge(
                    label:
                        'LEVEL ${_run.level} · '
                        '${ArrowEscapeRun.tierFor(_run.level)}',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              for (var i = 0; i < ArrowEscapeRun.maxLives; i++)
                AnimatedScale(
                  scale: i < _run.lives ? 1 : 0.8,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      i < _run.lives
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 26,
                      color: i < _run.lives
                          ? GameColors.red.$1
                          : GameColors.soft.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: GameBadge(label: '⭐ ${_run.score}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _bar(
            board.initialCount == 0
                ? 0
                : board.escapedCount / board.initialCount,
            GameColors.green.$1,
          ),
        ],
      ),
    );
  }

  /// Everyone's progress on the shared board, mine first.
  Widget _raceStats() {
    final m = _match;
    final board = _raceBoard;
    final me = _net.uid;
    if (m == null || board == null) return const SizedBox.shrink();
    Widget lane(String name, ArrowProgress p, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 74,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gameFont(14, Colors.white),
            ),
          ),
          Expanded(child: _bar(p.fraction, color)),
          SizedBox(
            width: 52,
            child: Text(
              p.cleared ? '🏁' : '${p.escaped}/${p.total}',
              textAlign: TextAlign.right,
              style: gameFont(13, GameColors.soft),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 6),
      child: GameTray(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Column(
          children: [
            lane(
              'You',
              ArrowProgress(
                escaped: board.escapedCount,
                total: board.initialCount,
                bumps: _bumps,
                done: _raceDone,
                finishedAtMs: _finishedAtMs,
              ),
              GameColors.green.$1,
            ),
            for (final p in m.ordered.where((p) => p.uid != me))
              lane(
                p.name,
                // Rivals start on the same board, so show its size early.
                m.progress.containsKey(p.uid)
                    ? m.progressOf(p.uid)
                    : ArrowProgress(
                        escaped: 0,
                        total: board.initialCount,
                        bumps: 0,
                        done: false,
                        finishedAtMs: 0,
                      ),
                GameColors.yellow.$1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _boardArea() {
    final board = _board;
    return LayoutBuilder(
      builder: (context, box) {
        final cell = min(
          (box.maxWidth - 32) / board.cols,
          (box.maxHeight - 20) / board.rows,
        );
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => _onBoardTap(d.localPosition, cell),
            child: CustomPaint(
              key: const Key('arrow_escape_board'),
              size: Size(cell * board.cols, cell * board.rows),
              painter: _BoardPainter(
                board: board,
                fx: _fx,
                pops: _pops,
                hintId: _hintId,
                introStart: _introStart,
                frozen: _frozen,
                look: ArrowLook.current,
                clock: _clock,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _footer() {
    final left = '${_board.arrows.length} arrows left';
    final hints = _online ? '' : '\n💡 ${_run.hints} hints';
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _online
                    ? '$left · $_bumps bumps'
                    : '$left${_run.streak > 1 ? ' · 🔥 x${_run.streak}' : ''}$hints',
                style: gameFont(15, GameColors.soft),
              ),
            ),
            if (_online)
              AnimatedOpacity(
                opacity: _frozen ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: const GameBadge(label: '🧊 FROZEN'),
              )
            else
              SizedBox(
                width: 130,
                child: GameButton(
                  label: 'Hint',
                  icon: Icons.lightbulb_rounded,
                  subtitle: _run.hints > 0
                      ? null
                      : '${MiniGameCoins.arrowEscapeHint} coins',
                  tone: GameButtonTone.yellow,
                  height: 46,
                  onPressed: _run.hints > 0 ? _showHint : _buyHint,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _countdown() {
    final m = _match;
    final left = m == null ? 3.0 : (m.startAtMs - _net.serverNowMs) / 1000;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SAME BOARD FOR EVERYONE',
                style: gameFont(16, Colors.white),
              ),
              const SizedBox(height: 8),
              GameText(
                left > 0 ? '${left.ceil().clamp(1, 9)}' : 'GO!',
                size: 84,
                color: GameColors.yellow.$1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- panels

  Widget _modal(Widget panel) => Positioned.fill(
    child: ColoredBox(
      color: Colors.black.withValues(alpha: 0.55),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
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
      case _Phase.levelClear:
        return _modal(_levelClearPanel());
      case _Phase.gameOver:
        return _modal(_gameOverPanel());
      case _Phase.lobby:
        return _modal(_lobbyPanel());
      case _Phase.raceOver:
        return _modal(_racePanel());
      case _Phase.waiting:
        return Positioned(
          left: 0,
          right: 0,
          bottom: 84,
          child: Center(
            child: GameBadge(
              label: _raceBoard?.cleared ?? false
                  ? '🏁 Board cleared · waiting for rivals…'
                  : '⌛ Time’s up · waiting for rivals…',
            ),
          ),
        );
      case _Phase.playing:
      case _Phase.countdown:
        return const SizedBox.shrink();
    }
  }

  Widget _leaderboardButton() => GameButton(
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
  );

  Widget _menu() {
    return GamePanel(
      headerColors: GameColors.green,
      headerHeight: 92,
      header: Row(
        children: [
          const SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(painter: _LogoPainter()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FittedBox(child: GameText('ARROW ESCAPE', size: 30)),
                Text(
                  'Untangle the board, one arrow at a time.',
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in const [
                  '👆 Tap an arrow to shoot it off the board.',
                  '🚧 It only escapes if its lane is clear.',
                  '💔 Solo: every bump costs one of 3 lives.',
                  '🏁 Race: first to clear the same board wins.',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(line, style: gameFont(15, Colors.white)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GameButton(
            label: 'Play',
            icon: Icons.play_arrow_rounded,
            subtitle:
                'Solo · Level $_unlocked · ${ArrowEscapeRun.tierFor(_unlocked)}',
            height: 60,
            onPressed: _startRun,
          ),
          if (_unlocked > 1) ...[
            const SizedBox(height: 10),
            GameButton(
              label: 'Start from Level 1',
              icon: Icons.restart_alt_rounded,
              tone: GameButtonTone.grey,
              height: 44,
              onPressed: () => _startRun(level: 1),
            ),
          ],
          const SizedBox(height: 10),
          GameButton(
            label: 'Race Friends',
            icon: Icons.groups_rounded,
            subtitle: '2–4 players · same board',
            tone: _busy ? GameButtonTone.grey : GameButtonTone.purple,
            height: 60,
            onPressed: _busy ? null : _createRace,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  label: 'Themes',
                  icon: Icons.palette_rounded,
                  tone: GameButtonTone.purple,
                  height: 46,
                  onPressed: () async {
                    await openCosmeticShop(
                      context,
                      title: 'ARROW THEMES',
                      tabs: GameShops.arrowEscape,
                    );
                    if (mounted) setState(() {});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _leaderboardButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _levelClearPanel() {
    return GamePanel(
      headerColors: GameColors.yellow,
      header: Center(child: GameText('LEVEL ${_run.level} CLEARED', size: 24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 40)),
                GameText(
                  '+${ArrowEscapeRun.clearBonus(_run.level)}',
                  size: 34,
                  color: GameColors.yellow.$1,
                ),
                Text('level bonus', style: gameFont(14, GameColors.soft)),
                const SizedBox(height: 6),
                Text('Score ${_run.score}', style: gameFont(18, Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GameButton(
            label: 'Next level',
            icon: Icons.arrow_forward_rounded,
            onPressed: _nextLevel,
          ),
        ],
      ),
    );
  }

  Widget _gameOverPanel() {
    return GamePanel(
      headerColors: GameColors.red,
      header: const Center(child: GameText('OUT OF LIVES', size: 26)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            child: Column(
              children: [
                GameText(
                  '${_run.score}',
                  size: 40,
                  color: GameColors.yellow.$1,
                ),
                Text(
                  'Reached level ${_run.level} · Best $_best',
                  style: gameFont(15, GameColors.soft),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GameButton(
            label: _reviving ? 'Spending…' : 'Continue',
            icon: Icons.favorite_rounded,
            subtitle:
                '${MiniGameCoins.arrowEscapeContinue} HashCoins · keep board & score',
            tone: _reviving ? GameButtonTone.grey : GameButtonTone.yellow,
            height: 60,
            onPressed: _reviving ? null : _continueWithCoins,
          ),
          const SizedBox(height: 10),
          GameButton(
            label: 'Retry Level ${_run.level}',
            icon: Icons.replay_rounded,
            onPressed: () => _startRun(level: _run.level),
          ),
          const SizedBox(height: 10),
          _leaderboardButton(),
        ],
      ),
    );
  }

  Widget _playerRow(
    ArrowPlayer p, {
    required bool isMe,
    Widget? trailing,
    String? lead,
  }) {
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
          if (lead != null) ...[
            SizedBox(
              width: 28,
              child: Text(
                lead,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 6),
          ],
          CircleAvatar(
            radius: 15,
            backgroundColor: GameColors.purple.$2,
            child: Text(
              p.name.isEmpty ? '?' : p.name[0].toUpperCase(),
              style: gameFont(15, Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isMe ? 'You' : p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gameFont(16, Colors.white),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _lobbyPanel() {
    final m = _match;
    final me = _net.uid;
    final isHost = m != null && m.hostUid == me;
    final players = m?.ordered ?? const <ArrowPlayer>[];
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
              child: GameText('ARROW RACE', size: 30),
            ),
          ),
          GameBadge(
            label: '${players.length}/${ArrowMatch.maxPlayers}',
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
            'Same board for everyone, 2 minutes on the clock. A bump '
            'freezes you for a moment.',
            textAlign: TextAlign.center,
            style: gameFont(13, GameColors.soft),
          ),
          const SizedBox(height: 10),
          GameTray(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (var i = 0; i < ArrowMatch.maxPlayers; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                    child: i < players.length
                        ? _playerRow(
                            players[i],
                            isMe: players[i].uid == me,
                            trailing: players[i].uid == m?.hostUid
                                ? const GameBadge(label: '👑 HOST')
                                : null,
                          )
                        : Container(
                            height: 48,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: GameColors.socket.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: GameColors.trayEdge,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              'Waiting for a player…',
                              style: gameFont(14, GameColors.soft),
                            ),
                          ),
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
                      ClipboardData(text: ArrowMatchService.inviteLink(id)),
                    );
                    _snack('Invite link copied');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GameButton(
            label: isHost ? 'Start Race' : 'Waiting for host…',
            icon: isHost ? Icons.flag_rounded : Icons.hourglass_top_rounded,
            subtitle: isHost && players.length < 2
                ? 'Need at least 2 players'
                : null,
            tone: canStart ? GameButtonTone.green : GameButtonTone.grey,
            height: 58,
            onPressed: canStart ? _hostStart : null,
          ),
        ],
      ),
    );
  }

  Widget _racePanel() {
    final m = _match;
    final me = _net.uid;
    final standings = m?.standings ?? const <ArrowPlayer>[];
    final won =
        standings.isNotEmpty &&
        standings.first.uid == me &&
        (m?.progressOf(me ?? '').cleared ?? false);
    final isHost = m != null && m.hostUid == me;
    const medals = ['🥇', '🥈', '🥉', '4️⃣'];
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
                    child: _playerRow(
                      p,
                      isMe: p.uid == me,
                      lead: medals[i.clamp(0, 3)],
                      trailing: () {
                        final pr = m!.progressOf(p.uid);
                        final secs = (pr.finishedAtMs - m.startAtMs) / 1000;
                        return GameBadge(
                          label: pr.cleared
                              ? '🏁 ${secs.toStringAsFixed(1)}s'
                              : '${pr.escaped}/${pr.total}',
                        );
                      }(),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
}

/// A move being played out: an escape flight or a bump-and-return.
class _Fx {
  _Fx({
    required this.arrow,
    required this.escaped,
    required this.steps,
    required this.start,
  });

  final EscapeArrow arrow;
  final bool escaped;
  final int steps;
  final double start;

  /// Cells travelled: off the board, or up to the blocker (plus a nudge).
  double get distance => escaped ? steps + arrow.length + 0.5 : steps + 0.18;

  double get duration => escaped ? 0.18 + 0.04 * distance : 0.26 + 0.06 * steps;
}

/// Points floating up from where an arrow took off.
class _Pop {
  _Pop({required this.cell, required this.text, required this.start});

  static const life = 0.8;

  final Point<int> cell;
  final String text;
  final double start;
}

const _arrowPalette = [
  Color(0xFFFF6B6B),
  Color(0xFFFFD93D),
  Color(0xFF6BCB77),
  Color(0xFF4D96FF),
  Color(0xFFFF9F45),
  Color(0xFFC77DFF),
  Color(0xFF4DD6D0),
  Color(0xFFFF7EB6),
];

/// Draws one arrow along [cells] (head first), slid [offset] cells forward
/// and grown to [grow] of its length from the tail.
void _paintArrow(
  Canvas canvas, {
  required List<Offset> cells,
  required Offset dir,
  required double cell,
  required Color color,
  double offset = 0,
  double grow = 1,
  double glow = 0,
  double reach = 40,
  Color outline = GameColors.outline,
}) {
  final track = Path()..moveTo(cells.last.dx, cells.last.dy);
  for (final p in cells.reversed.skip(1)) {
    track.lineTo(p.dx, p.dy);
  }
  final end = cells.first + dir * (reach * cell);
  track.lineTo(end.dx, end.dy);

  final metric = track.computeMetrics().first;
  final from = offset * cell;
  final to = from + (cells.length - 1) * cell * grow;
  final body = metric.extractPath(from, to);
  final tip = metric.getTangentForOffset(to);
  if (tip == null) return;
  final ahead = tip.vector;
  final side = Offset(-ahead.dy, ahead.dx);
  final size = cell * (0.4 + 0.6 * grow);
  final front = tip.position + ahead * (size * 0.4);
  final back = tip.position - ahead * (size * 0.08);
  final left = back + side * (size * 0.32);
  final right = back - side * (size * 0.32);
  final point = Path()
    ..moveTo(front.dx, front.dy)
    ..lineTo(left.dx, left.dy)
    ..lineTo(right.dx, right.dy)
    ..close();

  Paint stroke(Color c, double width) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..strokeWidth = width
    ..color = c;

  if (glow > 0) {
    final halo = Colors.white.withValues(alpha: 0.25 + 0.45 * glow);
    canvas.drawPath(body, stroke(halo, cell * 0.62));
    canvas.drawPath(point, stroke(halo, cell * 0.34));
  }
  // Soft drop shadow, then outline, colour and a glossy highlight.
  final drop = Offset(0, cell * 0.09);
  final shade = Colors.black.withValues(alpha: 0.3);
  canvas.drawPath(body.shift(drop), stroke(shade, cell * 0.42));
  canvas.drawPath(point.shift(drop), stroke(shade, cell * 0.14));
  canvas.drawPath(body, stroke(outline, cell * 0.42));
  canvas.drawPath(point, stroke(outline, cell * 0.14));
  canvas.drawPath(body, stroke(color, cell * 0.27));
  canvas.drawPath(point, Paint()..color = color);
  final gloss = Offset(-cell * 0.045, -cell * 0.045);
  canvas.drawPath(
    body.shift(gloss),
    stroke(Colors.white.withValues(alpha: 0.38), cell * 0.07),
  );
  canvas.drawPath(
    body.shift(-gloss),
    stroke(Colors.black.withValues(alpha: 0.16), cell * 0.07),
  );
}

class _BoardPainter extends CustomPainter {
  _BoardPainter({
    required this.board,
    required this.fx,
    required this.pops,
    required this.hintId,
    required this.introStart,
    required this.frozen,
    required this.look,
    required this.clock,
  }) : super(repaint: clock);

  final ArrowBoard board;
  final List<_Fx> fx;
  final List<_Pop> pops;
  final int? hintId;

  /// Clock time the arrows start sliding in (infinity keeps them hidden).
  final double introStart;
  final bool frozen;
  final ArrowLook look;
  final ValueNotifier<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    final now = clock.value;
    final cell = size.width / board.cols;
    Offset centre(Point<int> p) =>
        Offset((p.x + 0.5) * cell, (p.y + 0.5) * cell);

    // A bump rattles the whole board.
    final bumps = fx.where((f) => !f.escaped);
    canvas.save();
    if (bumps.isNotEmpty) {
      final f = bumps.last;
      final t = ((now - f.start) / f.duration).clamp(0.0, 1.0);
      canvas.translate(sin(t * pi * 6) * (1 - t) * cell * 0.07, 0);
    }

    final area = Offset.zero & size;
    final frame = RRect.fromRectAndRadius(
      area.inflate(8),
      const Radius.circular(20),
    );
    canvas.drawRRect(
      frame.shift(const Offset(0, 5)),
      Paint()..color = GameColors.outline,
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [look.boardTop, look.boardBottom],
        ).createShader(frame.outerRect),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = GameColors.outline,
    );
    final tile = Paint()..color = look.tile;
    for (var r = 0; r < board.rows; r++) {
      for (var c = 0; c < board.cols; c++) {
        if ((r + c).isOdd) continue;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(c * cell, r * cell, cell, cell).deflate(cell * 0.05),
            Radius.circular(cell * 0.2),
          ),
          tile,
        );
      }
    }

    // Escaping arrows disappear at the board edge.
    canvas.save();
    canvas.clipRRect(frame);
    final reach = (board.cols + board.rows + 8).toDouble();
    void draw(
      EscapeArrow arrow, {
      double offset = 0,
      double grow = 1,
      double glow = 0,
      Color? tint,
      double tintAmount = 0,
    }) {
      final base = look.palette[arrow.id % look.palette.length];
      _paintArrow(
        canvas,
        cells: [for (final c in arrow.cells) centre(c)],
        dir: Offset(arrow.dir.dx.toDouble(), arrow.dir.dy.toDouble()),
        cell: cell,
        color: tint == null ? base : Color.lerp(base, tint, tintAmount)!,
        offset: offset,
        grow: grow,
        glow: glow,
        reach: reach,
        outline: look.outline,
      );
    }

    for (final (i, arrow) in board.arrows.indexed) {
      final grow = Curves.easeOutBack.transform(
        ((now - introStart - i * 0.035) / 0.3).clamp(0.0, 1.0),
      );
      if (grow <= 0) continue;
      final bump = fx.where((f) => f.arrow == arrow).firstOrNull;
      final swing = bump == null
          ? 0.0
          : sin(pi * ((now - bump.start) / bump.duration).clamp(0.0, 1.0));
      draw(
        arrow,
        offset: (bump?.distance ?? 0) * swing,
        grow: grow.clamp(0.05, 1.15),
        glow: arrow.id == hintId ? 0.5 + 0.5 * sin(now * 6) : 0,
        tint: GameColors.red.$2,
        tintAmount: swing,
      );
      if (bump != null) {
        // Impact burst where the head meets the blocker.
        final hit =
            centre(arrow.head) +
            Offset(arrow.dir.dx.toDouble(), arrow.dir.dy.toDouble()) *
                ((bump.steps + 0.5) * cell);
        canvas.drawCircle(
          hit,
          cell * 0.5 * swing,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = cell * 0.08
            ..color = Colors.white.withValues(alpha: 0.8 * swing),
        );
      }
    }
    for (final f in fx.where((f) => f.escaped)) {
      final t = ((now - f.start) / f.duration).clamp(0.0, 1.0);
      draw(f.arrow, offset: f.distance * t * t);
    }
    canvas.restore();

    // Launch rings and floating points.
    for (final p in pops) {
      final t = ((now - p.start) / _Pop.life).clamp(0.0, 1.0);
      final at = centre(p.cell);
      canvas.drawCircle(
        at,
        cell * (0.3 + 0.7 * t),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * 0.07 * (1 - t)
          ..color = Colors.white.withValues(alpha: 0.6 * (1 - t)),
      );
      final label = TextPainter(
        text: TextSpan(
          text: p.text,
          style:
              gameFont(
                cell * 0.42,
                GameColors.yellow.$1.withValues(alpha: 1 - t * t),
              ).copyWith(
                shadows: [
                  Shadow(
                    color: GameColors.outline.withValues(alpha: 1 - t * t),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        at - Offset(label.width / 2, label.height / 2 + cell * 0.9 * t),
      );
    }

    if (frozen) {
      canvas.drawRRect(
        frame,
        Paint()..color = const Color(0xFF8FD3FF).withValues(alpha: 0.22),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BoardPainter old) => true;
}

/// The little pair of arrows in the menu header.
class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 3;
    Offset at(double x, double y) => Offset((x + 0.5) * cell, (y + 0.5) * cell);
    _paintArrow(
      canvas,
      cells: [at(1.7, 0.2), at(0.2, 0.2), at(0.2, 1.4)],
      dir: const Offset(1, 0),
      cell: cell,
      color: _arrowPalette[1],
    );
    _paintArrow(
      canvas,
      cells: [at(1.8, 1.1), at(1.8, 2), at(0.6, 2)],
      dir: const Offset(0, -1),
      cell: cell,
      color: _arrowPalette[3],
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}
