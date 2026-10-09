import 'dart:async';
import 'ludo_score_service.dart';
import 'package:hash/utils/widgets/game_button.dart';
import 'package:hash/utils/widgets/game_panel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'ludo_analytics.dart';
import 'ludo_provider.dart';
import 'main_screen.dart';
import 'online/ludo_live_matches_screen.dart';
import 'online/ludo_match_screen.dart';
import 'online/ludo_match_service.dart';
import 'online/ludo_presence_widgets.dart';

/// The entry point always offers a mode before creating a local board.
class LudoGameScreen extends StatefulWidget {
  const LudoGameScreen({super.key, this.source = 'arcade'});

  /// Where the player came from, for `ludo_opened` (home / arcade / push /
  /// deeplink / banner).
  final String source;

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
    LudoAnalytics.opened(widget.source);
    _refreshMatch();
    WidgetsBinding.instance.addObserver(this);
    unawaited(LudoScoreService.instance.sync());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(LudoScoreService.instance.sync());
      unawaited(_refreshMatch());
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

  void _openLocal({required bool againstAi, bool powerMode = false}) {
    LudoAnalytics.modeSelected(
      !againstAi ? 'pass_and_play' : (powerMode ? 'power' : 'vs_ai'),
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider(
          create: (_) =>
              LudoProvider(againstAi: againstAi, powerMode: powerMode)
                ..startGame(),
          child: const MainScreen(),
        ),
      ),
    );
  }

  /// Opens an online room: [matchId] to resume/join a known room, [quick] to
  /// Quick Match into someone's waiting room, otherwise a new friends room.
  Future<void> _openOnline({String? matchId, bool quick = false}) async {
    if (_openingOnline) return;
    setState(() => _openingOnline = true);
    final String stage;
    if (matchId != null) {
      stage = 'open_room';
    } else {
      LudoAnalytics.modeSelected(quick ? 'quick' : 'friends');
      stage = quick ? 'quick_match' : 'create_room';
    }
    try {
      final service = LudoMatchService();
      final String id;
      if (matchId != null) {
        id = matchId;
      } else if (quick) {
        final result = await service.quickMatch();
        id = result.id;
        if (result.created) LudoAnalytics.roomCreated('quick');
      } else {
        id = (await service.createMatch()).id;
        LudoAnalytics.roomCreated('friends');
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => LudoMatchScreen(matchId: id)),
      );
      await _refreshMatch();
    } catch (e) {
      LudoAnalytics.syncFailed(stage: stage, error: e);
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

  Future<void> _joinWithCode() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _RoomCodeSheet(),
    );
    if (code == null || !mounted) return;
    setState(() => _openingOnline = true);
    String? id;
    try {
      id = await LudoMatchService().findByCode(code);
    } catch (e) {
      LudoAnalytics.syncFailed(stage: 'find_code', error: e);
      id = null;
    }
    LudoAnalytics.roomCodeEntered(found: id != null);
    if (!mounted) return;
    setState(() => _openingOnline = false);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No open room with that code. Check it with your friend and try again.',
          ),
        ),
      );
      return;
    }
    await _openOnline(matchId: id);
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
                    title: 'Quick Match',
                    subtitle: 'Play someone online. Starts in 15s or less.',
                    tag: 'Online · ranked',
                    icon: Icons.bolt_rounded,
                    colors: GameColors.green,
                    tone: GameButtonTone.green,
                    action: _openingOnline ? 'Opening' : 'Play',
                    onTap: _openingOnline
                        ? null
                        : () => _openOnline(quick: true),
                    footer: const LudoLiveCount(
                      emptyText: 'Be the first in — others see you waiting',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _modeCard(
                    title: 'Play with Friends',
                    subtitle: 'Private room. Share the code on WhatsApp.',
                    tag: '2–4 players',
                    icon: Icons.public_rounded,
                    colors: GameColors.green,
                    tone: GameButtonTone.green,
                    action: _openingOnline ? 'Opening' : 'Create',
                    onTap: _openingOnline ? null : () => _openOnline(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: _openingOnline ? null : _joinWithCode,
                      icon: const Icon(
                        Icons.vpn_key_rounded,
                        size: 18,
                        color: GameColors.soft,
                      ),
                      label: Text(
                        'Have a room code? Join',
                        style: gameFont(14, GameColors.soft),
                      ),
                    ),
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
                    title: 'Power Ludo',
                    subtitle:
                        'Vs AI. Start with Reroll, Lucky Six, Boost & Shield.',
                    tag: 'New · power-ups · unranked',
                    icon: Icons.bolt_rounded,
                    colors: GameColors.yellow,
                    tone: GameButtonTone.yellow,
                    action: 'Play',
                    onTap: () => _openLocal(againstAi: true, powerMode: true),
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
                    onTap: () {
                      LudoAnalytics.modeSelected('spectate');
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LudoLiveMatchesScreen(),
                        ),
                      );
                    },
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
                          : () {
                              LudoAnalytics.resume('resume_button');
                              _openOnline(matchId: _activeMatchId);
                            },
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
    Widget? footer,
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
              if (footer != null) ...[const SizedBox(height: 3), footer],
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

/// Bottom sheet that asks for a friend's room code.
class _RoomCodeSheet extends StatefulWidget {
  const _RoomCodeSheet();

  @override
  State<_RoomCodeSheet> createState() => _RoomCodeSheetState();
}

class _RoomCodeSheetState extends State<_RoomCodeSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _valid =>
      LudoMatchService.normalizeRoomCode(_controller.text).length == 6;

  void _submit() {
    if (!_valid) return;
    Navigator.of(
      context,
    ).pop(LudoMatchService.normalizeRoomCode(_controller.text));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      16,
      0,
      16,
      16 + MediaQuery.of(context).viewInsets.bottom,
    ),
    child: SafeArea(
      top: false,
      child: GamePanel(
        headerColors: GameColors.green,
        header: const GameText('JOIN A ROOM', size: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter the 6-character code your friend shared.',
              textAlign: TextAlign.center,
              style: gameFont(14, GameColors.soft),
            ),
            const SizedBox(height: 12),
            GameTray(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLength: 7,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: gameFont(26, Colors.white),
                cursorColor: GameColors.yellow.$1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  counterText: '',
                  hintText: 'ABC123',
                  hintStyle: gameFont(
                    26,
                    GameColors.soft.withValues(alpha: 0.35),
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 12),
            GameButton(
              label: 'Join',
              icon: Icons.login_rounded,
              tone: GameButtonTone.green,
              height: 50,
              onPressed: _valid ? _submit : null,
            ),
          ],
        ),
      ),
    ),
  );
}
