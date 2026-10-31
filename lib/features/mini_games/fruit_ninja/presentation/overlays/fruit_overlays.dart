import 'package:flutter/material.dart';
import 'package:hash/features/mini_games/fruit_ninja/core/configs/assets/app_images.dart';
import 'package:hash/features/mini_games/fruit_ninja/main_router_game.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

const _fruitHeader = (Color(0xFFFF8A5B), Color(0xFFE8392C));

String _asset(String name) => '${AppImages.basePath}$name';

/// Start screen: title, mode picker, rules, best score and Play.
class FruitMenuOverlay extends StatelessWidget {
  const FruitMenuOverlay({
    super.key,
    required this.game,
    required this.best,
    required this.onExit,
  });

  final MainRouterGame game;
  final int best;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Row(
                  children: [
                    GameIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Exit',
                      onPressed: onExit,
                    ),
                    const Spacer(),
                    GameBadge(label: '🏆 BEST $best'),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: GamePanel(
                        headerColors: _fruitHeader,
                        headerHeight: 92,
                        header: Row(
                          children: [
                            _fruitIcon(AppImages.watermelon, 56),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GameText('FRUIT CUT', size: 32),
                                  Text(
                                    'Slice fast. Dodge the bombs.',
                                    style: TextStyle(
                                      color: Color(0xB30B0B10),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'DIFFICULTY',
                              style: gameFont(13, GameColors.soft),
                            ),
                            const SizedBox(height: 6),
                            _ModePicker(game: game),
                            const SizedBox(height: 14),
                            GameTray(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: [
                                  _rule(
                                    _fruitIcon(AppImages.apple, 34),
                                    'Slice fruit',
                                    '+1 point each',
                                  ),
                                  _rule(
                                    const Text(
                                      '💔',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    'Miss 3 fruit',
                                    'and you’re out',
                                  ),
                                  _rule(
                                    _fruitIcon(AppImages.bomb, 34),
                                    'Hit a bomb',
                                    'game over instantly',
                                  ),
                                  _rule(
                                    const Text(
                                      '🏁',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                    'Clear 3 levels',
                                    'to win the run',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            GameButton(
                              label: 'Play',
                              icon: Icons.play_arrow_rounded,
                              tone: GameButtonTone.green,
                              height: 58,
                              onPressed: game.startGame,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rule(Widget icon, String title, String detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(width: 40, child: Center(child: icon)),
        const SizedBox(width: 10),
        Text(title, style: gameFont(15, Colors.white)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            detail,
            style: gameFont(13, GameColors.soft),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _fruitIcon(String image, double size) => Image.asset(
  _asset(image),
  width: size,
  height: size,
  errorBuilder: (_, _, _) => SizedBox(width: size, height: size),
);

class _ModePicker extends StatelessWidget {
  const _ModePicker({required this.game});

  final MainRouterGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.modeListenable,
      builder: (context, mode, _) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: GameColors.socket,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GameColors.trayEdge, width: 2),
        ),
        child: Row(
          children: [
            for (var i = 0; i < MainRouterGame.modeNames.length; i++)
              Expanded(
                child: GestureDetector(
                  onTap: () => game.saveMode(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      border: i == mode
                          ? Border.all(color: GameColors.outline, width: 2)
                          : null,
                      gradient: i == mode
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                [
                                  GameColors.green,
                                  GameColors.yellow,
                                  GameColors.red,
                                ][i].$1,
                                [
                                  GameColors.green,
                                  GameColors.yellow,
                                  GameColors.red,
                                ][i].$2,
                              ],
                            )
                          : null,
                    ),
                    child: i == mode
                        ? GameText(MainRouterGame.modeNames[i], size: 16)
                        : Text(
                            MainRouterGame.modeNames[i],
                            style: gameFont(16, GameColors.soft),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// In-game HUD: pause, lives, level, score and the level banner.
class FruitHudOverlay extends StatelessWidget {
  const FruitHudOverlay({super.key, required this.game});

  final MainRouterGame game;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GameIconButton(
                  icon: Icons.pause_rounded,
                  tooltip: 'Pause',
                  onPressed: game.pauseGame,
                ),
                const SizedBox(width: 10),
                ValueListenableBuilder<int>(
                  valueListenable: game.livesListenable,
                  builder: (context, lives, _) => Container(
                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 6),
                    decoration: BoxDecoration(
                      color: GameColors.outline.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GameColors.outline, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < MainRouterGame.maxLives; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: i < lives ? 1 : 0.25,
                              child: Text(
                                i < lives ? '❤️' : '🖤',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: game.scoreListenable,
                      builder: (context, score, _) =>
                          GameText('$score', size: 38),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: game.levelListenable,
                      builder: (context, level, _) => GameBadge(
                        label:
                            'LV $level/3 · ${MainRouterGame.modeNames[game.getMode()].toUpperCase()}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IgnorePointer(
            child: Center(
              child: ValueListenableBuilder<String?>(
                valueListenable: game.bannerListenable,
                builder: (context, banner, _) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: banner == null
                      ? const SizedBox.shrink()
                      : GameText(banner, key: ValueKey(banner), size: 46),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pause sheet: resume, restart or quit to the menu.
class FruitPauseOverlay extends StatelessWidget {
  const FruitPauseOverlay({super.key, required this.game});

  final MainRouterGame game;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: GamePanel(
              headerColors: GameColors.purple,
              header: const Center(child: GameText('PAUSED', size: 28)),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: game.scoreListenable,
                    builder: (context, score, _) => Text(
                      'Score $score · Level ${game.levelListenable.value}',
                      textAlign: TextAlign.center,
                      style: gameFont(16, GameColors.soft),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GameButton(
                    label: 'Resume',
                    icon: Icons.play_arrow_rounded,
                    tone: GameButtonTone.green,
                    onPressed: game.resumeGame,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GameButton(
                          label: 'Restart',
                          tone: GameButtonTone.yellow,
                          height: 46,
                          onPressed: game.startGame,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GameButton(
                          label: 'Quit',
                          tone: GameButtonTone.red,
                          height: 46,
                          onPressed: game.backToMenu,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// End-of-run panel: win/lose, score, new best and the next step.
class FruitResultOverlay extends StatelessWidget {
  const FruitResultOverlay({
    super.key,
    required this.game,
    required this.onLeaderboard,
  });

  final MainRouterGame game;
  final VoidCallback onLeaderboard;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<FruitResult?>(
      valueListenable: game.resultListenable,
      builder: (context, result, _) {
        if (result == null) return const SizedBox.shrink();
        return ColoredBox(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: GamePanel(
                  headerColors: result.win ? GameColors.yellow : GameColors.red,
                  headerHeight: 72,
                  header: Center(
                    child: GameText(
                      result.win ? 'VICTORY!' : 'GAME OVER',
                      size: 32,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GameTray(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          children: [
                            Text('SCORE', style: gameFont(13, GameColors.soft)),
                            GameText(
                              '${result.score}',
                              size: 56,
                              color: GameColors.yellow.$1,
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: result.saving
                                  ? Text(
                                      'Saving score…',
                                      key: const ValueKey('saving'),
                                      style: gameFont(13, GameColors.soft),
                                    )
                                  : result.isNewBest
                                  ? const GameBadge(
                                      key: ValueKey('best'),
                                      label: '⭐ NEW BEST!',
                                    )
                                  : Text(
                                      result.synced
                                          ? 'Saved to leaderboard'
                                          : 'Couldn’t sync. Check your connection.',
                                      key: ValueKey('saved-${result.synced}'),
                                      style: gameFont(
                                        13,
                                        result.synced
                                            ? GameColors.soft
                                            : const Color(0xFFFF8A80),
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${MainRouterGame.modeNames[result.mode]} · reached level ${result.level}',
                              style: gameFont(13, GameColors.soft),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GameButton(
                        label: 'Play Again',
                        icon: Icons.refresh_rounded,
                        tone: GameButtonTone.green,
                        onPressed: game.startGame,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: GameButton(
                              label: 'Menu',
                              tone: GameButtonTone.purple,
                              height: 46,
                              onPressed: game.backToMenu,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GameButton(
                              label: 'Ranks',
                              icon: Icons.emoji_events_rounded,
                              tone: GameButtonTone.yellow,
                              height: 46,
                              onPressed: onLeaderboard,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
