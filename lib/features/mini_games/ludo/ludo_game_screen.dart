import 'dart:async';
import 'ludo_score_service.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/utils/widgets/home_section_title.dart';
import 'package:hash/utils/widgets/hash_wordmark.dart';
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
    backgroundColor: HomeTokens.ink,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Row(
                children: [
                  HomeIconAction(
                    icon: Icons.arrow_back_ios_new_rounded,
                    label: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                    size: 42,
                  ),
                  const Spacer(),
                  const HashWordmark(
                    fontSize: 20,
                    letterSpacing: 5,
                    accentColor: HomeTokens.green,
                  ),
                  const Spacer(),
                  const SizedBox(width: 42),
                ],
              ),
              const SizedBox(height: 24),
              HomeCard(
                accent: HomeTokens.green,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/mini_game_icons/ludo_icon.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const HomeEyebrow('HASH MINI GAMES'),
                          const SizedBox(height: 8),
                          Text('Ludo', style: HomeTokens.title(28)),
                          const SizedBox(height: 6),
                          Text(
                            'Roll the dice. Race to home.',
                            style: HomeTokens.body(
                              HomeTokens.textSecondary,
                              size: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              const HomeSectionTitle(title: 'Choose your ', accent: 'Mode'),
              const SizedBox(height: 8),
              Text(
                'Online & AI: 1st 400 · 2nd 300 · 3rd 200 · 4th 100 pts. Best result counts.',
                style: HomeTokens.body(HomeTokens.textSecondary),
              ),
              const SizedBox(height: 18),
              _modeCard(
                title: 'Online multiplayer',
                subtitle: 'Create a room and invite your friends.',
                tag: '2–4 PLAYERS · ONLINE',
                icon: Icons.public_rounded,
                busy: _openingOnline,
                onTap: _openingOnline ? null : () => _openOnline(),
              ),
              const SizedBox(height: 12),
              _modeCard(
                title: 'Single player',
                subtitle: 'Play as Green against 3 AI opponents.',
                tag: 'VS AI · OFFLINE',
                icon: Icons.smart_toy_outlined,
                onTap: () => _openLocal(againstAi: true),
              ),
              const SizedBox(height: 12),
              _modeCard(
                title: 'Offline with friends',
                subtitle: '4 real players on one phone. Unranked.',
                tag: 'LOCAL MULTIPLAYER',
                icon: Icons.groups_outlined,
                onTap: () => _openLocal(againstAi: false),
              ),
              const SizedBox(height: 12),
              _modeCard(
                title: 'Watch live',
                subtitle: 'Spectate matches happening right now.',
                tag: 'SPECTATE · LIVE',
                icon: Icons.visibility_rounded,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LudoLiveMatchesScreen(),
                  ),
                ),
              ),
              if (_activeMatchId != null) ...[
                const SizedBox(height: 22),
                IgnorePointer(
                  ignoring: _openingOnline,
                  child: Opacity(
                    opacity: _openingOnline ? 0.5 : 1,
                    child: HomeCta(
                      label: 'Resume online match',
                      icon: Icons.play_arrow_rounded,
                      onTap: () => _openOnline(matchId: _activeMatchId),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wifi_off_rounded,
                    size: 14,
                    color: HomeTokens.textTertiary,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'AI and local games work offline',
                      style: HomeTokens.body(HomeTokens.textTertiary, size: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _modeCard({
    required String title,
    required String subtitle,
    required String tag,
    required IconData icon,
    required VoidCallback? onTap,
    bool busy = false,
  }) => HomeCard(
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: HomeTokens.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: HomeTokens.green.withValues(alpha: 0.2)),
          ),
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    color: HomeTokens.green,
                    strokeWidth: 2,
                  ),
                )
              : Icon(icon, color: HomeTokens.green, size: 23),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tag,
                style: HomeTokens.eyebrow(
                  HomeTokens.green,
                ).copyWith(fontSize: 9, letterSpacing: 0.8),
              ),
              const SizedBox(height: 6),
              Text(title, style: HomeTokens.title(16)),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: HomeTokens.body(HomeTokens.textSecondary, size: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.chevron_right_rounded,
          color: HomeTokens.green,
          size: 22,
        ),
      ],
    ),
  );
}
