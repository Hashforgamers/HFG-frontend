import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
          'Leaderboard',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff291702), Color(0xff000000)],
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

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    'Top Players',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...rest.asMap().entries.map(
                      (entry) => _leaderboardTile(
                        rank: entry.key + 4,
                        data: entry.value,
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
            Icons.leaderboard_outlined,
            color: Colors.white38,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No scores yet.\nPlay a mini game to join the board!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _podium(List<LeaderboardEntry> entries) {
    const rankHeights = {1: 200.0, 2: 160.0, 3: 130.0};
    const order = [1, 0, 2]; // show 2nd, 1st, 3rd visually like tournaments
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
    final accent = rank == 1
        ? Colors.amber
        : rank == 2
        ? Colors.grey
        : Colors.brown;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(10),
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: accent,
            child: Text(
              '#$rank',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Column(
            children: [
              Text(
                data?.displayName ?? 'Empty',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data != null ? '${data.totalScore} pts' : '--',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _leaderboardTile({required int rank, required LeaderboardEntry data}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: rank == 1
              ? Colors.amber
              : rank == 2
              ? Colors.grey
              : rank == 3
              ? Colors.brown
              : Colors.white10,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: rank == 1
                ? Colors.amber
                : rank == 2
                ? Colors.grey
                : rank == 3
                ? Colors.brown
                : Colors.white12,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              data.displayName,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            '${data.totalScore} pts',
            style: GoogleFonts.orbitron(
              color: const Color(0xff00DC00),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
