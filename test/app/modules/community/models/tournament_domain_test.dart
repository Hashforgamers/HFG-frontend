import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/community/models/host_verification.dart';
import 'package:hash/app/modules/community/models/tournament.dart';
import 'package:hash/app/modules/community/models/tournament_domain.dart';
import 'package:hash/app/modules/community/models/tournament_operations.dart';

void main() {
  group('safe status parsing', () {
    test('maps known and alias tournament states', () {
      expect(
        tournamentStatusFrom('registration-open'),
        TournamentStatus.registrationOpen,
      );
      expect(tournamentStatusFrom('in progress'), TournamentStatus.live);
      expect(
        tournamentStatusFrom('future_backend_state'),
        TournamentStatus.unknown,
      );
    });

    test('maps registration states without throwing on unknown values', () {
      expect(
        registrationStatusFrom('pending_payment'),
        RegistrationStatus.paymentPending,
      );
      expect(
        registrationStatusFrom('future_backend_state'),
        RegistrationStatus.unknown,
      );
    });

    test('models tolerate missing and unknown values', () {
      final tournament = Tournament.fromJson({
        'id': 42,
        'status': 'future_backend_state',
      });
      final registration = Registration.fromJson({
        'id': 'r1',
        'status': 'future_backend_state',
      });
      expect(tournament.id, '42');
      expect(tournament.statusValue, TournamentStatus.unknown);
      expect(tournament.canRegister, isFalse);
      expect(registration.statusValue, RegistrationStatus.unknown);
    });

    test('tournament parses esports scheduling configuration', () {
      final tournament = Tournament.fromJson({
        'id': 't1',
        'match_duration_minutes': 45,
        'break_duration_minutes': 15,
        'schedule_config': {'concurrent_matches': 3},
        'team_size': 5,
        'registration_policy': 'manual_approval',
        'rules_config': {'evidence_required': true},
      });
      expect(tournament.matchDurationMinutes, 45);
      expect(tournament.breakDurationMinutes, 15);
      expect(tournament.concurrentMatches, 3);
      expect(tournament.teamSize, 5);
      expect(tournament.registrationPolicy, 'manual_approval');
      expect(tournament.evidenceRequired, isTrue);
    });
  });

  group('capabilities', () {
    test('verified owner can publish a draft', () {
      const capabilities = TournamentCapabilities(
        roles: {TournamentRole.verifiedHost},
        ownsTournament: true,
      );
      expect(capabilities.canPublishTournament(TournamentStatus.draft), isTrue);
    });

    test('suspended host cannot create, publish, or operate', () {
      const capabilities = TournamentCapabilities(
        roles: {TournamentRole.verifiedHost, TournamentRole.suspendedHost},
        ownsTournament: true,
      );
      expect(capabilities.canCreateTournament, isFalse);
      expect(
        capabilities.canPublishTournament(TournamentStatus.draft),
        isFalse,
      );
      expect(capabilities.canManageMatch(TournamentStatus.live), isFalse);
    });

    test('only an eligible participant can review after completion', () {
      const participant = TournamentCapabilities(isRegistered: true);
      const bystander = TournamentCapabilities();
      expect(
        participant.canReviewTournament(TournamentStatus.completed),
        isTrue,
      );
      expect(
        bystander.canReviewTournament(TournamentStatus.completed),
        isFalse,
      );
    });

    test('free hosting is open but paid hosting requires verification', () {
      const player = TournamentCapabilities();
      expect(player.canCreateTournamentWithFee(paid: false), isTrue);
      expect(player.canCreateTournamentWithFee(paid: true), isFalse);
    });
  });

  group('schedule validation', () {
    test('returns field-specific ordering errors', () {
      final start = DateTime.utc(2026, 8, 10, 12);
      final schedule = TournamentSchedule(
        registrationOpenAt: start.subtract(const Duration(days: 1)),
        registrationCloseAt: start.add(const Duration(hours: 1)),
        rosterLockAt: start.add(const Duration(hours: 2)),
        checkInOpenAt: start.subtract(const Duration(minutes: 30)),
        checkInCloseAt: start.add(const Duration(minutes: 10)),
        tournamentStartAt: start,
        tournamentEndAt: start.subtract(const Duration(minutes: 1)),
      );
      final errors = schedule.validate();
      expect(errors, contains('tournamentStartAt'));
      expect(errors, contains('rosterLockAt'));
      expect(errors, contains('checkInCloseAt'));
      expect(errors, contains('tournamentEndAt'));
    });
  });

  group('lifecycle status', () {
    test('parses the public status response and capacity', () {
      final status = TournamentLifecycleStatus.fromJson({
        'id': 't1',
        'title': 'Friday Cup',
        'status': 'registration_closed',
        'registration_start_at': '2026-07-24T10:00:00Z',
        'registration_end_at': '2026-07-25T10:00:00Z',
        'tournament_start_at': '2026-07-25T12:00:00Z',
        'registered_players_count': 8,
        'max_players': 16,
      });

      expect(status.status, 'registration_closed');
      expect(status.registeredPlayersCount, 8);
      expect(status.maxPlayers, 16);
      expect(status.hasCapacity, isTrue);
      expect(status.tournamentStartAt, DateTime.utc(2026, 7, 25, 12));
    });
  });

  group('host verification', () {
    test('keeps unknown status safe and masks UPI', () {
      final host = HostVerification.fromJson({
        'id': 'h1',
        'verification_status': 'future_state',
        'upi_id': 'playername@bank',
      });
      expect(host.status, HostVerificationStatus.unknown);
      expect(host.maskedUpiId, 'pl••••••••@bank');
    });
  });

  test('maps stable backend error codes to safe messages', () {
    expect(
      tournamentErrorMessage('CAPACITY_REACHED'),
      'This tournament is full.',
    );
    expect(
      tournamentErrorMessage('INTERNAL_TRACE', fallback: 'Please retry.'),
      'Please retry.',
    );
  });
}
