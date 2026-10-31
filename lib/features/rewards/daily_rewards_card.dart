import 'dart:async';

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

  Widget _missionRow(DailyMission m) {
    final busy = _claimingMissions.contains(m.id);
    final Widget trailing;
    if (m.claimed) {
      trailing = const Icon(Icons.check_circle_rounded, color: HomeTokens.gold);
    } else if (m.complete) {
      trailing = TextButton(
        onPressed: busy ? null : () => _claimMission(m),
        style: TextButton.styleFrom(foregroundColor: HomeTokens.gold),
        child: Text(busy ? '…' : 'Claim +${m.reward}'),
      );
    } else {
      trailing = Text(
        '+${m.reward}',
        style: HomeTokens.body(HomeTokens.textSecondary),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.title, style: HomeTokens.body(HomeTokens.textPrimary)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: m.target == 0 ? 0 : m.progress / m.target,
                    minHeight: 5,
                    color: HomeTokens.green,
                    backgroundColor: HomeTokens.hairline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${m.progress}/${m.target}',
            style: HomeTokens.body(HomeTokens.textSecondary, size: 12),
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
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, HomeTokens.gap),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeTokens.surface,
        borderRadius: BorderRadius.circular(HomeTokens.radius),
        border: Border.all(color: HomeTokens.gold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                color: HomeTokens.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  done > 0 ? '$done-day streak' : 'Start your streak',
                  style: HomeTokens.title(17),
                ),
              ),
              Text('DAILY REWARD', style: HomeTokens.eyebrow(HomeTokens.gold)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: _dayPip(i, done: i < done, today: _isNext(i)),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: HomeTokens.gold,
                foregroundColor: HomeTokens.ink,
                disabledBackgroundColor: HomeTokens.hairline,
                disabledForegroundColor: HomeTokens.textSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: s.claimedToday || _claiming ? null : _claim,
              child: _claiming
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      s.claimedToday
                          ? 'Come back tomorrow for +${s.nextAmount}'
                          : 'Claim +${s.nextAmount} Hash Coins',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
          if (_missions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'TODAY’S MISSIONS',
              style: HomeTokens.eyebrow(HomeTokens.green),
            ),
            const SizedBox(height: 4),
            for (final m in _missions) _missionRow(m),
          ],
        ],
      ),
    );
  }

  bool _isNext(int i) {
    final s = _status!;
    return !s.claimedToday && i == s.streak;
  }

  Widget _dayPip(int i, {required bool done, required bool today}) {
    final color = done
        ? HomeTokens.gold
        : (today ? HomeTokens.goldLight : HomeTokens.textTertiary);
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? HomeTokens.gold : Colors.transparent,
            border: Border.all(color: color, width: today ? 2 : 1),
          ),
          child: done
              ? const Icon(Icons.check_rounded, size: 18, color: HomeTokens.ink)
              : Text(
                  '${DailyRewardsCard.rewards[i]}',
                  style: HomeTokens.body(color, size: 11),
                ),
        ),
        const SizedBox(height: 4),
        Text('D${i + 1}', style: HomeTokens.body(color, size: 10)),
      ],
    );
  }
}
