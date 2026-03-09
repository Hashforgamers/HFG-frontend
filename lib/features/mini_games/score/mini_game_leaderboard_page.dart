import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/features/mini_games/flappy_birds/Layouts/Pages/page_start_screen.dart';
import 'package:hash/features/mini_games/pacman/HomePage.dart';
import 'package:hash/features/mini_games/plant_vs_zombies/Screens/home_page.dart';

import '../../../../features/mini_games/fruit_ninja/fruit_ninja_screen.dart';
import 'mini_game_leaderboard_service.dart';
import 'mini_game_score_service.dart';

class MiniGameLeaderboardPage extends StatelessWidget {
  final MiniGameScoreService scoreService;
  final MiniGameLeaderboardService leaderboardService;

  const MiniGameLeaderboardPage({
    super.key,
    required this.scoreService,
    required this.leaderboardService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        ),
        title: Text(
          'Arcade Leaderboard',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF301900), Color(0xFF141414), Color(0xFF000000)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<LeaderboardEntry>>(
            stream: leaderboardService.leaderboardStream(limit: 50),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) return _emptyState();

              final top3 = entries.take(3).toList();
              final rest = entries.length > 3 ? entries.sublist(3) : [];
              final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
              final myIndex = entries.indexWhere(
                (entry) => entry.userId == currentUid,
              );
              final myRank = myIndex >= 0 ? myIndex + 1 : null;
              final myEntry = myIndex >= 0 ? entries[myIndex] : null;
              final nextTarget = myIndex > 0 ? entries[myIndex - 1] : null;

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _yourStandingCard(
                    myRank: myRank,
                    myEntry: myEntry,
                    topScore: entries.first.totalScore,
                  ),
                  if (myEntry != null && nextTarget != null) ...[
                    const SizedBox(height: 10),
                    _nextTargetCard(
                      context: context,
                      myEntry: myEntry,
                      nextTarget: nextTarget,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Top Players',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _podium(top3),
                  const SizedBox(height: 20),
                  if (rest.isNotEmpty) ...[
                    Text(
                      'Challengers',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...rest.asMap().entries.map(
                      (entry) => _leaderboardTile(
                        context: context,
                        rank: entry.key + 4,
                        data: entry.value,
                        topScore: entries.first.totalScore,
                        isCurrentUser: entry.value.userId == currentUid,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sports_esports_rounded,
            color: Colors.white38,
            size: 50,
          ),
          const SizedBox(height: 12),
          Text(
            'No scores yet.\nStart a mini game and claim rank #1.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _yourStandingCard({
    required int? myRank,
    required LeaderboardEntry? myEntry,
    required int topScore,
  }) {
    final score = myEntry?.totalScore ?? scoreService.totalScore;
    final rankLabel = myRank == null ? 'Unranked' : '#$myRank';
    final gap = myRank == 1 ? 0 : (topScore - score).clamp(0, 999999);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0x33FF8A00), Color(0x221E1E1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x33FF8A00),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.16),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: Color(0xFFFFB347),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Standing  $rankLabel',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gap == 0
                      ? 'You are leading the board'
                      : '$gap pts to reach #1',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$score pts',
            style: GoogleFonts.orbitron(
              color: const Color(0xFFFFC65C),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _podium(List<LeaderboardEntry> entries) {
    const rankHeights = {1: 200.0, 2: 160.0, 3: 132.0};
    const order = [1, 0, 2];
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: order.map((idx) {
        final rank = idx + 1;
        final data = idx < entries.length ? entries[idx] : null;
        return Expanded(
          child: _pillarCard(
            rank: rank,
            data: data,
            height: rankHeights[rank] ?? 150,
          ),
        );
      }).toList(),
    );
  }

  Widget _pillarCard({
    required int rank,
    required double height,
    LeaderboardEntry? data,
  }) {
    final accent = _rankColor(rank);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(10),
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withValues(alpha: 0.14), const Color(0xFF171717)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Rank #$rank',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          Column(
            children: [
              CircleAvatar(
                radius: rank == 1 ? 23 : 20,
                backgroundColor: accent.withValues(alpha: 0.58),
                backgroundImage: (data?.avatarUrl ?? '').trim().isNotEmpty
                    ? NetworkImage((data?.avatarUrl ?? '').trim())
                    : null,
                child: (data?.avatarUrl ?? '').trim().isNotEmpty
                    ? null
                    : Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: rank == 1 ? 22 : 18,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                data?.displayName ?? 'Empty',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data != null ? '${data.totalScore} pts' : '--',
                style: GoogleFonts.orbitron(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leaderboardTile({
    required BuildContext context,
    required int rank,
    required LeaderboardEntry data,
    required int topScore,
    required bool isCurrentUser,
  }) {
    final accent = _rankColor(rank);
    final progress = topScore <= 0
        ? 0.0
        : (data.totalScore / topScore).clamp(0, 1).toDouble();
    final primaryGame = _primaryGame(data.scores);
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: () => _showPlayerSheet(
        context: context,
        rank: rank,
        data: data,
        topScore: topScore,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? const Color(0x332D6A4F)
              : const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: isCurrentUser
                ? const Color(0x664ADE80)
                : Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 0.8,
                ),
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white12,
              backgroundImage: (data.avatarUrl ?? '').trim().isNotEmpty
                  ? NetworkImage((data.avatarUrl ?? '').trim())
                  : null,
              child: (data.avatarUrl ?? '').trim().isNotEmpty
                  ? null
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.displayName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'Main: $primaryGame',
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 6),
                        Text(
                          'YOU',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF4ADE80),
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${data.totalScore} pts',
              style: GoogleFonts.orbitron(
                color: const Color(0xFFFFC65C),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextTargetCard({
    required BuildContext context,
    required LeaderboardEntry myEntry,
    required LeaderboardEntry nextTarget,
  }) {
    final gap = (nextTarget.totalScore - myEntry.totalScore).clamp(1, 999999);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Color(0xFFFF9E44),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Beat ${nextTarget.displayName} in $gap pts',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _openBestGame(context, myEntry),
            child: Text(
              'Play',
              style: GoogleFonts.inter(
                color: const Color(0xFF7EA5FF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBestGame(
    BuildContext context,
    LeaderboardEntry myEntry,
  ) async {
    final gameKey = myEntry.scores.isEmpty
        ? ''
        : (myEntry.scores.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value)))
              .first
              .key;

    Widget? target;
    switch (gameKey) {
      case 'fruit_cutting':
        target = FruitCuttingScreen();
        break;
      case 'plant_vs_zombie':
        target = PlantVsZombie();
        break;
      case 'pac_man':
        target = PacManHome();
        break;
      case 'laggy_bird':
        target = const FlappyBirds();
        break;
    }

    if (target != null) {
      await Get.to(() => target!);
      return;
    }

    // Fallback: close leaderboard so user can pick any mini game manually.
    Navigator.pop(context);
  }

  Future<void> _showPlayerSheet({
    required BuildContext context,
    required int rank,
    required LeaderboardEntry data,
    required int topScore,
  }) async {
    final sortedScores = data.scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final gapToTop = rank == 1
        ? 0
        : (topScore - data.totalScore).clamp(0, 999999);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF151A33),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white12,
                      backgroundImage: (data.avatarUrl ?? '').trim().isNotEmpty
                          ? NetworkImage((data.avatarUrl ?? '').trim())
                          : null,
                      child: (data.avatarUrl ?? '').trim().isNotEmpty
                          ? null
                          : const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${data.displayName}  •  Rank #$rank',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${data.totalScore} pts',
                      style: GoogleFonts.orbitron(
                        color: const Color(0xFFFFC65C),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  gapToTop == 0
                      ? 'Top player right now'
                      : '$gapToTop pts behind #1',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...sortedScores
                    .take(4)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _readableGameName(entry.key),
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '${entry.value}',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF7EA5FF),
                                fontWeight: FontWeight.w700,
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
      },
    );
  }

  String _primaryGame(Map<String, int> scores) {
    if (scores.isEmpty) return 'Rookie';
    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return _readableGameName(sorted.first.key);
  }

  String _readableGameName(String key) {
    final value = key.replaceAll('_', ' ').trim();
    if (value.isEmpty) return 'Rookie';
    return value
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  Color _rankColor(int rank) {
    if (rank == 1) return const Color(0xFFFFC857);
    if (rank == 2) return const Color(0xFFC7D2E0);
    if (rank == 3) return const Color(0xFFD8975A);
    return const Color(0xFF6B7280);
  }
}
