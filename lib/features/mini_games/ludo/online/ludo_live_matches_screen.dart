import 'package:flutter/material.dart';

import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import '../constants.dart';
import '../widgets/ludo_seat_token.dart';
import 'ludo_match.dart';
import 'ludo_match_screen.dart';
import 'ludo_match_service.dart';

/// A browser of in-progress Ludo matches anyone can drop into and spectate.
class LudoLiveMatchesScreen extends StatefulWidget {
  const LudoLiveMatchesScreen({super.key});

  @override
  State<LudoLiveMatchesScreen> createState() => _LudoLiveMatchesScreenState();
}

class _LudoLiveMatchesScreenState extends State<LudoLiveMatchesScreen> {
  static const _accent = Color(0xFF00DC00);
  static const _live = Color(0xFFFF4D4D);

  final LudoMatchService _service = LudoMatchService();

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

  void _watch(String matchId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LudoMatchScreen(matchId: matchId, spectate: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bgBottom,
      body: Stack(
        children: [
          const GameBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Row(
                    children: [
                      GameIconButton(
                        icon: Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: GameText('LIVE MATCHES', size: 24)),
                      const GameBadge(label: 'LIVE', dot: _live),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<LudoMatch>>(
                    stream: _service.watchLiveMatches(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _empty(
                          icon: Icons.error_outline_rounded,
                          title: 'Couldn’t load matches',
                          subtitle: 'Check your connection and try again.',
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(color: _accent),
                        );
                      }
                      final matches = snapshot.data!;
                      if (matches.isEmpty) {
                        return _empty(
                          icon: Icons.sports_esports_rounded,
                          title: 'No live matches',
                          subtitle:
                              'Start an online match or check back in a bit.',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: matches.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => _matchCard(matches[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _matchCard(LudoMatch match) {
    final hostName =
        match
            .seats[match.occupiedSeats.isNotEmpty
                ? match.occupiedSeats.first
                : LudoPlayerType.green]
            ?.name ??
        'Host';
    final turnName = match.seats[match.turn]?.name.split(' ').first;
    return GamePanel(
      onTap: () => _watch(match.id),
      headerColors: GameColors.red,
      headerHeight: 52,
      header: Row(
        children: [
          Expanded(
            child: GameText('${hostName.split(' ').first}’s match', size: 19),
          ),
          const GameBadge(label: 'LIVE', dot: Colors.white),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GameTray(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (final seat in kLudoSeatOrder)
                      LudoSeatToken(
                        color: _seatColor(seat),
                        name: match.seats[seat]?.name,
                        photo: match.seats[seat]?.photo,
                        size: 42,
                        glow: seat == match.turn,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  turnName == null
                      ? '${match.seatCount} playing'
                      : '$turnName’s turn · ${match.seatCount} playing',
                  style: gameFont(13, GameColors.soft),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GameButton(
            label: 'Watch',
            icon: Icons.visibility_rounded,
            tone: GameButtonTone.purple,
            height: 46,
            onPressed: () => _watch(match.id),
          ),
        ],
      ),
    );
  }

  Widget _empty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GamePanel(
          headerColors: GameColors.purple,
          header: Row(
            children: [
              GameIcon(icon: icon, size: 26),
              const SizedBox(width: 10),
              Expanded(child: GameText(title, size: 20)),
            ],
          ),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: gameFont(14, GameColors.soft),
          ),
        ),
      ),
    );
  }
}
