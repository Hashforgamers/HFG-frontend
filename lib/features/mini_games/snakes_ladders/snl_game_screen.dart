import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import 'snl_match_screen.dart';
import 'snl_match_service.dart';

/// Snakes & Ladders entry: create an online room or resume one.
class SnlGameScreen extends StatefulWidget {
  const SnlGameScreen({super.key});

  @override
  State<SnlGameScreen> createState() => _SnlGameScreenState();
}

class _SnlGameScreenState extends State<SnlGameScreen> {
  final SnlMatchService _service = SnlMatchService();
  bool _opening = false;
  String? _activeMatchId;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    try {
      final id = await _service.activeMatchId();
      if (mounted) setState(() => _activeMatchId = id);
    } catch (_) {}
  }

  Future<void> _open({String? matchId}) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final id = matchId ?? await _service.createMatch();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SnlMatchScreen(matchId: id)),
      );
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t open the room. Check your connection and sign-in.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameColors.bgBottom,
      body: Stack(
        children: [
          const GameBackground(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                  children: [
                    Row(
                      children: [
                        GameIconButton(
                          icon: Icons.arrow_back_rounded,
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        const GameText('HASH ARCADE', size: 20),
                        const Spacer(),
                        const SizedBox(width: 44),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GamePanel(
                      headerColors: GameColors.green,
                      headerHeight: 96,
                      header: Row(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: GameColors.outline,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.asset(
                                'assets/mini_game_icons/snakes_ladders.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const GameText('SNAKES &', size: 26),
                                const GameText('LADDERS', size: 26),
                                Text(
                                  'Race to 100 with friends',
                                  style: gameFont(
                                    13,
                                    GameColors.outline.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      child: GameTray(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            _rule('👥', '2–4 players', 'online with friends'),
                            _rule('🎲', 'Roll to move', 'a six rolls again'),
                            _rule('🪜', 'Ladders', 'climb up'),
                            _rule('🐍', 'Snakes', 'slide down'),
                            _rule('🏆', 'Exactly 100', 'first there wins'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GameButton(
                      label: _opening ? 'Opening…' : 'Create Room',
                      subtitle: 'invite friends from chat',
                      icon: _opening ? null : Icons.add_rounded,
                      tone: GameButtonTone.green,
                      height: 62,
                      onPressed: _opening ? null : () => _open(),
                    ),
                    if (_activeMatchId != null) ...[
                      const SizedBox(height: 10),
                      GameButton(
                        label: 'Resume Room',
                        icon: Icons.play_arrow_rounded,
                        tone: GameButtonTone.red,
                        height: 54,
                        onPressed: _opening
                            ? null
                            : () => _open(matchId: _activeMatchId),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'Placement points: 1st 400 · 2nd 300 · 3rd 200 · 4th 100',
                      textAlign: TextAlign.center,
                      style: gameFont(12.5, GameColors.soft),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rule(String emoji, String title, String detail) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 36,
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: gameFont(15, Colors.white)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            detail,
            overflow: TextOverflow.ellipsis,
            style: gameFont(13, GameColors.soft),
          ),
        ),
      ],
    ),
  );
}
