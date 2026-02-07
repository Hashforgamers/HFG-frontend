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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon (App Style)
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18), // rounded app icon
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
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
            const SizedBox(height: 5),
            // Title under icon
            Text(
              game.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (scoresLoaded)
              Text(
                'Best: ${scoreService.bestScore(gameKey)}',
                style: GoogleFonts.inter(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
