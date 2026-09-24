import 'dart:async';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/hash_coin/cubit/hash_coin_cubit.dart';
import 'package:hash/core/repositories/remote/remote_repo_interface.dart';
import 'package:hash/core/service/fb_events_service.dart';
import 'package:hash/core/service_locator.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:hash/core/service/segment_sdk_service.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hash/app/modules/hash_coin/widgets/hash_coin_icon.dart';

class MiniGameScoreService {
  static const _prefsKey = 'mini_game_scores';
  static const _rankRewardClaimsKey = 'mini_game_rank_reward_claims';
  static const _topRankRewardClaimLimit = 3;
  static const _playRewardKey = 'mini_game_daily_play_reward';

  /// HashCoins granted the first time each game is played on a given day.
  /// Single source of truth — set to 0 to disable the daily play reward.
  static const int dailyPlayRewardAmount = 5;
  static final MiniGameScoreService _instance =
      MiniGameScoreService._internal();

  MiniGameScoreService._internal();

  factory MiniGameScoreService() => _instance;

  final Map<String, int> _scores = {};
  Future<SharedPreferences>? _prefsFuture;
  bool _loaded = false;
  final MiniGameLeaderboardService _leaderboard = MiniGameLeaderboardService();
  final SegmentSdkService _segmentService = locator<SegmentSdkService>();
  final FbEventsService _fbEventsService = locator<FbEventsService>();

  Future<void> _ensureLoaded() async {
    _prefsFuture ??= SharedPreferences.getInstance();
    final prefs = await _prefsFuture!;
    final stored = prefs.getStringList(_prefsKey);
    if (stored != null) {
      for (final entry in stored) {
        final parts = entry.split(':');
        if (parts.length == 2) {
          final value = int.tryParse(parts[1]);
          if (value != null) _scores[parts[0]] = value;
        }
      }
    }
    _loaded = true;
  }

  /// Public hook so widgets can await readiness before reading scores.
  Future<void> ensureLoaded() => _ensureLoaded();

  Future<bool> recordScore(String gameId, int score) async {
    await _ensureLoaded();

    // Reward simply playing (first finish of each game per day) so every player
    // earns something, not only those who crack the global top 100.
    unawaited(_maybeAwardDailyPlayReward(gameId));

    final best = _scores[gameId] ?? 0;
    final isNewBest = score > best;
    if (isNewBest) {
      _scores[gameId] = score;
      final prefs = await _prefsFuture!;
      final serialized = _scores.entries
          .map((e) => '${e.key}:${e.value}')
          .toList();
      await prefs.setStringList(_prefsKey, serialized);
    }

    // Always push latest attempt; backend keeps best per user/game.
    final result = await _leaderboard.submitScore(gameId: gameId, score: score);
    if (!result.synced) {
      unawaited(
        _trackArcadeScoreEvent('Arcade Score Sync Failed', {
          'game_id': gameId,
          'score': score,
        }),
      );
      Get.snackbar(
        'Score not synced',
        'Could not sync to leaderboard. Check login or connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1E1E),
        colorText: const Color(0xFFE0E0E0),
        margin: const EdgeInsets.all(12),
      );
      return false;
    }

    if (result.isNewGlobalLeader &&
        Get.isRegistered<NotificationController>()) {
      unawaited(
        _trackArcadeScoreEvent('Arcade Leaderboard Crown Taken', {
          'game_id': gameId,
          'score': result.newBest,
          'previous_leader_name': result.previousLeaderName,
          'current_rank': result.currentRank,
        }),
      );
      final notification = Get.find<NotificationController>();
      final readableName = MiniGameLeaderboardService.readableGameName(gameId);
      final defeatedLabel = result.previousTopScore <= 0
          ? 'You opened the board with the first elite score.'
          : 'You beat ${result.previousLeaderName} and took the top score.';
      await notification.showLeaderboardNotification(
        title: 'New leaderboard crown',
        body: '$readableName: $defeatedLabel',
      );
    }

    if (result.storedNewBest) {
      unawaited(
        _trackArcadeScoreEvent('Arcade Personal Best Recorded', {
          'game_id': gameId,
          'score': result.newBest,
          'previous_best': result.previousBest,
          'current_rank': result.currentRank,
        }),
      );
      final rank = result.currentRank;
      final reward = rank == null
          ? 0
          : MiniGameLeaderboardService.hashCoinRewardForRank(rank);
      if (rank != null && reward > 0) {
        final topRankRewardCapReached = await _hasReachedTopRankRewardLimit(
          rank,
        );
        if (topRankRewardCapReached) {
          unawaited(
            _trackArcadeScoreEvent('Arcade Reward Limit Reached', {
              'game_id': gameId,
              'rank': rank,
              'score': result.newBest,
            }),
          );
          Get.snackbar(
            'Reward limit reached',
            'Rank #$rank HashCoin rewards can only be claimed 3 times.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: const Color(0xFF141414),
            colorText: const Color(0xFFEDEDED),
            margin: const EdgeInsets.all(12),
          );
        } else {
          final rewardCredited = await _creditRankReward(
            rank: rank,
            amount: reward,
            gameId: gameId,
            score: result.newBest,
          );
          if (rewardCredited) {
            await _showRankRewardPopup(rank: rank, amount: reward);
            return true;
          }
        }
      }

      Get.snackbar(
        'New personal best',
        '${MiniGameLeaderboardService.readableGameName(gameId)}: ${result.newBest} pts',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF141414),
        colorText: const Color(0xFFEDEDED),
        margin: const EdgeInsets.all(12),
      );
    }

