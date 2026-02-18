import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/loader.dart';

import '../cubit/tournaments_leaderboard_cubit.dart';

class TournamentsLeaderboardView extends StatefulWidget {
  const TournamentsLeaderboardView({super.key});

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
      TournamentsLeaderboardCubit()..fetchLeaderboard(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            onPressed: (){
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.white,),
          ),
          title: Text('Leaderboard', style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),),
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
            child: BlocBuilder<TournamentsLeaderboardCubit,
                TournamentsLeaderboardState>(
              builder: (context, state) {
                if (state is TournamentsLeaderboardLoading) {
                  return const Center(child: RainbowLoadingBar());
                } else if (state is TournamentsLeaderboardLoaded) {
                  return _buildLeaderboardList(state.leaderboard);
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

  Widget _buildLeaderboardList(List<Map<String, dynamic>> leaderboard) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      children: [
        // Scrollable PNG image at the top
        Image.asset(
          'assets/hash_store_images/leaderboard_img.png',
          height: 170,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 20),

        // Main leaderboard container
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white30, width: 1.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [

              ...List.generate(leaderboard.length, (index) {
                final player = leaderboard[index];
                final rank = player['rank'];
                final name = player['player'];
                final points = player['points'];
                final matchesWon = player['matchesWon'];

                return Column(
                  children: [

                    // Each row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(
                              '$rank',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(player["photoUrl"] ?? ""),
                            backgroundColor: Colors.white12,
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      color: Colors.green, size: 11),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$points pts',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$matchesWon Matches Won',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Add divider except after last row
                    if (index != leaderboard.length - 1)
                      Divider(
                        color: Colors.white24,
                        thickness: 0.6,
                        height: 0,
                        indent: 30,
                        endIndent: 30,
                      ),
                  ],
                );
              }),
            ],
          ),
        )
      ],
    );
  }


}
