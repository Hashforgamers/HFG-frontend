import 'package:flutter/material.dart';

import '../constants.dart';
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
      backgroundColor: const Color(0xFF0B0D12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Text(
              'Live matches',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _live.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _LiveDot(),
                  SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: _live,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<LudoMatch>>(
        stream: _service.watchLiveMatches(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _empty(
              icon: Icons.error_outline_rounded,
              title: 'Couldn’t load live matches',
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
              icon: Icons.sports_esports_outlined,
              title: 'No live matches right now',
              subtitle: 'Start an online match or check back in a bit.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _matchCard(matches[i]),
          );
        },
      ),
    );
  }

  Widget _matchCard(LudoMatch match) {
    final players = match.occupiedSeats;
    final hostName =
        match.seats[match.occupiedSeats.isNotEmpty
                ? match.occupiedSeats.first
                : LudoPlayerType.green]
            ?.name ??
        'Host';
    return InkWell(
      onTap: () => _watch(match.id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF14161C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            // Seat color dots.
            SizedBox(
              width: 46,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final seat in players)
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _seatColor(seat),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$hostName’s match',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${match.seatCount} playing • in progress',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_rounded, size: 15, color: _accent),
                  SizedBox(width: 6),
                  Text(
                    'Watch',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white38, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 6,
    height: 6,
    decoration: const BoxDecoration(
      color: Color(0xFFFF4D4D),
      shape: BoxShape.circle,
    ),
  );
}
