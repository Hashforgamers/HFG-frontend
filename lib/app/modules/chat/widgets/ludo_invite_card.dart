import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/features/mini_games/ludo/constants.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_match.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_match_service.dart';
import 'package:hash/features/mini_games/ludo/widgets/ludo_seat_token.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

/// Chat card for a `ludo_invite` message, drawn as a chunky mobile-game panel
/// (thick outline, 3D lip, glossy header) to match [GameButton].
///
/// It listens to the match document so seats, status and the button stay live.
/// The lobby facts the card needs, shared by every seat-based game.
class InviteLobby {
  const InviteLobby({
    required this.status,
    required this.seats,
    required this.turn,
    required this.winners,
  });

  factory InviteLobby.fromLudo(LudoMatch m) => InviteLobby(
    status: m.status,
    seats: m.seats,
    turn: m.turn,
    winners: m.winners,
  );

  final LudoMatchStatus status;
  final Map<LudoPlayerType, LudoSeatInfo> seats;
  final LudoPlayerType turn;
  final List<LudoPlayerType> winners;

  bool get isFull => seats.length >= 4;
  int get seatCount => seats.length;

  LudoPlayerType? seatOf(String uid) {
    for (final e in seats.entries) {
      if (e.value.uid == uid) return e.key;
    }
    return null;
  }
}

class LudoInviteCard extends StatefulWidget {
  const LudoInviteCard({
    super.key,
    required this.matchId,
    required this.inviterName,
    required this.isMine,
    required this.timeLabel,
    required this.onOpen,
    this.lobby,
    this.title = 'LUDO',
    this.iconAsset = 'assets/mini_game_icons/ludo_icon.png',
  });

  /// Live lobby for a non-Ludo game; defaults to watching the Ludo match.
  final Stream<InviteLobby?>? lobby;
  final String title;
  final String iconAsset;

  final String matchId;
  final String inviterName;
  final bool isMine;
  final String timeLabel;
  final VoidCallback onOpen;

  @override
  State<LudoInviteCard> createState() => _LudoInviteCardState();
}

enum _LobbyState { loading, open, full, live, finished, closed }

/// Header colours per status.
const _headerTones = {
  _LobbyState.loading: GameColors.grey,
  _LobbyState.open: GameColors.green,
  _LobbyState.full: GameColors.green,
  _LobbyState.live: GameColors.red,
  _LobbyState.finished: GameColors.yellow,
  _LobbyState.closed: GameColors.grey,
};

