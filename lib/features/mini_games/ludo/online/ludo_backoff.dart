import 'dart:math';

/// Capped exponential backoff with jitter for Ludo's Firestore sync.
///
/// Delays double from [base] up to [max]; each gets ±[jitter] so devices that
/// dropped together don't retry in lockstep. After [maxAttempts] failures the
/// caller should stop and show a manual "Retry" instead of failing silently.
class LudoBackoff {
  LudoBackoff({
    this.base = const Duration(seconds: 1),
    this.max = const Duration(seconds: 16),
    this.maxAttempts = 5,
    this.jitter = 0.2,
    Random? random,
  }) : _random = random ?? Random();

  final Duration base;
  final Duration max;
  final int maxAttempts;
  final double jitter;
  final Random _random;

  int _attempts = 0;

  /// Failures recorded since the last [reset].
  int get attempts => _attempts;

  /// True once [maxAttempts] failures have been recorded.
  bool get exhausted => _attempts >= maxAttempts;

  /// Records a failure and returns how long to wait before the next try.
  Duration fail() {
    final exp = base.inMilliseconds * pow(2, _attempts);
    _attempts++;
    final capped = min(exp.toDouble(), max.inMilliseconds.toDouble());
    final spread = capped * jitter * (_random.nextDouble() * 2 - 1);
    return Duration(milliseconds: (capped + spread).round());
  }

  void reset() => _attempts = 0;
}
