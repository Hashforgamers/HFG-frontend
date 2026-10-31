import 'dart:math';

/// A bike in the shop. Speeds are world units per second and read as mph
/// when divided by 100.
class RrBike {
  const RrBike(this.name, this.price, this.topSpeed, this.accel, this.handling);

  final String name;
  final int price;
  final double topSpeed;
  final double accel;
  final double handling;

  int get mph => (topSpeed / 100).round();
}

const rrBikes = <RrBike>[
  RrBike('SPARROW 250', 0, 11500, 3600, 1.00),
  RrBike('COYOTE 400', 3000, 12700, 4000, 1.05),
  RrBike('RAZOR 600', 7000, 13900, 4500, 1.10),
  RrBike('TYPHOON 750', 13000, 15000, 5000, 1.12),
  RrBike('INFERNO 900', 22000, 16000, 5600, 1.15),
  RrBike('REAPER 1100', 35000, 17000, 6200, 1.20),
];

enum RrTheme { forest, coast, desert, valley, peaks }

class RrTrack {
  const RrTrack(
    this.id,
    this.name,
    this.theme,
    this.seed,
    this.curves,
    this.hills,
  );

  final String id;
  final String name;
  final RrTheme theme;
  final int seed;

  /// Multipliers on how twisty and how hilly the generated road is.
  final double curves;
  final double hills;
}

const rrTracks = <RrTrack>[
  RrTrack('pine_ridge', 'PINE RIDGE', RrTheme.forest, 11, 0.9, 1.0),
  RrTrack('coast_highway', 'COAST HIGHWAY', RrTheme.coast, 23, 1.0, 0.6),
  RrTrack('dust_bowl', 'DUST BOWL', RrTheme.desert, 37, 0.7, 0.8),
  RrTrack('green_valley', 'GREEN VALLEY', RrTheme.valley, 41, 1.0, 1.2),
  RrTrack('granite_peaks', 'GRANITE PEAKS', RrTheme.peaks, 59, 1.25, 1.4),
];

enum RrProp {
  pine,
  oak,
  palm,
  cactus,
  rock,
  bush,
  pole,
  billboard,
  barn,
  signLeft,
  signRight,
  start,
  finish,
  tuft,
  fence,
}

/// Half-width (in road half-widths) that wipes the player out; 0 = harmless.
double _propRadius(RrProp kind) => switch (kind) {
  RrProp.pine || RrProp.palm || RrProp.cactus => 0.06,
  RrProp.oak => 0.08,
  RrProp.rock => 0.13,
  RrProp.pole => 0.03,
  RrProp.billboard => 0.25,
  RrProp.barn => 0.45,
  RrProp.signLeft || RrProp.signRight => 0.06,
  RrProp.fence => 0.15,
  RrProp.bush || RrProp.tuft || RrProp.start || RrProp.finish => 0,
};

class RrRoadside {
  const RrRoadside(this.kind, this.x);

  final RrProp kind;

  /// Offset from the centre line in road half-widths.
  final double x;
}

/// A sum of money rising from a blow just landed.
class RrPopup {
  RrPopup(this.text, this.side, {this.big = false});

  static const double life = 1.5;

  final String text;
  final int side;

  /// A combo or a knockout, shown larger and in gold.
  final bool big;
  double age = 0;
}

class RrRider {
  RrRider({
    required this.name,
    required this.look,
    this.isCop = false,
    this.top = 0,
    this.accel = 0,
    this.aggression = 0,
    this.clumsy = 0,
    this.maxStamina = 100,
    this.homeX = 0.5,
  }) : stamina = maxStamina;

  final String name;

  /// Index into the rider sprite palettes.
  final int look;
  final bool isCop;
  final double top;
  final double accel;
  final double aggression;

  /// Chance of not noticing a car until it's too late.
  final double clumsy;
  final double maxStamina;
  final double homeX;

  double x = 0;
  double z = 0;
  double speed = 0;
  double stamina;
  bool club = false;

  /// -1..1, drives the lean frames.
  double lean = 0;

  // Attack animation: counts down from [RrEngine.attackTime].
  double attackT = 0;
  int attackSide = 1;
  bool attackKick = false;
  bool attackLanded = false;
  double cooldown = 0;

  /// Seconds left lying on the road after a wipeout.
  double downT = 0;
  double? finishTime;

