import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hash/app/modules/home/widgets/home_design.dart';
import 'package:hash/core/utils/haptics.dart';

import 'rewards_service.dart';

/// Home card for the daily login streak: seven escalating HashWallet rewards
/// (Day 1 -> Day 7), claimed once per IST day and validated server-side.
class DailyStreakCard extends StatefulWidget {
  const DailyStreakCard({super.key});

  /// Mirrors STREAK_REWARDS in functions/reward_rules.js (display only; the
  /// server decides what is actually paid).
  static const rewards = [5, 10, 15, 20, 25, 30, 50];

  @override
  State<DailyStreakCard> createState() => _DailyStreakCardState();
}

class _DailyStreakCardState extends State<DailyStreakCard> {
  final RewardsService _rewards = RewardsService.instance;
  StreakStatus? _status;
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
                  '${DailyStreakCard.rewards[i]}',
                  style: HomeTokens.body(color, size: 11),
                ),
        ),
        const SizedBox(height: 4),
        Text('D${i + 1}', style: HomeTokens.body(color, size: 10)),
      ],
    );
  }
}
