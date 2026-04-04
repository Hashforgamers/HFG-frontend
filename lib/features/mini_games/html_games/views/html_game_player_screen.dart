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
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
  @override
  void initState() {
    super.initState();
    unawaited(_enterGameMode());
  }

  Future<void> _enterGameMode() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  Future<void> _exitGameMode() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    unawaited(_exitGameMode());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) return;
        unawaited(_exitGameMode());
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: GameWebView(
                game: widget.game,
                scoreBridgeService: HtmlGameScoreBridgeService(),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.48),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.game.name,
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Landscape mode',
                                style: GoogleFonts.inter(
                                  color: Colors.white60,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
