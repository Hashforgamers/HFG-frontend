import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/features/mini_games/pacman/HomePage.dart';
import 'package:hash/features/mini_games/plant_vs_zombies/Screens/home_page.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_page.dart';
import 'flappy_birds/Layouts/Pages/page_start_screen.dart';
import 'mini_game_card.dart';
import '../../../../features/mini_games/fruit_ninja/fruit_ninja_screen.dart';
import 'models/minigame_model.dart';
import 'score/mini_game_score_service.dart';
import 'score/mini_game_leaderboard_service.dart';

class MiniGamesSection extends StatefulWidget {
  const MiniGamesSection({super.key});

  @override
  State<MiniGamesSection> createState() => _MiniGamesSectionState();
}

class _MiniGamesSectionState extends State<MiniGamesSection> {
  late final List<MiniGame> _games;
  final MiniGameScoreService _scoreService = MiniGameScoreService();
  final MiniGameLeaderboardService _leaderboardService =
      MiniGameLeaderboardService();
  bool _scoresLoaded = false;

  @override
  void initState() {
    super.initState();
    _games = [
      MiniGame(
        id: 'fruit_cutting',
        title: "Fruit Cutting",
        subtitle: "Slice & earn coins",
        icon: const AssetImage("assets/mini_game_icons/fruit_cutting.png"),
        onTap: () async {
          await Get.to(() => FruitCuttingScreen());
          await _loadScores();
        },
      ),
      MiniGame(
        id: 'plant_vs_zombie',
        title: "Plant vs Zombie",
        subtitle: "Test gaming knowledge",
        icon: const AssetImage("assets/mini_game_icons/pvz.png"),
        onTap: () async {
          await Get.to(() => PlantVsZombie());
          await _loadScores();
        },
      ),
      MiniGame(
        id: 'pac_man',
        title: "Pac Man",
        subtitle: "Daily rewards",
        icon: const AssetImage("assets/mini_game_icons/pacman.png"),
        onTap: () async {
          await Get.to(() => PacManHome());
          await _loadScores();
        },
      ),
      MiniGame(
        id: 'laggy_bird',
        title: "Laggy Bird",
        subtitle: "Daily rewards",
        icon: const AssetImage("assets/mini_game_icons/flappy_birds.png"),
        onTap: () async {
          await Get.to(() => const FlappyBirds());
          await _loadScores();
        },
      ),
    ];

    // Precache icons to avoid jank on first scroll/tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final game in _games) {
        precacheImage(game.icon, context);
      }
    });

    _loadScores();
  }

  Future<void> _loadScores() async {
    await _scoreService.ensureLoaded();
    if (mounted) {
      setState(() => _scoresLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 10.0),
          child: Row(
            children: [
              Text(
                "Mini Games 🎮",
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                onPressed: () => _showLeaderboard(context, _scoreService),
                icon: const Icon(Icons.leaderboard_outlined, size: 18),
                label: Text(
                  'Leaderboard (${_scoreService.totalScore})',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),

            itemCount: _games.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => RepaintBoundary(
              child: MiniGameCard(
                game: _games[index],
                scoresLoaded: _scoresLoaded,
                scoreService: _scoreService,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showLeaderboard(
    BuildContext context,
    MiniGameScoreService scoreService,
  ) {
    Get.to(
      () => MiniGameLeaderboardPage(
        scoreService: scoreService,
        leaderboardService: _leaderboardService,
      ),
    );
  }
}
