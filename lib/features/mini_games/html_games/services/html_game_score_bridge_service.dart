import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hash/app/data/services/user_controller.dart';
import 'package:hash/features/mini_games/html_games/models/html_mini_game.dart';
import 'package:hash/features/mini_games/score/mini_game_score_service.dart';

enum HtmlGameScoreSubmissionStatus {
  success,
  duplicate,
  invalidScore,
  missingUser,
  failed,
}

class HtmlGameScoreSubmissionResult {
  final HtmlGameScoreSubmissionStatus status;
  final int? score;
  final String message;

  const HtmlGameScoreSubmissionResult({
    required this.status,
    required this.message,
    this.score,
  });

  bool get didSubmit => status == HtmlGameScoreSubmissionStatus.success;
}

class HtmlGameScoreBridgeService {
  HtmlGameScoreBridgeService({MiniGameScoreService? scoreService})
    : _scoreService = scoreService ?? MiniGameScoreService();

  final MiniGameScoreService _scoreService;
  bool _hasSubmittedScore = false;

  bool get hasSubmittedScore => _hasSubmittedScore;

  Future<HtmlGameScoreSubmissionResult> submitScoreFromPayload({
    required HtmlMiniGame game,
    required dynamic payload,
  }) async {
    if (_hasSubmittedScore) {
      return const HtmlGameScoreSubmissionResult(
        status: HtmlGameScoreSubmissionStatus.duplicate,
        message: 'Score already submitted for this session.',
      );
    }

    final score = _extractScore(payload);
    if (score == null) {
      return const HtmlGameScoreSubmissionResult(
        status: HtmlGameScoreSubmissionStatus.invalidScore,
        message: 'Game returned an invalid score payload.',
      );
    }

    final userId = _resolveUserId();
    if (userId.isEmpty) {
      return const HtmlGameScoreSubmissionResult(
        status: HtmlGameScoreSubmissionStatus.missingUser,
        message: 'Please sign in before submitting a score.',
      );
    }

    _hasSubmittedScore = true;
    final didSubmit = await submitScore(
      userId: userId,
      gameId: game.gameId,
      score: score,
    );
    if (didSubmit) {
      return HtmlGameScoreSubmissionResult(
        status: HtmlGameScoreSubmissionStatus.success,
        score: score,
        message: 'Score submitted successfully.',
      );
    }

    _hasSubmittedScore = false;
    return const HtmlGameScoreSubmissionResult(
      status: HtmlGameScoreSubmissionStatus.failed,
      message: 'Score submission failed. Please try again.',
    );
  }

  Future<bool> submitScore({
    required String userId,
    required String gameId,
    required int score,
  }) async {
    if (userId.trim().isEmpty) {
      return false;
    }

    // The underlying score service resolves the authenticated Firebase user.
    // The explicit signature keeps the HTML game bridge aligned with backend
    // expectations: userId, gameId, score.
    return _scoreService.recordScore(gameId, score);
  }

  int? _extractScore(dynamic payload) {
    final rawScore = switch (payload) {
      {'score': final dynamic value} => value,
      _ => payload,
    };

    if (rawScore is num) {
      if (!rawScore.isFinite || rawScore < 0) return null;
      return rawScore.round();
    }

    if (rawScore is String) {
      final parsed = num.tryParse(rawScore.trim());
      if (parsed == null || !parsed.isFinite || parsed < 0) return null;
      return parsed.round();
    }

    return null;
  }

  String _resolveUserId() {
    if (Get.isRegistered<UserController>()) {
      final backendUserId = Get.find<UserController>().userId.trim();
      if (backendUserId.isNotEmpty) {
        return backendUserId;
      }
    }

    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }
}
