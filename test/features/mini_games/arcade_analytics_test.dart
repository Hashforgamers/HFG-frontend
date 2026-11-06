import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/arcade_analytics.dart';

void main() {
  final events = <(String, Map<String, Object?>)>[];

  setUp(() {
    ArcadeAnalytics.resetForTest();
    events.clear();
    ArcadeAnalytics.testSink = (name, params) => events.add((name, params));
  });
  tearDown(ArcadeAnalytics.resetForTest);

  test('a full session shares one session id and counts its runs', () {
    ArcadeAnalytics.opened('pac_man');
    ArcadeAnalytics.started('pac_man');
    ArcadeAnalytics.completed('pac_man', score: 120, synced: true, rank: 4);
    ArcadeAnalytics.started('pac_man');
    ArcadeAnalytics.closed('pac_man');

    expect(events.map((e) => e.$1), [
      'arcade_game_opened',
      'arcade_game_started',
      'arcade_game_completed',
      'arcade_game_started',
      'arcade_game_closed',
    ]);
    expect(events.map((e) => e.$2['session_id']).toSet(), hasLength(1));
    expect(events.every((e) => e.$2['game_id'] == 'pac_man'), isTrue);
    expect(events[2].$2, containsPair('score', 120));
    expect(events[2].$2, containsPair('synced', 'true'));
    expect(events[2].$2, containsPair('run_no', 1));
    expect(events[4].$2, containsPair('runs', 2));
    expect(events[4].$2, containsPair('completed_runs', 1));
    expect(events[4].$2, containsPair('abandoned', 'true'));
  });

  test('ifIdle ignores a start while a run is already going', () {
    ArcadeAnalytics.opened('laggy_bird');
    ArcadeAnalytics.started('laggy_bird', ifIdle: true);
    ArcadeAnalytics.started('laggy_bird', ifIdle: true);
    expect(events.where((e) => e.$1 == 'arcade_game_started'), hasLength(1));
  });

  test('a pending source wins once, then the default applies', () {
    ArcadeAnalytics.from('leaderboard');
    ArcadeAnalytics.opened('wordly', source: 'home');
    ArcadeAnalytics.opened('wordly');
    expect(events[0].$2['source'], 'leaderboard');
    expect(events[1].$2['source'], 'home');
  });

  test('a game with no start signal still counts completed runs', () {
    ArcadeAnalytics.opened('hash_rush', source: 'mini_games');
    ArcadeAnalytics.completed('hash_rush', score: 9, synced: false);
    ArcadeAnalytics.closed('hash_rush');
    expect(events[1].$2, containsPair('run_no', 1));
    expect(events[1].$2['duration_sec'], isNull);
    expect(events[2].$2, containsPair('abandoned', 'false'));
  });

  test('closing a game that never opened logs nothing', () {
    ArcadeAnalytics.closed('ludo');
    expect(events, isEmpty);
  });

  test('a game page start signal opens a run, a continue does not', () {
    ArcadeAnalytics.opened('hash_rush');
    ArcadeAnalytics.fromWeb('hash_rush', {
      'event': 'hash_rush_game_start',
      'params': {'mode': 'endless'},
    });
    ArcadeAnalytics.fromWeb('hash_rush', {
      'event': 'hash_rush_game_start',
      'params': {'level': 3, 'continued': true},
    });
    ArcadeAnalytics.fromWeb('hash_rush', {'event': 'hash_rush_exit'});
    ArcadeAnalytics.fromWeb('hash_rush', 'nonsense');
    final starts = events.where((e) => e.$1 == 'arcade_game_started').toList();
    expect(starts, hasLength(1));
    expect(starts.single.$2, containsPair('mode', 'endless'));
  });

  test('a late leaderboard answer fills in the completed event', () async {
    ArcadeAnalytics.opened('ludo');
    ArcadeAnalytics.started('ludo', mode: 'quick');
    ArcadeAnalytics.completed(
      'ludo',
      score: 400,
      outcome: Future.value((synced: true, isNewBest: true, rank: 7)),
    );
    // The run closes at once, so a rematch is a new run, not a restart.
    ArcadeAnalytics.started('ludo', mode: 'quick');
    await pumpEventQueue();
    final done = events.singleWhere((e) => e.$1 == 'arcade_game_completed');
    expect(done.$2, containsPair('run_no', 1));
    expect(done.$2, containsPair('synced', 'true'));
    expect(done.$2, containsPair('is_new_best', 'true'));
    expect(done.$2, containsPair('rank', 7));
  });

  test('a lost level ends the run, an endless one waits for its score', () {
    ArcadeAnalytics.opened('hash_rush');
    ArcadeAnalytics.fromWeb('hash_rush', {'event': 'hash_rush_game_start'});
    ArcadeAnalytics.fromWeb('hash_rush', {
      'event': 'hash_rush_level_failed',
      'params': {'level': 1, 'score': 589},
    });
    ArcadeAnalytics.fromWeb('hash_rush', {
      'event': 'hash_rush_level_failed',
      'params': {'mode': 'endless', 'score': 40},
    });
    final done = events.where((e) => e.$1 == 'arcade_game_completed').toList();
    expect(done, hasLength(1));
    expect(done.single.$2, containsPair('score', 589));
  });
}
