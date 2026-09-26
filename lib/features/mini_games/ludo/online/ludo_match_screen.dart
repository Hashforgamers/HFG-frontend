import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import 'package:provider/provider.dart';

import '../audio.dart';
import '../constants.dart';
import '../ludo_provider.dart';
import '../ludo_score_service.dart';
import '../widgets/board_widget.dart';
import '../widgets/dice_widget.dart';
import '../widgets/ludo_reactions.dart';
import '../widgets/ludo_seat_token.dart';
import 'ludo_invite_friends_sheet.dart';
import 'ludo_match.dart';
import 'ludo_match_service.dart';

/// The networked Ludo experience: a lobby while [LudoMatchStatus.waiting], then
/// the synced board once the host starts. Handles auto-joining an open seat for
/// invited players.
class LudoMatchScreen extends StatefulWidget {
  const LudoMatchScreen({
    super.key,
    required this.matchId,
    this.spectate = false,
  });

  final String matchId;

  /// When true, open as a read-only spectator: never take a seat, never roll,
  /// just mirror the live board.
  final bool spectate;

  @override
  State<LudoMatchScreen> createState() => _LudoMatchScreenState();
}

class _LudoMatchScreenState extends State<LudoMatchScreen>
    with TickerProviderStateMixin {
  static const _accent = Color(0xFF00DC00);
  static const int _turnSeconds = 30;

  // Grace period after a turn's clock expires before *another* seated player is
  // allowed to force it forward (covers the active player being briefly slow or
  // reconnecting). The active player skips themselves the instant it hits 0.
  static const int _abandonGraceMs = 6000;

  final LudoMatchService _service = LudoMatchService();
  final LudoProvider _provider = LudoProvider()..startGame();

  StreamSubscription<LudoMatch?>? _sub;
  LudoMatch? _match;
  LudoPlayerType? _mySeat;
  bool _attached = false;
  bool _joinAttempted = false;
  bool _starting = false;
  bool _resultRecorded = false;
  String? _error;

  Timer? _ticker;
  late final AnimationController _bounce;
  int _lastSkippedTurnMs = 0;

  // In-match emoji reactions.
  final ValueNotifier<LudoReactionEvent?> _reactionNotifier =
      ValueNotifier<LudoReactionEvent?>(null);
  int _lastReactionId = 0;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
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

  int _remainingSeconds(LudoMatch match) {
    if (match.turnStartedAtMs <= 0) return _turnSeconds;
    final elapsed =
        (DateTime.now().millisecondsSinceEpoch - match.turnStartedAtMs) / 1000;
    final r = (_turnSeconds - elapsed).ceil();
    return r < 0 ? 0 : r;
  }

  void _onTick() {
    final match = _match;
    if (!mounted || match == null) return;
    if (match.status == LudoMatchStatus.active &&
        match.turnStartedAtMs > 0 &&
        _lastSkippedTurnMs != match.turnStartedAtMs) {
      final elapsedMs =
          DateTime.now().millisecondsSinceEpoch - match.turnStartedAtMs;
      final expiredMs = elapsedMs - _turnSeconds * 1000;
      if (expiredMs >= 0 && _provider.isMyTurn) {
        // It's my turn and my clock ran out — skip myself.
        _lastSkippedTurnMs = match.turnStartedAtMs;
        _provider.skipTurn();
      } else if (expiredMs >= _abandonGraceMs &&
          !_provider.isSpectator &&
          !_provider.isMyTurn) {
        // The active seat didn't advance in time (likely left/backgrounded) —
        // a fellow seated player nudges the turn so the match can't freeze.
        _lastSkippedTurnMs = match.turnStartedAtMs;
        _provider.forceAdvanceExpiredTurn();
      }

      // Clock-ticking sound through the final 15s of my own turn.
      final remaining = _remainingSeconds(match);
      if (_provider.soundEnabled &&
          _provider.isMyTurn &&
          remaining <= 15 &&
          remaining > 0) {
        Audio.startTicking();
      } else {
        Audio.stopTicking();
      }
    } else {
      Audio.stopTicking();
    }
    setState(() {}); // refresh the countdown display
  }

  Future<void> _onMatch(LudoMatch? match) async {
    if (!mounted) return;
    if (match == null) {
      setState(() => _error = 'This match is no longer available.');
      return;
    }

    var seat = widget.spectate ? null : match.seatOf(_uid);

    // Invited player opening a still-open match: grab a seat once. Spectators
    // never take a seat.
    if (!widget.spectate &&
        seat == null &&
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

    // Attach the mirror once — as a player (seat) or, when spectating, seat-less.
    if (!_attached && (seat != null || widget.spectate)) {
      _attached = true;
      _provider.attachOnline(
        service: _service,
        matchId: widget.matchId,
        mySeat: seat,
        initial: match,
      );
    }

    // Spectators don't earn placement points or remember the room to rejoin.
    if (!widget.spectate) {
      if (!_resultRecorded &&
          (match.status == LudoMatchStatus.active ||
              match.status == LudoMatchStatus.finished)) {
        final score = ludoPlacementScore(
          seat: seat,
          winners: match.winners,
          participants: match.seats.keys.toSet(),
          finished: match.status == LudoMatchStatus.finished,
        );
        if (score != null) {
          _resultRecorded = true;
          unawaited(LudoScoreService.instance.record(score));
        }
      }

      // Remember this room so an accidental back-out can rejoin it; forget it
      // once the match is over.
      if (seat != null &&
          (match.status == LudoMatchStatus.waiting ||
              match.status == LudoMatchStatus.active)) {
        unawaited(_service.saveActiveMatch(widget.matchId));
      } else if (match.status == LudoMatchStatus.finished ||
          match.status == LudoMatchStatus.cancelled) {
        unawaited(_service.clearActiveMatch(widget.matchId));
      }
    }

    // Surface a new emoji reaction (from anyone, including me once it round-trips
    // through Firestore so every device animates it identically).
    if (match.reactionId > 0) {
      if (_lastReactionId == 0) {
        _lastReactionId = match.reactionId; // don't replay history on first load
      } else if (match.reactionId != _lastReactionId) {
        _lastReactionId = match.reactionId;
        final option = ludoReactionByKey(match.reactionEmoji);
        if (option != null) {
          Haptics.light();
          final seatOf = match.reactionSeat;
          final String label;
          if (seatOf != null) {
            label =
                match.seats[seatOf]?.name.split(' ').first ??
                _seatName(seatOf);
          } else if (match.reactionName.trim().isNotEmpty) {
            // Spectator reaction — tag it so players know it's from the crowd.
            label = '${match.reactionName.split(' ').first} 👀';
          } else {
            label = '';
          }
          _reactionNotifier.value = LudoReactionEvent(
            option: option,
            id: match.reactionId,
            label: label,
          );
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _match = match;
      _mySeat = seat;
    });
  }

  void _sendReaction(LudoReactionOption option) {
    final seat = _mySeat;
    // Seated players react from their seat; spectators react with their name.
    final name = seat == null
        ? (FirebaseAuth.instance.currentUser?.displayName ?? 'Spectator')
        : '';
    unawaited(
      _service.sendReaction(
        widget.matchId,
        seat: seat,
        key: option.key,
        name: name,
      ),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    Audio.stopTicking();
    _bounce.dispose();
    _reactionNotifier.dispose();
    _sub?.cancel();
    _provider.dispose();
    super.dispose();
  }

  String _seatName(LudoPlayerType type) {
    final n = type.name;
    return n[0].toUpperCase() + n.substring(1);
  }

  Color _seatColor(LudoPlayerType type) {
    switch (type) {
      case LudoPlayerType.green:
        return LudoColor.green;
      case LudoPlayerType.yellow:
        return LudoColor.yellow;
      case LudoPlayerType.blue:
        return LudoColor.blue;
      case LudoPlayerType.red:
        return LudoColor.red;
    }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      await _service.startMatch(widget.matchId);
    } catch (e) {
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF1E1E1E)),
    );
  }

  Future<void> _invite() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LudoInviteFriendsSheet(matchId: widget.matchId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leaveAndExit();
        },
        child: Scaffold(
          backgroundColor: GameColors.bgBottom,
          body: Stack(
            children: [
              const GameBackground(),
              SafeArea(child: _body()),
              LudoReactionLayer(listenable: _reactionNotifier),
            ],
          ),
        ),
      ),
    );
  }

  /// Leaving a live match forfeits: a seated player quits (the service resolves
  /// win/continue/end), spectators and finished matches just close.
  Future<void> _leaveAndExit() async {
    final match = _match;
    final seat = _mySeat;
    final over =
        match == null ||
        match.status == LudoMatchStatus.finished ||
        match.status == LudoMatchStatus.cancelled;

    if (widget.spectate || seat == null || over) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    final onePlayerLeft = match.seatCount <= 2;
    final confirmed = await showGameDialog(
      context,
      title: 'LEAVE MATCH?',
      message: onePlayerLeft
          ? 'If you leave now, your opponent wins the match.'
          : 'You’ll forfeit and the others will keep playing without you.',
      cancelLabel: 'Keep Playing',
      confirmLabel: 'Leave',
      confirmTone: GameButtonTone.red,
      headerColors: GameColors.red,
    );
    if (confirmed != true) return;

    try {
      await _service.leaveMatch(widget.matchId, seat);
    } catch (_) {
      // Best-effort; never trap the user in the screen.
    }
    // Forfeiting shouldn't offer a rejoin afterwards.
    unawaited(_service.clearActiveMatch(widget.matchId));
    if (mounted) Navigator.of(context).pop();
  }

  Widget _body() {
    if (_error != null) {
      return _centered(
        icon: Icons.error_outline_rounded,
        title: 'Couldn’t open match',
        subtitle: _error!,
      );
    }
    final match = _match;
    if (match == null) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    return Column(
      children: [
        _header(match),
        Expanded(
          child: match.status == LudoMatchStatus.waiting
              ? _lobby(match)
              : _game(match),
        ),
      ],
    );
  }

  Widget _header(LudoMatch match) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Row(
        children: [
          GameIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Leave',
            onPressed: _leaveAndExit,
          ),
          const SizedBox(width: 10),
          const GameText('LUDO', size: 26),
          const SizedBox(width: 8),
          GameBadge(
            label: widget.spectate ? 'WATCHING' : 'ONLINE',
            dot: widget.spectate ? const Color(0xFFFF3B30) : _accent,
            pulse: _bounce,
          ),
          const Spacer(),
          GameBadge(label: '${match.seatCount}/4'),
        ],
      ),
    );
  }

  // ---------------- Lobby ----------------

  Widget _lobby(LudoMatch match) {
    final isHost = match.hostUid == _uid;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GamePanel(
            headerColors: GameColors.green,
            header: Row(
              children: [
                const Expanded(child: GameText('MATCH LOBBY', size: 22)),
                GameBadge(
                  label: match.isFull ? 'FULL' : 'OPEN',
                  dot: const Color(0xFF7CF06B),
                  pulse: match.isFull ? null : _bounce,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isHost
                      ? 'Invite up to 3 friends, then start when everyone’s in.'
                      : 'Waiting for the host to start the match…',
                  textAlign: TextAlign.center,
                  style: gameFont(14, GameColors.soft),
                ),
                const SizedBox(height: 12),
                GameTray(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      for (final seat in kLudoSeatOrder) _seatRow(match, seat),
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
                    onPressed: match.isFull ? null : _invite,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GameButton(
                    label: 'Copy Link',
                    icon: Icons.link_rounded,
                    tone: GameButtonTone.yellow,
                    height: 50,
                    onPressed: match.isFull
                        ? null
                        : () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: LudoMatchService.inviteLink(
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
              subtitle: match.seatCount < 2 ? 'Need at least 2 players' : null,
              tone: GameButtonTone.green,
              height: match.seatCount < 2 ? 62 : 56,
              onPressed: (match.seatCount >= 2 && !_starting) ? _start : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _seatRow(LudoMatch match, LudoPlayerType seat) {
    final info = match.seats[seat];
    final isMe = seat == _mySeat;
    final color = _seatColor(seat);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Row(
        children: [
          LudoSeatToken(
            color: color,
            name: info?.name,
            photo: info?.photo,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info?.name ?? 'Waiting for player…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gameFont(
                16,
                info != null ? Colors.white : GameColors.soft.withValues(alpha: 0.5),
              ),
            ),
          ),
          if (isMe)
            const GameBadge(label: 'YOU')
          else if (info != null && match.hostUid == info.uid)
            const GameBadge(label: 'HOST'),
        ],
      ),
    );
  }

  // ---------------- Game ----------------

  Widget _game(LudoMatch match) {
    return Column(
      children: [
        _playersStrip(match),
        const SizedBox(height: 6),
        // Size the board to the space left so it sits centred in its frame
        // (the player strip already shows whose turn it is).
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: LayoutBuilder(
              builder: (context, c) {
                const frameX = 8.0; // 4 + 4
                const frameY = 13.0; // 4 top + 9 lip
                final side = (c.maxWidth - frameX < c.maxHeight - frameY
                        ? c.maxWidth - frameX
                        : c.maxHeight - frameY)
                    .clamp(0.0, 520.0);
                return Center(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(4, 4, 4, 9),
                    decoration: BoxDecoration(
                      color: GameColors.outline,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x80000000),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: BoardWidget(size: side, showTurnIndicator: false),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        _diceTray(),
        const SizedBox(height: 10),
        // Both seated players and spectators can react.
        if (match.status == LudoMatchStatus.active &&
            (_mySeat != null || widget.spectate))
          LudoReactionBar(onSelected: _sendReaction),
        const SizedBox(height: 10),
        if (match.status == LudoMatchStatus.finished) _finishedOverlay(match),
      ],
    );
  }

  /// A row of player tokens with a countdown ring around whoever's turn it is.
  Widget _playersStrip(LudoMatch match) {
    return Consumer<LudoProvider>(
      builder: (context, provider, _) {
        final active = provider.gameState == LudoGameState.finish
            ? null
            : provider.currentTurnSeat;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: GameTray(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final seat in kLudoSeatOrder)
                  _playerChip(match, seat, seat == active),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _playerChip(LudoMatch match, LudoPlayerType seat, bool active) {
    final info = match.seats[seat];
    final color = _seatColor(seat);
    final isMe = seat == _mySeat;
    final remaining = _remainingSeconds(match);
    // Matches written without a turn timestamp can't be timed.
    final timed = active && match.turnStartedAtMs > 0;
    final urgent = timed && remaining <= 15;
    final ring = urgent ? const Color(0xFFFF4D4D) : color;

    Widget avatar = SizedBox(
      width: 58,
      height: 58,
      child: Center(
        child: LudoSeatToken(
          color: color,
          name: info?.name,
          photo: info?.photo,
          size: 44,
          glow: active,
          progress: timed ? remaining / _turnSeconds : null,
          progressColor: ring,
        ),
      ),
    );

    if (urgent) {
      avatar = ScaleTransition(
        scale: Tween<double>(
          begin: 1.0,
          end: 1.14,
        ).animate(CurvedAnimation(parent: _bounce, curve: Curves.easeInOut)),
        child: avatar,
      );
    }

    return Opacity(
      opacity: info != null ? 1 : 0.55,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: 2),
            Text(
              info == null
                  ? 'Empty'
                  : (isMe ? 'You' : info.name.split(' ').first),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: gameFont(13, active ? Colors.white : GameColors.soft),
            ),
            SizedBox(
              height: 18,
              child: timed
                  ? GameText('${remaining}s', size: 13, color: ring)
                  : (active
                        ? Text('Playing', style: gameFont(12, ring))
                        : null),
            ),
          ],
        ),
      ),
    );
  }

  /// The dice in a chunky socket.
  Widget _diceTray() {
    return Container(
      width: 96,
      height: 100,
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 8),
      decoration: BoxDecoration(
        color: GameColors.outline,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), blurRadius: 14, offset: Offset(0, 6)),
        ],
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(21),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameColors.bodyTop, GameColors.bodyBottom],
          ),
        ),
        child: Container(
          width: 66,
          height: 66,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: GameColors.socket,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GameColors.trayEdge, width: 2),
          ),
          child: const DiceWidget(),
        ),
      ),
    );
  }

  Widget _finishedOverlay(LudoMatch match) {
    final winner = match.winners.isEmpty ? null : match.winners.first;
    final winnerName = winner == null
        ? '—'
        : (match.seats[winner]?.name ?? _seatName(winner));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: GamePanel(
        headerColors: GameColors.yellow,
        header: const Center(child: GameText('MATCH OVER', size: 24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (winner != null)
                  LudoSeatToken(
                    color: _seatColor(winner),
                    name: winnerName,
                    photo: match.seats[winner]?.photo,
                    size: 40,
                  ),
                const SizedBox(width: 10),
                Flexible(
                  child: GameText('$winnerName wins!', size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GameButton(
              label: 'Exit to Games',
              tone: GameButtonTone.purple,
              height: 46,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centered({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GamePanel(
          headerColors: GameColors.red,
          header: Row(
            children: [
              GameIcon(icon: icon, size: 26),
              const SizedBox(width: 10),
              Expanded(child: GameText(title, size: 20)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                subtitle,
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
}
