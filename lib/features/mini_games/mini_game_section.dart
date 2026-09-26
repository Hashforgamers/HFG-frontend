import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
import 'package:hash/features/mini_games/snakes_ladders/snl_game_screen.dart';
import 'package:hash/utils/widgets/home_section_title.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';
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
        id: 'snakes_ladders',
        title: "Snakes & Ladders",
        subtitle: "Race to 100 · 2–4 players",
        icon: const AssetImage("assets/mini_game_icons/snakes_ladders.png"),
        onTap: () async {
          await Get.to(() => const SnlGameScreen());
          await _loadScores();
        },
      ),
      MiniGame(
        id: 'fruit_cutting',
        title: "Fruit Cutting",
        subtitle: "Slice fruit · +coins daily",
        icon: const AssetImage("assets/mini_game_icons/fruit_cutting.png"),
        onTap: () async {
          await Get.to(() => const FruitCuttingScreen());
          await _loadScores();
        },
      ),
      MiniGame(
        id: 'plant_vs_zombie',
        title: "Plant vs Zombie",
        subtitle: "Defend the lawn · +coins",
        icon: const AssetImage("assets/mini_game_icons/pvz.png"),
        onTap: () async {
          await Get.to(() => const PlantVsZombie());
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
    // Ludo gets its own featured card; the row holds the other games.
    final ludo = _games.where((game) => game.id == 'ludo').firstOrNull;
    final games = _games.where((game) => game.id != 'ludo').toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              const HomeSectionTitle(title: 'Hash ', accent: 'Arcade'),
              const Spacer(),
              GestureDetector(
                onTap: () => _showLeaderboard(context, _scoreService),
                child: GameBadge(
                  label: '🏆 Leaderboard · ${_scoreService.totalScore}',
                ),
              ),
            ],
          ),
        ),
        if (ludo != null) ...[
          _FeaturedGameTile(
            game: ludo,
            best: _scoresLoaded ? _scoreService.bestScore('ludo') : null,
          ),
          const SizedBox(height: 12),
        ],
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

/// Featured card for Ludo: chunky game panel with a Play button.
class _FeaturedGameTile extends StatelessWidget {
  const _FeaturedGameTile({required this.game, required this.best});

  final MiniGame game;
  final int? best;

  @override
  Widget build(BuildContext context) {
    return GamePanel(
      onTap: game.onTap,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: GameColors.outline,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image(image: game.icon, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const GameText('LUDO', size: 26),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: GameColors.outline,
                          width: 1.5,
                        ),
                      ),
                      child: Text('ONLINE', style: gameFont(10, Colors.white)),
                    ),
                  ],
                ),
                Text(
                  'Online · vs AI · Pass & Play',
                  style: gameFont(12.5, GameColors.soft),
                ),
                const SizedBox(height: 2),
                Text(
                  best == null || best == 0 ? 'No best yet' : 'Best $best',
                  style: gameFont(12, GameColors.yellow.$1),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 92,
            child: GameButton(
              label: 'Play',
              tone: GameButtonTone.green,
              height: 48,
              onPressed: game.onTap,
            ),
          ),
        ],
      ),
    );
  }
}
