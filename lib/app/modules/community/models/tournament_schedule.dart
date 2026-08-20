import 'dart:math' as math;

class TournamentSchedule {
  final DateTime? registrationStartAt;
  final DateTime? registrationEndAt;
  final DateTime? rosterLockAt;
  final DateTime? tournamentStartAt;
  final DateTime? tournamentEndAt;
  final DateTime? checkInStartAt;
  final DateTime? checkInEndAt;

  const TournamentSchedule({
    required this.registrationStartAt,
    required this.registrationEndAt,
    required this.rosterLockAt,
    required this.tournamentStartAt,
    required this.tournamentEndAt,
    this.checkInStartAt,
    this.checkInEndAt,
  });

  String? validate() {
    final registrationStart = registrationStartAt;
    final registrationEnd = registrationEndAt;
    final rosterLock = rosterLockAt;
    final tournamentStart = tournamentStartAt;
    final tournamentEnd = tournamentEndAt;
    if (registrationStart == null ||
        registrationEnd == null ||
        tournamentStart == null ||
        tournamentEnd == null) {
      return 'Registration and tournament dates are required.';
    }
    if (!registrationEnd.isAfter(registrationStart)) {
      return 'Registration end must be after registration start.';
    }
    if (!tournamentStart.isAfter(registrationEnd)) {
      return 'Tournament start must be after registration end.';
    }
    if (rosterLock == null) {
      return 'Roster lock could not be calculated from the selected dates.';
    }
    if (!rosterLock.isAfter(registrationEnd)) {
      return 'Roster lock must be after registration end.';
    }
    if (!tournamentStart.isAfter(rosterLock)) {
      return 'Roster lock must be before tournament start.';
    }
    if (!tournamentEnd.isAfter(tournamentStart)) {
      return 'Tournament end must be after tournament start.';
    }
    if (checkInStartAt != null &&
        checkInEndAt != null &&
        !checkInEndAt!.isAfter(checkInStartAt!)) {
      return 'Check-in end must be after check-in start.';
    }
    return null;
  }

  static Duration estimateDuration({
    required int numberOfTeams,
    required int concurrentMatches,
    required int matchDurationMinutes,
    required int breakDurationMinutes,
    String tournamentFormat = 'single_elimination',
    int resultBufferMinutesPerRound = 15,
  }) {
    if (numberOfTeams < 2 ||
        concurrentMatches < 1 ||
        matchDurationMinutes < 1 ||
        breakDurationMinutes < 0) {
      return Duration.zero;
    }
    final rounds = estimateRounds(
      numberOfTeams: numberOfTeams,
      tournamentFormat: tournamentFormat,
    );
    final matches = estimateMatches(
      numberOfTeams: numberOfTeams,
      tournamentFormat: tournamentFormat,
    );
    final waves = (matches / concurrentMatches).ceil();
    final totalMinutes =
        waves * matchDurationMinutes +
        rounds * resultBufferMinutesPerRound +
        math.max(0, rounds - 1) * breakDurationMinutes;
    return Duration(minutes: totalMinutes);
  }

  static int estimateRounds({
    required int numberOfTeams,
    required String tournamentFormat,
  }) {
    if (numberOfTeams < 2) return 0;
    final eliminationRounds = (math.log(numberOfTeams) / math.ln2).ceil();
    return switch (tournamentFormat) {
      'double_elimination' => eliminationRounds * 2 - 1,
      'round_robin' => numberOfTeams.isEven ? numberOfTeams - 1 : numberOfTeams,
      'battle_royale' => 1,
      _ => eliminationRounds,
    };
  }

  static int estimateMatches({
    required int numberOfTeams,
    required String tournamentFormat,
  }) {
    if (numberOfTeams < 2) return 0;
    return switch (tournamentFormat) {
      'double_elimination' => numberOfTeams * 2 - 2,
      'round_robin' => numberOfTeams * (numberOfTeams - 1) ~/ 2,
      'battle_royale' => 1,
      _ => numberOfTeams - 1,
    };
  }
}
