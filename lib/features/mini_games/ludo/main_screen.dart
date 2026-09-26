import 'dart:async';
import 'ludo_score_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import 'package:hash/features/mini_games/ludo/widgets/ludo_seat_token.dart';
import 'package:flutter/material.dart';
import 'package:hash/features/mini_games/ludo/widgets/board_widget.dart';
import 'package:hash/features/mini_games/ludo/widgets/dice_widget.dart';
import 'package:hash/features/mini_games/ludo/widgets/ludo_reactions.dart';
import 'package:provider/provider.dart';

import 'audio.dart';
import 'constants.dart';
import 'ludo_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  LudoProvider? _game;
  bool _resultRecorded = false;

  final ValueNotifier<LudoReactionEvent?> _reactionNotifier =
      ValueNotifier<LudoReactionEvent?>(null);
  int _reactionSeq = 0;

  // Per-turn countdown (offline AI/local play), mirroring the online match.
  static const int _turnSeconds = 30;
  Timer? _ticker;
  late final AnimationController _bounce;
  LudoPlayerType? _lastSeat;
  LudoGameState? _lastStage;
  int _turnStartMs = 0;
  int _remaining = _turnSeconds;

  // The signed-in user's Google photo, shown on the "You" (green) card.
  String? _myPhoto;

  @override
  void initState() {
    super.initState();
    _myPhoto = FirebaseAuth.instance.currentUser?.photoURL;
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);
    _turnStartMs = DateTime.now().millisecondsSinceEpoch;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    final game = _game;
    if (!mounted || game == null) return;
    if (game.gameState == LudoGameState.finish || game.winners.length >= 3) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    // Restart the clock for every decision: a new seat, a fresh roll after a
    // six, or a pawn to pick after rolling.
    final seat = game.currentTurnSeat;
    final stage = game.gameState;
    final newDecision =
        stage != _lastStage &&
        (stage == LudoGameState.throwDice || stage == LudoGameState.pickPawn);
    if (seat != _lastSeat || newDecision) {
      _turnStartMs = now;
      Audio.stopTicking();
    }
    _lastSeat = seat;
    _lastStage = stage;
    _remaining = (_turnSeconds - ((now - _turnStartMs) / 1000).floor()).clamp(
      0,
      _turnSeconds,
    );

    final humanTurn =
        !game.isAiTurn &&
        !game.diceStarted &&
        (game.gameState == LudoGameState.throwDice ||
            game.gameState == LudoGameState.pickPawn);

    // Clock-ticking sound through the final 15 seconds of a human's turn.
    if (game.soundEnabled && humanTurn && _remaining <= 15 && _remaining > 0) {
      Audio.startTicking();
    } else {
      Audio.stopTicking();
    }

    // Only a human turn times out; AI turns resolve on their own quickly.
    if (_remaining <= 0 && humanTurn) {
      _turnStartMs = now; // avoid repeated skips
      Audio.stopTicking();
      game.skipLocalTurn();
    }
    setState(() {});
  }

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
    _ticker?.cancel();
    Audio.stopTicking();
    _bounce.dispose();
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
    final restart = await showGameDialog(
      context,
      title: 'NEW GAME?',
      message: 'Your current game will be reset.',
      cancelLabel: 'Keep Playing',
      confirmLabel: 'Restart',
      confirmTone: GameButtonTone.red,
    );
    if (restart == true && mounted) context.read<LudoProvider>().resetGame();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.read<LudoProvider>();
    return Scaffold(
      backgroundColor: GameColors.bgBottom,
      body: Stack(
        children: [
          const GameBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          GameIconButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Game modes',
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 10),
                          const GameText('LUDO', size: 26),
                          const SizedBox(width: 8),
                          GameBadge(
                            label: game.againstAi ? 'VS AI' : 'PASS & PLAY',
                          ),
                          const Spacer(),
                          GameIconButton(
                            icon: Icons.restart_alt_rounded,
                            tooltip: 'New game',
                            colors: GameColors.red,
                            onPressed: _newGame,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _playerRow(LudoPlayerType.green, LudoPlayerType.yellow),
                      const SizedBox(height: 8),
                      // Board flexes to fill remaining space so the whole
                      // screen fits without scrolling.
                      Expanded(
                        child: Center(
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final side = c.maxWidth < c.maxHeight
                                  ? c.maxWidth
                                  : c.maxHeight;
                              return _boardFrame(side - 14);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _playerRow(LudoPlayerType.red, LudoPlayerType.blue),
                      const SizedBox(height: 8),
                      _turnControl(),
                      const SizedBox(height: 8),
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
          LudoReactionLayer(listenable: _reactionNotifier),
          _gameOverOverlay(context),
        ],
      ),
    );
  }

  /// Thick dark frame + lip around the board so it sits like a game piece.
  Widget _boardFrame(double side) => Container(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 9),
    decoration: BoxDecoration(
      color: GameColors.outline,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(color: Color(0x80000000), blurRadius: 18, offset: Offset(0, 10)),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BoardWidget(size: side, showTurnIndicator: false),
    ),
  );

  Widget _playerRow(LudoPlayerType left, LudoPlayerType right) => Row(
    children: [
      Expanded(child: _playerCard(left)),
      const SizedBox(width: 10),
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
      final showTimer = active && !game.isAiTurn;
      final urgent = showTimer && _remaining <= 15;
      final isMe = type == LudoPlayerType.green && game.againstAi;
      final isAi = game.againstAi && !isMe;

      Widget token = LudoSeatToken(
        color: player.color,
        name: isAi ? null : (isMe ? 'You' : _playerName(type)),
        icon: isAi ? Icons.smart_toy_rounded : null,
        photo: isMe ? _myPhoto : null,
        size: 36,
        glow: active,
        progress: showTimer ? _remaining / _turnSeconds : null,
        progressColor: urgent ? const Color(0xFFFF4D4D) : null,
      );
      if (urgent) {
        token = ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.12).animate(
            CurvedAnimation(parent: _bounce, curve: Curves.easeInOut),
          ),
          child: token,
        );
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          color: active ? player.color : GameColors.outline,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [BoxShadow(color: player.color.withValues(alpha: 0.5), blurRadius: 12)]
              : null,
        ),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13.5),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [GameColors.bodyTop, GameColors.bodyBottom],
            ),
          ),
          child: Row(
            children: [
              token,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMe
                          ? 'You'
                          : (isAi
                                ? '${_playerName(type)} Bot'
                                : _playerName(type)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: gameFont(14, Colors.white),
                    ),
                    Text(
                      active
                          ? (game.isAiTurn ? 'Thinking…' : 'Your turn · ${_remaining}s')
                          : '$finished/4 home',
                      style: gameFont(
                        11.5,
                        urgent
                            ? const Color(0xFFFF6B6B)
                            : (active ? player.color : GameColors.soft),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
      return GamePanel(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Row(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: GameColors.socket,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GameColors.trayEdge, width: 2),
              ),
              child: const DiceWidget(),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GameText(
                    '${_playerName(game.currentPlayer.type)}’s move',
                    size: 17,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    game.isAiTurn
                        ? 'AI is playing…'
                        : game.diceStarted
                        ? 'Rolling…'
                        : canRoll
                        ? 'Roll a six to leave home'
                        : _stageText(game.gameState),
                    style: gameFont(12.5, GameColors.soft),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: GameButton(
                label: 'Roll',
                icon: Icons.casino_rounded,
                tone: GameButtonTone.green,
                height: 50,
                onPressed: canRoll ? game.throwDice : null,
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
        if (value.winners.length < 3) return const SizedBox.shrink();
        final ranking = value.winners;
        const places = ['1ST', '2ND', '3RD'];
        const medalColors = [
          Color(0xFFFFD60A),
          Color(0xFFD9DEE8),
          Color(0xFFE39B5B),
        ];
        return Container(
          color: Colors.black.withValues(alpha: 0.75),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: GamePanel(
              headerColors: GameColors.yellow,
              headerHeight: 70,
              header: const Center(child: GameText('GAME OVER', size: 30)),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GameTray(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        for (int i = 0; i < ranking.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 44,
                                  child: GameText(
                                    places[i],
                                    size: 16,
                                    color: medalColors[i],
                                  ),
                                ),
                                LudoSeatToken(
                                  color: value.player(ranking[i]).color,
                                  name: _playerName(ranking[i]),
                                  size: 34,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _playerName(ranking[i]),
                                    style: gameFont(18, Colors.white),
                                  ),
                                ),
                                if (i == 0)
                                  Text('👑', style: TextStyle(fontSize: 28, height: 1)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GameButton(
                    label: 'Play Again',
                    icon: Icons.refresh_rounded,
                    tone: GameButtonTone.green,
                    onPressed: () => value.resetGame(),
                  ),
                  const SizedBox(height: 8),
                  GameButton(
                    label: 'Exit',
                    tone: GameButtonTone.purple,
                    height: 46,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
