import 'package:flutter/material.dart';

import '../models/tournament_operations.dart';
import '../views/community_theme.dart';

class TournamentBracket extends StatelessWidget {
  const TournamentBracket({
    super.key,
    required this.matches,
    this.currentTeamId,
  });

  final List<CommunityMatch> matches;
  final String? currentTeamId;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return _BracketEmpty();
    }
    final grouped = <String, List<CommunityMatch>>{};
    for (final match in matches) {
      final label = match.roundName?.trim().isNotEmpty == true
          ? match.roundName!
          : 'Round ${match.round ?? 1}';
      grouped.putIfAbsent(label, () => []).add(match);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 430;
        return SizedBox(
          height: compact ? 300 : 344,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8),
            itemCount: grouped.length,
            separatorBuilder: (_, _) => const SizedBox(width: 20),
            itemBuilder: (context, roundIndex) {
              final entry = grouped.entries.elementAt(roundIndex);
              return SizedBox(
                width: compact ? constraints.maxWidth - 8 : 340,
                child: _BracketRound(
                  title: entry.key,
                  matches: entry.value,
                  currentTeamId: currentTeamId,
                  showConnectors: roundIndex < grouped.length - 1,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _BracketRound extends StatelessWidget {
  const _BracketRound({
    required this.title,
    required this.matches,
    required this.currentTeamId,
    required this.showConnectors,
  });

  final String title;
  final List<CommunityMatch> matches;
  final String? currentTeamId;
  final bool showConnectors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: CT.mono(10, color: CT.primaryBright),
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, _) => const SizedBox(height: 18),
            itemBuilder: (_, index) => _FixtureCard(
              match: matches[index],
              currentTeamId: currentTeamId,
              showConnector: showConnectors,
            ),
          ),
        ),
      ],
    );
  }
}

class _FixtureCard extends StatelessWidget {
  const _FixtureCard({
    required this.match,
    required this.currentTeamId,
    required this.showConnector,
  });

  final CommunityMatch match;
  final String? currentTeamId;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${match.teamA?.name ?? 'To be decided'} versus '
          '${match.teamB?.name ?? 'To be decided'}, ${match.status}',
      child: SizedBox(
        height: 94,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              right: showConnector ? 13 : 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF20233F),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF373B60)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 14,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: _TeamRow(
                        team: match.teamA,
                        score: match.teamAScore,
                        isWinner:
                            match.winnerTeamId != null &&
                            match.winnerTeamId == match.teamA?.id,
                        highlighted: currentTeamId == match.teamA?.id,
                        top: true,
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFF343856)),
                    Expanded(
                      child: _TeamRow(
                        team: match.teamB,
                        score: match.teamBScore,
                        isWinner:
                            match.winnerTeamId != null &&
                            match.winnerTeamId == match.teamB?.id,
                        highlighted: currentTeamId == match.teamB?.id,
                        top: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showConnector)
              const Positioned(
                right: 0,
                top: 23,
                bottom: 23,
                width: 14,
                child: CustomPaint(painter: _ConnectorPainter()),
              ),
          ],
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.score,
    required this.isWinner,
    required this.highlighted,
    required this.top,
  });

  final CommunityTeam? team;
  final int? score;
  final bool isWinner;
  final bool highlighted;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final name = team?.name ?? 'TBD';
    final seed = team?.seed;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? const Color(0x183DDC84) : Colors.transparent,
        borderRadius: BorderRadius.vertical(
          top: top ? const Radius.circular(17) : Radius.zero,
          bottom: top ? Radius.zero : const Radius.circular(17),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              seed?.toString() ?? '—',
              textAlign: TextAlign.center,
              style: CT.mono(10, color: CT.muted),
            ),
          ),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlighted ? CT.primary : const Color(0xFF2D3152),
            ),
            child: Text(
              name == 'TBD' ? '?' : name.characters.first.toUpperCase(),
              style: CT.headline(11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: CT.body(
                13,
                color: Colors.white,
                w: isWinner ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 42,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isWinner ? const Color(0xFF7138E8) : Colors.transparent,
              borderRadius: BorderRadius.only(
                topRight: top ? const Radius.circular(17) : Radius.zero,
                bottomRight: top ? Radius.zero : const Radius.circular(17),
              ),
            ),
            child: Text(
              score?.toString() ?? '—',
              style: CT.headline(
                14,
                color: isWinner ? Colors.white : CT.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  const _ConnectorPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF454A70)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .58, 0)
      ..lineTo(size.width * .58, size.height / 2)
      ..lineTo(size.width, size.height / 2)
      ..moveTo(0, size.height)
      ..lineTo(size.width * .58, size.height)
      ..lineTo(size.width * .58, size.height / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) => false;
}

class _BracketEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 180,
    alignment: Alignment.center,
    decoration: CT.card(),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.account_tree_outlined, color: CT.muted, size: 34),
        const SizedBox(height: 10),
        Text('Bracket has not been generated', style: CT.body(12)),
      ],
    ),
  );
}
