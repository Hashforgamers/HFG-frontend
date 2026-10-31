import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/tournament_operations.dart';
import '../views/community_theme.dart';

class TournamentBracket extends StatefulWidget {
  const TournamentBracket({
    super.key,
    required this.matches,
    this.currentTeamId,
    this.expanded = false,
    this.onStartMatch,
    this.onSubmitResult,
  });

  final List<CommunityMatch> matches;
  final String? currentTeamId;
  final bool expanded;
  final ValueChanged<CommunityMatch>? onStartMatch;
  final ValueChanged<CommunityMatch>? onSubmitResult;

  @override
  State<TournamentBracket> createState() => _TournamentBracketState();
}

class _TournamentBracketState extends State<TournamentBracket> {
  final TransformationController _transform = TransformationController();
  String? _selectedMatchId;
  var _activeRound = 0;
  var _showMyPath = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.matches.isEmpty) return const _BracketEmpty();
    final rounds = _groupRounds(widget.matches);
    final canvasWidth = math.max(760.0, rounds.length * 310.0 + 80);
    final largestRound = rounds
        .map((round) => round.matches.length)
        .fold<int>(1, math.max);
    final canvasHeight = math.max(560.0, largestRound * 126.0 + 110);
    final viewportHeight = widget.expanded
        ? math.max(
            280.0,
            MediaQuery.sizeOf(context).height -
                kToolbarHeight -
                MediaQuery.paddingOf(context).vertical,
          )
        : math.min(610.0, math.max(470.0, canvasHeight));

    return Container(
      height: viewportHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF080A14),
        borderRadius: BorderRadius.circular(widget.expanded ? 0 : 22),
        border: widget.expanded
            ? null
            : Border.all(color: const Color(0xFF2C3152)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: const _ArenaBackgroundPainter()),
          ),
          Positioned.fill(
            top: 96,
            child: InteractiveViewer(
              transformationController: _transform,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100),
              minScale: .45,
              maxScale: 2.2,
              trackpadScrollCausesScale: true,
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: _BracketCanvas(
                  rounds: rounds,
                  canvasWidth: canvasWidth,
                  canvasHeight: canvasHeight,
                  currentTeamId: widget.currentTeamId,
                  focusedTeamId: _showMyPath ? widget.currentTeamId : null,
                  selectedMatchId: _selectedMatchId,
                  onMatchTap: _selectMatch,
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 8,
            top: 10,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 390;
                return Row(
                  children: [
                    Container(
                      width: 6,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF8A241), Color(0xFFC06701)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Color(0x99F8A241), blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            compact ? 'BRACKET' : 'TOURNAMENT BRACKET',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CT.headline(compact ? 12 : 14),
                          ),
                          if (!compact)
                            Text(
                              'TAP A MATCH  •  DRAG  •  PINCH TO ZOOM',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: CT.mono(8, color: CT.muted),
                            ),
                        ],
                      ),
                    ),
                    _toolButton(
                      Icons.remove_rounded,
                      () => _zoom(.82),
                      tooltip: 'Zoom out',
                    ),
                    _toolButton(
                      Icons.center_focus_strong_rounded,
                      _resetView,
                      tooltip: 'Reset view',
                    ),
                    _toolButton(
                      Icons.add_rounded,
                      () => _zoom(1.22),
                      tooltip: 'Zoom in',
                    ),
                    if (!widget.expanded)
                      _toolButton(
                        Icons.open_in_full_rounded,
                        () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => Scaffold(
                              backgroundColor: const Color(0xFF080A14),
                              appBar: AppBar(
                                backgroundColor: const Color(0xFF080A14),
                                foregroundColor: Colors.white,
                                title: const Text('Tournament bracket'),
                              ),
                              body: TournamentBracket(
                                matches: widget.matches,
                                currentTeamId: widget.currentTeamId,
                                expanded: true,
                                onStartMatch: widget.onStartMatch,
                                onSubmitResult: widget.onSubmitResult,
                              ),
                            ),
                          ),
                        ),
                        tooltip: 'Open full screen',
                      ),
                  ],
                );
              },
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 53,
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (widget.currentTeamId != null) ...[
                  _navChip(
                    label: 'MY PATH',
                    icon: Icons.route_rounded,
                    selected: _showMyPath,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showMyPath = !_showMyPath);
                    },
                  ),
                  const SizedBox(width: 7),
                ],
                for (var index = 0; index < rounds.length; index++) ...[
                  _navChip(
                    label: rounds[index].title.toUpperCase(),
                    icon: index == rounds.length - 1
                        ? Icons.emoji_events_rounded
                        : null,
                    selected: _activeRound == index,
                    onTap: () => _focusRound(index),
                  ),
                  if (index != rounds.length - 1) const SizedBox(width: 7),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _zoom(double factor) {
    _transform.value = _transform.value.clone()
      ..scaleByDouble(factor, factor, factor, 1);
  }

  void _selectMatch(CommunityMatch match) {
    HapticFeedback.selectionClick();
    setState(() => _selectedMatchId = match.id);
    _showMatchDetails(match);
  }

  void _focusRound(int index) {
    HapticFeedback.selectionClick();
    const scale = .9;
    final targetX = 38.0 + index * 310.0;
    final matrix = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setTranslationRaw(16 - targetX * scale, 0, 0);
    setState(() => _activeRound = index);
    _transform.value = matrix;
  }

  void _resetView() {
    HapticFeedback.selectionClick();
    setState(() => _activeRound = 0);
    _transform.value = Matrix4.identity();
  }

  Widget _navChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return ActionChip(
      onPressed: onTap,
      avatar: icon == null
          ? null
          : Icon(icon, size: 14, color: selected ? CT.primary : CT.muted),
      label: Text(label),
      labelStyle: CT.mono(7.5, color: selected ? CT.primary : CT.muted),
      padding: const EdgeInsets.symmetric(horizontal: 3),
      visualDensity: VisualDensity.compact,
      backgroundColor: selected
          ? CT.primary.withValues(alpha: .12)
          : const Color(0xB30E1223),
      side: BorderSide(
        color: selected
            ? CT.primary.withValues(alpha: .65)
            : const Color(0xFF343A60),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
    );
  }

  Future<void> _showMatchDetails(CommunityMatch match) async {
    final localizations = MaterialLocalizations.of(context);
    final scheduledAt = match.scheduledAt?.toLocal();
    final schedule = scheduledAt == null
        ? 'Schedule to be announced'
        : '${localizations.formatMediumDate(scheduledAt)} · '
              '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(scheduledAt))}';
    final canStart =
        widget.onStartMatch != null &&
        {'scheduled', 'ready'}.contains(match.status) &&
        match.teamA != null &&
        match.teamB != null;
    final canSubmitResult =
        widget.onSubmitResult != null &&
        {'active', 'in_progress', 'awaiting_results'}.contains(match.status);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF111526),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF343A60)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CT.muted.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (match.roundName ?? 'Match').toUpperCase(),
                          style: CT.mono(9, color: CT.primary),
                        ),
                        const SizedBox(height: 3),
                        Text(schedule, style: CT.body(11.5)),
                      ],
                    ),
                  ),
                  _StatusPill(status: match.status),
                ],
              ),
              const SizedBox(height: 16),
              _MatchDetailTeam(
                team: match.teamA,
                score: match.teamAScore,
                winner: match.winnerTeamId == match.teamA?.id,
                isCurrent: widget.currentTeamId == match.teamA?.id,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text('VS', style: CT.mono(8, color: CT.muted)),
              ),
              const SizedBox(height: 8),
              _MatchDetailTeam(
                team: match.teamB,
                score: match.teamBScore,
                winner: match.winnerTeamId == match.teamB?.id,
                isCurrent: widget.currentTeamId == match.teamB?.id,
              ),
              const SizedBox(height: 16),
              if (canStart || canSubmitResult) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (canStart) {
                        widget.onStartMatch!(match);
                      } else {
                        widget.onSubmitResult!(match);
                      }
                    },
                    icon: Icon(
                      canStart
                          ? Icons.play_arrow_rounded
                          : Icons.emoji_events_outlined,
                    ),
                    label: Text(canStart ? 'START MATCH' : 'ADD RESULT'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: const Color(0xFFF8A241),
                      foregroundColor: const Color(0xFF171006),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: CT.onSurface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('CLOSE'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton(
    IconData icon,
    VoidCallback onPressed, {
    required String tooltip,
  }) => IconButton(
    tooltip: tooltip,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.all(6),
    constraints: const BoxConstraints.tightFor(width: 34, height: 34),
    onPressed: onPressed,
    icon: Icon(icon, size: 19, color: Colors.white),
  );
}

class _BracketCanvas extends StatelessWidget {
  const _BracketCanvas({
    required this.rounds,
    required this.canvasWidth,
    required this.canvasHeight,
    required this.currentTeamId,
    required this.focusedTeamId,
    required this.selectedMatchId,
    required this.onMatchTap,
  });

  final List<_RoundData> rounds;
  final double canvasWidth;
  final double canvasHeight;
  final String? currentTeamId;
  final String? focusedTeamId;
  final String? selectedMatchId;
  final ValueChanged<CommunityMatch> onMatchTap;

  @override
  Widget build(BuildContext context) {
    const cardWidth = 246.0;
    const cardHeight = 92.0;
    const roundWidth = 310.0;
    final cards = <Widget>[];

    for (var roundIndex = 0; roundIndex < rounds.length; roundIndex++) {
      final round = rounds[roundIndex];
      final usableHeight = canvasHeight - 104;
      final slotHeight = usableHeight / math.max(1, round.matches.length);
      final x = 38.0 + roundIndex * roundWidth;
      cards.add(
        Positioned(
          left: x,
          top: 18,
          width: cardWidth,
          child: _RoundHeader(
            title: round.title,
            matchCount: round.matches.length,
            isFinal: roundIndex == rounds.length - 1,
          ),
        ),
      );
      for (
        var matchIndex = 0;
        matchIndex < round.matches.length;
        matchIndex++
      ) {
        final y =
            76.0 + slotHeight * matchIndex + (slotHeight - cardHeight) / 2;
        cards.add(
          Positioned(
            left: x,
            top: y,
            width: cardWidth,
            height: cardHeight,
            child: _MatchCard(
              match: round.matches[matchIndex],
              currentTeamId: currentTeamId,
              focusedTeamId: focusedTeamId,
              featured: roundIndex == rounds.length - 1,
              selected: selectedMatchId == round.matches[matchIndex].id,
              onTap: () => onMatchTap(round.matches[matchIndex]),
            ),
          ),
        );
      }
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _BracketConnectorPainter(
              rounds: rounds,
              canvasHeight: canvasHeight,
              focusedTeamId: focusedTeamId,
            ),
          ),
        ),
        ...cards,
      ],
    );
  }
}