  // AI scratch state.
  double targetX = 0;
  double thinkT = 0;
  RrCar? seenCar;
  bool blind = false;

  bool get down => downT > 0;
}

class RrCar {
  RrCar(this.x, this.z, this.speed, this.look);

  final double x;
  double z;

  /// Negative for oncoming traffic.
  final double speed;
  final int look;
  double prevZ = 0;

  bool get oncoming => speed < 0;

  /// Half the vehicle's length: every fourth one is a lorry, and another
  /// fourth are short vans.
  double get halfLen => look % 4 == 3 ? 2500 : (look % 4 == 1 ? 720 : 900);
}

enum RrOutcome { none, finished, busted, wrecked }

/// Pure simulation for one race: a pseudo-3D road built from segments, the
/// player's bike, rival riders, traffic and police. No Flutter imports so it
/// can be unit tested; the renderer reads its state every frame.
class RrEngine {
  RrEngine({required this.track, required this.level, required this.bike})
    : _rng = Random(track.seed * 7919 + level) {
    _buildRoad();
    _placeProps();
    _spawnRiders();
    _spawnTraffic();
  }

  static const double segL = 200;
  static const double roadW = 3200;
  static const double camH = 1000;
  static const double camDepth = 0.84;

  /// How far ahead of the camera the player's bike sits.
  static const double playerDist = camH * camDepth * 1.6;
  static const double attackTime = 0.32;
  static const int racers = 15;

  static const _names = [
    'MADDOX',
    'ROXY',
    'TANK',
    'VENOM',
    'DUKE',
    'RAZOR',
    'JINX',
    'BRUNO',
    'SPIKE',
    'NITRO',
    'KNOX',
    'BLAZE',
    'GRIM',
    'DIESEL',
  ];

  final RrTrack track;
  final int level;
  final RrBike bike;
  final Random _rng;

  // Road geometry: point i is the start of segment i.
  final List<double> _y = [0];
  final List<double> _curve = [];
  late final List<List<RrRoadside>?> props;
  late final int finishSeg;

  final RrRider player = RrRider(name: 'YOU', look: 0);
  final List<RrRider> rivals = [];
  final List<RrRider> cops = [];
  final List<RrCar> cars = [];

  /// Sounds/haptics raised by the last [update].
  final List<String> events = [];

  double countdown = 3.2;
  double time = 0;
  RrOutcome outcome = RrOutcome.none;

  /// Seconds since the race ended, for the screen to time the results.
  double endT = 0;
  int finishPlace = 0;
  int kos = 0;
  double bikeDamage = 0;
  double skyOffset = 0;

  /// Brief impact spark beside the player when a blow lands.
  double flashT = 0;

  /// Money earned by landing blows this race, and the sums still floating
  /// up the screen from the latest ones.
  int fightCash = 0;
  final List<RrPopup> popups = [];
  int _comboHits = 0;
  int _comboCash = 0;
  int _comboSide = 1;
  double _comboT = 0;

  /// Red wash after taking a blow.
  double hurtT = 0;

  /// Cars skimmed past at speed; each pays a bonus.
  int nearMisses = 0;
  int _lastPlace = 0;
  int flashSide = 1;

  String? message;
  double messageT = 0;

  // Wipeout: tumble off the bike, then run back to it.
  double _crashT = 0;
  double _tumbleT = 0;
  double _runT = 0;
  double _thrown = 0;

  final List<double> _copTriggers = [];
  double _copTimer = 0;
  double _sirenT = 0;

  int get segCount => _curve.length;
  double get finishZ => finishSeg * segL;
  double get mph => player.speed / 100;
  double get progress => (player.z / finishZ).clamp(0.0, 1.0);
  bool get crashed => _crashT > 0;

  /// Seconds since the current wipeout began.
  double get crashAge => _crashT;
  bool get tumbling => _crashT > 0 && _crashT <= _tumbleT;
  bool get offRoad => player.x.abs() > 1.04;
  bool get copActive => cops.isNotEmpty;

  /// How far ahead of the bike the thrown rider currently is.
  double get riderOffset {
    if (_crashT <= 0) return 0;
    if (_crashT <= _tumbleT) {
      final p = _crashT / _tumbleT;
      return _thrown * (1 - (1 - p) * (1 - p));
    }
    return _thrown * (1 - (_crashT - _tumbleT) / _runT).clamp(0.0, 1.0);
  }

