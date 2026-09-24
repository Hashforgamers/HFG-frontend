import 'package:flutter/material.dart';
import 'package:hash/features/mini_games/ludo/widgets/board_widget.dart';
import 'package:hash/features/mini_games/ludo/widgets/dice_widget.dart';
import 'package:provider/provider.dart';

import 'constants.dart';
import 'ludo_provider.dart';
import 'online/ludo_match_screen.dart';
import 'online/ludo_match_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _accent = Color(0xFF00DC00);
  final LudoMatchService _matchService = LudoMatchService();
  bool _creatingOnline = false;
  String? _activeMatchId;

  @override
  void initState() {
    super.initState();
    _reloadActiveMatch();
  }

  Future<void> _reloadActiveMatch() async {
    final id = await _matchService.activeMatchId();
    if (mounted) setState(() => _activeMatchId = id);
  }

  Future<void> _openOnline(String matchId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LudoMatchScreen(matchId: matchId)),
    );
    // Coming back (accidental or not): refresh whether a room is still active.
    await _reloadActiveMatch();
  }

  Future<void> _playWithFriends() async {
    if (_creatingOnline) return;
    setState(() => _creatingOnline = true);
    try {
      final match = await _matchService.createMatch();
      if (!mounted) return;
      await _openOnline(match.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn’t start online match: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _creatingOnline = false);
    }
  }

  Widget _resumeBanner() {
    final id = _activeMatchId;
    if (id == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openOnline(id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_fill_rounded,
                    color: _accent, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'You have a match in progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Text(
                  'Resume',
                  style: TextStyle(
                    color: _accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _accent),
              ],
            ),
          ),
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D12),
      body: Stack(
        children: [
          // On-brand backdrop: deep gradient + soft green bloom top.
          const _Backdrop(),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                _resumeBanner(),
                _turnBanner(context),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: BoardWidget(),
                    ),
                  ),
                ),
                const _DiceTray(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          _gameOverOverlay(context),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Back',
          ),
          const SizedBox(width: 2),
          const Text(
            'Ludo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: _creatingOnline ? null : _playWithFriends,
            style: TextButton.styleFrom(
              foregroundColor: _accent,
              backgroundColor: _accent.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: _creatingOnline
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _accent,
                    ),
                  )
                : const Icon(Icons.group_rounded, size: 18),
            label: const Text(
              'Play online',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: () => context.read<LudoProvider>().resetGame(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'New game',
          ),
        ],
      ),
    );
  }

  Widget _turnBanner(BuildContext context) {
    return Consumer<LudoProvider>(
      builder: (context, value, _) {
        if (value.winners.length >= 3 || value.players.isEmpty) {
          return const SizedBox(height: 8);
        }
        final color = value.currentPlayer.color;
        final name = _playerName(value.currentPlayer.type);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                '$name’s turn',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                '  ·  ${_stageText(value.gameState)}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _gameOverOverlay(BuildContext context) {
    return Consumer<LudoProvider>(
      builder: (context, value, _) {
        if (value.winners.length < 3) return const SizedBox.shrink();
        final ranking = value.winners;
        const medals = ['🥇', '🥈', '🥉'];
        return Container(
          color: Colors.black.withValues(alpha: 0.82),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🏆', style: TextStyle(fontSize: 56)),
                const SizedBox(height: 8),
                const Text(
                  'Game over',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                for (int i = 0; i < ranking.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          medals[i],
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: value.player(ranking[i]).color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _playerName(ranking[i]),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => value.resetGame(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: const Color(0xFF06130B),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text(
                      'Play again',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Exit to games'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Deep on-brand background with a soft green bloom.
class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0E1A12), Color(0xFF0B0D12)],
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: FractionallySizedBox(
            widthFactor: 1.4,
            heightFactor: 0.4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF00DC00).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dice on a subtle pedestal so it reads as an interactive control.
class _DiceTray extends StatelessWidget {
  const _DiceTray();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
      ),
      child: const SizedBox(width: 58, height: 58, child: DiceWidget()),
    );
  }
}
