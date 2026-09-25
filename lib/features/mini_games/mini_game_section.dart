import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/features/mini_games/pacman/HomePage.dart';
import 'package:hash/features/mini_games/plant_vs_zombies/Screens/home_page.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/features/mini_games/html_games/models/html_mini_game.dart';
import 'package:hash/features/mini_games/html_games/services/html_mini_game_catalog_service.dart';
import 'package:hash/features/mini_games/html_games/views/html_game_player_screen.dart';
import 'package:hash/features/mini_games/html_games/widgets/html_mini_game_card.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_page.dart';
import 'package:hash/features/mini_games/ludo/ludo_game_screen.dart';
import 'package:hash/utils/widgets/home_section_title.dart';
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
  late final List<HtmlMiniGame> _htmlGames;
  final MiniGameScoreService _scoreService = MiniGameScoreService();
  final MiniGameLeaderboardService _leaderboardService =
      MiniGameLeaderboardService();
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();
  bool _scoresLoaded = false;

  @override
  void initState() {
    super.initState();
    _games = [
      MiniGame(
        id: 'ludo',
        title: "Ludo",
        subtitle: "Roll & race · 2–4 players",
        icon: const AssetImage("assets/mini_game_icons/ludo_icon.png"),
        onTap: () async {
          await Get.to(() => const LudoGameScreen());
          await _loadScores();
        },
      ),
      MiniGame(
        id: 'fruit_cutting',
        title: "Fruit Cutting",
        subtitle: "Slice fruit · +coins daily",
        icon: const AssetImage("assets/mini_game_icons/fruit_cutting.png"),
        onTap: () async {
          await Get.to(() => FruitCuttingScreen());
          await _loadScores();
        },
      ),
      MiniGame(
        id: 'plant_vs_zombie',
        title: "Plant vs Zombie",
        subtitle: "Defend the lawn · +coins",
        icon: const AssetImage("assets/mini_game_icons/pvz.png"),
        onTap: () async {
          await Get.to(() => PlantVsZombie());
          await _loadScores();
        },
      ),
      MiniGame(
        id: 'pac_man',
        title: "Pac Man",
        subtitle: "Dodge ghosts · +coins",
        icon: const AssetImage("assets/mini_game_icons/pacman.png"),
        onTap: () async {
          await Get.to(() => PacManHome());
          await _loadScores();
        },
      ),
      MiniGame(
        id: 'laggy_bird',
        title: "Laggy Bird",
        subtitle: "Tap to fly · +coins",
        icon: const AssetImage("assets/mini_game_icons/flappy_birds.png"),
        onTap: () async {
          await Get.to(() => const FlappyBirds());
          await _loadScores();
        },
      ),
    ];
    _htmlGames = const HtmlMiniGameCatalogService().getGames();

    // Precache icons to avoid jank on first scroll/tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final game in _games) {
        precacheImage(game.icon, context);
      }
      for (final game in _htmlGames) {
        if (game.thumbnail.isEmpty) continue;
        precacheImage(AssetImage(game.thumbnail), context);
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
    // Keep Ludo first even when an existing section survives a hot reload.
    final games = [
      ..._games.where((game) => game.id == 'ludo'),
      ..._games.where((game) => game.id != 'ludo'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const HomeSectionTitle(title: 'Mini ', accent: 'Games'),
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
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemCount: games.length + _htmlGames.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              if (index < games.length) {
                final nativeGame = games[index];
                return RepaintBoundary(
                  child: MiniGameCard(
                    game: nativeGame,
                    scoresLoaded: _scoresLoaded,
                    scoreService: _scoreService,
                  ),
                );
              }

              final game = _htmlGames[index - games.length];
              return HtmlMiniGameCard(
                game: game,
                compact: true,
                bestScore: _scoresLoaded
                    ? _scoreService.bestScore(game.gameId)
                    : null,
                onTap: () => _openHtmlGame(game),
              );
            },
          ),
        ),
      ],
    );
  }

  void _openHtmlGame(HtmlMiniGame game) {
    unawaited(HtmlGamePlayerScreen.open(game));
  }

  void _showLeaderboard(
    BuildContext context,
    MiniGameScoreService scoreService,
  ) {
    unawaited(
      _segmentService.onCustomEvent('Arcade Leaderboard Entry Tapped', {
        'entry_point': 'mini_games_section',
        'total_score': _scoreService.totalScore,
      }),
    );
    unawaited(
      _fbEventsService.onCustomEvent('Arcade Leaderboard Entry Tapped', {
        'entry_point': 'mini_games_section',
        'total_score': _scoreService.totalScore,
      }),
    );
    Get.to(
      () => MiniGameLeaderboardPage(
        scoreService: scoreService,
        leaderboardService: _leaderboardService,
      ),
    );
  }
}