class _RoundHeader extends StatelessWidget {
  const _RoundHeader({
    required this.title,
    required this.matchCount,
    required this.isFinal,
  });
  final String title;
  final int matchCount;
  final bool isFinal;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(
        isFinal ? Icons.emoji_events_rounded : Icons.bolt_rounded,
        size: 16,
        color: isFinal ? const Color(0xFFFFC857) : CT.primary,
      ),
      const SizedBox(width: 7),
      Expanded(
        child: Text(
          title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: CT.mono(
            10,
            color: isFinal ? const Color(0xFFFFC857) : Colors.white,
          ),
        ),
      ),
      Text(
        '$matchCount MATCH${matchCount == 1 ? '' : 'ES'}',
        style: CT.mono(7),
      ),
    ],
  );
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({
    required this.match,
    required this.currentTeamId,
    required this.focusedTeamId,
    required this.featured,
    required this.selected,
    required this.onTap,
  });
  final CommunityMatch match;
  final String? currentTeamId;
  final String? focusedTeamId;
  final bool featured;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final live = {'live', 'in_progress'}.contains(match.status);
    final isResolvedBye =
        {'completed', 'bye'}.contains(match.status) &&
        (match.teamA == null || match.teamB == null) &&
        (match.teamA != null || match.teamB != null);
    final onFocusedPath =
        focusedTeamId == null ||
        match.teamA?.id == focusedTeamId ||
        match.teamB?.id == focusedTeamId;
    return Semantics(
      button: true,
      selected: selected,
      hint: 'Tap for match details',
      onTap: onTap,
      label:
          '${match.teamA?.name ?? (isResolvedBye ? 'No opponent' : 'To be decided')} versus '
          '${match.teamB?.name ?? (isResolvedBye ? 'No opponent' : 'To be decided')}, ${match.status}',
      child: AnimatedOpacity(
        opacity: onFocusedPath || selected ? 1 : .24,
        duration: const Duration(milliseconds: 180),
        child: AnimatedScale(
          scale: selected ? 1.035 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: selected
                      ? const [Color(0xFF243B42), Color(0xFF101D29)]
                      : featured
                      ? const [Color(0xFF261A3F), Color(0xFF11162A)]
                      : const [Color(0xFF171B31), Color(0xFF0E1223)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? CT.primary
                      : live
                      ? CT.primary
                      : featured
                      ? const Color(0xFFFFC857)
                      : const Color(0xFF343A60),
                  width: selected || live || featured ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected || live
                        ? CT.primary.withValues(alpha: .32)
                        : const Color(0x66000000),
                    blurRadius: selected || live ? 18 : 12,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Column(
                  children: [
                    _TeamLine(
                      team: match.teamA,
                      score: match.teamAScore,
                      winner: match.winnerTeamId == match.teamA?.id,
                      highlighted: currentTeamId == match.teamA?.id,
                      placeholder: isResolvedBye ? '' : 'TBD',
                    ),
                    Container(height: 1, color: const Color(0xFF44301D)),
                    _TeamLine(
                      team: match.teamB,
                      score: match.teamBScore,
                      winner: match.winnerTeamId == match.teamB?.id,
                      highlighted: currentTeamId == match.teamB?.id,
                      placeholder: isResolvedBye ? '' : 'TBD',
                    ),
                    Container(
                      height: 19,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      color: const Color(0x66000000),
                      child: Row(
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: live ? CT.primary : CT.muted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            match.status.replaceAll('_', ' ').toUpperCase(),
                            style: CT.mono(
                              7,
                              color: live ? CT.primary : CT.muted,
                            ),
                          ),
                          const Spacer(),
                          if (selected) ...[
                            const Icon(
                              Icons.touch_app_rounded,
                              size: 11,
                              color: CT.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            match.roundName ?? 'MATCH',
                            style: CT.mono(7, color: CT.muted),
                          ),
                        ],
                      ),
                    ),
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

class _TeamLine extends StatelessWidget {
  const _TeamLine({
    required this.team,
    required this.score,
    required this.winner,
    required this.highlighted,
    required this.placeholder,
  });
  final CommunityTeam? team;
  final int? score;
  final bool winner;
  final bool highlighted;
  final String placeholder;

  @override
  Widget build(BuildContext context) {
    if (team == null && placeholder.isEmpty) {
      return const Expanded(child: SizedBox.expand());
    }
    final name = team?.name ?? placeholder;
    return Expanded(
      child: Container(
        color: highlighted ? const Color(0x252BFFB0) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8A241), Color(0xFFC06701)],
                ),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                team == null
                    ? (placeholder == 'BYE' ? '—' : '?')
                    : name.characters.first.toUpperCase(),
                style: CT.headline(10),
              ),
            ),
            const SizedBox(width: 8),
            if (team?.seed != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Text('${team!.seed}', style: CT.mono(8)),
              ),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CT.body(
                  12,
                  color: winner ? Colors.white : CT.onSurfaceVariant,
                  w: winner ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (winner)
              const Icon(
                Icons.arrow_upward_rounded,
                size: 13,
                color: CT.primary,
              ),
            const SizedBox(width: 6),
            Text(
              score?.toString() ?? '—',
              style: CT.headline(14, color: winner ? CT.primary : Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final live = {'live', 'in_progress'}.contains(status);
    final disputed = status == 'disputed';
    final color = live
        ? CT.primary
        : disputed
        ? const Color(0xFFFFC857)
        : CT.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: .45)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: CT.mono(8, color: color),
      ),
    );
  }
}

class _MatchDetailTeam extends StatelessWidget {
  const _MatchDetailTeam({
    required this.team,
    required this.score,
    required this.winner,
    required this.isCurrent,
  });

  final CommunityTeam? team;
  final int? score;
  final bool winner;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final name = team?.name ?? 'To be decided';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? CT.primary.withValues(alpha: .08)
            : const Color(0xFF191E33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: winner
              ? CT.primary
              : isCurrent
              ? CT.primary.withValues(alpha: .45)
              : const Color(0xFF343A60),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF2A1A0D),
            child: Text(
              team == null ? '?' : name.characters.first.toUpperCase(),
              style: CT.headline(12, color: CT.primary),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CT.headline(14),
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 7),
                      Text('YOU', style: CT.mono(7, color: CT.primary)),
                    ],
                  ],
                ),
                if (team != null && team!.members.isNotEmpty)
                  Text(
                    '${team!.members.length} player${team!.members.length == 1 ? '' : 's'}',
                    style: CT.body(9.5, color: CT.muted),
                  ),
              ],
            ),
          ),
          if (winner)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.emoji_events_rounded,
                color: CT.primary,
                size: 18,
              ),
            ),
          Text(score?.toString() ?? '—', style: CT.display(22)),
        ],
      ),
    );
  }
}

