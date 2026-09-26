import 'dart:async';
import 'ludo_score_service.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ludo_provider.dart';
import 'main_screen.dart';
import 'online/ludo_live_matches_screen.dart';
import 'online/ludo_match_screen.dart';
import 'online/ludo_match_service.dart';

/// The entry point always offers a mode before creating a local board.
class LudoGameScreen extends StatefulWidget {
  const LudoGameScreen({super.key});

  @override
  State<LudoGameScreen> createState() => _LudoGameScreenState();
}

class _LudoGameScreenState extends State<LudoGameScreen>
    with WidgetsBindingObserver {
  bool _openingOnline = false;
  String? _activeMatchId;

  @override
  void initState() {
    super.initState();
    _refreshMatch();
    WidgetsBinding.instance.addObserver(this);
    unawaited(LudoScoreService.instance.sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(LudoScoreService.instance.sync());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _refreshMatch() async {
    try {
      final id = await LudoMatchService().activeMatchId();
      if (mounted) setState(() => _activeMatchId = id);
    } catch (_) {
      // Local modes remain available when the online service is unavailable.
    }
  }

  void _openLocal({required bool againstAi}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => LudoProvider(againstAi: againstAi)..startGame(),
          child: const MainScreen(),
        ),
      ),
    );
  }

  Future<void> _openOnline({String? matchId}) async {
    if (_openingOnline) return;
    setState(() => _openingOnline = true);
    try {
      final id = matchId ?? (await LudoMatchService().createMatch()).id;
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => LudoMatchScreen(matchId: id)),
      );
      await _refreshMatch();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Couldn’t open the online room. Check your connection and sign-in, then try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _openingOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  _hero(),
                  const SizedBox(height: 22),
                  const GameText('CHOOSE YOUR MODE', size: 20),
                  const SizedBox(height: 12),
                  _modeCard(
                    title: 'Online',
                    subtitle: 'Create a room and invite friends.',
                    tag: '2–4 players',
                    icon: Icons.public_rounded,
                    colors: GameColors.green,
                    tone: GameButtonTone.green,
                    action: _openingOnline ? 'Opening' : 'Play',
                    onTap: _openingOnline ? null : () => _openOnline(),
                  ),
                  const SizedBox(height: 12),
                  _modeCard(
                    title: 'Vs AI',
                    subtitle: 'Play as Green against 3 bots.',
                    tag: 'Solo · offline',
                    icon: Icons.smart_toy_rounded,
                    colors: GameColors.purple,
                    tone: GameButtonTone.purple,
                    action: 'Play',
                    onTap: () => _openLocal(againstAi: true),
                  ),
                  const SizedBox(height: 12),
                  _modeCard(
                    title: 'Pass & Play',
                    subtitle: '4 players on one phone. Unranked.',
                    tag: 'Local',
                    icon: Icons.groups_rounded,
                    colors: GameColors.yellow,
                    tone: GameButtonTone.yellow,
                    action: 'Play',
                    onTap: () => _openLocal(againstAi: false),
                  ),
                  const SizedBox(height: 12),
                  _modeCard(
                    title: 'Watch Live',
                    subtitle: 'Spectate matches happening now.',
                    tag: 'Spectate',
                    icon: Icons.visibility_rounded,
                    colors: GameColors.red,
                    tone: GameButtonTone.red,
                    action: 'Watch',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LudoLiveMatchesScreen(),
                      ),
                    ),
                  ),
                  if (_activeMatchId != null) ...[
                    const SizedBox(height: 20),
                    GameButton(
                      label: 'Resume Match',
                      subtitle: 'Your online game is still on',
                      icon: Icons.play_arrow_rounded,
                      tone: GameButtonTone.red,
                      height: 60,
                      onPressed: _openingOnline
                          ? null
                          : () => _openOnline(matchId: _activeMatchId),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off_rounded,
                        size: 14,
                        color: GameColors.soft,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Vs AI and Pass & Play work offline',
                          style: gameFont(12, GameColors.soft),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _hero() => GamePanel(
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
              'assets/mini_game_icons/ludo_icon.png',
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
              const GameText('LUDO', size: 34),
              Text(
                'Roll the dice. Race to home.',
                style: gameFont(14, GameColors.outline.withValues(alpha: 0.75)),
              ),
            ],
          ),
        ),
      ],
    ),
    child: GameTray(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final (place, pts) in const [
            ('1st', 400),
            ('2nd', 300),
            ('3rd', 200),
            ('4th', 100),
          ])
            Column(
              children: [
                GameText('$pts', size: 18, color: GameColors.yellow.$1),
                Text(place, style: gameFont(12, GameColors.soft)),
              ],
            ),
        ],
      ),
    ),
  );

  Widget _modeCard({
    required String title,
    required String subtitle,
    required String tag,
    required IconData icon,
    required (Color, Color) colors,
    required GameButtonTone tone,
    required String action,
    required VoidCallback? onTap,
  }) => GamePanel(
    onTap: onTap,
    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
    child: Row(
      children: [
        Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: GameColors.outline,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors.$1, colors.$2],
              ),
            ),
            child: Center(child: GameIcon(icon: icon, size: 28)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameText(title, size: 20),
              const SizedBox(height: 2),
              Text(subtitle, style: gameFont(13, GameColors.soft)),
              const SizedBox(height: 2),
              Text(tag.toUpperCase(), style: gameFont(11, colors.$1)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 92,
          child: GameButton(
            label: action,
            tone: tone,
            height: 44,
            onPressed: onTap,
          ),
        ),
      ],
    ),
  );
}
