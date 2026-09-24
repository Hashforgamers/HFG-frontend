import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../constants.dart';
import '../ludo_provider.dart';
import '../widgets/board_widget.dart';
import '../widgets/dice_widget.dart';
import 'ludo_invite_friends_sheet.dart';
import 'ludo_match.dart';
import 'ludo_match_service.dart';

/// The networked Ludo experience: a lobby while [LudoMatchStatus.waiting], then
/// the synced board once the host starts. Handles auto-joining an open seat for
/// invited players.
class LudoMatchScreen extends StatefulWidget {
  const LudoMatchScreen({super.key, required this.matchId});

  final String matchId;

  @override
  State<LudoMatchScreen> createState() => _LudoMatchScreenState();
}

class _LudoMatchScreenState extends State<LudoMatchScreen>
    with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFF00DC00);
  static const int _turnSeconds = 30;

  final LudoMatchService _service = LudoMatchService();
  final LudoProvider _provider = LudoProvider()..startGame();

  StreamSubscription<LudoMatch?>? _sub;
  LudoMatch? _match;
  LudoPlayerType? _mySeat;
  bool _attached = false;
  bool _joinAttempted = false;
  bool _starting = false;
  String? _error;

  Timer? _ticker;
  late final AnimationController _bounce;
  int _lastSkippedTurnMs = 0;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _sub = _service.watch(widget.matchId).listen(_onMatch, onError: (e) {
      if (mounted) setState(() => _error = e.toString());
    });
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
    if (match.status != LudoMatchStatus.active) return;
    // Auto-skip my own turn if the clock runs out, once per turn.
    if (_remainingSeconds(match) <= 0 &&
        _provider.isMyTurn &&
        _lastSkippedTurnMs != match.turnStartedAtMs) {
      _lastSkippedTurnMs = match.turnStartedAtMs;
      _provider.skipTurn();
    }
    setState(() {}); // refresh the countdown display
  }

  Future<void> _onMatch(LudoMatch? match) async {
    if (!mounted) return;
    if (match == null) {
      setState(() => _error = 'This match is no longer available.');
      return;
    }

    var seat = match.seatOf(_uid);

    // Invited player opening a still-open match: grab a seat once.
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

    if (seat != null && !_attached) {
      _attached = true;
      _provider.attachOnline(
        service: _service,
        matchId: widget.matchId,
        mySeat: seat,
        initial: match,
      );
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

    if (!mounted) return;
    setState(() {
      _match = match;
      _mySeat = seat;
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _bounce.dispose();
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
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0D12),
        body: Stack(
          children: [
            const _Backdrop(),
            SafeArea(child: _body()),
          ],
        ),
      ),
    );
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
      return const Center(
        child: CircularProgressIndicator(color: _accent),
      );
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
      padding: const EdgeInsets.fromLTRB(6, 8, 14, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const Text(
            'Ludo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'ONLINE',
              style: TextStyle(
                color: _accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${match.seatCount}/4',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Lobby ----------------

  Widget _lobby(LudoMatch match) {
    final isHost = match.hostUid == _uid;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Match lobby',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isHost
                ? 'Invite up to 3 friends, then start when everyone’s in.'
                : 'Waiting for the host to start the match…',
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          for (final seat in kLudoSeatOrder) _seatRow(match, seat),
          const SizedBox(height: 24),
          if (isHost) ...[
            OutlinedButton.icon(
              onPressed: match.isFull ? null : _invite,
              style: OutlinedButton.styleFrom(
                foregroundColor: _accent,
                side: BorderSide(color: _accent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Invite friends',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: match.isFull
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(
                        text: LudoMatchService.inviteLink(widget.matchId),
                      ));
                      _snack('Invite link copied');
                    },
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              icon: const Icon(Icons.link_rounded, size: 18),
              label: const Text('Copy invite link'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed:
                  (match.seatCount >= 2 && !_starting) ? _start : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: const Color(0xFF06130B),
                disabledBackgroundColor: const Color(0xFF1B2A20),
                disabledForegroundColor: Colors.white38,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _starting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(
                match.seatCount < 2
                    ? 'Need at least 2 players'
                    : 'Start match',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14161C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: info != null
              ? color.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: info != null ? 1 : 0.25),
            ),
            child: info == null
                ? const Icon(Icons.hourglass_empty_rounded,
                    size: 16, color: Colors.white38)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info?.name ?? 'Empty seat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: info != null ? Colors.white : Colors.white38,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text('You',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  )),
            )
          else if (match.hostUid == info?.uid)
            const Text('Host',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
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
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: BoardWidget(),
            ),
          ),
        ),
        _diceTray(),
        const SizedBox(height: 18),
        if (match.status == LudoMatchStatus.finished) _finishedOverlay(match),
      ],
    );
  }

  /// A Ludo King–style row of player panels: avatar, name and a countdown ring
  /// around whoever's turn it is.
  Widget _playersStrip(LudoMatch match) {
    return Consumer<LudoProvider>(
      builder: (context, provider, _) {
        final active = provider.gameState == LudoGameState.finish
            ? null
            : provider.currentTurnSeat;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final seat in kLudoSeatOrder)
                _playerChip(match, seat, seat == active),
            ],
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
    final urgent = active && remaining <= 15;
    final ring = urgent ? const Color(0xFFFF4D4D) : color;
    final initial =
        (info?.name.trim().isNotEmpty ?? false) ? info!.name.trim()[0].toUpperCase() : '?';

    Widget avatar = SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            SizedBox(
              width: 52,
              height: 52,
              child: CircularProgressIndicator(
                value: (remaining / _turnSeconds).clamp(0.0, 1.0),
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(ring),
                backgroundColor: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: info != null ? 1 : 0.22),
              border: Border.all(
                color: active ? ring : Colors.black.withValues(alpha: 0.25),
                width: 2,
              ),
              boxShadow: active
                  ? [BoxShadow(color: ring.withValues(alpha: 0.5), blurRadius: 10)]
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: info == null
                ? const Icon(Icons.person_outline_rounded,
                    size: 18, color: Colors.white38)
                : (info.photo != null && info.photo!.isNotEmpty
                    ? Image.network(info.photo!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initialAvatar(initial))
                    : _initialAvatar(initial)),
          ),
        ],
      ),
    );

    if (urgent) {
      avatar = ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.14).animate(
          CurvedAnimation(parent: _bounce, curve: Curves.easeInOut),
        ),
        child: avatar,
      );
    }

    return Opacity(
      opacity: info != null ? 1 : 0.5,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: 5),
            Text(
              info == null
                  ? 'Empty'
                  : (isMe ? 'You' : info.name.split(' ').first),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
            ),
            SizedBox(
              height: 16,
              child: active
                  ? Text(
                      '${remaining}s',
                      style: TextStyle(
                        color: ring,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialAvatar(String initial) => Container(
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      );

  /// The dice on a warm wooden-style tray, à la a physical board game.
  Widget _diceTray() {
    return Container(
      width: 92,
      height: 92,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2C1E), Color(0xFF241A11)],
        ),
        border: Border.all(color: const Color(0xFF5A4632)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const SizedBox(width: 56, height: 56, child: DiceWidget()),
    );
  }

  Widget _finishedOverlay(LudoMatch match) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF14161C),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏆 Match finished',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 8),
          Text(
            'Winner: ${match.winners.isEmpty ? '—' : (match.seats[match.winners.first]?.name ?? _seatName(match.winners.first))}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            style: TextButton.styleFrom(foregroundColor: _accent),
            child: const Text('Exit to games'),
          ),
        ],
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 48),
            const SizedBox(height: 14),
            Text(title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 18),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    // A warm "game table" backdrop — deep wood tones with a soft felt-green
    // glow behind the board, rather than a neon look.
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E2114), Color(0xFF17110B)],
          ),
        ),
        child: Align(
          alignment: Alignment.center,
          child: FractionallySizedBox(
            widthFactor: 1.2,
            heightFactor: 0.6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1E5A3A).withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