  double curveAt(int seg) => _curve[seg.clamp(0, segCount - 1)];
  double pointY(int i) => _y[i.clamp(0, _y.length - 1)];

  double heightAt(double z) {
    final f = z / segL;
    final i = f.floor().clamp(0, segCount - 1);
    return _y[i] + (_y[i + 1] - _y[i]) * (f - i).clamp(0.0, 1.0);
  }

  int get place {
    if (finishPlace > 0) return finishPlace;
    var ahead = 0;
    for (final r in rivals) {
      if (r.finishTime != null || r.z > player.z) ahead++;
    }
    return ahead + 1;
  }

  static String ordinal(int n) {
    final suffix = (n % 100 >= 11 && n % 100 <= 13)
        ? 'TH'
        : switch (n % 10) {
            1 => 'ST',
            2 => 'ND',
            3 => 'RD',
            _ => 'TH',
          };
    return '$n$suffix';
  }

  /// Everyone in race order: finishers by time, then the rest by distance.
  List<RrRider> get standings {
    final all = [player, ...rivals];
    all.sort((a, b) {
      final ta = a.finishTime, tb = b.finishTime;
      if (ta != null && tb != null) return ta.compareTo(tb);
      if (ta != null) return -1;
      if (tb != null) return 1;
      return b.z.compareTo(a.z);
    });
    return all;
  }

  /// The closest rider worth showing in the HUD, if any.
  RrRider? get nearRider {
    RrRider? best;
    var bestD = 1500.0;
    for (final r in [...cops, ...rivals]) {
      final d = (r.z - player.z).abs();
      if (d < bestD) {
        bestD = d;
        best = r;
      }
    }
    return best;
  }

  // ------------------------------------------------------------- building

  void _addRoad(int enter, int hold, int leave, double curve, double hill) {
    final startY = _y.last;
    final total = enter + hold + leave;
    final endY = startY + hill * segL;
    var n = 0;
    void add(double c) {
      n++;
      _curve.add(c);
      final p = n / total;
      _y.add(startY + (endY - startY) * (0.5 - cos(p * pi) / 2));
    }

    for (var i = 0; i < enter; i++) {
      final p = i / enter;
      add(curve * p * p);
    }
    for (var i = 0; i < hold; i++) {
      add(curve);
    }
    for (var i = 0; i < leave; i++) {
      final p = i / leave;
      add(curve * (1 - p) * (1 - p));
    }
  }

  void _buildRoad() {
    final rng = Random(track.seed + level * 101);
    final target = 4200 + level * 700;
    _addRoad(0, 60, 0, 0, 0);
    while (_curve.length < target) {
      final roll = rng.nextDouble();
      final len = 20 + rng.nextInt(50);
      final c =
          (rng.nextBool() ? 1 : -1) *
          (1.0 + rng.nextDouble() * 3.2) *
          track.curves;
      var h = (rng.nextDouble() * 2 - 1) * 45 * track.hills;
      final endY = _y.last + h * segL;
      if (endY > 9000 || endY < -6000) h = -h;
      if (roll < 0.25) {
        _addRoad(0, len * 2, 0, 0, 0);
      } else if (roll < 0.55) {
        _addRoad(len, len, len, c, 0);
      } else if (roll < 0.8) {
        _addRoad(len, len, len, 0, h);
      } else {
        _addRoad(len, len, len, c, h);
      }
    }
    _addRoad(0, 160, 0, 0, 0);
    finishSeg = _curve.length - 120;
  }

