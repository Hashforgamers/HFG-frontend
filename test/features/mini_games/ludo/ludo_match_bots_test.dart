import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/ludo/constants.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_match.dart';
import 'package:hash/features/mini_games/ludo/online/ludo_match_service.dart';

LudoMatch _match(Map<LudoPlayerType, LudoSeatInfo> seats) => LudoMatch(
  id: 'm1',
  hostUid: 'host',
  status: LudoMatchStatus.waiting,
  seats: seats,
  invitedUids: const [],
  turn: LudoPlayerType.green,
  dice: 1,
  winners: const [],
  pawns: const {},
  lastWriterUid: 'host',
  version: 0,
  turnStartedAtMs: 0,
  roomCode: 'ABC234',
  quick: true,
  quickOpen: true,
  createdAtMs: 42,
);

void main() {
  test('bot seats round-trip and are reported as bots', () {
    final m = _match({
      LudoPlayerType.green: const LudoSeatInfo(uid: 'host', name: 'Zara'),
      LudoPlayerType.yellow: const LudoSeatInfo(
        uid: 'bot_1',
        name: 'Rohan',
        bot: true,
      ),
    });
    final back = LudoMatch.fromMap(m.id, m.toMap());
    expect(back.botSeats, {LudoPlayerType.yellow});
    expect(back.humanCount, 1);
    expect(back.roomCode, 'ABC234');
    expect(back.quick, isTrue);
    expect(back.quickOpen, isTrue);
    expect(back.createdAtMs, 42);
    // Human seats don't write a bot flag at all.
    expect((m.toMap()['seats'] as Map)['green'], isNot(contains('bot')));
  });

  test('bot driver is the first human in turn order', () {
    final m = _match({
      LudoPlayerType.green: const LudoSeatInfo(
        uid: 'bot_1',
        name: 'Rohan',
        bot: true,
      ),
      LudoPlayerType.blue: const LudoSeatInfo(uid: 'b', name: 'B'),
      LudoPlayerType.red: const LudoSeatInfo(uid: 'r', name: 'R'),
    });
    expect(m.botDriverUid, 'b');

    final botsOnly = _match({
      LudoPlayerType.green: const LudoSeatInfo(
        uid: 'bot_1',
        name: 'Rohan',
        bot: true,
      ),
    });
    expect(botsOnly.botDriverUid, isNull);
  });

  test('older match docs without the new fields still parse', () {
    final legacy = LudoMatch.fromMap('old', {
      'host_uid': 'h',
      'status': 'waiting',
      'seats': {
        'green': {'uid': 'h', 'name': 'H'},
      },
    });
    expect(legacy.roomCode, isEmpty);
    expect(legacy.quick, isFalse);
    expect(legacy.botSeats, isEmpty);
  });

  test('rematch pointer round-trips and is absent until requested', () {
    final m = _match(const {});
    expect(m.toMap(), isNot(contains('rematch_id')));
    final asked = LudoMatch.fromMap(m.id, {
      ...m.toMap(),
      'rematch_id': 'm2',
      'rematch_by': 'Zara Khan',
    });
    expect(asked.rematchId, 'm2');
    expect(asked.rematchBy, 'Zara Khan');
    expect(LudoMatch.fromMap(m.id, asked.toMap()).rematchId, 'm2');
  });

  test('room codes are normalised from what people type', () {
    expect(LudoMatchService.normalizeRoomCode(' abc-234 '), 'ABC234');
  });

  test('invite message carries the code and a tappable https link', () {
    final msg = LudoMatchService.inviteMessage(_match(const {}));
    expect(msg, contains('ABC234'));
    expect(msg, contains('https://hashforgamers.co.in/game/ludomatch_m1'));
  });
}
