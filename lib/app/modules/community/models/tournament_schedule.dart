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
        rosterLock == null ||
        tournamentStart == null ||
        tournamentEnd == null) {
      return 'Registration, roster lock, tournament start, and tournament end are required.';
    }
    if (!registrationEnd.isAfter(registrationStart)) {
      return 'Registration end must be after registration start.';
    }
    if (rosterLock.isBefore(registrationEnd)) {
      return 'Roster lock must be at or after registration end.';
    }
    if (rosterLock.isAfter(tournamentStart)) {
      return 'Roster lock must be at or before tournament start.';
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
    int resultBufferMinutesPerRound = 15,
  }) {
    if (numberOfTeams < 2 ||
        concurrentMatches < 1 ||
        matchDurationMinutes < 1 ||
        breakDurationMinutes < 0) {
      return Duration.zero;
    }
    final rounds = (math.log(numberOfTeams) / math.ln2).ceil();
    var matchesInRound = numberOfTeams - math.pow(2, rounds - 1).toInt();
    var totalMinutes = 0;
    for (var round = 0; round < rounds; round++) {
      final waves = (matchesInRound / concurrentMatches).ceil();
      totalMinutes += waves * matchDurationMinutes;
      totalMinutes += resultBufferMinutesPerRound;
      if (round < rounds - 1) totalMinutes += breakDurationMinutes;
      matchesInRound = math.pow(2, rounds - round - 2).toInt();
    }
    return Duration(minutes: totalMinutes);
  }
}
