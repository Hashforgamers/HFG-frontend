import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hash/core/service/notification_service.dart';
import 'package:hash/features/mini_games/score/mini_game_leaderboard_service.dart';

class MiniGameLeaderboardNotificationService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MiniGameLeaderboardService _leaderboardService =
      MiniGameLeaderboardService();

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<List<LeaderboardEntry>>? _leaderboardSubscription;
  List<LeaderboardEntry> _previousEntries = const <LeaderboardEntry>[];
  bool _hasPrimedSnapshot = false;
  String? _activeUserId;

  @override
  void onInit() {
    super.onInit();
    _authSubscription = _auth.authStateChanges().listen(_handleAuthChanged);
    _handleAuthChanged(_auth.currentUser);
  }

  @override
  void onClose() {
    _authSubscription?.cancel();
    _leaderboardSubscription?.cancel();
    super.onClose();
  }

  void _handleAuthChanged(User? user) {
    _leaderboardSubscription?.cancel();
    _leaderboardSubscription = null;
    _previousEntries = const <LeaderboardEntry>[];
    _hasPrimedSnapshot = false;
    _activeUserId = user?.uid;

    final uid = user?.uid.trim() ?? '';
    if (uid.isEmpty) {
      return;
    }

    _leaderboardSubscription = _leaderboardService
        .leaderboardStream(limit: 25)
        .listen((entries) => _handleLeaderboardUpdate(uid, entries));
  }

  Future<void> _handleLeaderboardUpdate(
    String currentUserId,
    List<LeaderboardEntry> entries,
  ) async {
    if (_activeUserId != currentUserId) {
      return;
    }

    final rankedEntries = _leaderboardService.rankEntriesForGame(
      entries,
      gameId: MiniGameLeaderboardService.overallGameId,
    );

    if (!_hasPrimedSnapshot) {
      _previousEntries = List<LeaderboardEntry>.from(rankedEntries);
      _hasPrimedSnapshot = true;
      return;
    }

    final previousRank = _rankForUser(
      entries: _previousEntries,
      userId: currentUserId,
    );
    final currentRank = _rankForUser(
      entries: rankedEntries,
      userId: currentUserId,
    );
    final notificationController = _notificationControllerOrNull();

    if (notificationController != null) {
      if (currentRank != null && currentRank <= 4) {
        final climbedIntoTopFour = previousRank == null || previousRank > 4;
        final improvedWithinTopFour =
            previousRank != null &&
            previousRank <= 4 &&
            currentRank < previousRank;
        if (climbedIntoTopFour || improvedWithinTopFour) {
          final body = climbedIntoTopFour
              ? 'You climbed to #$currentRank on the overall arcade leaderboard.'
              : 'You moved up from #$previousRank to #$currentRank on the overall arcade leaderboard.';
          await notificationController.showLeaderboardNotification(
            title: 'Leaderboard climb',
            body: body,
          );
        }
      }

      final slippedWithinTopFour =
          previousRank != null &&
          previousRank <= 4 &&
          (currentRank == null || currentRank > previousRank);
      if (slippedWithinTopFour) {
        final overtakerName = _resolveOvertakerName(
          entries: rankedEntries,
          currentUserId: currentUserId,
          currentRank: currentRank,
        );
        final body = currentRank == null || currentRank > 4
            ? overtakerName.isEmpty
                  ? 'You slipped out of the top 4 on the overall arcade leaderboard.'
                  : '$overtakerName moved ahead of you. You slipped out of the top 4 overall.'
            : overtakerName.isEmpty
            ? 'You dropped to #$currentRank on the overall arcade leaderboard.'
            : '$overtakerName moved ahead of you. You are now #$currentRank overall.';
        await notificationController.showLeaderboardNotification(
          title: 'Leaderboard update',
          body: body,
        );
      }
    }

    _previousEntries = List<LeaderboardEntry>.from(rankedEntries);
  }

  NotificationController? _notificationControllerOrNull() {
    if (!Get.isRegistered<NotificationController>()) {
      return null;
    }
    return Get.find<NotificationController>();
  }

  int? _rankForUser({
    required List<LeaderboardEntry> entries,
    required String userId,
  }) {
    final index = entries.indexWhere((entry) => entry.userId == userId);
    if (index < 0) {
      return null;
    }
    return index + 1;
  }

  String _resolveOvertakerName({
    required List<LeaderboardEntry> entries,
    required String currentUserId,
    required int? currentRank,
  }) {
    if (entries.isEmpty) {
      return '';
    }

    if (currentRank != null && currentRank > 1) {
      final overtakerIndex = currentRank - 2;
      if (overtakerIndex >= 0 && overtakerIndex < entries.length) {
        final overtaker = entries[overtakerIndex];
        if (overtaker.userId != currentUserId) {
          return _displayName(overtaker);
        }
      }
    }

    final topFourCutoff = entries
        .take(4)
        .where((entry) => entry.userId != currentUserId);
    if (topFourCutoff.isNotEmpty) {
      return _displayName(topFourCutoff.last);
    }

    return '';
  }

  String _displayName(LeaderboardEntry entry) {
    final name = entry.displayName.trim();
    return name.isEmpty ? 'Another player' : name;
  }
}
