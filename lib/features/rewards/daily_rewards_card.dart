import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/core/utils/haptics.dart';

import 'rewards_service.dart';

/// Home card for the daily habit loop: the login streak (seven escalating
/// HashWallet rewards, Day 1 -> Day 7) and today's missions. Everything is
/// validated server-side; this only displays and claims.
class DailyRewardsCard extends StatefulWidget {
  const DailyRewardsCard({super.key});

  /// Mirrors STREAK_REWARDS in functions/reward_rules.js (display only; the
  /// server decides what is actually paid).
  static const rewards = [5, 10, 15, 20, 25, 30, 50];

  @override
  State<DailyRewardsCard> createState() => _DailyRewardsCardState();
}

class _DailyRewardsCardState extends State<DailyRewardsCard> {
  final RewardsService _rewards = RewardsService.instance;
  StreakStatus? _status;
  List<DailyMission> _missions = const [];
  final Set<String> _claimingMissions = {};
  bool _claiming = false;
  bool _failed = false;

  /// Null until the user toggles: open while today's reward is unclaimed.
  bool? _expanded;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final s = await _rewards.status();
      if (!mounted) return;
      setState(() {
        _status = s.streak;
        _missions = s.missions;
        _failed = false;
      });
      // Anything issued earlier (match rewards, missions) gets credited now.
      if (s.pending.isNotEmpty) unawaited(_rewards.payPending(s.pending));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      final r = await _rewards.claimStreak();
      Haptics.heavy();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.alreadyClaimed
                ? 'Already claimed today. See you tomorrow!'
                : 'Day ${r.streak} streak: +${r.amount} Hash Coins',
          ),
        ),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Couldn’t claim right now. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  Future<void> _claimMission(DailyMission m) async {
    if (_claimingMissions.contains(m.id)) return;
    setState(() => _claimingMissions.add(m.id));
    try {
      final amount = await _rewards.claimMission(m.id);
      Haptics.heavy();
      if (mounted && amount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${m.title}: +$amount Hash Coins')),
        );
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t claim right now. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _claimingMissions.remove(m.id));
    }
  }

  // Content sits on the vivid gradient, so it is white-on-colour throughout.
  static const _white70 = Color(0xB3FFFFFF);
  static const _glass = Color(0x2EFFFFFF);
  // See-through tint over a backdrop blur: frosted glass with brand colour.
  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x597B2FF7), Color(0x40FF3E8E), Color(0x33FF9A3D)],
    stops: [0, 0.55, 1],
  );

  Widget _missionRow(DailyMission m) {
    final busy = _claimingMissions.contains(m.id);
    final Widget trailing;
    if (m.claimed) {
      trailing = const Icon(Icons.check_circle_rounded, color: Colors.white);
    } else if (m.complete) {
      trailing = TextButton(
        onPressed: busy ? null : () => _claimMission(m),
        style: TextButton.styleFrom(
          foregroundColor: HomeTokens.ink,
          backgroundColor: Colors.white,
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        child: Text(busy ? '…' : 'Claim +${m.reward}'),
      );
    } else {
      trailing = Text('+${m.reward}', style: HomeTokens.body(_white70));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title, style: HomeTokens.body(Colors.white)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: m.target == 0 ? 0 : m.progress / m.target,
                    minHeight: 5,
                    color: Colors.white,
                    backgroundColor: _glass,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${m.progress}/${m.target}',
            style: HomeTokens.body(_white70, size: 12),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _status;
    if (_failed || s == null) return const SizedBox.shrink();
    // Days already earned in this streak, including today once claimed.
    final done = s.streak;
    final expanded = _expanded ?? !s.claimedToday;
    final subtitle = s.claimedToday
        ? 'Claimed today · +${s.nextAmount} tomorrow'
        : done > 0
        ? 'Day ${done + 1} of 7 is ready'
        : 'Claim daily to climb to +${DailyRewardsCard.rewards.last}';
    return ClipRRect(
      borderRadius: BorderRadius.circular(HomeTokens.radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: _gradient),
          child: Stack(
            children: [
              // Light blobs and a big Hash logo watermark for depth.
              Positioned(top: -60, right: -40, child: _blob(180, 0.22)),
              Positioned(bottom: -70, left: -50, child: _blob(200, 0.12)),
              Positioned(
                right: -20,
                top: -14,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Image.asset(
                    'assets/images/hash_silhouette.png',
                    width: 150,
                    color: Colors.white.withValues(alpha: 0.1),
                    colorBlendMode: BlendMode.srcIn,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topCenter,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(s, done, expanded, subtitle),
                      if (expanded) ...[
                        const SizedBox(height: 18),
                        _streakTrack(done),
                        const SizedBox(height: 18),
                        _claimArea(s),
                        if (_missions.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Text(
                            'TODAY’S MISSIONS',
                            style: HomeTokens.eyebrow(Colors.white),
                          ),
                          const SizedBox(height: 4),
                          for (final m in _missions) _missionRow(m),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, double alpha) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          Colors.white.withValues(alpha: alpha),
          Colors.transparent,
        ],
      ),
    ),
  );

  Widget _header(
    StreakStatus s,
    int done,
    bool expanded,
    String subtitle,
  ) => Semantics(
    button: true,
    expanded: expanded,
    child: InkWell(
      onTap: () => setState(() => _expanded = !expanded),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _glass),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: HomeTokens.goldLight,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done > 0 ? '$done-day streak 🔥' : 'Start your streak',
                  style: HomeTokens.title(19),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: HomeTokens.body(_white70, size: 12)),
              ],
            ),
          ),
          if (!expanded && !s.claimedToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+${s.nextAmount}',
                style: HomeTokens.body(
                  HomeTokens.pink,
                  size: 12,
                ).copyWith(fontWeight: FontWeight.w900),
              ),
            ),
          Icon(
            expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: Colors.white,
          ),
        ],
      ),
    ),
  );

  Widget _claimArea(StreakStatus s) {
    if (s.claimedToday) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _glass,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Come back tomorrow for +${s.nextAmount}',
              style: HomeTokens.body(
                Colors.white,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: HomeTokens.ink,
          elevation: 6,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: _claiming ? null : _claim,
        child: _claiming
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: HomeTokens.pink,
                ),
              )
            : Text(
                'Claim +${s.nextAmount} Hash Coins',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  bool _isNext(int i) {
    final s = _status!;
    return !s.claimedToday && i == s.streak;
  }

  /// Seven day pips joined by connectors that turn white once both ends
  /// are claimed.
  Widget _streakTrack(int done) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var i = 0; i < 7; i++) ...[
        if (i > 0)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: i < done ? Colors.white : _glass,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        _dayPip(i, done: i < done, today: _isNext(i)),
      ],
    ],
  );

  Widget _dayPip(int i, {required bool done, required bool today}) {
    final last = i == 6;
    return SizedBox(
      width: 34,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done
                  ? Colors.white
                  : (last ? HomeTokens.goldLight : _glass),
              border: today ? Border.all(color: Colors.white, width: 2) : null,
              boxShadow: today || last
                  ? [
                      BoxShadow(
                        color: (last ? HomeTokens.goldLight : Colors.white)
                            .withValues(alpha: 0.6),
                        blurRadius: 14,
                      ),
                    ]
                  : null,
            ),
            child: done
                ? const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: HomeTokens.pink,
                  )
                : last
                ? const Icon(
                    Icons.card_giftcard_rounded,
                    size: 17,
                    color: HomeTokens.ink,
                  )
                : Text(
                    '${DailyRewardsCard.rewards[i]}',
                    style: HomeTokens.body(
                      Colors.white,
                      size: 11,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            last ? '+${DailyRewardsCard.rewards[i]}' : 'D${i + 1}',
            style: HomeTokens.body(
              last ? HomeTokens.goldLight : _white70,
              size: 10,
            ).copyWith(fontWeight: last ? FontWeight.w800 : null),
          ),
        ],
      ),
    );
  }
}
