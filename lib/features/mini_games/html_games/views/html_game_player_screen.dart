import 'package:hash/core/app_orientation.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/features/mini_games/html_games/models/html_mini_game.dart';
import 'package:hash/features/mini_games/html_games/services/html_game_score_bridge_service.dart';
import 'package:hash/features/mini_games/html_games/widgets/game_web_view.dart';

class HtmlGamePlayerScreen extends StatefulWidget {
  const HtmlGamePlayerScreen({super.key, required this.game});

  final HtmlMiniGame game;

  static Future<void> open(HtmlMiniGame game) async {
    await AppOrientation.landscape();
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
    await Get.to(() => HtmlGamePlayerScreen(game: game));
  }

  @override
  State<HtmlGamePlayerScreen> createState() => _HtmlGamePlayerScreenState();
}

class _HtmlGamePlayerScreenState extends State<HtmlGamePlayerScreen> {
  // one bridge per screen, so its per-innings dedupe survives rebuilds
  final _scoreBridge = HtmlGameScoreBridgeService();

  @override
  void initState() {
    super.initState();
    unawaited(_enterGameMode());
  }

  Future<void> _enterGameMode() async {
    await AppOrientation.landscape();
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  Future<void> _exitGameMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await AppOrientation.portrait();
  }

  @override
  void dispose() {
    unawaited(_exitGameMode());
    super.dispose();
  }

  bool _leaving = false;

  /// Back (button or system gesture) asks first, so a stray swipe doesn't end a match.
  Future<void> _confirmLeave() async {
    if (_leaving) return;
    final leave = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Leave the game?',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'Your current match will be lost.',
          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Keep playing',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Leave',
              style: GoogleFonts.inter(
                color: const Color(0xFFF87171),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    _leaving = true;
    unawaited(_exitGameMode());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_confirmLeave());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: GameWebView(
                game: widget.game,
                scoreBridgeService: _scoreBridge,
              ),
            ),
            // compact back button: the game draws its own title, so just the arrow
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: CircleBorder(
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _confirmLeave,
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
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