  void _placeProps() {
    final rng = Random(track.seed * 31 + 5);
    props = List<List<RrRoadside>?>.filled(segCount, null);
    void put(int i, RrProp kind, double x) =>
        (props[i] ??= []).add(RrRoadside(kind, x));

    final (common, rare, density) = switch (track.theme) {
      RrTheme.forest => (
        [RrProp.pine, RrProp.pine, RrProp.pine, RrProp.bush, RrProp.rock],
        [RrProp.billboard, RrProp.barn],
        0.55,
      ),
      RrTheme.coast => (
        [RrProp.palm, RrProp.palm, RrProp.bush, RrProp.rock],
        [RrProp.billboard, RrProp.billboard, RrProp.barn],
        0.32,
      ),
      RrTheme.desert => (
        [RrProp.cactus, RrProp.cactus, RrProp.rock, RrProp.bush],
        [RrProp.billboard, RrProp.barn],
        0.24,
      ),
      RrTheme.valley => (
        [RrProp.oak, RrProp.oak, RrProp.bush, RrProp.pine],
        [RrProp.barn, RrProp.barn, RrProp.billboard],
        0.36,
      ),
      RrTheme.peaks => (
        [RrProp.pine, RrProp.rock, RrProp.rock, RrProp.pine, RrProp.bush],
        [RrProp.billboard],
        0.45,
      ),
    };

    final fences =
        track.theme == RrTheme.valley || track.theme == RrTheme.forest;
    for (var i = 24; i < segCount - 4; i++) {
      if (i % 18 == 0) put(i, RrProp.pole, -1.2);
      // Verge grass right at the roadside sells the speed.
      if (rng.nextDouble() < 0.4) {
        put(
          i,
          RrProp.tuft,
          (rng.nextBool() ? 1 : -1) * (1.1 + rng.nextDouble() * 0.3),
        );
      }
      if (fences && (i ~/ 70) % 3 == 0 && i % 6 == 0) put(i, RrProp.fence, 1.6);
      final c = _curve[i];
      if (c.abs() > 2.2 && i % 10 == 0) {
        // Chevrons on the outside of sharp bends.
        put(
          i,
          c > 0 ? RrProp.signRight : RrProp.signLeft,
          c > 0 ? -1.14 : 1.14,
        );
      }
      for (var k = 0; k < 2; k++) {
        if (rng.nextDouble() >= density) continue;
        final side = rng.nextBool() ? 1.0 : -1.0;
        if (rng.nextDouble() < 0.03) {
          final kind = rare[rng.nextInt(rare.length)];
          final edge = kind == RrProp.barn ? 2.2 : 1.6;
          put(i, kind, side * (edge + rng.nextDouble() * 0.8));
        } else {
          final kind = common[rng.nextInt(common.length)];
          put(i, kind, side * (1.28 + rng.nextDouble() * 2.3));
        }
      }
    }
    put(18, RrProp.start, 0);
    put(finishSeg, RrProp.finish, 0);
  }

  void _spawnRiders() {
    const startZ = 2400.0;
    player
      ..x = 0.5
      ..z = startZ;

    final levelTop = 10200.0 + 1200 * level;
    final order = List<int>.generate(_names.length, (i) => i)..shuffle(_rng);
    final clubs = min(2 + level, 8);
    for (var i = 0; i < _names.length; i++) {
      final skill = 0.88 + 0.15 * i / (_names.length - 1);
      final id = order[i];
      final r =
          RrRider(
              name: _names[id],
              look: 1 + id,
              top: levelTop * skill,
              accel: 3300 + level * 300 + _rng.nextDouble() * 600,
              aggression: 0.25 + _rng.nextDouble() * 0.65 + level * 0.03,
              clumsy: 0.05 + _rng.nextDouble() * 0.12,
              maxStamina: 40 + _rng.nextDouble() * 40 + level * 6,
              homeX: 0.15 + _rng.nextDouble() * 0.6,
            )
            // A ragged grid: two loose files, nobody quite level or in line.
            ..x = (i.isEven ? 0.24 : 0.7) + (_rng.nextDouble() - 0.5) * 0.3
            ..z =
                startZ + 420 + (i ~/ 2) * 360 + (_rng.nextDouble() - 0.5) * 300
            ..club = i >= _names.length - clubs && i.isEven;
      r.targetX = r.x;
      rivals.add(r);
    }

    final count = level >= 3 ? 3 : 2;
    for (var i = 0; i < count; i++) {
      _copTriggers.add(
        finishZ * ((i + 0.6) / (count + 0.6) + _rng.nextDouble() * 0.08),
      );
    }
  }

