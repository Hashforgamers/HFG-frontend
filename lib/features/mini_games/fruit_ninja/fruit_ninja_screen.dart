import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_page.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';

import 'main_router_game.dart';
import 'presentation/overlays/fruit_overlays.dart';

/// Hosts the Fruit Cutting Flame game with Flutter overlays for the menu,
/// HUD, pause and result screens.
class FruitCuttingScreen extends StatefulWidget {
  const FruitCuttingScreen({super.key});

  @override
  State<FruitCuttingScreen> createState() => _FruitCuttingScreenState();
}

class _FruitCuttingScreenState extends State<FruitCuttingScreen>
    with WidgetsBindingObserver {
  final MainRouterGame _game = MainRouterGame();
  final MiniGameScoreService _scores = MiniGameScoreService();
  final ValueNotifier<int> _best = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game.resultListenable.addListener(_onResult);
    _loadBest();
  }

  Future<void> _loadBest() async {
    await _scores.ensureLoaded();
    // No setState: rebuilding the GameWidget can re-initialise its overlays.
    if (mounted) _best.value = _scores.bestScore(MainRouterGame.gameId);
  }

  void _onResult() {
    final result = _game.resultListenable.value;
    if (result != null && !result.saving) _loadBest();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Never keep slicing (or playing music) in the background.
    if (state != AppLifecycleState.resumed) _game.pauseGame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _game.resultListenable.removeListener(_onResult);
    _game.stopMusic();
    _best.dispose();
    super.dispose();
  }

  void _exit() => Navigator.of(context).maybePop();

  void _openLeaderboard() {
    Get.to(
      () => MiniGameLeaderboardPage(
        scoreService: _scores,
        leaderboardService: MiniGameLeaderboardService(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Back while playing pauses instead of dropping the run.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_game.isPlaying) {
          _game.paused ? _game.resumeGame() : _game.pauseGame();
          return;
        }
        if (_game.overlays.isActive(FruitOverlay.result)) {
          _game.backToMenu();
          return;
        }
        _game.stopMusic();
        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GameWidget<MainRouterGame>(
          game: _game,
          overlayBuilderMap: {
            FruitOverlay.menu: (context, game) => ValueListenableBuilder<int>(
              valueListenable: _best,
              builder: (context, best, _) =>
                  FruitMenuOverlay(game: game, best: best, onExit: _exit),
            ),
            FruitOverlay.hud: (context, game) => FruitHudOverlay(game: game),
            FruitOverlay.pause: (context, game) =>
                FruitPauseOverlay(game: game),
            FruitOverlay.result: (context, game) =>
                FruitResultOverlay(game: game, onLeaderboard: _openLeaderboard),
          },
        ),
      ),
    );
  }
}
