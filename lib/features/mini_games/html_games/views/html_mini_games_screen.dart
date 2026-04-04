import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/features/mini_games/html_games/models/html_mini_game.dart';
import 'package:hash/features/mini_games/html_games/services/html_mini_game_catalog_service.dart';
import 'package:hash/features/mini_games/html_games/views/html_game_player_screen.dart';
import 'package:hash/features/mini_games/html_games/widgets/html_mini_game_card.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';

class HtmlMiniGamesScreen extends StatefulWidget {
  const HtmlMiniGamesScreen({
    super.key,
    this.games = HtmlMiniGameCatalogService.games,
  });

  final List<HtmlMiniGame> games;

  @override
  State<HtmlMiniGamesScreen> createState() => _HtmlMiniGamesScreenState();
}

class _HtmlMiniGamesScreenState extends State<HtmlMiniGamesScreen> {
  final MiniGameScoreService _scoreService = MiniGameScoreService();
  bool _scoresLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    await _scoreService.ensureLoaded();
    if (!mounted) return;
    setState(() => _scoresLoaded = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090909),
        surfaceTintColor: Colors.transparent,
        title: Text(
          'HTML Arcade',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Play instantly through WebView. Each game pushes its score back to Flutter through the JavaScript bridge.',
              style: GoogleFonts.inter(
                color: Colors.white60,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.76,
              ),
              itemCount: widget.games.length,
              itemBuilder: (context, index) {
                final game = widget.games[index];
                return HtmlMiniGameCard(
                  game: game,
                  bestScore: _scoresLoaded
                      ? _scoreService.bestScore(game.gameId)
                      : null,
                  onTap: () => HtmlGamePlayerScreen.open(game),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