  void _spawnTraffic() {
    final scale = 1 + 0.15 * (level - 1);
    final end = finishZ - 6000;
    // Same direction, right lane.
    for (
      var z = 15000.0;
      z < end;
      z += (16000 + _rng.nextDouble() * 20000) / scale
    ) {
      cars.add(
        RrCar(
          _rng.nextBool() ? 0.25 : 0.75,
          z,
          4500 + _rng.nextDouble() * 1800,
          _rng.nextInt(8),
        ),
      );
    }
    // Oncoming, left lane. They drive toward the start, so spread them well
    // past the finish too.
    for (
      var z = 30000.0;
      z < end * 1.6;
      z += (38000 + _rng.nextDouble() * 50000) / scale
    ) {
      cars.add(
        RrCar(
          _rng.nextBool() ? -0.25 : -0.75,
          z,
          -(4800 + _rng.nextDouble() * 1500),
          _rng.nextInt(8),
        ),
      );
    }
  }

  // --------------------------------------------------------------- input

  void punch() => _attack(false);
  void kick() => _attack(true);

  /// Distance from the sweet spot for a blow: riders a little ahead of the
  /// player, where the first-person camera can see them.
  double _reach(RrRider r) => (r.z - player.z - 300).abs();

  void _attack(bool kick) {
    if (countdown > 0 || crashed || outcome != RrOutcome.none) return;
    if (player.attackT > 0) return;
    // Swing at whoever is closest; default to the right-hand side.
    var side = 1;
    var best = double.infinity;
    for (final r in [...rivals, ...cops]) {
      if (r.down) continue;
      final dz = _reach(r);
      final dx = r.x - player.x;
      if (dz < 600 && dx.abs() < 0.4 && dz < best) {
        best = dz;
        side = dx < 0 ? -1 : 1;
      }
    }
    player
      ..attackSide = side
      ..attackKick = kick
      ..attackLanded = false
      ..attackT = attackTime;
    events.add('swing');
  }

  // -------------------------------------------------------------- update

  void update(
    double dt, {
    required double steer,
    required bool gas,
    required bool brake,
  }) {
    events.clear();
    if (flashT > 0) flashT -= dt;
    for (final popup in popups) {
      popup.age += dt;
    }
    popups.removeWhere((popup) => popup.age > RrPopup.life);
    if (_comboT > 0) {
      _comboT -= dt;
      if (_comboT <= 0 || crashed || outcome != RrOutcome.none) _bank();
    }
    if (hurtT > 0) hurtT -= dt;
    if (messageT > 0) {
      messageT -= dt;
      if (messageT <= 0) message = null;
    }
    if (countdown > 0) {
      final before = countdown.ceil();
      countdown -= dt;
      if (countdown <= 0) {
        events.add('go');
      } else if (countdown.ceil() != before) {
        events.add('beep');
      }
      return;
    }
    if (outcome == RrOutcome.none) {
      time += dt;
    } else {
      endT += dt;
    }
    for (final car in cars) {
      car.prevZ = car.z;
      car.z += car.speed * dt;
    }
    _updatePlayer(dt, steer, gas, brake);
    for (final r in rivals) {
      _updateRider(r, dt);
    }
    _updateCops(dt);
  }

  void _say(String text, [double seconds = 1.6]) {
    message = text;
    messageT = seconds;
  }

