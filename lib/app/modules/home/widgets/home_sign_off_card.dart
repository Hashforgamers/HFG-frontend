import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/app/modules/rewards/models/squad_weekly_progress.dart';
import 'package:hash/core/service/squad_missions_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/features/mini_games/mini_game_launcher.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';
import 'package:hash/features/mini_games/arcade_analytics.dart';

/// What the sign-off card says for a streak of [streak] days. [name] is the
/// player's first name, or empty when unknown.
({String title, String body}) signOffCopy({
  required int streak,
  required String name,
}) {
  final who = name.isEmpty ? '' : ', $name';
  if (streak >= 2) {
    return (
      title: "You're on a $streak-day streak$who",
      body: 'One game today keeps it alive.',
    );
  }
  if (streak == 1) {
    return (
      title: 'Day 1 of your streak$who',
      body: 'Play again tomorrow to make it 2.',
    );
  }
  return (
    title: name.isEmpty ? 'Ready when you are' : 'Ready when you are, $name',
    body: 'Play one game to start a streak.',
  );
}

/// First word of a display name, for a friendly greeting.
String firstNameOf(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}

/// The last thing on the home feed: a personal sign-off built from the
/// player's own streak, with one tap back into the game they played last.
class HomeSignOffCard extends StatefulWidget {
  const HomeSignOffCard({super.key});

  @override
  State<HomeSignOffCard> createState() => _HomeSignOffCardState();
}

class _HomeSignOffCardState extends State<HomeSignOffCard> {
  late final Stream<SquadWeeklyProgress?> _progress =
      locator<SquadMissionsService>().watchCurrentWeekProgress();
  ArcadeGameEntry _game = MiniGameLauncher.resolve(null);

  @override
  void initState() {
    super.initState();
    unawaited(_loadLastPlayed());
  }

  Future<void> _loadLastPlayed() async {
    final last = await MiniGameScoreService().lastPlayedGame();
    if (!mounted) return;
    setState(() => _game = MiniGameLauncher.resolve(last));
  }

  Future<void> _play() async {
    ArcadeAnalytics.from('home_sign_off');
    await _game.open();
    // they may have played something else from inside that screen
    await _loadLastPlayed();
  }

  String _name() {
    if (!Get.isRegistered<UserController>()) return '';
    return firstNameOf(Get.find<UserController>().user.value.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SquadWeeklyProgress?>(
      stream: _progress,
      builder: (context, snapshot) {
        final streak = snapshot.data?.currentStreak ?? 0;
        final copy = signOffCopy(streak: streak, name: _name());
        return HomeCard(
          accent: streak > 0 ? HomeTokens.gold : HomeTokens.coral,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      _game.icon,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.sports_esports_rounded,
                          color: HomeTokens.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          copy.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HomeTokens.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          copy.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: HomeTokens.textSecondary,
                            fontSize: 12.5,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              HomeCta(
                label: 'Play ${_game.title}',
                icon: Icons.play_arrow_rounded,
                gold: streak > 0,
                height: 44,
                onTap: () => unawaited(_play()),
              ),
            ],
          ),
        );
      },
    );
  }
}
