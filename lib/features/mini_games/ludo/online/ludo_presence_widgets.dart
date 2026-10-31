import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hash/utils/widgets/game_panel.dart';

import '../ludo_analytics.dart';
import 'ludo_match.dart';
import 'ludo_match_screen.dart';
import 'ludo_match_service.dart';

/// Live "N looking · M playing" line for Ludo entry points, so players can see
/// that real people are online right now. Renders nothing while both are zero
/// unless [emptyText] is given.
class LudoLiveCount extends StatefulWidget {
  const LudoLiveCount({super.key, this.size = 12, this.emptyText});

  final double size;
  final String? emptyText;

  @override
  State<LudoLiveCount> createState() => _LudoLiveCountState();
}

class _LudoLiveCountState extends State<LudoLiveCount> {
  static const _live = Color(0xFF7CF06B);

  final LudoMatchService _service = LudoMatchService();
  late final Stream<List<LudoMatch>> _open = _service.watchOpenQuickRooms();
  late final Stream<List<LudoMatch>> _playing = _service.watchLiveMatches();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LudoMatch>>(
      stream: _open,
      builder: (context, openSnap) => StreamBuilder<List<LudoMatch>>(
        stream: _playing,
        builder: (context, playSnap) {
          int humans(List<LudoMatch>? ms) =>
              (ms ?? const []).fold(0, (sum, m) => sum + m.humanCount);
          final looking = humans(openSnap.data);
          final playing = humans(playSnap.data);

          final String text;
          if (looking == 0 && playing == 0) {
            final empty = widget.emptyText;
            if (empty == null) return const SizedBox.shrink();
            text = empty;
          } else {
            text = [
              if (looking > 0) '$looking looking',
              if (playing > 0) '$playing playing',
            ].join(' · ');
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: widget.size * 0.6,
                height: widget.size * 0.6,
                decoration: const BoxDecoration(
                  color: _live,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: gameFont(widget.size, _live),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Home banner shown while someone is waiting in a Quick Match room:
/// "Priya is looking for a Ludo opponent · Join". Hidden when nobody is
/// waiting, when the only room is mine, or after the user dismisses it.
class LudoLookingBanner extends StatefulWidget {
  const LudoLookingBanner({super.key, this.bottomGap = 0});

  /// Space below the banner when it is showing (none when hidden).
  final double bottomGap;

  @override
  State<LudoLookingBanner> createState() => _LudoLookingBannerState();
}

class _LudoLookingBannerState extends State<LudoLookingBanner> {
  static const _accent = Color(0xFF00DC00);

  // Rooms dismissed this app session, so the banner doesn't keep coming back
  // for the same waiting player.
  static final Set<String> _dismissed = {};
  static final Set<String> _shown = {};

  static int _waitSec(LudoMatch room) => room.createdAtMs > 0
      ? (DateTime.now().millisecondsSinceEpoch - room.createdAtMs) ~/ 1000
      : 0;

  final LudoMatchService _service = LudoMatchService();
  late final Stream<List<LudoMatch>> _open = _service.watchOpenQuickRooms();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Rooms age out (bot fill / staleness) without a new snapshot; re-check.
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LudoMatch>>(
      stream: _open,
      builder: (context, snap) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return const SizedBox.shrink();
        final now = DateTime.now().millisecondsSinceEpoch;
        // Leave a couple of seconds' margin before the bot takes the seat.
        final cutoffMs = (LudoMatchService.quickFillSeconds - 2) * 1000;
        final room = (snap.data ?? const <LudoMatch>[])
            .where(
              (m) =>
                  m.seatOf(uid) == null &&
                  !_dismissed.contains(m.id) &&
                  now - m.createdAtMs < cutoffMs,
            )
            .firstOrNull;
        if (room == null) return const SizedBox.shrink();

        // Logged after the frame (never from build itself); one per room.
        if (_shown.add(room.id)) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => LudoAnalytics.banner(
              'shown',
              waitSec: _waitSec(room),
              matchId: room.id,
            ),
          );
        }

        final host = room.seats.values.where((s) => !s.bot).firstOrNull;
        final name = (host?.name ?? 'Someone').split(' ').first;
        return Padding(
          padding: EdgeInsets.only(bottom: widget.bottomGap),
          child: _banner(room, name),
        );
      },
    );
  }

  Widget _banner(LudoMatch room, String name) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _join(room),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _accent.withValues(alpha: 0.45)),
            gradient: LinearGradient(
              colors: [
                _accent.withValues(alpha: 0.18),
                const Color(0xFF111111),
              ],
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/mini_game_icons/ludo_icon.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name is looking for a Ludo opponent',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Jump in now — the match starts right away',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _join(room),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  'Join',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Dismiss',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
                onPressed: () {
                  LudoAnalytics.banner('dismissed', waitSec: _waitSec(room));
                  setState(() => _dismissed.add(room.id));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _join(LudoMatch room) {
    LudoAnalytics.banner('tapped', waitSec: _waitSec(room));
    LudoAnalytics.opened('banner');
    _dismissed.add(room.id);
    // The match screen takes a free seat on open (or says the room filled).
    Get.to(() => LudoMatchScreen(matchId: room.id));
  }
}