    return true;
  }

  /// Credits [dailyPlayRewardAmount] HashCoins the first time [gameId] is
  /// played each day. Idempotent per game/user/day via a deterministic
  /// reference id, so repeated finishes never double-credit. Guests are skipped
  /// (they can't be credited) and any failure is swallowed to never block play.
  Future<void> _maybeAwardDailyPlayReward(String gameId) async {
    if (dailyPlayRewardAmount <= 0) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    await _ensureLoaded();
    final prefs = await _prefsFuture!;
    final mapKey = '${_playRewardKey}_$uid';
    final today = _todayKey();
    final raw = prefs.getStringList(mapKey) ?? const <String>[];
    final lastAwardedByGame = <String, String>{};
    for (final entry in raw) {
      final i = entry.indexOf(':');
      if (i > 0) {
        lastAwardedByGame[entry.substring(0, i)] = entry.substring(i + 1);
      }
    }
    if (lastAwardedByGame[gameId] == today) return; // already rewarded today

    try {
      final remoteRepo = locator<RemoteRepoInterface>();
      await remoteRepo.addHashCoins(
        amount: dailyPlayRewardAmount,
        source: 'mini_game_daily_play',
        referenceId: 'mini_game_play_${gameId}_${uid}_$today',
      );

      lastAwardedByGame[gameId] = today;
      await prefs.setStringList(
        mapKey,
        lastAwardedByGame.entries.map((e) => '${e.key}:${e.value}').toList(),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = Get.context;
        if (ctx == null) return;
        try {
          BlocProvider.of<HashCoinCubit>(ctx).getHashCoin();
        } catch (_) {
          // ignore if cubit context is unavailable
        }
      });

      Get.snackbar(
        'Daily play bonus',
        '+$dailyPlayRewardAmount HashCoins for playing '
            '${MiniGameLeaderboardService.readableGameName(gameId)}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF141414),
        colorText: const Color(0xFFEDEDED),
        margin: const EdgeInsets.all(12),
      );

      unawaited(
        _trackArcadeScoreEvent('Arcade Daily Play Reward', {
          'game_id': gameId,
          'amount': dailyPlayRewardAmount,
        }),
      );
    } catch (_) {
      // Never block gameplay on a reward failure; it retries next play.
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<bool> _creditRankReward({
    required int rank,
    required int amount,
    required String gameId,
    required int score,
  }) async {
    final rankRewardCapReached = await _hasReachedTopRankRewardLimit(rank);
    if (rankRewardCapReached) {
      return false;
    }

    try {
      final remoteRepo = locator<RemoteRepoInterface>();
      await remoteRepo.addHashCoins(
        amount: amount,
        source: 'mini_game_rank_reward',
        referenceId:
            'mini_game_rank_${gameId}_${rank}_${score}_${DateTime.now().millisecondsSinceEpoch}',
      );
      await _incrementTopRankRewardClaim(rank);
      unawaited(
        _trackArcadeScoreEvent('Arcade Rank Reward Credited', {
          'game_id': gameId,
          'rank': rank,
          'amount': amount,
          'score': score,
        }),
      );

      try {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final currentContext = Get.context;
          if (currentContext == null) return;
          try {
            BlocProvider.of<HashCoinCubit>(currentContext).getHashCoin();
          } catch (_) {
            // ignore if cubit context is unavailable
          }
        });
      } catch (_) {
        // ignore if cubit context is unavailable
      }

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasReachedTopRankRewardLimit(int rank) async {
    if (rank < 1 || rank > 3) return false;
    final count = await _topRankRewardClaimCount(rank);
    return count >= _topRankRewardClaimLimit;
  }

  Future<int> _topRankRewardClaimCount(int rank) async {
    if (rank < 1 || rank > 3) return 0;
    await _ensureLoaded();
    final prefs = await _prefsFuture!;
    final rawEntries = prefs.getStringList(_rankRewardClaimsKey) ?? const [];
    final rewardCounts = _decodeRewardCounts(rawEntries);
    return rewardCounts[_rewardClaimKey(rank)] ?? 0;
  }

  Future<void> _incrementTopRankRewardClaim(int rank) async {
    if (rank < 1 || rank > 3) return;
    await _ensureLoaded();
    final prefs = await _prefsFuture!;
    final rawEntries = prefs.getStringList(_rankRewardClaimsKey) ?? const [];
    final rewardCounts = _decodeRewardCounts(rawEntries);
    final key = _rewardClaimKey(rank);
    rewardCounts[key] = (rewardCounts[key] ?? 0) + 1;
    final serialized = rewardCounts.entries
        .map((entry) => '${entry.key}:${entry.value}')
        .toList();
    await prefs.setStringList(_rankRewardClaimsKey, serialized);
  }

  Map<String, int> _decodeRewardCounts(List<String> rawEntries) {
    final rewardCounts = <String, int>{};
    for (final entry in rawEntries) {
      final separatorIndex = entry.lastIndexOf(':');
      if (separatorIndex <= 0 || separatorIndex >= entry.length - 1) {
        continue;
      }
      final key = entry.substring(0, separatorIndex);
      final value = int.tryParse(entry.substring(separatorIndex + 1));
      if (value != null) {
        rewardCounts[key] = value;
      }
    }
    return rewardCounts;
  }

  String _rewardClaimKey(int rank) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return '$uid|rank_$rank';
  }

  Future<void> _trackArcadeScoreEvent(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final eventPayload = <String, dynamic>{
      'module': 'mini_games_arcade',
      ...payload,
    };
    await _segmentService.onCustomEvent(name, eventPayload);
    await _fbEventsService.onCustomEvent(name, eventPayload);
  }

  Future<void> _showRankRewardPopup({
    required int rank,
    required int amount,
  }) async {
    final rankSuffix = switch (rank) {
      1 => '1st',
      2 => '2nd',
      3 => '3rd',
      _ => '#$rank',
    };

    await Get.dialog<void>(
      Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1016).withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFC857).withValues(alpha: 0.24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFC857).withValues(alpha: 0.26),
                          blurRadius: 24,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const HashCoinIcon(size: 76),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      'Arcade Reward',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFFDA8A),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Rank $rankSuffix secured',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC857).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFC857).withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HashCoinIcon(size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'You received $amount HashCoins',
                          style: GoogleFonts.inter(
                            color: const Color(0xFFFFDE93),
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    rank <= 3
                        ? 'Top 3 rewards can only be claimed 3 times per rank to prevent abuse.'
                        : 'Every ranked finish up to #100 earns HashCoins.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Get.back<void>(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC857),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Collect',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int bestScore(String gameId) => _scores[gameId] ?? 0;

  Map<String, int> get allScores => Map.unmodifiable(_scores);

  int get totalScore =>
      _scores.values.fold<int>(0, (prev, value) => prev + value);

  bool get isLoaded => _loaded;
}
