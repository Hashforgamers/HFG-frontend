import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';

class MiniGameScoreService {
  static const _prefsKey = 'mini_game_scores';
  static final MiniGameScoreService _instance =
      MiniGameScoreService._internal();

  MiniGameScoreService._internal();

  factory MiniGameScoreService() => _instance;

  final Map<String, int> _scores = {};
  Future<SharedPreferences>? _prefsFuture;
  bool _loaded = false;
  final MiniGameLeaderboardService _leaderboard = MiniGameLeaderboardService();

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

  Future<void> recordScore(String gameId, int score) async {
    await _ensureLoaded();
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
    final ok = await _leaderboard.submitScore(gameId: gameId, score: score);
    if (!ok) {
      Get.snackbar(
        'Score not synced',
        'Could not sync to leaderboard. Check login or connection.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF1E1E1E),
        colorText: const Color(0xFFE0E0E0),
        margin: const EdgeInsets.all(12),
      );
    }
  }

  int bestScore(String gameId) => _scores[gameId] ?? 0;

  Map<String, int> get allScores => Map.unmodifiable(_scores);

  int get totalScore =>
      _scores.values.fold<int>(0, (prev, value) => prev + value);

  bool get isLoaded => _loaded;
}
