import 'package:flutter_test/flutter_test.dart';
import 'package:hash/features/mini_games/road_rumble/rr_engine.dart';
import 'package:hash/features/mini_games/road_rumble/rr_progress.dart';

RrEngine _engine({int level = 1, int bike = 0}) =>
    RrEngine(track: rrTracks.first, level: level, bike: rrBikes[bike]);

/// Holds the centre line (clear of both traffic lanes) at full throttle.
void _ride(RrEngine e, {double seconds = 600}) {
  for (var t = 0.0; t < seconds && e.outcome == RrOutcome.none; t += 1 / 60) {
    final x = e.player.x;
    e.update(
      1 / 60,
      steer: x > 0.04 ? -1 : (x < -0.04 ? 1 : 0),
      gas: true,
      brake: false,
    );
  }
}

void main() {
  test('nobody moves until the countdown ends', () {
    final e = _engine();
    final start = e.player.z;
    for (var i = 0; i < 60; i++) {
      e.update(1 / 60, steer: 0, gas: true, brake: false);
    }
    expect(e.player.z, start);
    expect(e.rivals.every((r) => r.speed == 0), isTrue);
  });

  test('the bike tops out at its rated speed', () {
    final e = _engine();
    _ride(e, seconds: 40);
    expect(e.player.speed, lessThanOrEqualTo(rrBikes[0].topSpeed));
    expect(e.player.speed, greaterThan(rrBikes[0].topSpeed * 0.8));
  });

  test('a clean run reaches the finish with a valid place', () {
    final e = _engine();
    _ride(e);
    expect(e.outcome, RrOutcome.finished);
    expect(e.finishPlace, inInclusiveRange(1, RrEngine.racers));
    // ignore: avoid_print
    print(
      'finished ${e.finishPlace} in ${e.time.toStringAsFixed(1)}s, damage ${e.bikeDamage}',
    );
  });

  test('punching a rider alongside hurts them and can knock them out', () {
    final e = _engine();
    for (var i = 0; i < 240; i++) {
      e.update(1 / 60, steer: 0, gas: false, brake: false);
    }
    final rival = e.rivals.first
      ..z = e.player.z + 300
      ..x = e.player.x + 0.15
      ..stamina = 10;
    e.punch();
    expect(e.player.attackSide, 1);
    for (var i = 0; i < 20; i++) {
      rival.z = e.player.z + 300;
      e.update(1 / 60, steer: 0, gas: false, brake: false);
    }
    expect(rival.down, isTrue);
    expect(e.kos, 1);
  });

  test('driving into roadside scenery wipes out and damages the bike', () {
    final e = _engine();
    for (var t = 0.0; t < 60 && !e.crashed; t += 1 / 60) {
      e.update(1 / 60, steer: 1, gas: true, brake: false);
    }
    expect(e.crashed, isTrue);
    expect(e.bikeDamage, greaterThan(0));
  });

  test('a top-four finish pays out and qualifies the track', () {
    final e = _engine();
    _ride(e);
    e.finishPlace = 2;
    final progress = RrProgress();
    final result = progress.apply(e);
    expect(result.prize, 800);
    expect(result.qualified, isTrue);
    expect(progress.cash, result.prize + result.bonus);
    expect(progress.qualified, {rrTracks.first.id});
    expect(result.score, inInclusiveRange(1, 200));
  });
}
