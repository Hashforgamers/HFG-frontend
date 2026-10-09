/// When a waiting Quick Match room should start, as a pure function of time
/// so it can be unit-tested.
///
/// The host's device starts the room once it is full, once a second player has
/// been seated for [startWithPlayersMs] (so a near-simultaneous third joiner
/// isn't left out), or with a bot after [fillSeconds]. Any other seated player
/// steps in after [fallbackMs] in case the host's device went quiet.
class LudoMatchmakingTimer {
  const LudoMatchmakingTimer({
    required this.fillSeconds,
    this.startWithPlayersMs = 3000,
    this.fallbackExtraMs = 10000,
  });

  final int fillSeconds;
  final int startWithPlayersMs;
  final int fallbackExtraMs;

  int get fillMs => fillSeconds * 1000;
  int get fallbackMs => fillMs + fallbackExtraMs;

  /// Whole seconds until the bot fill, never negative.
  int secondsLeft({required int createdAtMs, required int nowMs}) {
    if (createdAtMs <= 0) return 0;
    final leftMs = fillMs - (nowMs - createdAtMs);
    return leftMs <= 0 ? 0 : (leftMs / 1000).ceil();
  }

  bool isDue({
    required bool isHost,
    required bool isFull,
    required int createdAtMs,
    required int nowMs,
    required int secondPlayerSeenAtMs,
  }) {
    final waited = nowMs - createdAtMs;
    if (!isHost) return waited >= fallbackMs;
    return isFull ||
        waited >= fillMs ||
        (secondPlayerSeenAtMs > 0 &&
            nowMs - secondPlayerSeenAtMs >= startWithPlayersMs);
  }
}
