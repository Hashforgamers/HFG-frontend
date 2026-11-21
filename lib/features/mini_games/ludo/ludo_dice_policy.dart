import 'dart:math';

/// Dice tweaks for the easy first match (a new player's very first game), so
/// it is short and very likely a win. Every other mode rolls fair.
abstract final class LudoDicePolicy {
  /// [roll] is the fair 1-6 result. A human with every pawn still at home
  /// gets a 1-in-3 chance of a six so they aren't stuck waiting; half the
  /// bot's sixes are re-rolled to 1-5.
  static int adjust(
    int roll, {
    required bool easy,
    required bool isBot,
    required bool allPawnsHome,
    required Random random,
  }) {
    if (!easy) return roll;
    if (!isBot && allPawnsHome && roll != 6 && random.nextInt(3) == 0) {
      return 6;
    }
    if (isBot && roll == 6 && random.nextBool()) return random.nextInt(5) + 1;
    return roll;
  }
}
