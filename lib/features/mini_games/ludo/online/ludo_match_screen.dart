import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hash/core/service/crash_reporting.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio.dart';
import '../constants.dart';
import '../ludo_analytics.dart';
import '../ludo_provider.dart';
import '../ludo_score_service.dart';
import '../widgets/board_widget.dart';
import '../widgets/dice_widget.dart';
import '../widgets/ludo_reactions.dart';
import '../widgets/ludo_seat_token.dart';
import 'ludo_backoff.dart';
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
    this.source,
  });

  final String matchId;

  /// When true, open as a read-only spectator: never take a seat, never roll,
  /// just mirror the live board.
  final bool spectate;

  /// How this screen was reached when that matters for analytics (e.g.
  /// 'deeplink'). A seated player arriving this way counts as `ludo_resume`.
  final String? source;

  @override
  State<LudoMatchScreen> createState() => _LudoMatchScreenState();
}

class _LudoMatchScreenState extends State<LudoMatchScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const _accent = Color(0xFF00DC00);
  static const int _turnSeconds = 30;

  // Grace period after a turn's clock expires before *another* seated player is
  // allowed to force it forward (covers the active player being briefly slow or
  // reconnecting). The active player skips themselves the instant it hits 0.
  static const int _abandonGraceMs = 6000;

  // Quick Match: once a second player is seated, give others a moment to land
  // before starting so a near-simultaneous third joiner isn't left out.
  static const int _quickStartWithPlayersMs = 3000;

  final LudoMatchService _service = LudoMatchService();
  final LudoProvider _provider = LudoProvider()..startGame();

  StreamSubscription<LudoMatch?>? _sub;
  LudoMatch? _match;
  LudoPlayerType? _mySeat;
  bool _attached = false;
  bool _joinAttempted = false;
  bool _starting = false;
  bool _addingBot = false;
  bool _rematching = false;

  /// Starts as [LudoMatchScreen.spectate], but a player who opens their own
  /// match from Watch Live is put back in their seat instead of watching —
  /// otherwise nobody could play that seat (or its bots) and the match would
  /// freeze on their turn.
  late bool _spectating = widget.spectate;

  // Analytics bookkeeping (players only; spectators never send match events).
  bool _firstSnapshot = true;
  bool _sawWaiting = false;
  bool _startTracked = false;
  bool _endTracked = false;
  int _startedAtMs = 0;
  int _turns = 0;
  LudoPlayerType? _lastTurn;
  int _humansAtStart = 0;
  int _botsAtStart = 0;

  // Quick Match auto-start bookkeeping.
  bool _autoStartInFlight = false;
  int _secondPlayerSeenAtMs = 0;
  bool _resultRecorded = false;
  String? _error;

  // Sync health. A failed match stream is retried with backoff; after the cap
  // the player gets an explicit Retry instead of a silently frozen board.
  final LudoBackoff _watchBackoff = LudoBackoff();
  Timer? _resubscribeTimer;
  _Conn _conn = _Conn.live;

  // Quick Match auto-start retries back off the same way and stop at the cap.
  final LudoBackoff _autoStartBackoff = LudoBackoff();
  int _autoStartNextMs = 0;
  bool _autoStartFailed = false;

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
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
  }

  void _subscribe() {
    _resubscribeTimer?.cancel();
    unawaited(_sub?.cancel());
    _sub = _service
        .watch(widget.matchId)
        .listen(_onMatch, onError: _onWatchError);
  }

  void _onWatchError(Object e) {
    unawaited(_sub?.cancel());
    _sub = null;
    if (_conn == _Conn.live) {
      LudoAnalytics.disconnect(turnNumber: _turns, reconnected: false);
    }
    final delay = _watchBackoff.fail();
    LudoAnalytics.syncFailed(
      stage: 'watch',
      error: e,
      attempt: _watchBackoff.attempts,
    );
    if (!mounted) return;
    if (_watchBackoff.exhausted) {
      setState(() => _conn = _Conn.failed);
      return;
    }
    setState(() => _conn = _Conn.reconnecting);
    _resubscribeTimer = Timer(delay, () {
      if (mounted) _subscribe();
    });
  }

  /// Manual retry (button) or the app coming back to the foreground.
  void _retryNow(String source) {
    _watchBackoff.reset();
    LudoAnalytics.resume(source);
    setState(() => _conn = _Conn.reconnecting);
    _subscribe();
  }

  /// A snapshot arrived, so the stream is healthy again.
  void _markLive() {
    if (_conn == _Conn.live) return;
    LudoAnalytics.disconnect(turnNumber: _turns, reconnected: true);
    LudoAnalytics.resume('reconnect');
    _watchBackoff.reset();
    _conn = _Conn.live;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _conn != _Conn.live) {
      _retryNow('app_resume');
    }
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
      if (expiredMs >= 0 && (_provider.isMyTurn || _provider.isBotTurn)) {
        // It's my turn (or a bot I play for) and the clock ran out — skip it.
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
    _maybeAutoStartQuick(match);
    setState(() {}); // refresh the countdown display
  }

  /// Seconds left before a waiting Quick Match room starts with a bot.
  int _quickSecondsLeft(LudoMatch match) {
    if (match.createdAtMs <= 0) return 0;
    final waited = DateTime.now().millisecondsSinceEpoch - match.createdAtMs;
    final left = (LudoMatchService.quickFillSeconds * 1000 - waited) / 1000;
    return left <= 0 ? 0 : left.ceil();
  }

  /// Quick Match rooms never wait on the host: they start as soon as a second
  /// player is in (after a short grace), or with a bot once the fill timer
  /// runs out. The host's device does this; any seated player steps in if the
  /// host's device hasn't after [LudoMatchService.quickStartFallbackMs].
  void _maybeAutoStartQuick(LudoMatch match) {
    if (!match.quick ||
        match.status != LudoMatchStatus.waiting ||
        _spectating ||
        _mySeat == null ||
        _autoStartInFlight) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_autoStartFailed || now < _autoStartNextMs) return;
    final waited = now - match.createdAtMs;
    final isHost = match.hostUid == _uid;

    if (match.seatCount >= 2) {
      if (_secondPlayerSeenAtMs == 0) _secondPlayerSeenAtMs = now;
    } else {
      _secondPlayerSeenAtMs = 0;
    }
    final bool due;
    if (isHost) {
      due =
          match.isFull ||
          waited >= LudoMatchService.quickFillSeconds * 1000 ||
          (_secondPlayerSeenAtMs > 0 &&
              now - _secondPlayerSeenAtMs >= _quickStartWithPlayersMs);
    } else {
      due = waited >= LudoMatchService.quickStartFallbackMs;
    }
    if (!due) return;

    _autoStartInFlight = true;
    _service
        .fillWithBotAndStart(widget.matchId)
        .then((added) {
          _autoStartBackoff.reset();
          if (added > 0) {
            LudoAnalytics.botFilled(
              matchId: widget.matchId,
              trigger: 'quick_timeout',
              waitSec: (now - match.createdAtMs) ~/ 1000,
              bots: match.botSeats.length + added,
            );
          }
        })
        .catchError((Object e) {
          debugPrint('[LudoMatch] auto-start: $e');
          final delay = _autoStartBackoff.fail();
          _autoStartNextMs =
              DateTime.now().millisecondsSinceEpoch + delay.inMilliseconds;
          LudoAnalytics.syncFailed(
            stage: 'auto_start',
            error: e,
            attempt: _autoStartBackoff.attempts,
          );
          if (_autoStartBackoff.exhausted && mounted) {
            setState(() => _autoStartFailed = true);
          }
        })
        .whenComplete(() => _autoStartInFlight = false);
  }

  Future<void> _onMatch(LudoMatch? match) async {
    if (!mounted) return;
    _markLive();
    if (match == null) {
      setState(() => _error = 'This match is no longer available.');
      return;
    }
    CrashReporting.setGameMode('ludo_${LudoAnalytics.onlineMode(match)}');

    if (_spectating &&
        !_attached &&
        match.seatOf(_uid) != null &&
        (match.status == LudoMatchStatus.waiting ||
            match.status == LudoMatchStatus.active)) {
      _spectating = false;
    }

    var seat = _spectating ? null : match.seatOf(_uid);

    if (_firstSnapshot) {
      _firstSnapshot = false;
      if (seat != null && widget.source != null) {
        LudoAnalytics.resume(widget.source!);
      }
    }

    // Invited player opening a still-open match: grab a seat once. Spectators
    // never take a seat.
    if (!_spectating &&
        seat == null &&
        match.status == LudoMatchStatus.waiting &&
        !match.isFull &&
        !_joinAttempted) {
      _joinAttempted = true;
      try {
        seat = await _service.joinMatch(widget.matchId);
      } catch (e) {
        LudoAnalytics.syncFailed(stage: 'join', error: e);
        if (mounted) setState(() => _error = e.toString());
        return;
      }
    }

    // Attach the mirror once — as a player (seat) or, when spectating, seat-less.
    if (!_attached && (seat != null || _spectating)) {
      _attached = true;
      _provider.attachOnline(
        service: _service,
        matchId: widget.matchId,
        mySeat: seat,
        initial: match,
      );
    }

    if (!_spectating && seat != null) _trackMatch(match, seat);

    // Spectators don't earn placement points or remember the room to rejoin.
    if (!_spectating) {
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
        _lastReactionId =
            match.reactionId; // don't replay history on first load
      } else if (match.reactionId != _lastReactionId) {
        _lastReactionId = match.reactionId;
        final option = ludoReactionByKey(match.reactionEmoji);
        if (option != null) {
          Haptics.light();
          final seatOf = match.reactionSeat;
          final String label;
          if (seatOf != null) {
            label =
                match.seats[seatOf]?.name.split(' ').first ?? _seatName(seatOf);
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

  /// Sends `ludo_match_start` / `ludo_match_end` for a seated player.
  void _trackMatch(LudoMatch match, LudoPlayerType seat) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (match.status == LudoMatchStatus.waiting) _sawWaiting = true;
    if (match.status == LudoMatchStatus.active && match.turn != _lastTurn) {
      _lastTurn = match.turn;
      _turns++;
    }

    // Only a start this player actually witnessed counts — reopening a match
    // already under way is a resume, not a new start. A rematch against bots
    // is created already active, with no moves yet.
    final freshlyActive =
        _sawWaiting ||
        (match.version == 0 && now - match.createdAtMs < 2 * 60 * 1000);
    if (!_startTracked &&
        match.status != LudoMatchStatus.waiting &&
        match.status != LudoMatchStatus.cancelled) {
      _startTracked = true;
      _startedAtMs = now;
      _humansAtStart = match.humanCount;
      _botsAtStart = match.botSeats.length;
      if (freshlyActive && match.status == LudoMatchStatus.active) {
        LudoAnalytics.matchStart(
          matchId: match.id,
          mode: LudoAnalytics.onlineMode(match),
          humans: _humansAtStart,
          bots: _botsAtStart,
          quick: match.quick,
        );
      }
    }

    if (match.status == LudoMatchStatus.finished && !_endTracked) {
      _endTracked = true;
      final points = ludoPlacementScore(
        seat: seat,
        winners: match.winners,
        participants: match.seats.keys.toSet(),
        finished: true,
      );
      final index = match.winners.indexOf(seat);
      final position = index >= 0 ? index + 1 : match.seats.length;
      final player = _provider.player(seat);
      final allHome = player.pawns.every(
        (p) => p.step == player.path.length - 1,
      );
      final String result;
      if (position == 1) {
        // First by everyone else leaving rather than by racing home.
        result = allHome ? 'win' : 'forfeit_win';
      } else {
        result = 'lose';
      }
      final startedAt = _startedAtMs > 0 ? _startedAtMs : match.createdAtMs;
      LudoAnalytics.matchEnd(
        matchId: match.id,
        mode: LudoAnalytics.onlineMode(match),
        result: result,
        position: position,
        points: points,
        humans: _humansAtStart > 0 ? _humansAtStart : match.humanCount,
        bots: _humansAtStart > 0 ? _botsAtStart : match.botSeats.length,
        durationSec: startedAt > 0 ? (now - startedAt) ~/ 1000 : 0,
        turns: _turns,
      );
    }
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
    CrashReporting.setGameMode(null);
    WidgetsBinding.instance.removeObserver(this);
    _resubscribeTimer?.cancel();
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
      LudoAnalytics.syncFailed(stage: 'start', error: e);
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

    if (_spectating || seat == null || over) {
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

    if (match.status == LudoMatchStatus.active) {
      final startedAt = _startedAtMs > 0 ? _startedAtMs : match.createdAtMs;
      LudoAnalytics.matchQuit(
        matchId: match.id,
        mode: LudoAnalytics.onlineMode(match),
        turnNumber: _turns,
        durationSec: startedAt > 0
            ? (DateTime.now().millisecondsSinceEpoch - startedAt) ~/ 1000
            : 0,
        reason: 'back',
      );
    }

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
    if (_conn == _Conn.failed) {
      return _centered(
        icon: Icons.wifi_off_rounded,
        title: 'Connection lost',
        subtitle:
            'We couldn’t reach the match after several tries. Check your '
            'connection and try again — your seat is kept.',
        onRetry: () => _retryNow('retry_button'),
      );
    }
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
        if (_conn == _Conn.reconnecting)
          _statusBanner(
            'Reconnecting… (${_watchBackoff.attempts}/'
            '${_watchBackoff.maxAttempts})',
          ),
        if (_autoStartFailed && match.status == LudoMatchStatus.waiting)
          _statusBanner(
            'Couldn’t start the match.',
            actionLabel: 'Retry',
            onAction: () => setState(() {
              _autoStartBackoff.reset();
              _autoStartNextMs = 0;
              _autoStartFailed = false;
            }),
          ),
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
            label: _spectating ? 'WATCHING' : 'ONLINE',
            dot: _spectating ? const Color(0xFFFF3B30) : _accent,
            pulse: _bounce,
          ),
          const Spacer(),
          GameBadge(label: '${match.seatCount}/4'),
        ],
      ),
    );
  }

  // ---------------- Lobby ----------------

  /// Ask for (or accept) a rematch, then move everyone into the new room.
  Future<void> _rematch() async {
    if (_rematching) return;
    setState(() => _rematching = true);
    try {
      final rematch = await _service.requestRematch(widget.matchId);
      LudoAnalytics.rematch(
        requested: rematch.created,
        vsBot: rematch.vsBot,
        humans: rematch.humans,
      );
      if (rematch.created) LudoAnalytics.roomCreated('rematch');
      if (!mounted) return;
      unawaited(_service.clearActiveMatch(widget.matchId));
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LudoMatchScreen(matchId: rematch.id),
        ),
      );
    } catch (e) {
      LudoAnalytics.syncFailed(stage: 'rematch', error: e);
      _snack(e.toString());
      if (mounted) setState(() => _rematching = false);
    }
  }

  Future<void> _addBot() async {
    setState(() => _addingBot = true);
    try {
      await _service.addBot(widget.matchId);
      final match = _match;
      if (match != null) {
        LudoAnalytics.botFilled(
          matchId: match.id,
          trigger: 'host_added',
          waitSec: match.createdAtMs > 0
              ? (DateTime.now().millisecondsSinceEpoch - match.createdAtMs) ~/
                    1000
              : 0,
          bots: match.botSeats.length + 1,
        );
      }
    } catch (e) {
      LudoAnalytics.syncFailed(stage: 'add_bot', error: e);
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _addingBot = false);
    }
  }

  Future<void> _copyCode(LudoMatch match) async {
    await Clipboard.setData(
      ClipboardData(text: LudoMatchService.inviteMessage(match)),
    );
    Haptics.light();
    LudoAnalytics.inviteSent('copy');
    _snack('Room code and link copied');
  }

  /// Opens WhatsApp with the invite prefilled; falls back to the system share
  /// sheet when WhatsApp isn't installed.
  Future<void> _shareWhatsApp(LudoMatch match) async {
    final text = LudoMatchService.inviteMessage(match);
    final wa = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
    var opened = false;
    try {
      opened = await launchUrl(wa, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (opened) LudoAnalytics.inviteSent('whatsapp');
    if (opened || !mounted) return;
    LudoAnalytics.inviteSent('share_sheet');
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        sharePositionOrigin: box == null
            ? const Rect.fromLTWH(0, 0, 1, 1)
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Widget _roomCodeTile(LudoMatch match) {
    return GestureDetector(
      onTap: () => _copyCode(match),
      child: GameTray(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ROOM CODE', style: gameFont(11, GameColors.soft)),
                  const SizedBox(height: 2),
                  GameText(
                    match.roomCode,
                    size: 26,
                    color: GameColors.yellow.$1,
                  ),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: GameColors.soft, size: 20),
            const SizedBox(width: 4),
            Text('Copy', style: gameFont(13, GameColors.soft)),
          ],
        ),
      ),
    );
  }

  Widget _lobby(LudoMatch match) {
    final isHost = match.hostUid == _uid;
    final quickLeft = _quickSecondsLeft(match);
    final String lobbyHint;
    if (match.quick) {
      lobbyHint = match.seatCount >= 2
          ? 'Opponent found! Starting…'
          : (quickLeft > 0
                ? 'Finding a player… starting in ${quickLeft}s'
                : 'Starting…');
    } else {
      lobbyHint = isHost
          ? 'Invite up to 3 friends, then start when everyone’s in.'
          : 'Waiting for the host to start the match…';
    }
    final canShare = !match.isFull && match.roomCode.isNotEmpty;
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
                  lobbyHint,
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
          if (canShare) ...[
            const SizedBox(height: 18),
            _roomCodeTile(match),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GameButton(
                    label: 'WhatsApp',
                    icon: Icons.chat_rounded,
                    tone: GameButtonTone.green,
                    height: 50,
                    onPressed: () => _shareWhatsApp(match),
                  ),
                ),
                if (isHost) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: GameButton(
                      label: 'Invite',
                      icon: Icons.person_add_alt_1_rounded,
                      tone: GameButtonTone.purple,
                      height: 50,
                      onPressed: _invite,
                    ),
                  ),
                ],
              ],
            ),
          ],
          // Quick Match rooms start themselves; friend rooms are host-started.
          if (isHost && !match.quick) ...[
            const SizedBox(height: 10),
            GameButton(
              label: _addingBot ? 'Adding…' : 'Add Bot',
              icon: _addingBot ? null : Icons.smart_toy_rounded,
              tone: GameButtonTone.yellow,
              height: 50,
              onPressed: (match.isFull || _addingBot) ? null : _addBot,
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
                info != null
                    ? Colors.white
                    : GameColors.soft.withValues(alpha: 0.5),
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
                final side =
                    (c.maxWidth - frameX < c.maxHeight - frameY
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
            (_mySeat != null || _spectating))
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
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
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
                Flexible(child: GameText('$winnerName wins!', size: 18)),
              ],
            ),
            if (_mySeat != null && !_spectating) ...[
              if (match.rematchId.isNotEmpty &&
                  match.rematchBy.isNotEmpty &&
                  match.seatOf(_uid) != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${match.rematchBy.split(' ').first} wants a rematch!',
                  textAlign: TextAlign.center,
                  style: gameFont(14, GameColors.soft),
                ),
              ],
              const SizedBox(height: 12),
              GameButton(
                label: _rematching
                    ? 'Joining…'
                    : (match.rematchId.isNotEmpty ? 'Join Rematch' : 'Rematch'),
                icon: _rematching ? null : Icons.replay_rounded,
                tone: GameButtonTone.green,
                height: 48,
                onPressed: _rematching ? null : _rematch,
              ),
            ],
            const SizedBox(height: 10),
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

  Widget _statusBanner(
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF3A2A00),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (actionLabel == null)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.amber,
              ),
            )
          else
            const Icon(Icons.warning_amber_rounded, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: gameFont(13, Colors.amber))),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _centered({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
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
              if (onRetry != null) ...[
                GameButton(
                  label: 'Retry',
                  tone: GameButtonTone.green,
                  height: 46,
                  onPressed: onRetry,
                ),
                const SizedBox(height: 10),
              ],
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

enum _Conn { live, reconnecting, failed }
