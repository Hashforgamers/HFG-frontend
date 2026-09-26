import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/chat/services/chat_service.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import '../ludo/constants.dart';
import '../ludo/ludo_score_service.dart';
import '../ludo/online/ludo_invite_friends_sheet.dart';
import '../ludo/online/ludo_match.dart';
import '../ludo/widgets/ludo_seat_token.dart';
import 'snl_board.dart';
import 'snl_match.dart';
import 'snl_match_service.dart';

/// Online Snakes & Ladders: lobby while waiting, then the synced board.
/// Every device animates the same [SnlMove] from the match document.
class SnlMatchScreen extends StatefulWidget {
  const SnlMatchScreen({super.key, required this.matchId});

  final String matchId;

  static const gameId = 'snakes_ladders';

  @override
  State<SnlMatchScreen> createState() => _SnlMatchScreenState();
}

class _SnlMatchScreenState extends State<SnlMatchScreen>
    with SingleTickerProviderStateMixin {
  static const _turnSeconds = 20;
  static const _abandonGraceMs = 6000;
  static const _hopMs = 170;
  static const _slideMs = 560;

  final SnlMatchService _service = SnlMatchService();
  StreamSubscription<SnlMatch?>? _sub;
  SnlMatch? _match;
  LudoPlayerType? _mySeat;
  String? _error;
  bool _joinAttempted = false;
  bool _starting = false;
  bool _rolling = false;
  bool _resultRecorded = false;

  // Displayed (animated) squares, which trail the authoritative positions.
  final Map<LudoPlayerType, int> _display = {};
  LudoPlayerType? _sliding;
  int _lastMoveId = 0;
  bool _animating = false;
  final List<SnlMove> _queue = [];
  String? _banner;

  Timer? _ticker;
  late final AnimationController _pulse;
  int _lastForcedTurn = 0;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _sub = _service
        .watch(widget.matchId)
        .listen(
          _onMatch,
          onError: (e) {
            if (mounted) setState(() => _error = e.toString());
          },
        );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    _sub?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- sync

  Future<void> _onMatch(SnlMatch? match) async {
    if (!mounted) return;
    if (match == null) {
      setState(() => _error = 'This room is no longer available.');
      return;
    }

    var seat = match.seatOf(_uid);
    if (seat == null &&
        match.status == LudoMatchStatus.waiting &&
        !match.isFull &&
        !_joinAttempted) {
      _joinAttempted = true;
      try {
        seat = await _service.joinMatch(widget.matchId);
      } catch (e) {
        if (mounted) setState(() => _error = e.toString());
        return;
      }
    }

    // First load: place tokens directly; later moves animate.
    if (_match == null) {
      _display
        ..clear()
        ..addAll(match.positions);
      _lastMoveId = match.lastMove?.id ?? 0;
    } else {
      final move = match.lastMove;
      if (move != null && move.id != _lastMoveId) {
        _lastMoveId = move.id;
        _queue.add(move);
        if (move.seat == _mySeat) _rolling = false;
        unawaited(_drainQueue());
      }
    }
    // Seats that joined or left.
    for (final s in match.seats.keys) {
      _display.putIfAbsent(s, () => match.positions[s] ?? 0);
    }
    _display.removeWhere((s, _) => !match.seats.containsKey(s));

    if (seat != null) {
      if (match.status == LudoMatchStatus.waiting ||
          match.status == LudoMatchStatus.active) {
        unawaited(_service.saveActiveMatch(widget.matchId));
      } else {
        unawaited(_service.clearActiveMatch(widget.matchId));
      }
    }
    if (match.status == LudoMatchStatus.finished) _recordResult(match, seat);

    setState(() {
      _match = match;
      _mySeat = seat;
    });
  }

  void _recordResult(SnlMatch match, LudoPlayerType? seat) {
    if (_resultRecorded || seat == null) return;
    final score = ludoPlacementScore(
      seat: seat,
      winners: match.winners,
      participants: {...match.seats.keys, ...match.winners},
      finished: true,
    );
    if (score == null) return;
    _resultRecorded = true;
    unawaited(MiniGameScoreService().recordScore(SnlMatchScreen.gameId, score));
  }

  Future<void> _drainQueue() async {
    if (_animating) return;
    _animating = true;
    while (_queue.isNotEmpty && mounted) {
      await _animate(_queue.removeAt(0));
    }
    _animating = false;
    // Converge on the authoritative positions.
    final match = _match;
    if (match != null && mounted) {
      setState(() {
        _sliding = null;
        for (final e in match.positions.entries) {
          _display[e.key] = e.value;
        }
      });
    }
  }

  Future<void> _animate(SnlMove move) async {
    final name = _nameOf(move.seat);
    setState(() {
      _sliding = null;
      _banner = move.bounced
          ? '$name rolled ${move.dice} (needs exact to finish)'
          : '$name rolled ${move.dice}';
    });
    if (!move.bounced) {
      for (var sq = move.from + 1; sq <= move.landed; sq++) {
        if (!mounted) return;
        setState(() => _display[move.seat] = sq);
        await Future.delayed(const Duration(milliseconds: _hopMs));
      }
    }
    if (move.isLadder || move.isSnake) {
      await Future.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      move.isLadder ? Haptics.success() : Haptics.warning();
      setState(() {
        _sliding = move.seat;
        _display[move.seat] = move.to;
        _banner = move.isLadder
            ? '🪜 $name climbed ${move.landed} → ${move.to}!'
            : '🐍 $name got bitten ${move.landed} → ${move.to}';
      });
      await Future.delayed(const Duration(milliseconds: _slideMs + 80));
    }
    if (move.to == kSnlGoal && mounted) {
      Haptics.heavy();
      setState(() => _banner = '🏆 $name reached 100!');
    } else if (move.dice == 6 && mounted) {
      setState(() => _banner = '${_banner ?? ''} · rolls again!');
    }
  }

  // ---------------------------------------------------------------- turns

  int _remaining(SnlMatch m) {
    if (m.turnStartedAtMs <= 0) return _turnSeconds;
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - m.turnStartedAtMs) / 1000;
    return (_turnSeconds - elapsed).ceil().clamp(0, _turnSeconds);
  }

  void _onTick() {
    final m = _match;
    if (!mounted || m == null || m.status != LudoMatchStatus.active) return;
    final elapsedMs = DateTime.now().millisecondsSinceEpoch - m.turnStartedAtMs;
    final expired = elapsedMs - _turnSeconds * 1000;
    if (m.turnStartedAtMs > 0 && _lastForcedTurn != m.turnStartedAtMs) {
      if (expired >= 0 && m.turn == _mySeat && !_rolling) {
        // My clock ran out: roll for me.
        _lastForcedTurn = m.turnStartedAtMs;
        unawaited(_roll());
      } else if (expired >= _abandonGraceMs &&
          _mySeat != null &&
          m.turn != _mySeat) {
        // The active player went quiet; roll on their behalf.
        _lastForcedTurn = m.turnStartedAtMs;
        unawaited(
          _service.roll(
            widget.matchId,
            m.turn,
            expectedTurnStartedAt: m.turnStartedAtMs,
          ),
        );
      }
    }
    setState(() {});
  }

  bool get _canRoll {
    final m = _match;
    return m != null &&
        m.status == LudoMatchStatus.active &&
        m.turn == _mySeat &&
        !_rolling &&
        !_animating;
  }

  Future<void> _roll() async {
    final seat = _mySeat;
    if (seat == null || _rolling) return;
    Haptics.selection();
    setState(() => _rolling = true);
    try {
      await _service.roll(widget.matchId, seat);
    } catch (e) {
      _snack('Couldn’t roll. Check your connection.');
    }
    // Safety: never leave the dice spinning if the move never arrives.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _rolling) setState(() => _rolling = false);
    });
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await _service.startMatch(widget.matchId);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _invite() async {
    final chat = Get.find<ChatService>();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LudoInviteFriendsSheet(
        matchId: widget.matchId,
        sendInvite: (friend, id) =>
            chat.sendSnlInviteMessage(friend: friend, matchId: id),
      ),
    );
  }

  Future<void> _leave() async {
    final m = _match;
    final seat = _mySeat;
    final over =
        m == null ||
        m.status == LudoMatchStatus.finished ||
        m.status == LudoMatchStatus.cancelled;
    if (seat == null || over) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final confirmed = await showGameDialog(
      context,
      title: 'LEAVE MATCH?',
      message: m.status == LudoMatchStatus.waiting
          ? 'You’ll give up your seat in this room.'
          : (m.seatCount <= 2
                ? 'If you leave now, your opponent wins.'
                : 'You’ll forfeit and the others keep playing.'),
      cancelLabel: 'Stay',
      confirmLabel: 'Leave',
      confirmTone: GameButtonTone.red,
      headerColors: GameColors.red,
    );
    if (confirmed != true) return;
    try {
      await _service.leaveMatch(widget.matchId, seat);
    } catch (_) {}
    unawaited(_service.clearActiveMatch(widget.matchId));
    if (mounted) Navigator.of(context).pop();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _nameOf(LudoPlayerType seat) {
    if (seat == _mySeat) return 'You';
    final name = _match?.seats[seat]?.name.trim() ?? '';
    return name.isEmpty ? 'Player' : name.split(' ').first;
  }

  static Color _seatColor(LudoPlayerType s) => switch (s) {
    LudoPlayerType.green => LudoColor.green,
    LudoPlayerType.yellow => LudoColor.yellow,
    LudoPlayerType.blue => LudoColor.blue,
    LudoPlayerType.red => LudoColor.red,
  };

  // -------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: GameColors.bgBottom,
        body: Stack(
          children: [
            const GameBackground(),
            SafeArea(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_error != null) return _errorPanel();
    final m = _match;
    if (m == null) {
      return const Center(
        child: CircularProgressIndicator(color: LudoColor.green),
      );
    }
    return Column(
      children: [
        _header(m),
        Expanded(
          child: switch (m.status) {
            LudoMatchStatus.waiting => _lobby(m),
            LudoMatchStatus.cancelled => _errorPanel(),
            _ => _game(m),
          },
        ),
      ],
    );
  }

  Widget _header(SnlMatch m) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
    child: Row(
      children: [
        GameIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Leave',
          onPressed: _leave,
        ),
        const SizedBox(width: 10),
        const Expanded(child: GameText('SNAKES & LADDERS', size: 20)),
        GameBadge(label: '${m.seatCount}/4'),
      ],
    ),
  );

  // ----------------------------------------------------------------- lobby

  Widget _lobby(SnlMatch m) {
    final isHost = m.hostUid == _uid;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GamePanel(
            headerColors: GameColors.green,
            header: Row(
              children: [
                const Expanded(child: GameText('ROOM LOBBY', size: 22)),
                GameBadge(
                  label: m.isFull ? 'FULL' : 'OPEN',
                  dot: const Color(0xFF7CF06B),
                  pulse: m.isFull ? null : _pulse,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isHost
                      ? 'Invite up to 3 friends, then start when everyone’s in.'
                      : 'Waiting for the host to start…',
                  textAlign: TextAlign.center,
                  style: gameFont(14, GameColors.soft),
                ),
                const SizedBox(height: 12),
                GameTray(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      for (final seat in kLudoSeatOrder)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 4,
                          ),
                          child: Row(
                            children: [
                              LudoSeatToken(
                                color: _seatColor(seat),
                                name: m.seats[seat]?.name,
                                photo: m.seats[seat]?.photo,
                                size: 44,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  m.seats[seat]?.name ?? 'Waiting for player…',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: gameFont(
                                    16,
                                    m.seats[seat] != null
                                        ? Colors.white
                                        : GameColors.soft.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                                ),
                              ),
                              if (seat == _mySeat)
                                const GameBadge(label: 'YOU')
                              else if (m.seats[seat]?.uid == m.hostUid)
                                const GameBadge(label: 'HOST'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isHost) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: GameButton(
                    label: 'Invite',
                    icon: Icons.person_add_alt_1_rounded,
                    tone: GameButtonTone.purple,
                    height: 50,
                    onPressed: m.isFull ? null : _invite,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameButton(
                    label: 'Copy Link',
                    icon: Icons.link_rounded,
                    tone: GameButtonTone.yellow,
                    height: 50,
                    onPressed: m.isFull
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: SnlMatchService.inviteLink(
                                  widget.matchId,
                                ),
                              ),
                            );
                            _snack('Invite link copied');
                          },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GameButton(
              label: _starting ? 'Starting…' : 'Start Match',
              icon: _starting ? null : Icons.play_arrow_rounded,
              subtitle: m.seatCount < 2 ? 'Need at least 2 players' : null,
              tone: GameButtonTone.green,
              height: m.seatCount < 2 ? 62 : 56,
              onPressed: (m.seatCount >= 2 && !_starting) ? _start : null,
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ game

  Widget _game(SnlMatch m) {
    final finished = m.status == LudoMatchStatus.finished;
    return Stack(
      children: [
        Column(
          children: [
            _playersStrip(m),
            const SizedBox(height: 6),
            Expanded(child: Center(child: _board(m))),
            const SizedBox(height: 6),
            _bannerLine(),
            const SizedBox(height: 6),
            if (!finished) _dicePanel(m),
            const SizedBox(height: 10),
          ],
        ),
        if (finished && !_animating) _resultPanel(m),
      ],
    );
  }

  Widget _playersStrip(SnlMatch m) {
    final active = m.status == LudoMatchStatus.active ? m.turn : null;
    final remaining = _remaining(m);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GameTray(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final seat in kLudoSeatOrder)
              Opacity(
                opacity: m.seats.containsKey(seat) ? 1 : 0.45,
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: Center(
                          child: LudoSeatToken(
                            color: _seatColor(seat),
                            name: m.seats[seat]?.name,
                            photo: m.seats[seat]?.photo,
                            size: 42,
                            glow: seat == active,
                            progress: seat == active
                                ? remaining / _turnSeconds
                                : null,
                            progressColor: remaining <= 5
                                ? const Color(0xFFFF4D4D)
                                : null,
                          ),
                        ),
                      ),
                      Text(
                        m.seats.containsKey(seat) ? _nameOf(seat) : 'Empty',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: gameFont(
                          13,
                          seat == active ? Colors.white : GameColors.soft,
                        ),
                      ),
                      if (m.seats.containsKey(seat))
                        Text(
                          m.winners.contains(seat)
                              ? '#${m.winners.indexOf(seat) + 1}'
                              : 'Sq ${_display[seat] ?? 0}',
                          style: gameFont(
                            11.5,
                            m.winners.contains(seat)
                                ? GameColors.yellow.$1
                                : GameColors.soft,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _board(SnlMatch m) {
    return LayoutBuilder(
      builder: (context, box) {
        final side =
            (box.maxWidth - 32 < box.maxHeight - 13
                    ? box.maxWidth - 32
                    : box.maxHeight - 13)
                .clamp(120.0, 560.0);
        final token = side / 10 * 0.58;
        // Group tokens per square so they don't stack exactly.
        final bySquare = <int, List<LudoPlayerType>>{};
        for (final s in kLudoSeatOrder) {
          if (!m.seats.containsKey(s)) continue;
          bySquare.putIfAbsent(_display[s] ?? 0, () => []).add(s);
        }
        return Container(
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
              width: side,
              height: side,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: RepaintBoundary(
                      child: CustomPaint(painter: SnlBoardPainter()),
                    ),
                  ),
                  for (final entry in bySquare.entries)
                    for (final (i, seat) in entry.value.indexed)
                      _token(
                        seat: seat,
                        square: entry.key,
                        side: side,
                        size: token,
                        offset: _stackOffset(i, entry.value.length, token),
                        active:
                            m.turn == seat &&
                            m.status == LudoMatchStatus.active,
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Offset _stackOffset(int i, int count, double token) {
    if (count <= 1) return Offset.zero;
    const spots = [
      Offset(-0.28, -0.28),
      Offset(0.28, -0.28),
      Offset(-0.28, 0.28),
      Offset(0.28, 0.28),
    ];
    return spots[i % 4] * token;
  }

  Widget _token({
    required LudoPlayerType seat,
    required int square,
    required double side,
    required double size,
    required Offset offset,
    required bool active,
  }) {
    final c = snlCellCenter(square, side) + offset;
    final sliding = _sliding == seat;
    return AnimatedPositioned(
      key: ValueKey(seat),
      duration: Duration(milliseconds: sliding ? _slideMs : _hopMs - 20),
      curve: sliding ? Curves.easeInOutCubic : Curves.easeOut,
      left: c.dx - size / 2,
      top: c.dy - size / 2,
      width: size,
      height: size,
      child: ScaleTransition(
        scale: active
            ? Tween(begin: 1.0, end: 1.15).animate(_pulse)
            : const AlwaysStoppedAnimation(1.0),
        child: LudoSeatToken(
          color: _seatColor(seat),
          name: _match?.seats[seat]?.name,
          photo: _match?.seats[seat]?.photo,
          size: size,
          glow: active,
        ),
      ),
    );
  }

  Widget _bannerLine() => SizedBox(
    height: 24,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _banner == null
          ? const SizedBox.shrink()
          : Text(
              _banner!,
              key: ValueKey(_banner),
              textAlign: TextAlign.center,
              style: gameFont(16, Colors.white),
            ),
    ),
  );

  Widget _dicePanel(SnlMatch m) {
    final myTurn = m.turn == _mySeat;
    final spinning = _rolling || (_animating && m.lastMove?.seat == m.turn);
    final dice = m.dice.clamp(1, 6);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: GamePanel(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GameColors.socket,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GameColors.trayEdge, width: 2),
              ),
              child: Image.asset(
                spinning && _rolling
                    ? 'assets/ludo/images/dice/draw.gif'
                    : 'assets/ludo/images/dice/$dice.png',
                gaplessPlayback: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GameText(
                    _mySeat == null
                        ? '${_nameOf(m.turn)}’s turn'
                        : (myTurn ? 'Your turn!' : '${_nameOf(m.turn)}’s turn'),
                    size: 18,
                  ),
                  Text(
                    myTurn
                        ? 'Auto-rolls in ${_remaining(m)}s'
                        : 'Waiting… ${_remaining(m)}s',
                    style: gameFont(12.5, GameColors.soft),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 104,
              child: GameButton(
                label: 'Roll',
                icon: Icons.casino_rounded,
                tone: GameButtonTone.green,
                height: 50,
                onPressed: _canRoll ? _roll : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultPanel(SnlMatch m) {
    const places = ['1ST', '2ND', '3RD', '4TH'];
    const medal = [
      Color(0xFFFFD60A),
      Color(0xFFD9DEE8),
      Color(0xFFE39B5B),
      Color(0xFFB0B0B8),
    ];
    final myPlace = _mySeat == null ? -1 : m.winners.indexOf(_mySeat!);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GamePanel(
              headerColors: myPlace == 0
                  ? GameColors.yellow
                  : GameColors.purple,
              headerHeight: 70,
              header: Center(
                child: GameText(
                  myPlace == 0 ? 'YOU WIN!' : 'GAME OVER',
                  size: 30,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameTray(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        for (final (i, seat) in m.winners.take(4).indexed)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 44,
                                  child: GameText(
                                    places[i],
                                    size: 16,
                                    color: medal[i],
                                  ),
                                ),
                                LudoSeatToken(
                                  color: _seatColor(seat),
                                  name: m.seats[seat]?.name ?? '?',
                                  photo: m.seats[seat]?.photo,
                                  size: 34,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    m.seats[seat]?.name ?? _nameOf(seat),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: gameFont(17, Colors.white),
                                  ),
                                ),
                                if (i == 0)
                                  const Text(
                                    '👑',
                                    style: TextStyle(fontSize: 22),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (myPlace >= 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '+${(4 - myPlace) * 100} pts on the leaderboard',
                      textAlign: TextAlign.center,
                      style: gameFont(14, GameColors.yellow.$1),
                    ),
                  ],
                  const SizedBox(height: 14),
                  GameButton(
                    label: 'Exit',
                    tone: GameButtonTone.purple,
                    height: 50,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorPanel() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: GamePanel(
        headerColors: GameColors.red,
        header: const Center(child: GameText('ROOM UNAVAILABLE', size: 20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              (_error ?? 'This room was closed.').replaceFirst(
                'Exception: ',
                '',
              ),
              textAlign: TextAlign.center,
              style: gameFont(14, GameColors.soft),
            ),
            const SizedBox(height: 14),
            GameButton(
              label: 'Go Back',
              tone: GameButtonTone.purple,
              height: 46,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    ),
  );
}
