import 'package:flutter/material.dart';
import 'package:hash/config/web_links.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/core/utils/haptics.dart';
import 'package:hash/core/utils/share_origin.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';

const _arcadeLink = '$kWebOrigin/game/arcade';

/// Shares the arcade board: the caller's rank and score when they have one,
/// the current top 3, and a link that opens the leaderboard.
Future<void> shareArcadeLeaderboard(
  BuildContext context, {
  required List<LeaderboardEntry> top,
  int? myRank,
  int? myScore,
  String board = 'Hash Arcade',
  int Function(LeaderboardEntry)? scoreOf,
}) {
  return SharePlus.instance.share(
    ShareParams(
      text: arcadeShareText(
        top: top,
        myRank: myRank,
        myScore: myScore,
        board: board,
        scoreOf: scoreOf,
      ),
      sharePositionOrigin: shareOriginRect(context),
    ),
  );
}

@visibleForTesting
String arcadeShareText({
  required List<LeaderboardEntry> top,
  int? myRank,
  int? myScore,
  String board = 'Hash Arcade',
  int Function(LeaderboardEntry)? scoreOf,
}) {
  final score = scoreOf ?? (LeaderboardEntry e) => e.totalScore;
  const medals = ['🥇', '🥈', '🥉'];
  return [
    if (myRank != null && myScore != null)
      "I'm #$myRank on the $board leaderboard with ${_fmt(myScore)} pts! 🎮"
    else
      'This week on the $board leaderboard 🎮',
    for (final (i, e) in top.take(3).indexed)
      '${medals[i]} ${e.displayName} · ${_fmt(score(e))} pts',
    'Think you can beat us? $_arcadeLink',
  ].join('\n');
}