  void _updatePlayer(double dt, double steer, bool gas, bool brake) {
    final p = player;
    final racing = outcome == RrOutcome.none;
    if (crashed) {
      _updateCrash(dt);
      return;
    }
    if (!racing) {
      steer = 0;
      gas = false;
      brake = outcome != RrOutcome.finished;
    }

    final top = bike.topSpeed;
    final pct = p.speed / top;
    final seg = (p.z / segL).floor();
    final rate = p.speed < 60
        ? 0.0
        : dt * 0.95 * bike.handling * (0.25 + 0.75 * min(1.0, pct * 1.4));
    p.x += steer * rate;
    p.x -= rate * pct * curveAt(seg) * 0.2;
    p.x = p.x.clamp(-1.7, 1.7);
    p.lean += (steer - p.lean) * min(1.0, dt * 9);
    skyOffset += curveAt(seg) * pct * dt * 14;

    if (brake) {
      p.speed -= 9000 * dt;
    } else if (gas) {
      p.speed += bike.accel * (1 - pct * pct * 0.85) * dt;
    } else {
      p.speed -= (racing ? 1800 : 3500) * dt;
    }
    if (offRoad && p.speed > 4500) p.speed -= 9000 * dt;
    p.speed = p.speed.clamp(0.0, top);

    final oldZ = p.z;
    p.z += p.speed * dt;
    p.stamina = min(p.maxStamina, p.stamina + 3 * dt);

    if (p.attackT > 0) {
      p.attackT -= dt;
      if (!p.attackLanded && p.attackT <= attackTime - 0.12) {
        p.attackLanded = true;
        _landPlayerHit();
      }
    }

    // Shoulder-to-shoulder: nudge apart rather than passing through.
    for (final r in [...rivals, ...cops]) {
      if (r.down || (r.z - p.z).abs() > 200) continue;
      final dx = r.x - p.x;
      if (dx.abs() < 0.08) {
        final push = (0.08 - dx.abs()) / 2 * (dx < 0 ? -1 : 1);
        p.x -= push;
        r.x += push;
      }
    }

    if (!racing) return;

    if (p.x.abs() > 1.05) {
      final last = min((p.z / segL).floor(), segCount - 1);
      for (var i = (oldZ / segL).floor() + 1; i <= last; i++) {
        final list = props[i];
        if (list == null) continue;
        for (final prop in list) {
          final radius = _propRadius(prop.kind);
          if (radius > 0 && (prop.x - p.x).abs() < radius + 0.04) {
            _crash();
            return;
          }
        }
      }
    }

    for (final car in cars) {
      final before = car.prevZ - oldZ;
      final now = car.z - p.z;
      final side = (car.x - p.x).abs();
      if (side > 0.155) {
        // Skimming past a car at speed.
        if (side < 0.24 &&
            before.sign != now.sign &&
            (p.speed - car.speed).abs() > 5000) {
          nearMisses++;
          events.add('whoosh');
          _say('CLOSE CALL!', 0.9);
        }
        continue;
      }
      if (now.abs() > car.halfLen && before.sign == now.sign) continue;
      if (car.oncoming || (p.speed - car.speed).abs() > 1500) {
        _crash();
        return;
      }
      // A gentle touch from behind just scrubs speed.
      if (now >= 0) {
        p.speed = car.speed * 0.9;
        p.z = car.z - car.halfLen - 5;
      }
    }

    // Call out places gained.
    final current = place;
    if (_lastPlace != 0 &&
        current < _lastPlace &&
        message == null &&
        time > 3) {
      _say('${ordinal(current)} PLACE', 1.0);
    }
    _lastPlace = current;

    if (p.z >= finishZ) {
      finishPlace = place;
      p.finishTime = time;
      outcome = RrOutcome.finished;
      events.add('finish');
      _say('FINISH!', 3);
    }
  }

  void _landPlayerHit() {
    final p = player;
    final side = p.attackSide;
    RrRider? target;
    var best = 520.0;
    for (final r in [...rivals, ...cops]) {
      if (r.down) continue;
      final dz = _reach(r);
      final dx = (r.x - p.x) * side;
      if (dz < best && dx > 0 && dx < 0.3) {
        best = dz;
        target = r;
      }
    }
    if (target == null) return;
    final kick = p.attackKick;
    target.stamina -= kick ? 7 : (p.club ? 26 : 13);
    target.x += side * (kick ? 0.15 : 0.05);
    target.speed *= kick ? 0.97 : 0.99;
    target.cooldown = max(target.cooldown, 0.35);
    events.add('hit');
    // Blows in quick succession build a combo, each worth more than the
    // last; it is paid as one sum when the exchange ends.
    _comboHits++;
    _comboCash +=
        min(10 + 10 * _comboHits, 60) * level +
        (p.club && !kick ? 10 * level : 0);
    _comboSide = side;
    _comboT = 1.3;
    flashT = 0.12;
    flashSide = side;
    if (!kick && target.club && !p.club) {
      // Punching a rider mid-swing takes the club out of their hands.
      if (target.attackT > 0 || _rng.nextDouble() < 0.3) {
        target.club = false;
        target.attackT = 0;
        p.club = true;
        _comboCash += 50 * level;
        events.add('club');
        _say('GOT THE CLUB!');
      }
    }
    if (target.stamina <= 0) {
      _knockDown(target);
      kos++;
      _comboCash += 150 * level;
      _bank('KNOCKOUT ');
      events.add('ko');
      _say('${target.name} IS DOWN!');
    }
  }

