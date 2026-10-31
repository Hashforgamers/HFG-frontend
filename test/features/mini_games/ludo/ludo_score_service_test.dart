import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/ludo/constants.dart';
import 'package:hash/features/mini_games/ludo/ludo_score_service.dart';

void main() {
  const green = LudoPlayerType.green;
  const yellow = LudoPlayerType.yellow;
  const blue = LudoPlayerType.blue;
  final seats = LudoPlayerType.values.toSet();

  test('scores only the identified participant once placement is settled', () {
    expect(
      ludoPlacementScore(
        seat: green,
        winners: [],
        participants: seats,
        finished: false,
      ),
      isNull,
    );
    expect(
      ludoPlacementScore(
        seat: null,
        winners: [green],
        participants: seats,
        finished: true,
      ),
      isNull,
    );
    expect(
      ludoPlacementScore(
        seat: green,
        winners: [green],
        participants: seats,
        finished: false,
      ),
      400,
    );
    expect(
      ludoPlacementScore(
        seat: green,
        winners: [yellow, green],
        participants: seats,
        finished: false,
      ),
      300,
    );
    expect(
      ludoPlacementScore(
        seat: green,
        winners: [yellow, blue, green],
        participants: seats,
        finished: true,
      ),
      200,
    );
    expect(
      ludoPlacementScore(
        seat: green,
        winners: [yellow, blue, LudoPlayerType.red],
        participants: seats,
        finished: true,
      ),
      100,
    );
    expect(
      ludoPlacementScore(
        seat: yellow,
        winners: [green],
        participants: {green, yellow},
        finished: true,
      ),
      300,
    );
    expect(
      ludoPlacementScore(
        seat: green,
        winners: [yellow, yellow],
        participants: seats,
        finished: true,
      ),
      isNull,
    );
  });

  test(
    'failed upload persists, retries, and repeated results do not resubmit',
    () async {
      final disk = <String, int>{};
      final sent = <int>[];
      var connected = false;
      LudoScoreService service() => LudoScoreService(
        currentUid: () => 'alice',
        read: (key) async => disk[key] ?? 0,
        write: (key, value) async {
          disk[key] = value;
        },
        submit: (score) async {
          sent.add(score);
          return connected;
        },
      );
      expect(await service().record(300), isFalse);
      expect(disk['ludo_best_v1_alice'], 300);
      connected = true;
      final restarted = service();
      expect(await restarted.sync(), isTrue);
      expect(await restarted.record(200), isTrue);
      expect(await restarted.record(300), isTrue);
      expect(sent, [300, 300]);
      expect(await restarted.record(400), isTrue);
      expect(sent.last, 400);
    },
  );

  test('pending results cannot be uploaded to a different account', () async {
    final disk = <String, int>{};
    String? uid = 'alice';
    final sent = <int>[];
    var switchOnRead = false;
    final service = LudoScoreService(
      currentUid: () => uid,
      read: (key) async {
        if (switchOnRead) uid = 'bob';
        return disk[key] ?? 0;
      },
      write: (key, value) async {
        disk[key] = value;
      },
      submit: (score) async {
        sent.add(score);
        return true;
      },
    );
    switchOnRead = true;
    expect(await service.record(400), isFalse);
    expect(sent, isEmpty);
    switchOnRead = false;
    expect(await service.sync(), isTrue); // Bob has no queued score.
    expect(sent, isEmpty);
    uid = 'alice';
    expect(await service.sync(), isTrue);
    expect(sent, [400]);
    uid = null;
    expect(await service.record(400), isFalse);
  });

  test(
    'concurrent finishes serialize and preserve the highest score',
    () async {
      final disk = <String, int>{};
      final sent = <int>[];
      final service = LudoScoreService(
        currentUid: () => 'alice',
        read: (key) async => disk[key] ?? 0,
        write: (key, value) async {
          disk[key] = value;
        },
        submit: (score) async {
          sent.add(score);
          return true;
        },
      );
      await Future.wait([
        service.record(200),
        service.record(400),
        service.record(300),
      ]);
      expect(sent, [200, 400]);
      expect(disk['ludo_synced_v1_alice'], 400);
    },
  );
}
