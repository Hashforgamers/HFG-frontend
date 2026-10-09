import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/analytics_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A reward the server has issued but the app hasn't credited yet.
class RewardEntry {
  const RewardEntry({
    required this.referenceId,
    required this.amount,
    required this.source,
    required this.title,
  });

  factory RewardEntry.fromMap(Map<dynamic, dynamic> m) => RewardEntry(
    referenceId: '${m['reference_id']}',
    amount: (m['amount'] as num?)?.toInt() ?? 0,
    source: '${m['source'] ?? 'reward'}',
    title: '${m['title'] ?? ''}',
  );

  final String referenceId;
  final int amount;
  final String source;
  final String title;
}

class StreakStatus {
  const StreakStatus({
    required this.claimedToday,
    required this.streak,
    required this.nextAmount,
  });

  factory StreakStatus.fromMap(Map<dynamic, dynamic> m) => StreakStatus(
    claimedToday: m['claimedToday'] == true,
    streak: (m['streak'] as num?)?.toInt() ?? 0,
    nextAmount: (m['nextAmount'] as num?)?.toInt() ?? 0,
  );

  final bool claimedToday;
  final int streak;
  final int nextAmount;
}

class DailyMission {
  const DailyMission({
    required this.id,
    required this.title,
    required this.target,
    required this.progress,
    required this.reward,
    required this.claimed,
  });

  factory DailyMission.fromMap(Map<dynamic, dynamic> m) => DailyMission(
    id: '${m['id']}',
    title: '${m['title'] ?? m['id']}',
    target: (m['target'] as num?)?.toInt() ?? 1,
    progress: (m['progress'] as num?)?.toInt() ?? 0,
    reward: (m['reward'] as num?)?.toInt() ?? 0,
    claimed: m['claimed'] == true,
  );

  final String id;
  final String title;
  final int target;
  final int progress;
  final int reward;
  final bool claimed;

  bool get complete => progress >= target;
}

/// Server-decided HashWallet rewards, paid with the existing hash-coins API.
///
/// Cloud Functions decide eligibility and amount and issue a ledger entry with
/// a fixed reference id. [payPending] credits each entry via
/// `addHashCoins(referenceId: ...)`, remembers it locally (so a retry never
/// credits twice from this device), then marks it paid on the server.
class RewardsService {
  RewardsService._();
  static final RewardsService instance = RewardsService._();

  static const _paidKey = 'reward_paid_refs';
  final FirebaseFunctions _fn = FirebaseFunctions.instance;
  Future<int>? _paying;

  Future<Map<dynamic, dynamic>> _call(String name, [Object? data]) async {
    final result = await _fn.httpsCallable(name).call<dynamic>(data);
    return (result.data as Map?) ?? const {};
  }

  List<RewardEntry> _pending(Map<dynamic, dynamic> m) =>
      ((m['pending'] as List?) ?? const [])
          .whereType<Map>()
          .map(RewardEntry.fromMap)
          .toList();

  List<DailyMission> _missions(Map<dynamic, dynamic> m) =>
      ((m['missions'] as List?) ?? const [])
          .whereType<Map>()
          .map(DailyMission.fromMap)
          .toList();

  Future<
    ({
      StreakStatus streak,
      List<DailyMission> missions,
      List<RewardEntry> pending,
    })
  >
  status() async {
    final m = await _call('rewardsStatus');
    return (
      streak: StreakStatus.fromMap((m['streak'] as Map?) ?? const {}),
      missions: _missions(m),
      pending: _pending(m),
    );
  }

  /// A finished offline Ludo or arcade game, counted toward daily missions on
  /// the server. Fire-and-forget: gameplay never waits on it. Online Ludo is
  /// counted server-side, so don't report it here.
  void reportGamePlayed({
    required String game,
    required String eventId,
    bool won = false,
  }) {
    unawaited(() async {
      try {
        final m = await _call('reportGamePlayed', {
          'game': game,
          'eventId': eventId,
          'won': won,
        });
        for (final id in (m['completed'] as List?) ?? const []) {
          _log('mission_completed', {'mission_id': '$id', 'game': game});
        }
      } catch (e) {
        debugPrint('[Rewards] reportGamePlayed failed: $e');
      }
    }());
  }

  /// One-time reward for finishing the onboarding first match. Returns the
  /// coins credited (0 if this account already had it).
  Future<int> claimFirstMatchReward() async {
    final m = await _call('claimFirstMatchReward');
    await payPending(_pending(m));
    return m['issued'] == true ? (m['amount'] as num?)?.toInt() ?? 0 : 0;
  }

  /// Claims a completed mission and credits it. Returns coins credited.
  Future<int> claimMission(String missionId) async {
    final m = await _call('claimMission', {'missionId': missionId});
    final amount = (m['amount'] as num?)?.toInt() ?? 0;
    if (m['issued'] == true) {
      _log('mission_claimed', {'mission_id': missionId, 'amount': amount});
    }
    await payPending(_pending(m));
    return amount;
  }

  /// Claims today's streak reward and credits it. Returns the coins credited
  /// (0 if today was already claimed).
  Future<({int streak, int amount, bool alreadyClaimed})> claimStreak() async {
    final m = await _call('claimDailyStreak');
    final already = m['alreadyClaimed'] == true;
    final streak = (m['streak'] as num?)?.toInt() ?? 0;
    final amount = (m['amount'] as num?)?.toInt() ?? 0;
    if (!already) {
      _log('streak_claimed', {'streak_day': streak, 'amount': amount});
    }
    await payPending(_pending(m));
    return (
      streak: streak,
      amount: already ? 0 : amount,
      alreadyClaimed: already,
    );
  }

  /// Credits every issued-but-unpaid reward. Safe to call any time (app open,
  /// after a match); concurrent calls share one run. Returns coins credited.
  Future<int> payPending([List<RewardEntry>? known]) =>
      _paying ??= _payPending(known).whenComplete(() => _paying = null);

  Future<int> _payPending(List<RewardEntry>? known) async {
    final entries = known ?? (await status()).pending;
    if (entries.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final paid = (prefs.getStringList(_paidKey) ?? const []).toSet();
    var credited = 0;
    for (final e in entries) {
      try {
        if (!paid.contains(e.referenceId)) {
          await locator<RemoteRepoInterface>().addHashCoins(
            amount: e.amount,
            source: e.source,
            referenceId: e.referenceId,
          );
          credited += e.amount;
          paid.add(e.referenceId);
          // Keep the newest 200 so the list can't grow forever.
          final list = paid.toList();
          await prefs.setStringList(
            _paidKey,
            list.length > 200 ? list.sublist(list.length - 200) : list,
          );
        }
        await _call('markRewardPaid', {'referenceId': e.referenceId});
      } catch (err) {
        debugPrint('[Rewards] paying ${e.referenceId} failed: $err');
      }
    }
    if (credited > 0) _refreshBalance();
    return credited;
  }

  void _refreshBalance() {
    final ctx = Get.context;
    if (ctx == null) return;
    try {
      unawaited(BlocProvider.of<HashCoinCubit>(ctx).getHashCoin());
    } catch (_) {}
  }

  void _log(String name, Map<String, Object?> params) {
    try {
      unawaited(locator<AnalyticsService>().log(name, parameters: params));
    } catch (_) {}
  }
}
