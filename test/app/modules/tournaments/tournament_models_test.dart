import 'package:flutter_test/flutter_test.dart';
import 'package:hash/app/modules/tournaments/data/tournament_models.dart';

void main() {
  test('tournament parses serializer fields and lifecycle', () {
    final t = Tournament.fromJson({
      'id': 't1',
      'title': 'Friday Cup',
      'status': 'registration_open',
      'entry_fee': '50',
      'max_players': 2,
      'registered_players_count': 2,
      'team_mode': 'squad',
      'team_size': 4,
      'prize_distribution': [
        {'rank': 1, 'percent': 70},
      ],
    });
    expect(t.status, TStatus.registrationOpen);
    expect(t.entryFee, 50);
    expect(t.isFree, isFalse);
    expect(t.isFull, isTrue);
    expect(t.isSolo, isFalse);
    expect(t.prizeDistribution.single.percent, 70);
    expect(TStatus.parse('weird'), TStatus.unknown);
  });

  test('/me bootstrap exposes actions, team and current match', () {
    final me = MyTournamentState({
      'registration': {'id': 'r1', 'status': 'pending_payment'},
      'team': {
        'id': 'team1',
        'name': 'Phoenix',
        'status': 'pending',
        'members': [
          {'user_id': 1, 'role': 'captain'},
          {'user_id': 2, 'role': 'player', 'verification_status': 'invited'},
        ],
      },
      'current_match': {'id': 'm1', 'status': 'in_progress'},
      'actions': {'can_continue_payment': true, 'can_play': false},
    });
    expect(me.registration!.isPendingPayment, isTrue);
    expect(me.canContinuePayment, isTrue);
    expect(me.canPlay, isFalse);
    expect(me.team!.members.where((m) => m.accepted).length, 1);
    expect(me.currentMatch!.statusLabel, 'In progress');
    expect(me.tournament, isNull);
  });

  test('result state reads viewer flags and the pending proposal', () {
    final rs = ResultState({
      'viewer': {'can_accept_pending_proposal': true},
      'proposals': [
        {'id': 'p0', 'status': 'expired'},
        {'id': 'p1', 'status': 'pending', 'team_a_score': 2, 'team_b_score': 1},
      ],
      'active_dispute': {'id': 'd1', 'status': 'open', 'chat_room_status': 'ready', 'chat_room_id': 'room'},
    });
    expect(rs.canAccept, isTrue);
    expect(rs.canDisputeProposal, isFalse);
    expect(rs.pendingProposal!.id, 'p1');
    expect(rs.activeDispute!.chatReady, isTrue);
  });

  test('paginated accepts items+pagination and bare lists', () {
    final p = Paginated.fromJson({
      'items': [
        {'id': 'a'},
      ],
      'pagination': {'page': 1, 'pages': 3, 'total': 21},
    }, Payout.new);
    expect(p.items.single.id, 'a');
    expect(p.hasMore, isTrue);
    final bare = Paginated.fromJson([
      {'id': 'b'},
    ], Payout.new);
    expect(bare.items.single.id, 'b');
    expect(bare.hasMore, isFalse);
  });
}
