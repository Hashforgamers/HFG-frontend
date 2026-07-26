import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/community/models/tournament_schedule.dart';

void main() {
  final start = DateTime.utc(2026, 7, 26, 12);

  TournamentSchedule validSchedule({
    DateTime? registrationEnd,
    DateTime? rosterLock,
  }) => TournamentSchedule(
    registrationStartAt: start.subtract(const Duration(days: 2)),
    registrationEndAt:
        registrationEnd ?? start.subtract(const Duration(hours: 1)),
    rosterLockAt: rosterLock ?? start.subtract(const Duration(minutes: 15)),
    tournamentStartAt: start,
    tournamentEndAt: start.add(const Duration(hours: 3)),
  );

  test('accepts the required schedule ordering', () {
    expect(validSchedule().validate(), isNull);
  });

  test('rejects a roster lock after tournament start', () {
    expect(
      validSchedule(
        rosterLock: start.add(const Duration(minutes: 1)),
      ).validate(),
      'Roster lock must be at or before tournament start.',
    );
  });

  test('rejects a roster lock before registration closes', () {
    expect(
      validSchedule(
        registrationEnd: start.subtract(const Duration(minutes: 10)),
        rosterLock: start.subtract(const Duration(minutes: 20)),
      ).validate(),
      'Roster lock must be at or after registration end.',
    );
  });

  test('estimates waves, breaks, and result buffers per round', () {
    final duration = TournamentSchedule.estimateDuration(
      numberOfTeams: 8,
      concurrentMatches: 2,
      matchDurationMinutes: 45,
      breakDurationMinutes: 15,
    );

    // Round waves: 2 + 1 + 1 = 4. Three buffers and two breaks.
    expect(duration, const Duration(minutes: 255));
  });
}