  /// Pays out the exchange just ended and floats the sum up the screen.
  void _bank([String? label]) {
    if (_comboCash <= 0) return;
    fightCash += _comboCash;
    final name = label ?? (_comboHits >= 2 ? '$_comboHits HIT COMBO ' : '');
    popups.add(
      RrPopup(
        '$name+\$$_comboCash',
        _comboSide,
        big: label != null || _comboHits >= 3,
      ),
    );
    if (popups.length > 4) popups.removeAt(0);
    _comboHits = 0;
    _comboCash = 0;
    _comboT = 0;
  }

  void _knockDown(RrRider r) {
    r
      ..downT = 3.5 + _rng.nextDouble()
      ..attackT = 0
      ..stamina = 0;
  }

  void _crash() {
    if (crashed) return;
    final p = player;
    final hit = p.speed;
    _tumbleT = 1.1;
    _runT = (hit / 12000 * 2.2).clamp(0.6, 2.4);
    _thrown = min(hit * 0.25, 3000);
    _crashT = 0.0001;
    p
      ..attackT = 0
      ..lean = 0;
    bikeDamage = min(100, bikeDamage + 7 + 13 * hit / 12000);
    events.add('crash');
    if (bikeDamage >= 100) {
      outcome = RrOutcome.wrecked;
      events.add('wrecked');
      _say('BIKE WRECKED', 4);
    } else {
      _say('WIPEOUT!');
    }
  }

  void _updateCrash(double dt) {
    final p = player;
    _crashT += dt;
    p.speed = max(0, p.speed - 14000 * dt);
    p.z += p.speed * dt;
    if (_crashT > _tumbleT) {
      // Walk the bike back onto the tarmac while the rider runs to it.
      final safe = p.x.clamp(-0.85, 0.85);
      p.x += (safe - p.x) * min(1.0, dt * 3);
    }
    if (_crashT >= _tumbleT + _runT && outcome == RrOutcome.none) {
      _crashT = 0;
      p
        ..x = p.x.clamp(-0.9, 0.9)
        ..stamina = max(p.stamina, p.maxStamina * 0.5);
    }
  }

  void _updateRider(RrRider r, double dt) {
    final p = player;
    if (r.finishTime != null) {
      r.speed = max(0, r.speed - 5000 * dt);
      r.z += r.speed * dt;
      return;
    }
    if (r.down) {
      r.downT -= dt;
      r.speed = max(0, r.speed - 12000 * dt);
      r.z += r.speed * dt;
      if (r.downT <= 0) {
        r
          ..stamina = r.maxStamina * 0.7
          ..x = r.x.clamp(-0.8, 0.8);
      }
      return;
    }

    final seg = (r.z / segL).floor();
    final gap = r.z - p.z;
    double target;
    if (r.isCop) {
      if (crashed) {
        // Roll up to the fallen rider and stop.
        target = gap < -300 ? min(6000.0, -gap * 2) : 0;
      } else {
        target = min(r.top, max(p.speed * 1.06 + 300, 6000));
        if (gap > 600) target = p.speed * 0.9;
        // Out of patience: drop back until out of sight.
        if (_copTimer <= 0) target = p.speed * 0.6;
      }
    } else {
      // Rubber band: the pack eases off ahead of you and pushes from behind.
      final band = outcome == RrOutcome.none
          ? 1 - (gap / 40000).clamp(-0.12, 0.06)
          : 1.0;
      target = r.top * band * (1 - min(0.15, curveAt(seg).abs() * 0.02));
    }
    r.speed += (target - r.speed).clamp(-6000 * dt, r.accel * dt);
    if (r.speed < 0) r.speed = 0;

    r.thinkT -= dt;
    if (r.thinkT <= 0) {
      r.thinkT = 0.2 + _rng.nextDouble() * 0.25;
      _think(r);
    }
    final move = (r.targetX - r.x).clamp(-0.6 * dt, 0.6 * dt);
    r.x += move;
    r.lean +=
        ((move / (0.6 * dt)).clamp(-1.0, 1.0) * 0.7 - r.lean) *
        min(1.0, dt * 8);

    final oldZ = r.z;
    r.z += r.speed * dt;

    for (final car in cars) {
      if ((car.x - r.x).abs() > 0.15) continue;
      final before = car.prevZ - oldZ;
      final now = car.z - r.z;
      if (now.abs() > car.halfLen && before.sign == now.sign) continue;
      _knockDown(r);
      return;
    }

    if (!r.isCop && r.z >= finishZ) {
      r.finishTime = time;
      return;
    }

    // Fighting the player.
    r.cooldown -= dt;
    final dxp = p.x - r.x;
    final adjacent =
        !crashed &&
        (gap - 250).abs() < 450 &&
        dxp.abs() < 0.3 &&
        dxp.abs() > 0.03;
    if (r.attackT > 0) {
      r.attackT -= dt;
      if (!r.attackLanded && r.attackT <= 0.22) {
        r.attackLanded = true;
        if (adjacent && dxp.sign == r.attackSide && outcome == RrOutcome.none) {
          p.stamina -= r.club ? 12 : 6;
          p.x += r.attackSide * 0.06;
          events.add('hurt');
          hurtT = 0.35;
          flashT = 0.12;
          flashSide = -r.attackSide;
          if (p.stamina <= 0) {
            p.stamina = 0;
            _crash();
          }
        }
      }
    } else if (adjacent && r.cooldown <= 0 && outcome == RrOutcome.none) {
      if (_rng.nextDouble() < r.aggression * dt * 1.8) {
        r
          ..attackSide = dxp < 0 ? -1 : 1
          ..attackKick = false
          ..attackLanded = false
          ..attackT = 0.42
          ..cooldown = 2.0 + _rng.nextDouble();
      }
    }
  }

