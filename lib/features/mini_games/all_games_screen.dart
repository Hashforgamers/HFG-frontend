import 'package:flutter/material.dart';
import 'package:hash/features/mini_games/html_games/models/html_mini_game.dart';
import 'package:hash/features/mini_games/html_games/widgets/html_mini_game_card.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import 'mini_game_card.dart';
import 'models/minigame_model.dart';
import 'score/mini_game_score_service.dart';

/// Every arcade game on one screen, opened from "See all" on the home row.
/// Styled like the Ludo panels: purple backdrop, chunky title, game tray.
class AllGamesScreen extends StatelessWidget {
  const AllGamesScreen({
    super.key,
    required this.games,
    required this.htmlGames,
    required this.scoreService,
    required this.onOpenHtml,
  });

  final List<MiniGame> games;
  final List<HtmlMiniGame> htmlGames;
  final MiniGameScoreService scoreService;
  final void Function(HtmlMiniGame game) onOpenHtml;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      for (final game in htmlGames)
        HtmlMiniGameCard(
          game: game,
          compact: true,
          bestScore: scoreService.bestScore(game.gameId),
          onTap: () => onOpenHtml(game),
        ),
      for (final game in games)
        MiniGameCard(
          game: game,
          scoresLoaded: true,
          scoreService: scoreService,
        ),
    ];
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [GameColors.bgTop, GameColors.bgBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 4),
                    const GameText('ALL GAMES', size: 28),
                    const Spacer(),
                    Text(
                      '${tiles.length} games',
                      style: gameFont(15, GameColors.soft),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    0,
                    12,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: GamePanel(
                    padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                    // cards are fixed 90×130 tiles; three per row, centred in each cell
                    child: GridView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            mainAxisExtent: 140,
                          ),
                      children: [for (final t in tiles) Center(child: t)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