String _fmt(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// Website-style ticker band (hot pink, black condensed caps, ✦ separators)
/// running this week's arcade top 3, with a pinned LIVE tag and a line on
/// where the viewer stands. Hidden until the board has a leader.
class LeaderMarquee extends StatefulWidget {
  const LeaderMarquee({super.key, required this.service, required this.onOpen});

  final MiniGameLeaderboardService service;
  final VoidCallback onOpen;

  @override
  State<LeaderMarquee> createState() => _LeaderMarqueeState();
}

class _LeaderMarqueeState extends State<LeaderMarquee> {
  // One live query and one standing read for the widget's life; rebuilds
  // must not resubscribe.
  late final _top = widget.service.boardFirstPageStream(
    MiniGameLeaderboardService.overallGameId,
    pageSize: 3,
  );
  late final Future<LeaderboardStanding?> _standing = widget.service
      .fetchStanding(MiniGameLeaderboardService.overallGameId)
      .then<LeaderboardStanding?>((s) => s)
      .catchError((Object _) => null);

  static final _caps = GoogleFonts.anton(
    color: Colors.black,
    fontSize: 17,
    letterSpacing: 0.4,
    height: 1,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LeaderboardPage>(
      stream: _top,
      builder: (context, snap) {
        final top = snap.data?.entries ?? const <LeaderboardEntry>[];
        if (top.isEmpty) return const SizedBox.shrink();
        return FutureBuilder<LeaderboardStanding?>(
          future: _standing,
          builder: (context, standing) {
            final you = _youLine(standing.data);
            const medals = ['🥇', '🥈', '🥉'];
            final items = <Widget>[
              for (final (i, e) in top.indexed) _leader(medals[i], e),
              if (you != null) _youPill(you),
              Text('CAN YOU BEAT THEM?', style: _caps),
            ];
            return Semantics(
              button: true,
              label:
                  "This week's arcade top 3: "
                  '${top.map((e) => '${e.displayName}, ${e.totalScore} points').join('; ')}. '
                  '${you == null ? '' : '$you. '}Opens the leaderboard.',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () {
                  Haptics.selection();
                  widget.onOpen();
                },
                child: Container(
                  height: 42,
                  decoration: const BoxDecoration(
                    color: HomeTokens.pink,
                    border: Border.symmetric(
                      horizontal: BorderSide(color: Colors.black, width: 1.5),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(child: _Ticker(items: items)),
                      const Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: _LiveTag(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// "YOU'RE #12 · 2,160 PTS TO #11" and friends; null while unknown.
  String? _youLine(LeaderboardStanding? s) {
    if (s == null) return null;
    final rank = s.rank;
    final me = s.me;
    if (rank == null || me == null) return 'PLAY A GAME TO GET ON THE BOARD';
    if (rank <= 3) return "YOU'RE #$rank · HOLD THE CROWN 🔥";
    final next = s.nextTarget;
    if (next == null) return "YOU'RE #$rank";
    final gap = next.totalScore - me.totalScore + 1;
    return "YOU'RE #$rank · ${_fmt(gap)} PTS TO #${rank - 1}";
  }

  Widget _leader(String medal, LeaderboardEntry e) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(medal, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 6),
      _Avatar(entry: e),
      const SizedBox(width: 7),
      Text(e.displayName.toUpperCase(), style: _caps),
      const SizedBox(width: 7),
      Text(
        '${_fmt(e.totalScore)} PTS',
        style: _caps.copyWith(color: Colors.black.withValues(alpha: 0.6)),
      ),
    ],
  );

  Widget _youPill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: _caps.copyWith(color: HomeTokens.pink, fontSize: 14),
    ),
  );
}

/// Pinned black tag with a pulsing dot; the ticker scrolls out from under it.
class _LiveTag extends StatefulWidget {
  const _LiveTag();

  @override
  State<_LiveTag> createState() => _LiveTagState();
}

class _LiveTagState extends State<_LiveTag>
    with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Row(
            children: [
              FadeTransition(
                opacity: Tween(begin: 0.35, end: 1.0).animate(_pulse),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: HomeTokens.pink,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'LIVE TOP 3',
                style: GoogleFonts.anton(
                  color: HomeTokens.pink,
                  fontSize: 15,
                  letterSpacing: 0.6,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        // Soft edge so names slide under the tag instead of being cut.
        Container(
          width: 18,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [HomeTokens.pink, HomeTokens.pink.withValues(alpha: 0)],
            ),
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.entry});
  final LeaderboardEntry entry;

  @override
  Widget build(BuildContext context) {
    final url = (entry.avatarUrl ?? '').trim();
    final initial = Center(
      child: Text(
        entry.displayName.isEmpty ? '?' : entry.displayName[0].toUpperCase(),
        style: GoogleFonts.anton(color: HomeTokens.pink, fontSize: 12),
      ),
    );
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: ClipOval(
        child: url.isEmpty
            ? initial
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: 72,
                errorBuilder: (_, _, _) => initial,
              ),
      ),
    );
  }
}

/// Endless right-to-left scroll of [items] at a steady speed.
class _Ticker extends StatefulWidget {
  const _Ticker({required this.items});
  final List<Widget> items;

  @override
  State<_Ticker> createState() => _TickerState();
}

class _TickerState extends State<_Ticker> with SingleTickerProviderStateMixin {
  static const _speed = 40.0; // logical px per second
  final _scroll = ScrollController();
  late final Ticker _ticker = createTicker(_tick);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still && _ticker.isActive) _ticker.stop();
    if (!still && !_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    // The list is endless, so the offset only grows; no wrap needed.
    if (_scroll.hasClients) {
      _scroll.jumpTo(elapsed.inMicroseconds / 1e6 * _speed);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scroll,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      // Starts clear of the pinned tag.
      padding: const EdgeInsets.only(left: 120),
      itemBuilder: (_, i) => Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 22),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.items[i % widget.items.length],
              const SizedBox(width: 22),
              const Text(
                '✦',
                style: TextStyle(color: Colors.black, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