class _LudoInviteCardState extends State<LudoInviteCard>
    with SingleTickerProviderStateMixin {
  static const _seatColors = {
    LudoPlayerType.green: LudoColor.green,
    LudoPlayerType.yellow: LudoColor.yellow,
    LudoPlayerType.blue: LudoColor.blue,
    LudoPlayerType.red: LudoColor.red,
  };

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  Stream<InviteLobby?>? _stream;

  @override
  void initState() {
    super.initState();
    if (widget.matchId.isNotEmpty) {
      _stream =
          widget.lobby ??
          LudoMatchService()
              .watch(widget.matchId)
              .map((m) => m == null ? null : InviteLobby.fromLudo(m));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulse.stop();
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  _LobbyState _stateOf(AsyncSnapshot<InviteLobby?> snap) {
    if (_stream == null) return _LobbyState.closed;
    if (!snap.hasData && snap.connectionState == ConnectionState.waiting) {
      return _LobbyState.loading;
    }
    final match = snap.data;
    if (match == null) return _LobbyState.closed;
    switch (match.status) {
      case LudoMatchStatus.waiting:
        return match.isFull ? _LobbyState.full : _LobbyState.open;
      case LudoMatchStatus.active:
        return _LobbyState.live;
      case LudoMatchStatus.finished:
        return _LobbyState.finished;
      case LudoMatchStatus.cancelled:
        return _LobbyState.closed;
    }
  }

  void _open() {
    Haptics.selection();
    widget.onOpen();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<InviteLobby?>(
      stream: _stream,
      builder: (context, snap) {
        final match = snap.data;
        final state = _stateOf(snap);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        final seated = uid != null && match?.seatOf(uid) != null;
        final enabled =
            state != _LobbyState.closed && state != _LobbyState.loading;

        return GamePanel(
          headerColors: _headerTones[state]!,
          headerHeight: 64,
          header: _header(state),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _tray(match, state),
              const SizedBox(height: 12),
              _button(state, match, seated, enabled),
              const SizedBox(height: 6),
              _footer(),
            ],
          ),
        );
      },
    );
  }

  Widget _header(_LobbyState state) {
    return Row(
      children: [
        _gameIcon(),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameText(widget.title, size: 24),
              Text(
                widget.isMine ? 'Your match · 4P' : '4-player match',
                style: gameFont(12, GameColors.outline.withValues(alpha: 0.7)),
              ),
            ],
          ),
        ),
        _statusBadge(state),
      ],
    );
  }

  Widget _gameIcon() => Container(
    width: 44,
    height: 44,
    padding: const EdgeInsets.all(2.5),
    decoration: BoxDecoration(
      color: GameColors.outline,
      borderRadius: BorderRadius.circular(12),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        widget.iconAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.casino_rounded, color: Colors.white, size: 24),
      ),
    ),
  );

  Widget _statusBadge(_LobbyState state) {
    final label = switch (state) {
      _LobbyState.loading => '...',
      _LobbyState.open => 'OPEN',
      _LobbyState.full => 'READY',
      _LobbyState.live => 'LIVE',
      _LobbyState.finished => 'ENDED',
      _LobbyState.closed => 'CLOSED',
    };
    final pulsing = state == _LobbyState.live || state == _LobbyState.open;
    return GameBadge(
      label: label,
      dot: pulsing
          ? (state == _LobbyState.live
                ? const Color(0xFFFF3B30)
                : const Color(0xFF7CF06B))
          : null,
      pulse: pulsing ? _pulse : null,
    );
  }

  /// Recessed tray holding the four seat tokens and the summary line.
  Widget _tray(InviteLobby? match, _LobbyState state) {
    final winner =
        state == _LobbyState.finished && (match?.winners.isNotEmpty ?? false)
        ? match!.winners.first
        : null;
    return GameTray(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final seat in kLudoSeatOrder)
                _seat(
                  color: _seatColors[seat]!,
                  info: match?.seats[seat],
                  joinable: state == _LobbyState.open,
                  isWinner: seat == winner,
                  isTurn: state == _LobbyState.live && match?.turn == seat,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _summary(match, state),
            textAlign: TextAlign.center,
            style: gameFont(13, GameColors.soft),
          ),
        ],
      ),
    );
  }

  Widget _seat({
    required Color color,
    required LudoSeatInfo? info,
    required bool joinable,
    required bool isWinner,
    required bool isTurn,
  }) {
    final filled = info != null;
    final name = filled ? info.name.trim() : '';
    final token = LudoSeatToken(
      color: color,
      name: info?.name,
      photo: info?.photo,
      joinable: joinable,
      glow: isTurn,
    );

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              token,
              if (isWinner)
                Positioned(
                  top: -16,
                  child: Text('👑', style: TextStyle(fontSize: 26, height: 1)),
                ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            filled ? _firstName(name) : (joinable ? 'Open' : '—'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: gameFont(
              12,
              filled ? Colors.white : GameColors.soft.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _firstName(String name) {
    final first = name.split(RegExp(r'\s+')).first;
    return first.isEmpty ? 'Player' : first;
  }

  String _summary(InviteLobby? match, _LobbyState state) {
    final count = match?.seatCount ?? 0;
    final open = 4 - count;
    return switch (state) {
      _LobbyState.loading => 'Loading match...',
      _LobbyState.open =>
        '$count of 4 joined · $open ${open == 1 ? 'seat' : 'seats'} open',
      _LobbyState.full => 'Everyone’s in! Waiting for the host',
      _LobbyState.live => _turnLine(match, count),
      _LobbyState.finished => _winnerLine(match),
      _LobbyState.closed => 'This match is no longer available',
    };
  }

  String _turnLine(InviteLobby? match, int count) {
    final name = match?.seats[match.turn]?.name;
    if (name == null || name.trim().isEmpty) {
      return 'In progress with $count players';
    }
    return '${_firstName(name.trim())}’s turn · $count players';
  }

  String _winnerLine(InviteLobby? match) {
    if (match == null || match.winners.isEmpty) return 'Match ended';
    final name = match.seats[match.winners.first]?.name ?? 'A player';
    return '${_firstName(name)} won the match!';
  }

  Widget _button(
    _LobbyState state,
    InviteLobby? match,
    bool seated,
    bool enabled,
  ) {
    final open = 4 - (match?.seatCount ?? 0);
    final (label, tone, icon, subtitle) = switch (state) {
      _LobbyState.loading => ('Loading', GameButtonTone.grey, null, null),
      _LobbyState.open when seated || widget.isMine => (
        'Open Lobby',
        GameButtonTone.green,
        Icons.groups_rounded,
        null,
      ),
      _LobbyState.open => (
        'Join Match',
        GameButtonTone.green,
        Icons.sports_esports_rounded,
        '$open ${open == 1 ? 'seat' : 'seats'} left',
      ),
      _LobbyState.full when seated => (
        'Open Lobby',
        GameButtonTone.green,
        Icons.groups_rounded,
        null,
      ),
      _LobbyState.full => (
        'Watch',
        GameButtonTone.purple,
        Icons.visibility_rounded,
        null,
      ),
      _LobbyState.live when seated => (
        'Rejoin',
        GameButtonTone.red,
        Icons.play_arrow_rounded,
        null,
      ),
      _LobbyState.live => (
        'Watch Live',
        GameButtonTone.purple,
        Icons.visibility_rounded,
        null,
      ),
      _LobbyState.finished => (
        'Results',
        GameButtonTone.yellow,
        Icons.emoji_events_rounded,
        null,
      ),
      _LobbyState.closed => ('Unavailable', GameButtonTone.grey, null, null),
    };
    return GameButton(
      label: label,
      tone: tone,
      icon: icon,
      subtitle: subtitle,
      height: subtitle == null ? 50 : 58,
      onPressed: enabled ? _open : null,
    );
  }

  Widget _footer() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.isMine
                ? 'You sent this invite'
                : 'From ${widget.inviterName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: gameFont(11.5, GameColors.soft.withValues(alpha: 0.75)),
          ),
        ),
        Text(
          widget.timeLabel,
          style: gameFont(11.5, GameColors.soft.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}
