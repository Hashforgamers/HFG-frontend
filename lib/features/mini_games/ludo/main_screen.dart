import 'dart:async';
import 'ludo_score_service.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/utils/widgets/home_section_title.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:hash/features/mini_games/ludo/widgets/board_widget.dart';
import 'package:hash/features/mini_games/ludo/widgets/dice_widget.dart';
import 'package:hash/features/mini_games/ludo/widgets/ludo_reactions.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'ludo_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  LudoProvider? _game;
  bool _resultRecorded = false;

  final ValueNotifier<LudoReactionEvent?> _reactionNotifier =
      ValueNotifier<LudoReactionEvent?>(null);
  int _reactionSeq = 0;

  void _onReactionTap(LudoReactionOption option) {
    _reactionSeq++;
    _reactionNotifier.value = LudoReactionEvent(
      option: option,
      id: _reactionSeq,
      label: 'You',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final game = context.read<LudoProvider>();
    if (_game == game) return;
    _game?.removeListener(_recordResult);
    _game = game;
    game.addListener(_recordResult);
  }

  void _recordResult() {
    final game = _game!;
    if (game.winners.isEmpty) _resultRecorded = false;
    if (!game.againstAi || _resultRecorded) return;
    final score = ludoPlacementScore(
      seat: LudoPlayerType.green,
      winners: game.winners,
      participants: LudoPlayerType.values.toSet(),
      finished: game.gameState == LudoGameState.finish,
    );
    if (score == null) return;
    _resultRecorded = true;
    unawaited(LudoScoreService.instance.record(score));
  }

  @override
  void dispose() {
    _game?.removeListener(_recordResult);
    _reactionNotifier.dispose();
    super.dispose();
  }

  String _playerName(LudoPlayerType type) {
    final n = type.name;
    return n[0].toUpperCase() + n.substring(1);
  }

  String _stageText(LudoGameState stage) {
    switch (stage) {
      case LudoGameState.throwDice:
        return 'Roll the dice';
      case LudoGameState.pickPawn:
        return 'Pick a pawn';
      case LudoGameState.moving:
        return 'Moving…';
      case LudoGameState.finish:
        return 'Game over';
    }
  }

  Future<void> _newGame() async {
    final restart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start a new game?'),
        content: Text('Your current local game will be reset.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Keep playing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('New game'),
          ),
        ],
      ),
    );
    if (restart == true && mounted) context.read<LudoProvider>().resetGame();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<LudoProvider>();
    return Scaffold(
      backgroundColor: HomeTokens.ink,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 560),
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(18, 12, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            HomeIconAction(
                              icon: Icons.arrow_back_ios_new_rounded,
                              label: 'Game modes',
                              onTap: () => Navigator.of(context).maybePop(),
                              size: 42,
                            ),
                            Spacer(),
                            HashWordmark(
                              fontSize: 20,
                              letterSpacing: 5,
                              accentColor: HomeTokens.green,
                            ),
                            Spacer(),
                            HomeIconAction(
                              icon: Icons.restart_alt_rounded,
                              label: 'New game',
                              onTap: _newGame,
                              size: 42,
                            ),
                          ],
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: HomeSectionTitle(
                                title: 'Ludo ',
                                accent: 'Arena',
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: HomeTokens.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: HomeTokens.green.withValues(
                                    alpha: 0.25,
                                  ),
                                ),
                              ),
                              child: Text(
                                game.againstAi
                                    ? 'SOLO · VS AI'
                                    : 'LOCAL · 4 PLAYERS',
                                style: HomeTokens.eyebrow(
                                  HomeTokens.green,
                                ).copyWith(fontSize: 9, letterSpacing: 0.5),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          game.againstAi
                              ? 'You play Green. Best placement counts.'
                              : 'Pass & play · Unranked local game',
                          style: HomeTokens.body(
                            HomeTokens.textSecondary,
                            size: 12,
                          ),
                        ),
                        SizedBox(height: 20),
                        _playerRow(LudoPlayerType.green, LudoPlayerType.yellow),
                        SizedBox(height: 12),
                        HomeCard(
                          padding: EdgeInsets.all(8),
                          child: BoardWidget(
                            size: constraints.maxWidth - 52,
                            showTurnIndicator: false,
                          ),
                        ),
                        SizedBox(height: 12),
                        _playerRow(LudoPlayerType.red, LudoPlayerType.blue),
                        SizedBox(height: 18),
                        _turnControl(),
                        SizedBox(height: 14),
                        LudoReactionBar(
                          onSelected: _onReactionTap,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          LudoReactionLayer(listenable: _reactionNotifier),
          _gameOverOverlay(context),
        ],
      ),
    );
  }

  Widget _playerRow(LudoPlayerType left, LudoPlayerType right) => Row(
    children: [
      Expanded(child: _playerCard(left)),
      SizedBox(width: 12),
      Expanded(child: _playerCard(right)),
    ],
  );

  Widget _playerCard(LudoPlayerType type) => Consumer<LudoProvider>(
    builder: (context, game, _) {
      final player = game.player(type);
      final active =
          game.currentPlayer.type == type &&
          game.gameState != LudoGameState.finish;
      final finished = player.pawns
          .where((pawn) => pawn.step == player.path.length - 1)
          .length;
      return AnimatedContainer(
        duration: Duration(milliseconds: 220),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: active
              ? player.color.withValues(alpha: 0.12)
              : HomeTokens.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? player.color.withValues(alpha: 0.7)
                : HomeTokens.hairline,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: player.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                active ? Icons.person_rounded : Icons.person_outline_rounded,
                color: player.color,
                size: 21,
              ),
            ),
            SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    game.againstAi
                        ? (type == LudoPlayerType.green
                              ? 'You · Green'
                              : '${_playerName(type)} · AI')
                        : _playerName(type),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    active
                        ? (game.isAiTurn ? 'THINKING…' : 'YOUR TURN')
                        : '$finished / 4 finished',
                    style: GoogleFonts.inter(
                      color: active ? player.color : HomeTokens.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _turnControl() => Consumer<LudoProvider>(
    builder: (context, game, _) {
      final canRoll =
          game.gameState == LudoGameState.throwDice &&
          !game.diceStarted &&
          game.isMyTurn;
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HomeTokens.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: HomeTokens.hairline),
        ),
        child: Row(
          children: [
            SizedBox(width: 56, height: 56, child: DiceWidget()),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_playerName(game.currentPlayer.type)}’s move',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    game.isAiTurn
                        ? 'AI is playing…'
                        : game.diceStarted
                        ? 'Rolling…'
                        : canRoll
                        ? 'Roll a six to leave home'
                        : _stageText(game.gameState),
                    style: GoogleFonts.inter(
                      color: HomeTokens.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8),
            SizedBox(
              width: 84,
              child: IgnorePointer(
                ignoring: !canRoll,
                child: Opacity(
                  opacity: canRoll ? 1 : 0.4,
                  child: HomeCta(
                    label: 'Roll',
                    onTap: game.throwDice,
                    height: 46,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _gameOverOverlay(BuildContext context) {
    return Consumer<LudoProvider>(
      builder: (context, value, _) {
        if (value.winners.length < 3) return SizedBox.shrink();
        final ranking = value.winners;
        const medals = ['🥇', '🥈', '🥉'];
        return Container(
          color: Colors.black.withValues(alpha: 0.82),
          alignment: Alignment.center,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🏆', style: GoogleFonts.inter(fontSize: 56)),
                SizedBox(height: 8),
                Text(
                  'Game over',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 20),
                for (int i = 0; i < ranking.length; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(medals[i], style: GoogleFonts.inter(fontSize: 22)),
                        SizedBox(width: 10),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: value.player(ranking[i]).color,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          _playerName(ranking[i]),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: HomeCta(
                    onTap: () => value.resetGame(),
                    icon: Icons.refresh_rounded,
                    label: 'Play again',
                  ),
                ),
                SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: Text('Exit to games'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
