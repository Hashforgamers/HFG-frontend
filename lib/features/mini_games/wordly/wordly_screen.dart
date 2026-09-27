import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

import 'online/wordly_match.dart';
import 'online/wordly_match_service.dart';
import 'wordly_engine.dart';

enum _Mode { daily, practice, online }

enum _Phase {
  loading,
  menu,
  playing,
  result,
  lobby,
  countdown,
  waiting,
  raceOver,
}

/// Wordly: guess the five-letter word in six tries. Daily word, endless
/// practice, or race friends online on the same word (rivals see your tile
/// colours, never your letters).
class WordlyGame extends StatefulWidget {
  const WordlyGame({super.key, this.matchId});

  /// Opens straight into this online race (from an invite link).
  final String? matchId;

  @override
  State<WordlyGame> createState() => _WordlyGameState();
}

class _WordlyGameState extends State<WordlyGame> with TickerProviderStateMixin {
  static const gameId = 'wordly';
  static const _dailyKey = 'wordly_daily_board';
  static const _revealStepMs = 180;
  static const _flipMs = 360;

  final MiniGameScoreService _scores = MiniGameScoreService();
  WordlyWords? _words;

  _Phase _phase = _Phase.loading;
  _Mode _mode = _Mode.practice;
  String _answer = '';
  final List<String> _guesses = [];
  final List<List<LetterMark>> _marks = [];
  String _current = '';
  bool _locked = false;

  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(
      milliseconds: _revealStepMs * (kWordLength - 1) + _flipMs,
    ),
  );
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  int? _revealing; // row currently flipping
  String? _toast;
  Timer? _toastTimer;

  int _best = 0;
  int _points = 0;
  bool _dailyDone = false;

  // Online race.
  final WordlyMatchService _net = WordlyMatchService();
  String? _matchId;
  WordlyMatch? _match;
  StreamSubscription<WordlyMatch?>? _sub;
  int _round = 0;
  Timer? _clock;
  bool _busy = false;

  bool get _online => _matchId != null;
  bool get _solved =>
      _marks.isNotEmpty && _marks.last.every((m) => m == LetterMark.correct);
  bool get _boardDone => _solved || _guesses.length >= kMaxGuesses;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      final words = await WordlyWords.load();
      await _scores.ensureLoaded();
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _words = words;
        _best = _scores.bestScore(gameId);
        _dailyDone = _savedDaily(prefs) != null;
        _phase = _Phase.menu;
      });
      final invite = widget.matchId;
      if (invite != null && invite.isNotEmpty) unawaited(_joinRace(invite));
    } catch (e) {
      if (kDebugMode) AppLogger.d('Wordly failed to load: $e');
      _snack('Couldn’t load the word list.');
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    _shake.dispose();
    _toastTimer?.cancel();
    _clock?.cancel();
    _sub?.cancel();
    final id = _matchId;
    if (id != null) unawaited(_net.leaveMatch(id).catchError((_) {}));
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showToast(String text) {
    _toastTimer?.cancel();
    setState(() => _toast = text);
    _toastTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  // ------------------------------------------------------------- daily save

  String get _today {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  List<String>? _savedDaily(SharedPreferences prefs) {
    try {
      final raw = prefs.getString(_dailyKey);
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['date'] != _today) return null;
      return [for (final g in map['guesses'] as List) g.toString()];
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveDaily() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _dailyKey,
      jsonEncode({'date': _today, 'guesses': _guesses}),
    );
  }

  int get _dailyNumber => DateTime.now().difference(DateTime(2024)).inDays + 1;

  // ------------------------------------------------------------------ flow

  void _resetBoard(String answer) {
    _answer = answer;
    _guesses.clear();
    _marks.clear();
    _current = '';
    _locked = false;
    _revealing = null;
    _points = 0;
    _flip.value = 1;
  }

  Future<void> _startDaily() async {
    final words = _words;
    if (words == null) return;
    final prefs = await SharedPreferences.getInstance();
    _mode = _Mode.daily;
    _resetBoard(words.daily(DateTime.now()));
    final saved = _savedDaily(prefs);
    if (saved != null) {
      for (final g in saved) {
        _guesses.add(g);
        _marks.add(scoreGuess(g, _answer));
      }
      _points = wordlyPoints(solved: _solved, guesses: _guesses.length);
    }
    setState(
      () =>
          _phase = saved != null && _boardDone ? _Phase.result : _Phase.playing,
    );
  }

  void _startPractice() {
    final words = _words;
    if (words == null) return;
    _mode = _Mode.practice;
    _resetBoard(words.random());
    setState(() => _phase = _Phase.playing);
  }

  void _toMenu() {
    setState(() => _phase = _Phase.menu);
  }

  void _type(String ch) {
    if (_phase != _Phase.playing || _locked || _boardDone) return;
    if (_current.length >= kWordLength) return;
    Haptics.selection();
    setState(() => _current += ch);
  }

  void _backspace() {
    if (_phase != _Phase.playing || _locked || _current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  Future<void> _submit() async {
    if (_phase != _Phase.playing || _locked || _boardDone) return;
    final words = _words;
    if (words == null) return;
    if (_current.length < kWordLength) {
      _showToast('Not enough letters');
      unawaited(_shake.forward(from: 0));
      return;
    }
    if (!words.isValid(_current)) {
      _showToast('Not in word list');
      unawaited(_shake.forward(from: 0));
      return;
    }
    final guess = _current;
    setState(() {
      _locked = true;
      _guesses.add(guess);
      _marks.add(scoreGuess(guess, _answer));
      _current = '';
      _revealing = _guesses.length - 1;
    });
    if (_mode == _Mode.daily) unawaited(_saveDaily());
    if (_online) unawaited(_publish());
    await _flip.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _revealing = null;
      _locked = false;
    });
    if (_boardDone) await _finishBoard();
  }

  Future<void> _finishBoard() async {
    _points = wordlyPoints(solved: _solved, guesses: _guesses.length);
    if (_solved) {
      Haptics.selection();
      _showToast(
        const [
          'Genius!',
          'Magnificent!',
          'Impressive!',
          'Splendid!',
          'Great!',
          'Phew!',
        ][_guesses.length - 1],
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (_online) {
      setState(() => _phase = _Phase.waiting);
    } else {
      setState(() {
        _phase = _Phase.result;
        if (_mode == _Mode.daily) _dailyDone = true;
      });
    }
    try {
      await _scores.recordScore(gameId, _points);
    } catch (e) {
      if (kDebugMode) AppLogger.d('Wordly score save failed: $e');
    }
    if (mounted) setState(() => _best = _scores.bestScore(gameId));
  }

  // ------------------------------------------------------------ online flow

  Future<void> _createRace() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      _enterRace(await _net.createMatch());
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
      await _net.joinMatch(id);
      _enterRace(id);
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
      _mode = _Mode.online;
      _phase = _Phase.lobby;
      _round = 0;
    });
    _sub = _net.watch(id).listen(_onMatch);
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (mounted) _onClock();
    });
  }

  void _onMatch(WordlyMatch? m) {
    if (!mounted) return;
    final me = _net.uid;
    if (m == null || (me != null && !m.players.containsKey(me))) {
      _exitRace();
      if (m == null) _snack('The race was closed.');
      return;
    }
    _match = m;
    final words = _words;
    if (m.status == WordlyMatchStatus.active &&
        m.round != _round &&
        words != null) {
      _round = m.round;
      _resetBoard(words.answers[m.wordIndex % words.answers.length]);
      setState(() => _phase = _Phase.countdown);
      return;
    }
    if (m.status == WordlyMatchStatus.waiting && _phase != _Phase.lobby) {
      setState(() => _phase = _Phase.lobby);
      return;
    }
    if (m.status == WordlyMatchStatus.finished &&
        m.round == _round &&
        _phase != _Phase.raceOver &&
        _phase != _Phase.lobby) {
      final wasPlaying = _phase == _Phase.playing;
      setState(() => _phase = _Phase.raceOver);
      if (wasPlaying && !_boardDone) unawaited(_publish(done: true));
      return;
    }
    setState(() {});
  }

  void _onClock() {
    final m = _match;
    if (m == null) return;
    final now = _net.serverNowMs;
    if (_phase == _Phase.countdown && now >= m.startAtMs) {
      setState(() => _phase = _Phase.playing);
    } else if (_phase == _Phase.playing && now >= m.endAtMs) {
      // Time's up: lock the board as unsolved.
      setState(() => _phase = _Phase.waiting);
      unawaited(_publish(done: true));
      unawaited(_net.closeIfExpired(m.id, m.round).catchError((_) {}));
    } else if (_phase == _Phase.waiting && now >= m.endAtMs + 1500) {
      unawaited(_net.closeIfExpired(m.id, m.round).catchError((_) {}));
    }
    if (_phase == _Phase.countdown ||
        _phase == _Phase.playing ||
        _phase == _Phase.waiting) {
      setState(() {}); // tick the countdown / timer text
    }
  }

  Future<void> _publish({bool done = false}) async {
    final id = _matchId;
    if (id == null) return;
    final finished = done || _boardDone;
    try {
      await _net.submitProgress(
        id,
        round: _round,
        progress: WordlyProgress(
          rows: [for (final r in _marks) r.map((m) => m.code).join()],
          solved: _solved,
          done: finished,
          finishedAtMs: finished ? _net.serverNowMs : 0,
        ),
      );
    } catch (e) {
      if (kDebugMode) AppLogger.d('Wordly progress sync failed: $e');
    }
  }

  Future<void> _hostStart() async {
    final id = _matchId;
    final words = _words;
    if (id == null || words == null || _busy) return;
    setState(() => _busy = true);
    try {
      await _net.startRound(id, wordCount: words.answers.length);
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
    _clock?.cancel();
    _clock = null;
    _match = null;
    _matchId = null;
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
        sendInvite: (friend, matchId) =>
            chat.sendWordlyInviteMessage(friend: friend, matchId: matchId),
      ),
    );
  }

  // ------------------------------------------------------------------- UI

  void _onBack() {
    if (_online) {
      unawaited(_leaveRace());
    } else if (_phase == _Phase.playing || _phase == _Phase.result) {
      _toMenu();
    } else {
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
        body: SizedBox.expand(
          child: Stack(
            children: [
              const GameBackground(),
              SafeArea(
                child: Column(
                  children: [
                    _hud(),
                    if (_online && _showBoard) _rivals(),
                    Expanded(
                      child: _showBoard ? _boardArea() : const SizedBox(),
                    ),
                    if (_showBoard) _keyboard(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (_phase == _Phase.loading)
                const Center(child: CircularProgressIndicator()),
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

  bool get _modalShown =>
      _phase == _Phase.menu ||
      _phase == _Phase.result ||
      _phase == _Phase.lobby ||
      _phase == _Phase.raceOver;

  bool get _showBoard =>
      _phase == _Phase.playing ||
      _phase == _Phase.result ||
      _phase == _Phase.countdown ||
      _phase == _Phase.waiting ||
      _phase == _Phase.raceOver;

  Widget _hud() {
    final m = _match;
    String? timer;
    if (_online && m != null && _phase == _Phase.playing) {
      final left = max(0, m.endAtMs - _net.serverNowMs) ~/ 1000;
      timer = '⏱ ${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}';
    }
    final label = switch (_mode) {
      _Mode.daily => 'DAILY #$_dailyNumber',
      _Mode.practice => 'PRACTICE',
      _Mode.online => 'RACE',
    };
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
          const GameText('WORDLY', size: 28),
          const Spacer(),
          if (_showBoard) ...[
            GameBadge(label: timer ?? label),
            const SizedBox(width: 6),
          ],
          GameBadge(label: '🏆 $_best'),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ board

  Widget _boardArea() {
    return LayoutBuilder(
      builder: (context, box) {
        const gap = 6.0;
        final tile = min(
          (box.maxWidth - 48 - gap * (kWordLength - 1)) / kWordLength,
          (box.maxHeight - 16 - gap * (kMaxGuesses - 1)) / kMaxGuesses,
        ).clamp(28.0, 64.0);
        return Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var r = 0; r < kMaxGuesses; r++)
                    Padding(
                      padding: EdgeInsets.only(top: r == 0 ? 0 : gap),
                      child: _row(r, tile, gap),
                    ),
                ],
              ),
            ),
            if (_toast != null)
              Positioned(
                top: 4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GameColors.outline, width: 2.5),
                      boxShadow: const [
                        BoxShadow(color: Color(0x66000000), blurRadius: 12),
                      ],
                    ),
                    child: Text(
                      _toast!,
                      style: gameFont(16, GameColors.outline),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _row(int r, double tile, double gap) {
    final isCurrent =
        r == _guesses.length && _phase == _Phase.playing && !_boardDone;
    final letters = r < _guesses.length
        ? _guesses[r]
        : (isCurrent ? _current : '');
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < kWordLength; i++) ...[
          if (i > 0) SizedBox(width: gap),
          _tileFor(r, i, letters.length > i ? letters[i] : '', tile),
        ],
      ],
    );
    if (!isCurrent) return row;
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(sin(_shake.value * pi * 6) * 10 * (1 - _shake.value), 0),
        child: child,
      ),
      child: row,
    );
  }

  Widget _tileFor(int r, int i, String ch, double size) {
    final scored = r < _marks.length;
    if (!scored) return _Tile(letter: ch, mark: null, size: size);
    if (_revealing != r) {
      return _Tile(letter: ch, mark: _marks[r][i], size: size);
    }
    return AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final totalMs = _flip.duration!.inMilliseconds;
        final t = ((_flip.value * totalMs - i * _revealStepMs) / _flipMs).clamp(
          0.0,
          1.0,
        );
        final showMark = t >= 0.5;
        final angle = showMark ? (1 - t) * pi : t * pi;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002)
            ..rotateX(angle),
          child: _Tile(
            letter: ch,
            mark: showMark ? _marks[r][i] : null,
            size: size,
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------- keyboard

  Widget _keyboard() {
    // Only colour keys for rows that have finished flipping.
    final shown = _revealing == null ? _guesses.length : _revealing!;
    final marks = keyboardMarks(
      _guesses.take(shown).toList(),
      _marks.take(shown).toList(),
    );
    const rows = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          for (final (ri, keys) in rows.indexed)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  if (ri == 1) const Spacer(flex: 5),
                  if (ri == 2)
                    Expanded(
                      flex: 15,
                      child: _Key(
                        label: 'ENTER',
                        onTap: _submit,
                        colors: GameColors.green,
                      ),
                    ),
                  for (final k in keys.split(''))
                    Expanded(
                      flex: 10,
                      child: _Key(
                        label: k.toUpperCase(),
                        onTap: () => _type(k),
                        colors: switch (marks[k]) {
                          LetterMark.correct => GameColors.green,
                          LetterMark.present => GameColors.yellow,
                          LetterMark.absent => GameColors.grey,
                          null => GameColors.purple,
                        },
                        dim: marks[k] == LetterMark.absent,
                      ),
                    ),
                  if (ri == 1) const Spacer(flex: 5),
                  if (ri == 2)
                    Expanded(
                      flex: 15,
                      child: _Key(
                        icon: Icons.backspace_rounded,
                        onTap: _backspace,
                        colors: GameColors.red,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- rivals

  Widget _rivals() {
    final m = _match;
    final me = _net.uid;
    if (m == null) return const SizedBox.shrink();
    final rivals = m.ordered.where((p) => p.uid != me).toList();
    if (rivals.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final p in rivals)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _MiniBoard(name: p.name, progress: m.progressOf(p.uid)),
            ),
        ],
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
              Text('SAME WORD FOR EVERYONE', style: gameFont(16, Colors.white)),
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
      case _Phase.result:
        return _modal(_resultPanel());
      case _Phase.lobby:
        return _modal(_lobbyPanel());
      case _Phase.waiting:
        return Positioned(
          left: 0,
          right: 0,
          bottom: 24,
          child: Center(
            child: GameBadge(
              label: _solved
                  ? '✅ Solved in ${_guesses.length} · waiting for rivals…'
                  : '⌛ Waiting for rivals…',
            ),
          ),
        );
      case _Phase.raceOver:
        return _modal(_racePanel());
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _menu() {
    return GamePanel(
      headerColors: GameColors.green,
      headerHeight: 92,
      header: Row(
        children: [
          const _Tile(letter: 'W', mark: LetterMark.correct, size: 44),
          const SizedBox(width: 4),
          const _Tile(letter: 'O', mark: LetterMark.present, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FittedBox(child: GameText('WORDLY', size: 32)),
                Text(
                  'Guess the word in six tries.',
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
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                _rule(LetterMark.correct, 'Green', 'right letter, right spot'),
                _rule(LetterMark.present, 'Yellow', 'in the word, wrong spot'),
                _rule(LetterMark.absent, 'Grey', 'not in the word'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GameButton(
            label: _dailyDone ? 'Daily Done ✓' : 'Daily Word',
            icon: Icons.today_rounded,
            subtitle: _dailyDone
                ? 'See today’s board · new word tomorrow'
                : 'Word #$_dailyNumber · same for everyone',
            tone: GameButtonTone.green,
            height: 58,
            onPressed: _startDaily,
          ),
          const SizedBox(height: 8),
          GameButton(
            label: 'Practice',
            icon: Icons.all_inclusive_rounded,
            subtitle: 'Endless random words',
            tone: GameButtonTone.yellow,
            height: 54,
            onPressed: _startPractice,
          ),
          const SizedBox(height: 8),
          GameButton(
            label: _busy ? 'Creating race…' : 'Race Friends Online',
            icon: Icons.groups_rounded,
            subtitle: 'Same word · first to crack it wins',
            tone: GameButtonTone.purple,
            height: 54,
            onPressed: _busy ? null : _createRace,
          ),
        ],
      ),
    );
  }

  Widget _rule(LetterMark mark, String title, String detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        _Tile(
          letter: mark == LetterMark.correct
              ? 'A'
              : mark == LetterMark.present
              ? 'B'
              : 'C',
          mark: mark,
          size: 30,
        ),
        const SizedBox(width: 10),
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

  Widget _answerTiles() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < _answer.length; i++) ...[
        if (i > 0) const SizedBox(width: 5),
        _Tile(
          letter: _answer[i],
          mark: _solved ? LetterMark.correct : LetterMark.present,
          size: 40,
        ),
      ],
    ],
  );

  Widget _resultPanel() {
    return GamePanel(
      headerColors: _solved ? GameColors.green : GameColors.red,
      headerHeight: 72,
      header: Center(
        child: GameText(_solved ? 'SOLVED!' : 'SO CLOSE', size: 30),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Text(
                  _solved
                      ? 'Cracked in ${_guesses.length}/$kMaxGuesses'
                      : 'The word was',
                  style: gameFont(14, GameColors.soft),
                ),
                const SizedBox(height: 8),
                _answerTiles(),
                const SizedBox(height: 10),
                GameText('+$_points', size: 40, color: GameColors.yellow.$1),
                Text('points', style: gameFont(13, GameColors.soft)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_mode == _Mode.daily)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'New daily word tomorrow',
                textAlign: TextAlign.center,
                style: gameFont(14, GameColors.soft),
              ),
            ),
          GameButton(
            label: _mode == _Mode.daily ? 'Practice' : 'Next Word',
            icon: Icons.refresh_rounded,
            tone: GameButtonTone.green,
            onPressed: _startPractice,
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
  }

  Widget _playerRow(
    WordlyPlayer p, {
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
    final players = m?.ordered ?? const <WordlyPlayer>[];
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
              child: GameText('WORD RACE', size: 30),
            ),
          ),
          GameBadge(
            label: '${players.length}/${WordlyMatch.maxPlayers}',
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
            'Same word for everyone, 3 minutes on the clock. You see '
            'rivals’ colours, never their letters.',
            textAlign: TextAlign.center,
            style: gameFont(13, GameColors.soft),
          ),
          const SizedBox(height: 10),
          GameTray(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (var i = 0; i < WordlyMatch.maxPlayers; i++)
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
                      ClipboardData(text: WordlyMatchService.inviteLink(id)),
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
    final standings = m?.standings ?? const <WordlyPlayer>[];
    final won =
        standings.isNotEmpty &&
        standings.first.uid == me &&
        (m?.progressOf(me ?? '').solved ?? false);
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
          Text(
            'The word was',
            textAlign: TextAlign.center,
            style: gameFont(14, GameColors.soft),
          ),
          const SizedBox(height: 6),
          _answerTiles(),
          const SizedBox(height: 12),
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
                        return GameBadge(
                          label: pr.solved
                              ? '${pr.rows.length}/$kMaxGuesses'
                              : '✗ ${pr.bestGreens} 🟩',
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

// ---------------------------------------------------------------- widgets

(Color, Color) _markColors(LetterMark? mark) => switch (mark) {
  LetterMark.correct => GameColors.green,
  LetterMark.present => GameColors.yellow,
  LetterMark.absent => GameColors.grey,
  null => (GameColors.socket, GameColors.socket),
};

/// Chunky letter tile: dark outline, coloured face with a lip once scored.
class _Tile extends StatelessWidget {
  const _Tile({required this.letter, required this.mark, required this.size});

  final String letter;
  final LetterMark? mark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = _markColors(mark);
    final filled = letter.isNotEmpty;
    final lip = mark == null
        ? GameColors.trayEdge
        : Color.lerp(bottom, Colors.black, 0.35)!;
    return AnimatedScale(
      scale: filled && mark == null ? 1.04 : 1,
      duration: const Duration(milliseconds: 90),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: GameColors.outline,
          borderRadius: BorderRadius.circular(size * 0.2),
        ),
        padding: const EdgeInsets.all(2.5),
        child: Container(
          decoration: BoxDecoration(
            color: lip,
            borderRadius: BorderRadius.circular(size * 0.17),
            border: mark == null && filled
                ? Border.all(color: GameColors.soft, width: 2)
                : null,
          ),
          padding: EdgeInsets.only(bottom: mark == null ? 0 : size * 0.07),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.15),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: mark == null
                    ? const [GameColors.socket, GameColors.socket]
                    : [top, bottom],
              ),
            ),
            child: Center(
              child: filled
                  ? GameText(letter.toUpperCase(), size: size * 0.5)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _Key extends StatefulWidget {
  const _Key({
    required this.onTap,
    required this.colors,
    this.label,
    this.icon,
    this.dim = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final (Color, Color) colors;
  final bool dim;

  @override
  State<_Key> createState() => _KeyState();
}

class _KeyState extends State<_Key> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final (top, bottom) = widget.colors;
    final lip = Color.lerp(bottom, Colors.black, 0.4)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: Opacity(
          opacity: widget.dim ? 0.6 : 1,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: GameColors.outline,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(2),
            child: Container(
              decoration: BoxDecoration(
                color: lip,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.only(
                top: _down ? 3 : 0,
                bottom: _down ? 0 : 3,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [top, bottom],
                  ),
                ),
                child: Center(
                  child: widget.icon != null
                      ? GameIcon(icon: widget.icon!, size: 20)
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: GameText(
                              widget.label ?? '',
                              size: widget.label!.length > 1 ? 13 : 19,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rival's board as colours only.
class _MiniBoard extends StatelessWidget {
  const _MiniBoard({required this.name, required this.progress});

  final String name;
  final WordlyProgress progress;

  @override
  Widget build(BuildContext context) {
    const cell = 8.0;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
      decoration: BoxDecoration(
        color: GameColors.outline.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: progress.solved ? GameColors.green.$1 : GameColors.outline,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var r = 0; r < kMaxGuesses; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 1.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < kWordLength; i++)
                    Container(
                      width: cell,
                      height: cell,
                      margin: const EdgeInsets.only(right: 1.5),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color:
                            r < progress.rows.length &&
                                i < progress.rows[r].length
                            ? _markColors(
                                LetterMark.fromCode(progress.rows[r][i]),
                              ).$2
                            : GameColors.socket,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 2),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 60),
            child: Text(
              progress.solved ? '✅ $name' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gameFont(10, Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