  void _think(RrRider r) {
    final p = player;
    var want = r.homeX;
    final gap = r.z - p.z;
    if (!crashed && gap.abs() < 700 && (r.isCop || r.aggression > 0.55)) {
      want = p.x + (r.x < p.x ? -0.15 : 0.15);
    }
    for (final o in rivals) {
      if (identical(o, r) || o.down) continue;
      if ((o.z - r.z).abs() < 300 && (o.x - want).abs() < 0.11) {
        want += r.x >= o.x ? 0.13 : -0.13;
      }
    }
    // Dodge the nearest car in the way.
    RrCar? threat;
    var nearest = double.infinity;
    for (final car in cars) {
      final d = car.z - r.z;
      final reach = (r.speed - car.speed) * 1.6 + 400;
      if (d > -200 && d < reach && d < nearest) {
        nearest = d;
        threat = car;
      }
    }
    if (threat != null) {
      if (!identical(threat, r.seenCar)) {
        r.seenCar = threat;
        r.blind = _rng.nextDouble() < r.clumsy;
      }
      if (!r.blind && (threat.x - want).abs() < 0.25) {
        want = threat.x > 0 ? threat.x - 0.3 : threat.x + 0.3;
      }
    }
    r.targetX = want.clamp(-0.9, 0.9);
  }

  void _updateCops(double dt) {
    final p = player;
    if (outcome == RrOutcome.none &&
        cops.isEmpty &&
        _copTriggers.isNotEmpty &&
        p.z > _copTriggers.first) {
      _copTriggers.removeAt(0);
      final cop =
          RrRider(
              name: 'SGT. DOYLE',
              look: 15,
              isCop: true,
              top: (10200.0 + 1200 * level) * 1.05,
              accel: 5200,
              aggression: 0.9,
              maxStamina: 70 + level * 8,
            )
            ..x = 0.1
            ..z = p.z - 2600
            ..speed = p.speed
            ..targetX = 0.1;
      cops.add(cop);
      _copTimer = 26;
      _sirenT = 0;
      _say('COPS!', 1.4);
    }
    if (cops.isEmpty) return;

    final cop = cops.first;
    _updateRider(cop, dt);
    _copTimer -= dt;
    _sirenT -= dt;
    final gap = cop.z - p.z;
    if (_sirenT <= 0 && !cop.down && gap.abs() < 5000) {
      _sirenT = 1.3;
      events.add('siren');
    }
    if (outcome == RrOutcome.none && crashed && !cop.down && gap.abs() < 600) {
      outcome = RrOutcome.busted;
      events.add('busted');
      _say('BUSTED!', 4);
    }
    // Gone once shaken off (well behind the camera).
    if (outcome == RrOutcome.none && !crashed && gap < -5000) cops.clear();
  }
}
