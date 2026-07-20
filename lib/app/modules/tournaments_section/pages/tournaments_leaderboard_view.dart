import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/tournaments_section/widgets/tournaments_loader.dart';

import '../cubit/tournaments_leaderboard_cubit.dart';

class TournamentsLeaderboardView extends StatefulWidget {
  const TournamentsLeaderboardView({super.key, required this.eventId});

  final String eventId;

  @override
  State<TournamentsLeaderboardView> createState() =>
      _TournamentsLeaderboardViewState();
}

class _TournamentsLeaderboardViewState
    extends State<TournamentsLeaderboardView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TournamentsLeaderboardCubit()
            ..fetchLeaderboard(eventId: widget.eventId),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          ),
          title: Text(
            'Leaderboard',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xff291702), // brownish shade
                Color(0xff000000), // black
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child:
                BlocBuilder<
                  TournamentsLeaderboardCubit,
                  TournamentsLeaderboardState
                >(
                  builder: (context, state) {
                    if (state is TournamentsLeaderboardLoading) {
                      return const TournamentsLoader.screen();
                    } else if (state is TournamentsLeaderboardLoaded) {
                      if (!state.isAvailable || state.leaderboard.isEmpty) {
                        return _pendingResults();
                      }
                      return _buildLeaderboardList(
                        state.leaderboard,
                        state.stage,
                      );
                    } else if (state is TournamentsLeaderboardError) {
                      return Center(
                        child: Text(
                          'Error: ${state.message}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
          ),
        ),
      ),
    );
  }

  Widget _pendingResults() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule_rounded, color: Colors.white38, size: 32),
        const SizedBox(height: 10),
        Text(
          'Results are being prepared',
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Check back after the matches conclude.',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildLeaderboardList(
    List<Map<String, dynamic>> leaderboard,
    String stage,
  ) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.white10, height: 12),
      itemBuilder: (context, index) {
        final player = leaderboard[index];
        final rank = player['rank'];
        final name = (player['team_name'] ?? 'Team ${index + 1}').toString();
        final score = player['score'];
        final amount = player['amount'];

        return Container(
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
                  name,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                amount != null
                    ? '${player['currency'] ?? ''} $amount'
                    : score != null
                    ? '$score'
                    : stage == 'winners'
                    ? 'Winner'
                    : '—',
                style: GoogleFonts.orbitron(
                  color: const Color(0xff00DC00),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