class _BracketConnectorPainter extends CustomPainter {
  const _BracketConnectorPainter({
    required this.rounds,
    required this.canvasHeight,
    required this.focusedTeamId,
  });
  final List<_RoundData> rounds;
  final double canvasHeight;
  final String? focusedTeamId;

  @override
  void paint(Canvas canvas, Size size) {
    const cardWidth = 246.0;
    const cardHeight = 92.0;
    const roundWidth = 310.0;
    final basePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFF8A241), Color(0xFFC06701)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    if (focusedTeamId != null) {
      basePaint.colorFilter = const ColorFilter.mode(
        Color(0x44343A60),
        BlendMode.srcIn,
      );
    }
    final pathPaint = Paint()
      ..color = CT.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    for (var round = 0; round < rounds.length - 1; round++) {
      final current = rounds[round].matches.length;
      final next = rounds[round + 1].matches.length;
      final currentSlot = (canvasHeight - 104) / math.max(1, current);
      final nextSlot = (canvasHeight - 104) / math.max(1, next);
      final startX = 38.0 + round * roundWidth + cardWidth;
      final endX = 38.0 + (round + 1) * roundWidth;
      for (var index = 0; index < current; index++) {
        final startY =
            76.0 + currentSlot * index + (currentSlot - cardHeight) / 2 + 36;
        final target = math.min(next - 1, index ~/ 2);
        final endY =
            76.0 + nextSlot * target + (nextSlot - cardHeight) / 2 + 36;
        final bendX = (startX + endX) / 2;
        final path = Path()
          ..moveTo(startX, startY)
          ..cubicTo(bendX, startY, bendX, endY, endX, endY);
        final match = rounds[round].matches[index];
        final onFocusedPath =
            focusedTeamId != null &&
            (match.teamA?.id == focusedTeamId ||
                match.teamB?.id == focusedTeamId);
        final paint = onFocusedPath ? pathPaint : basePaint;
        canvas.drawPath(path, paint);
        canvas.drawCircle(Offset(startX, startY), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BracketConnectorPainter oldDelegate) =>
      oldDelegate.rounds != rounds ||
      oldDelegate.canvasHeight != canvasHeight ||
      oldDelegate.focusedTeamId != focusedTeamId;
}

class _ArenaBackgroundPainter extends CustomPainter {
  const _ArenaBackgroundPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x18F8A241)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x28F8A241), Color(0x00080A14)],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * .5, size.height * .5),
              radius: size.width * .55,
            ),
          );
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BracketEmpty extends StatelessWidget {
  const _BracketEmpty();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: const Color(0xFF101424),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF44301D)),
    ),
    child: Column(
      children: [
        const Icon(Icons.account_tree_outlined, color: CT.primary, size: 34),
        const SizedBox(height: 10),
        Text('BRACKET NOT GENERATED', style: CT.mono(10)),
        const SizedBox(height: 5),
        Text(
          'The match tree will appear here when the host generates it.',
          textAlign: TextAlign.center,
          style: CT.body(12),
        ),
      ],
    ),
  );
}

class _RoundData {
  const _RoundData(this.title, this.matches);
  final String title;
  final List<CommunityMatch> matches;
}

List<_RoundData> _groupRounds(List<CommunityMatch> matches) {
  final grouped = <int, List<CommunityMatch>>{};
  final titles = <int, String>{};
  for (final match in matches) {
    final round = match.round ?? 1;
    final title = match.roundName?.trim().isNotEmpty == true
        ? match.roundName!
        : 'Round $round';
    titles[round] = title;
    grouped.putIfAbsent(round, () => []).add(match);
  }
  final rounds = grouped.keys.toList()..sort();
  return [
    for (var index = 0; index < rounds.length; index++)
      _RoundData(
        titles.values.where((title) => title == titles[rounds[index]]).length >
                1
            ? index == rounds.length - 1 && rounds.length > 1
                  ? 'Final'
                  : 'Round ${rounds[index]}'
            : titles[rounds[index]]!,
        grouped[rounds[index]]!,
      ),
  ];
}
