import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/utils/widgets/bounce_tap_widget.dart';
import 'models/minigame_model.dart';
import 'score/mini_game_score_service.dart';

class MiniGameCard extends StatelessWidget {
  final MiniGame game;
  final bool scoresLoaded;
  final MiniGameScoreService scoreService;

  const MiniGameCard({
    super.key,
    required this.game,
    required this.scoresLoaded,
    required this.scoreService,
  });

  @override
  Widget build(BuildContext context) {
    final gameKey = game.id ?? game.title;
    return BounceTap(
      onTap: game.onTap,
      child: SizedBox(
        width: 90, // like an app icon
        height: 130,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = constraints.maxWidth - 8;
            return Column(
              children: [
                // Icon (App Style)
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(2, 4),
                        ),
                      ],
                      image: DecorationImage(
                        image: game.icon,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        game.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.05,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      if (scoresLoaded)
                        Text(
                          'Best: ${scoreService.bestScore(gameKey)}',
                          style: GoogleFonts.inter(
                            color: Colors.white38,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
