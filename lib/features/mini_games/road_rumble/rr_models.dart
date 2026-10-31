import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Texture tiles in the atlas that a model face can be mapped to.
enum RrTile {
  road,
  grass,
  dirt,
  cloth,
  leather,
  metal,
  tyre,
  helmet,
  suit,
  leg,
  paint,
  glass,
  plate,
  white,
  shadow,
  puff,
  leaf,
  bark,
  rock,
}

/// What colours a face. Slots 1–4 come from the rider or car it belongs to;
/// the glow slots ignore lighting.
class RrSlot {
  static const none = 0;
  static const jacket = 1;
  static const pants = 2;
  static const helmet = 3;
  static const body = 4;
  static const skin = 5;
  static const wood = 6;
  static const glowRed = 7;
  static const glowWarm = 8;
  static const glowBlue = 9;
  static const count = 10;
}

/// Colours for one rider: jacket, helmet, trousers and bike paint.
class RrLook {
  const RrLook(this.jacket, this.helmet, this.pants, this.bike);

  final int jacket;
  final int helmet;
  final int pants;
  final int bike;
}

// 0 is the player, 1–14 the rivals, 15 the police. Slightly washed out, the
// way late-90s console palettes were.
const rrLooks = <RrLook>[
  RrLook(0xFF3A3A44, 0xFFD8B43C, 0xFF46609A, 0xFFB83430),
  RrLook(0xFFB84038, 0xFFD8D8DC, 0xFF34343C, 0xFF3A54A8),
  RrLook(0xFF8A4AA8, 0xFFD878A8, 0xFF34343C, 0xFF8A8A92),
  RrLook(0xFF667840, 0xFF484E3C, 0xFF74644A, 0xFF50505A),
  RrLook(0xFF3A9A62, 0xFF2C2C32, 0xFF46609A, 0xFF3A9A52),
  RrLook(0xFF9A7040, 0xFFCCC4AC, 0xFF46609A, 0xFF7E5030),
  RrLook(0xFFD0D0D8, 0xFFB83430, 0xFF34343C, 0xFFB83430),
  RrLook(0xFFD08030, 0xFF34343C, 0xFF34343C, 0xFFD08030),
  RrLook(0xFF44444E, 0xFF74302E, 0xFF5E5E66, 0xFF36363E),
  RrLook(0xFF3A9AA8, 0xFFD8B43C, 0xFF34343C, 0xFFD8B43C),
  RrLook(0xFF4A58B8, 0xFF4A58B8, 0xFF9A9AA2, 0xFFD8D8DC),
  RrLook(0xFFD0608A, 0xFFB8C440, 0xFF46609A, 0xFF8A4AA8),
  RrLook(0xFF6E6E76, 0xFF8AB84A, 0xFF34343C, 0xFF8AB84A),
  RrLook(0xFFA03432, 0xFFA03432, 0xFF74644A, 0xFF40404A),
  RrLook(0xFFBCAA36, 0xFF3A54A8, 0xFF34343C, 0xFF3A54A8),
  RrLook(0xFF2C3A68, 0xFFE4E4E8, 0xFF2C3A68, 0xFFE4E4E8),
];

const rrCarColors = [0xFFB04038, 0xFF4662A8, 0xFFD4D4CC, 0xFF4A948A];

class _V {
  const _V(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _V operator +(_V o) => _V(x + o.x, y + o.y, z + o.z);
  _V operator -(_V o) => _V(x - o.x, y - o.y, z - o.z);
  _V operator *(double s) => _V(x * s, y * s, z * s);
  double dot(_V o) => x * o.x + y * o.y + z * o.z;
  _V cross(_V o) => _V(y * o.z - z * o.y, z * o.x - x * o.z, x * o.y - y * o.x);
  double get length => sqrt(dot(this));
  _V get unit {
    final l = length;
    return l == 0 ? this : this * (1 / l);
  }
}

class RrFace {
  const RrFace(
    this.a,
    this.b,
    this.c,
    this.d,
    this.tile,
    this.slot,
    this.shade,
    this.shadeB,
    this.shadeC,
    this.shadeD, [
    this.u0 = 0,
    this.v0 = 0,
    this.u1 = 1,
    this.v1 = 1,
  ]);

  /// Vertex indices of the quad.
  final int a;
  final int b;
  final int c;
  final int d;
  final RrTile tile;
  final int slot;

  /// Baked lighting at each vertex, 0..1. Equal on a flat-shaded face;
  /// different on rounded bodies, which are smooth-shaded.
  final double shade;
  final double shadeB;
  final double shadeC;
  final double shadeD;

  /// The part of the tile this face shows, as fractions: vertices a and b
  /// sit on [v0], c and d on [v1].
  final double u0;
  final double v0;
  final double u1;
  final double v1;
}

/// A low-polygon model: quads over a shared vertex list, lit once at build
/// time. Units are world units (about 416 to a metre); y is up, z is forward.
class RrMesh {
  RrMesh(this.xyz, this.faces);

  final Float32List xyz;
  final List<RrFace> faces;

  int get vertexCount => xyz.length ~/ 3;
}

class _Builder {
  _Builder({this.low = false});

  /// Builds a cheaper model for use at a distance.
  final bool low;

  final List<double> _xyz = [];
  final List<RrFace> _faces = [];

  // Sun high, behind the camera and to the left.
  static final _V _sun = const _V(-0.35, 0.75, -0.55).unit;

  RrMesh build() => RrMesh(Float32List.fromList(_xyz), _faces);

  int _add(_V v) {
    _xyz.addAll([v.x, v.y, v.z]);
    return _xyz.length ~/ 3 - 1;
  }

  /// Adds a quad, lit by the normal facing away from [inside].
  static double _light(_V n) =>
      (0.42 + 0.5 * max(0.0, n.dot(_sun)) + 0.08 * max(0.0, n.y)).clamp(
        0.0,
        1.0,
      );

  /// Adds a quad. Flat faces are lit by the normal facing away from
  /// [inside]; pass [normals] (one per vertex) to smooth-shade instead.
  void quad(
    _V p0,
    _V p1,
    _V p2,
    _V p3,
    _V inside,
    RrTile tile,
    int slot, {
    List<_V>? normals,
    (double, double, double, double) uv = (0, 0, 1, 1),
  }) {
    var s = const [1.0, 1.0, 1.0, 1.0];
    if (slot < RrSlot.glowRed) {
      if (normals != null) {
        s = [for (final n in normals) _light(n.unit)];
      } else {
        var n = (p1 - p0).cross(p3 - p0);
        if (n.length == 0) n = (p2 - p1).cross(p3 - p1);
        n = n.unit;
        final centre = (p0 + p1 + p2 + p3) * 0.25;
        if (n.dot(centre - inside) < 0) n = n * -1;
        final flat = _light(n);
        s = [flat, flat, flat, flat];
      }
    }
    _faces.add(
      RrFace(
        _add(p0),
        _add(p1),
        _add(p2),
        _add(p3),
        tile,
        slot,
        s[0],
        s[1],
        s[2],
        s[3],
        uv.$1,
        uv.$2,
        uv.$3,
        uv.$4,
      ),
    );
  }

  void _hull(
    List<_V> lo,
    List<_V> hi,
    RrTile tile,
    int slot, {
    RrTile? capTile,
  }) {
    var centre = const _V(0, 0, 0);
    for (final v in [...lo, ...hi]) {
      centre = centre + v;
    }
    centre = centre * (1 / 8);
    for (var i = 0; i < 4; i++) {
      final j = (i + 1) % 4;
      quad(lo[i], lo[j], hi[j], hi[i], centre, tile, slot);
    }
    quad(lo[0], lo[1], lo[2], lo[3], centre, capTile ?? tile, slot);
    quad(hi[0], hi[1], hi[2], hi[3], centre, capTile ?? tile, slot);
  }

  /// Axis-aligned box about [c]; [top] scales the upper face for a taper.
  void box(
    _V c,
    double hx,
    double hy,
    double hz,
    RrTile tile,
    int slot, {
    double top = 1,
    double topZ = 1,
    RrTile? capTile,
  }) {
    List<_V> ring(double y, double sx, double sz) => [
      _V(c.x - hx * sx, y, c.z - hz * sz),
      _V(c.x + hx * sx, y, c.z - hz * sz),
      _V(c.x + hx * sx, y, c.z + hz * sz),
      _V(c.x - hx * sx, y, c.z + hz * sz),
    ];
    _hull(
      ring(c.y - hy, 1, 1),
      ring(c.y + hy, top, topZ),
      tile,
      slot,
      capTile: capTile,
    );
  }

  /// A box running from [a] to [b], [w] wide and [d] deep, optionally tapering.
  void bone(
    _V a,
    _V b,
    double w,
    double d,
    RrTile tile,
    int slot, {
    double? w1,
    double? d1,
  }) {
    final axis = (b - a).unit;
    var side = axis
        .cross(axis.y.abs() > 0.9 ? const _V(0, 0, 1) : const _V(0, 1, 0))
        .unit;
    // Keep "width" as close to the model's x axis as the bone allows.
    final other = axis.cross(side).unit;
    if (other.x.abs() > side.x.abs()) {
      final swap = side;
      side = other;
      List<_V> ring(_V o, double ww, double dd) => [
        o - side * (ww / 2) - swap * (dd / 2),
        o + side * (ww / 2) - swap * (dd / 2),
        o + side * (ww / 2) + swap * (dd / 2),
        o - side * (ww / 2) + swap * (dd / 2),
      ];
      _hull(ring(a, w, d), ring(b, w1 ?? w, d1 ?? d), tile, slot);
      return;
    }
    List<_V> ring(_V o, double ww, double dd) => [
      o - side * (ww / 2) - other * (dd / 2),
      o + side * (ww / 2) - other * (dd / 2),
      o + side * (ww / 2) + other * (dd / 2),
      o - side * (ww / 2) + other * (dd / 2),
    ];
    _hull(ring(a, w, d), ring(b, w1 ?? w, d1 ?? d), tile, slot);
  }

  /// Skins a row of horizontal elliptical rings, each (centre, x radius,
  /// z radius), into a smooth-shaded body. The tile wraps once around it:
  /// u runs round the rings (0.75 is the back, facing a following camera),
  /// v from the last ring (0) down to the first (1).
  void loft(
    List<(_V, double, double)> rings,
    RrTile tile,
    int slot, {
    int sides = 10,
    bool caps = true,
    _V? round,
  }) {
    if (low) sides = min(sides, 6);
    _V at((_V, double, double) ring, int k) {
      final a = (k + 0.5) * 2 * pi / sides;
      return _V(
        ring.$1.x + cos(a) * ring.$2,
        ring.$1.y,
        ring.$1.z + sin(a) * ring.$3,
      );
    }

    // Outward normal: from [round]'s centre for a ball, else straight out
    // from the ring's own axis.
    _V normal((_V, double, double) ring, int k) {
      final p = at(ring, k);
      if (round != null) return p - round;
      final a = (k + 0.5) * 2 * pi / sides;
      return _V(cos(a) * ring.$3, 0.12, sin(a) * ring.$2);
    }

    final last = rings.length - 1;
    for (var r = 0; r < last; r++) {
      final lo = rings[r], hi = rings[r + 1];
      final inside = (lo.$1 + hi.$1) * 0.5;
      for (var k = 0; k < sides; k++) {
        quad(
          at(lo, k),
          at(lo, k + 1),
          at(hi, k + 1),
          at(hi, k),
          inside,
          tile,
          slot,
          normals: [
            normal(lo, k),
            normal(lo, k + 1),
            normal(hi, k + 1),
            normal(hi, k),
          ],
          uv: (k / sides, 1 - r / last, (k + 1) / sides, 1 - (r + 1) / last),
        );
      }
    }
    if (!caps) return;
    final middle = (rings.first.$1 + rings.last.$1) * 0.5;
    for (final ring in [rings.first, rings.last]) {
      for (var k = 0; k < sides; k++) {
        quad(
          ring.$1,
          at(ring, k),
          at(ring, k + 1),
          at(ring, k + 1),
          middle,
          tile,
          slot,
          uv: (0.3, 0.02, 0.4, 0.08),
        );
      }
    }
  }

  /// A smooth ball.
  void ball(
    _V c,
    double rx,
    double ry,
    double rz,
    RrTile tile,
    int slot, {
    int sides = 10,
  }) => loft(
    [
      for (final lat in const [-1.45, -1.0, -0.5, 0.0, 0.5, 1.0, 1.45])
        (_V(c.x, c.y + ry * sin(lat), c.z), rx * cos(lat), rz * cos(lat)),
    ],
    tile,
    slot,
    sides: sides,
    caps: false,
    round: c,
  );

  /// A smooth-shaded limb from [a] to [b], tapering from [r0] to [r1].
  void tube(
    _V a,
    _V b,
    double r0,
    double r1,
    RrTile tile,
    int slot, {
    int sides = 6,
  }) {
    if (low) sides = 4;
    final axis = (b - a).unit;
    final side = axis
        .cross(axis.y.abs() > 0.9 ? const _V(0, 0, 1) : const _V(0, 1, 0))
        .unit;
    final other = axis.cross(side).unit;
    _V out(int k) {
      final t = k * 2 * pi / sides;
      return side * cos(t) + other * sin(t);
    }

    final inside = (a + b) * 0.5;
    for (var k = 0; k < sides; k++) {
      final n0 = out(k), n1 = out(k + 1);
      quad(
        a + n0 * r0,
        a + n1 * r0,
        b + n1 * r1,
        b + n0 * r1,
        inside,
        tile,
        slot,
        normals: [n0, n1, n1, n0],
        uv: (k / sides, 1, (k + 1) / sides, 0),
      );
      quad(b, b + n0 * r1, b + n1 * r1, b + n1 * r1, inside, tile, slot);
    }
  }

  /// A wheel: an n-sided drum on the x axis.
  void wheel(_V c, double r, double hw, {int sides = 14}) {
    if (low) sides = 8;
    for (var i = 0; i < sides; i++) {
      final a0 = i * 2 * pi / sides;
      final a1 = (i + 1) * 2 * pi / sides;
      _V rim(double a, double x) =>
          _V(c.x + x, c.y + cos(a) * r, c.z + sin(a) * r);
      _V out(double a) => _V(0, cos(a), sin(a));
      quad(
        rim(a0, -hw),
        rim(a0, hw),
        rim(a1, hw),
        rim(a1, -hw),
        c,
        RrTile.tyre,
        RrSlot.none,
        normals: [out(a0), out(a0), out(a1), out(a1)],
      );
      for (final x in [-hw, hw]) {
        final hub = _V(c.x + x, c.y, c.z);
        quad(
          hub,
          rim(a0, x),
          rim(a1, x),
          rim(a1, x),
          c,
          RrTile.metal,
          RrSlot.none,
        );
      }
    }
  }
}

/// The models used in a race, built once.
class RrModels {
  RrModels()
    : bike = _bike(cop: false),
      copBike = _bike(cop: true),
      farBike = _bike(cop: false, low: true),
      farRider = _rider(0, -1, low: true),
      // Index by pose; odd entries attack to the right.
      riders = [
        _rider(0, -1),
        _rider(1, -1),
        _rider(1, 1),
        _rider(2, -1),
        _rider(2, 1),
        _rider(3, -1),
        _rider(3, 1),
      ],
      runners = [_runner(1), _runner(-1)],
      car = _car(truck: false),
      truck = _car(truck: true),
      scenery = _scenery();

  static const poseRide = 0;
  static const posePunchL = 1;
  static const posePunchR = 2;
  static const poseKickL = 3;
  static const poseKickR = 4;
  static const poseClubL = 5;
  static const poseClubR = 6;

  final RrMesh bike;
  final RrMesh copBike;

  /// Cheaper stand-ins for riders well up the road.
  final RrMesh farBike;
  final RrMesh farRider;
  final List<RrMesh> riders;
  final List<RrMesh> runners;
  final RrMesh car;
  final RrMesh truck;

  /// Solid versions of the roadside scenery, keyed by [RrProp.name]. Kinds
  /// that are flat in life (signs, hoardings, the start banner) aren't here
  /// and stay as cut-outs.
  final Map<String, RrMesh> scenery;

  // Scenery tint slots: three greens for foliage, and barn red.
  static const pineSlot = RrSlot.jacket;
  static const oakSlot = RrSlot.pants;
  static const palmSlot = RrSlot.helmet;
  static const barnSlot = RrSlot.body;

  static Map<String, RrMesh> _scenery() {
    RrMesh make(void Function(_Builder b) build) {
      final b = _Builder();
      build(b);
      return b.build();
    }

    return {
      'pine': make((b) {
        b.tube(
          const _V(0, 0, 0),
          const _V(0, 760, 0),
          78,
          54,
          RrTile.bark,
          RrSlot.none,
          sides: 7,
        );
        for (final (lo, hi, r) in const [
          (460.0, 1320.0, 740.0),
          (980.0, 1820.0, 580.0),
          (1480.0, 2260.0, 420.0),
          (1940.0, 2640.0, 250.0),
        ]) {
          b.loft(
            [
              (_V(0, lo, 0), r, r),
              (_V(0, lo + (hi - lo) * 0.2, 0), r * 0.86, r * 0.86),
              (_V(0, lo + (hi - lo) * 0.6, 0), r * 0.42, r * 0.42),
              (_V(0, hi, 0), 14, 14),
            ],
            RrTile.leaf,
            pineSlot,
            sides: 9,
          );
        }
      }),
      'oak': make((b) {
        b.tube(
          const _V(0, 0, 0),
          const _V(20, 980, 0),
          120,
          84,
          RrTile.bark,
          RrSlot.none,
          sides: 7,
        );
        b.tube(
          const _V(20, 900, 0),
          const _V(-380, 1300, 120),
          60,
          36,
          RrTile.bark,
          RrSlot.none,
        );
        b.tube(
          const _V(20, 900, 0),
          const _V(420, 1340, -100),
          60,
          36,
          RrTile.bark,
          RrSlot.none,
        );
        b.ball(
          const _V(0, 1560, 0),
          780,
          620,
          760,
          RrTile.leaf,
          oakSlot,
          sides: 9,
        );
        b.ball(
          const _V(-560, 1300, 220),
          520,
          440,
          500,
          RrTile.leaf,
          oakSlot,
          sides: 8,
        );
        b.ball(
          const _V(540, 1340, -180),
          560,
          460,
          540,
          RrTile.leaf,
          oakSlot,
          sides: 8,
        );
        b.ball(
          const _V(120, 1980, 80),
          520,
          400,
          520,
          RrTile.leaf,
          oakSlot,
          sides: 8,
        );
      }),
      'palm': make((b) {
        b.tube(
          const _V(0, 0, 0),
          const _V(70, 1150, 0),
          76,
          58,
          RrTile.bark,
          RrSlot.none,
          sides: 7,
        );
        b.tube(
          const _V(70, 1150, 0),
          const _V(180, 2180, 0),
          58,
          44,
          RrTile.bark,
          RrSlot.none,
          sides: 7,
        );
        const top = _V(180, 2200, 0);
        b.ball(top, 110, 90, 110, RrTile.bark, RrSlot.none, sides: 6);
        for (var i = 0; i < 9; i++) {
          final a = i * 2 * pi / 9;
          final d = _V(cos(a), 0, sin(a));
          final across = _V(-sin(a), 0, cos(a)) * 150;
          final mid = top + d * 520 + const _V(0, 150, 0);
          final tip = top + d * 1040 + const _V(0, -330, 0);
          b.quad(
            top - across * 0.3,
            top + across * 0.3,
            mid + across,
            mid - across,
            top + const _V(0, -200, 0),
            RrTile.leaf,
            palmSlot,
          );
          b.quad(
            mid - across,
            mid + across,
            tip + across * 0.15,
            tip - across * 0.15,
            top + const _V(0, -200, 0),
            RrTile.leaf,
            palmSlot,
          );
        }
      }),
      'cactus': make((b) {
        b.tube(
          const _V(0, 0, 0),
          const _V(0, 1340, 0),
          118,
          100,
          RrTile.leaf,
          palmSlot,
          sides: 8,
        );
        b.ball(
          const _V(0, 1340, 0),
          100,
          90,
          100,
          RrTile.leaf,
          palmSlot,
          sides: 8,
        );
        for (final (s, y, up) in const [
          (-1.0, 560.0, 480.0),
          (1.0, 780.0, 420.0),
        ]) {
          b.tube(
            _V(0, y, 0),
            _V(s * 320, y + 40, 0),
            72,
            68,
            RrTile.leaf,
            palmSlot,
            sides: 7,
          );
          b.tube(
            _V(s * 320, y + 40, 0),
            _V(s * 320, y + up, 0),
            70,
            60,
            RrTile.leaf,
            palmSlot,
            sides: 7,
          );
          b.ball(
            _V(s * 320, y + up, 0),
            60,
            54,
            60,
            RrTile.leaf,
            palmSlot,
            sides: 7,
          );
        }
      }),
      'rock': make((b) {
        b.ball(
          const _V(0, 210, 0),
          440,
          300,
          380,
          RrTile.rock,
          RrSlot.none,
          sides: 8,
        );
        b.ball(
          const _V(260, 120, 140),
          240,
          170,
          220,
          RrTile.rock,
          RrSlot.none,
          sides: 6,
        );
      }),
      'bush': make((b) {
        b.ball(
          const _V(0, 250, 0),
          340,
          280,
          320,
          RrTile.leaf,
          oakSlot,
          sides: 8,
        );
        b.ball(
          const _V(-290, 190, 70),
          250,
          210,
          240,
          RrTile.leaf,
          oakSlot,
          sides: 7,
        );
        b.ball(
          const _V(280, 200, -50),
          260,
          220,
          250,
          RrTile.leaf,
          oakSlot,
          sides: 7,
        );
      }),
      'pole': make((b) {
        b.tube(
          const _V(0, 0, 0),
          const _V(0, 2320, 0),
          46,
          36,
          RrTile.bark,
          RrSlot.none,
          sides: 7,
        );
        b.box(const _V(0, 2090, 0), 235, 26, 26, RrTile.bark, RrSlot.none);
        for (final x in const [-200.0, 200.0]) {
          b.box(_V(x, 2140, 0), 16, 30, 16, RrTile.metal, RrSlot.none);
        }
      }),
      'barn': make((b) {
        b.box(const _V(0, 620, 0), 1300, 620, 1000, RrTile.paint, barnSlot);
        // A pitched roof with its ridge along the road.
        b.box(
          const _V(0, 1570, 0),
          1400,
          340,
          1070,
          RrTile.metal,
          RrSlot.none,
          top: 0.03,
        );
        b.box(
          const _V(0, 420, -1006),
          300,
          420,
          6,
          RrTile.leather,
          RrSlot.none,
        );
        b.box(const _V(0, 1050, -1006), 170, 110, 6, RrTile.glass, RrSlot.none);
      }),
      'fence': make((b) {
        for (final z in const [-300.0, 300.0]) {
          b.box(_V(0, 290, z), 38, 290, 38, RrTile.white, RrSlot.none);
        }
        for (final y in const [230.0, 440.0]) {
          b.box(_V(0, y, 0), 20, 42, 610, RrTile.white, RrSlot.none);
        }
      }),
    };
  }

  static RrMesh _bike({required bool cop, bool low = false}) {
    final b = _Builder(low: low);
    b.wheel(const _V(0, 135, -290), 135, 55);
    b.wheel(const _V(0, 135, 300), 135, 45);
    for (final s in const [-1.0, 1.0]) {
      b.bone(
        _V(s * 55, 135, -290),
        _V(s * 48, 205, -50),
        26,
        34,
        RrTile.metal,
        RrSlot.none,
      );
      b.bone(
        _V(s * 52, 135, 300),
        _V(s * 48, 440, 175),
        24,
        24,
        RrTile.metal,
        RrSlot.none,
      );
      b.tube(
        _V(s * 92, 175, -30),
        _V(s * 104, 240, -390),
        22,
        30,
        RrTile.metal,
        RrSlot.none,
      );
      b.box(_V(s * 168, 520, 185), 34, 20, 6, RrTile.metal, RrSlot.none);
    }
    b.box(const _V(0, 195, 10), 72, 72, 125, RrTile.metal, RrSlot.none);
    b.loft(
      const [
        (_V(0, 268, 60), 70, 120),
        (_V(0, 330, 66), 92, 132),
        (_V(0, 380, 72), 64, 100),
      ],
      RrTile.paint,
      RrSlot.body,
    );
    b.tube(
      const _V(0, 322, -40),
      const _V(0, 372, -338),
      76,
      46,
      RrTile.paint,
      RrSlot.body,
      sides: 8,
    );
    // Rear hugger over the tyre.
    b.tube(
      const _V(0, 282, -200),
      const _V(0, 300, -410),
      62,
      40,
      RrTile.leather,
      RrSlot.none,
      sides: 6,
    );
    b.box(const _V(0, 366, -130), 68, 16, 100, RrTile.leather, RrSlot.none);
    b.box(const _V(0, 376, -340), 44, 17, 6, RrTile.white, RrSlot.glowRed);
    b.box(const _V(0, 304, -346), 40, 27, 4, RrTile.plate, RrSlot.none);
    b.bone(
      const _V(0, 288, -300),
      const _V(0, 262, -420),
      70,
      12,
      RrTile.paint,
      RrSlot.body,
    );
    b.box(
      const _V(0, 432, 205),
      92,
      68,
      48,
      RrTile.paint,
      RrSlot.body,
      top: 0.75,
    );
    b.bone(
      const _V(0, 492, 196),
      const _V(0, 566, 160),
      120,
      10,
      RrTile.glass,
      RrSlot.none,
      w1: 80,
    );
    b.bone(
      const _V(-152, 462, 172),
      const _V(152, 462, 172),
      18,
      18,
      RrTile.metal,
      RrSlot.none,
    );
    if (cop) {
      b.box(const _V(-46, 420, -330), 34, 26, 26, RrTile.white, RrSlot.glowRed);
      b.box(const _V(46, 420, -330), 34, 26, 26, RrTile.white, RrSlot.glowBlue);
    }
    return b.build();
  }

  static void _helmet(_Builder b, _V c) {
    b.ball(c, 94, 100, 108, RrTile.helmet, RrSlot.helmet);
    // The chin bar's lower lip.
    b.loft(
      [
        (_V(c.x, c.y - 96, c.z + 4), 62, 76),
        (_V(c.x, c.y - 72, c.z + 4), 84, 98),
      ],
      RrTile.leather,
      RrSlot.none,
      caps: false,
    );
  }

  /// An arm or leg: two tapered tubes with a rounded joint between.
  static void _limb(
    _Builder b,
    _V a,
    _V joint,
    _V end,
    double r0,
    double r1,
    double r2,
    RrTile tile,
    int slot,
  ) {
    b.tube(a, joint, r0, r1, tile, slot, sides: 8);
    if (!b.low)
      b.ball(joint, r1 * 1.08, r1 * 1.08, r1 * 1.08, tile, slot, sides: 6);
    b.tube(joint, end, r1, r2, tile, slot, sides: 8);
  }

  /// [action]: 0 riding, 1 punch, 2 kick, 3 club, thrown to [side].
  static RrMesh _rider(int action, double side, {bool low = false}) {
    final b = _Builder(low: low);
    // Crouched forward over the tank, in racing leathers.
    b.loft(
      const [
        (_V(0, 338, -128), 104, 90),
        (_V(0, 372, -124), 124, 100),
        (_V(0, 404, -116), 120, 96),
      ],
      RrTile.leg,
      RrSlot.pants,
    );
    b.loft(
      const [
        (_V(0, 398, -114), 116, 92),
        (_V(0, 432, -92), 106, 82),
        (_V(0, 470, -60), 110, 82),
        (_V(0, 510, -24), 128, 90),
        (_V(0, 546, 10), 136, 88),
        (_V(0, 574, 34), 124, 72),
        (_V(0, 592, 46), 70, 56),
      ],
      RrTile.suit,
      RrSlot.jacket,
      sides: 12,
    );
    // Back protector hump, as on race suits.
    b.loft(
      const [
        (_V(0, 520, -62), 46, 22),
        (_V(0, 566, -30), 54, 30),
        (_V(0, 596, 0), 34, 20),
      ],
      RrTile.leather,
      RrSlot.none,
      sides: 6,
    );
    b.tube(
      const _V(0, 588, 44),
      const _V(0, 626, 66),
      40,
      36,
      RrTile.white,
      RrSlot.skin,
      sides: 8,
    );

    for (final s in const [-1.0, 1.0]) {
      final attacking = s == side;
      final hip = _V(s * 70, 380, -106);
      if (attacking && action == 2) {
        final foot = _V(s * 450, 312, 40);
        _limb(
          b,
          hip,
          _V(s * 250, 345, -30),
          foot,
          64,
          50,
          38,
          RrTile.leg,
          RrSlot.pants,
        );
        b.box(_V(s * 486, 304, 56), 60, 42, 46, RrTile.leather, RrSlot.none);
      } else {
        final ankle = _V(s * 118, 156, 0);
        _limb(
          b,
          hip,
          _V(s * 128, 326, 96),
          ankle,
          64,
          50,
          38,
          RrTile.leg,
          RrSlot.pants,
        );
        // Boot with a toe.
        b.box(_V(s * 118, 146, 2), 40, 34, 44, RrTile.leather, RrSlot.none);
        b.box(
          _V(s * 118, 116, 44),
          40,
          26,
          62,
          RrTile.leather,
          RrSlot.none,
          top: 0.8,
          topZ: 0.7,
        );
      }
      final shoulder = _V(s * 128, 566, 30);
      b.ball(shoulder, 50, 48, 50, RrTile.suit, RrSlot.jacket, sides: 6);
      if (attacking && (action == 1 || action == 3)) {
        final hand = _V(s * 450, 606, 92);
        _limb(
          b,
          shoulder,
          _V(s * 290, 590, 60),
          hand,
          44,
          38,
          31,
          RrTile.cloth,
          RrSlot.jacket,
        );
        b.ball(hand, 40, 40, 40, RrTile.leather, RrSlot.none, sides: 6);
        if (action == 3) {
          b.tube(
            hand,
            _V(s * 510, 880, 120),
            16,
            20,
            RrTile.cloth,
            RrSlot.wood,
          );
        }
      } else {
        final hand = _V(s * 150, 462, 172);
        _limb(
          b,
          shoulder,
          _V(s * 174, 478, 112),
          hand,
          44,
          38,
          31,
          RrTile.cloth,
          RrSlot.jacket,
        );
        b.ball(hand, 34, 32, 38, RrTile.leather, RrSlot.none, sides: 6);
      }
    }
    _helmet(b, const _V(0, 690, 86));
    return b.build();
  }

  /// A rider on foot, mid-stride; [s] flips which leg leads.
  static RrMesh _runner(double s) {
    final b = _Builder();
    b.loft(
      const [
        (_V(0, 360, 0), 112, 80),
        (_V(0, 460, 0), 104, 74),
        (_V(0, 560, 0), 132, 84),
        (_V(0, 612, 0), 120, 70),
        (_V(0, 634, 0), 56, 48),
      ],
      RrTile.cloth,
      RrSlot.jacket,
    );
    b.tube(
      _V(s * 60, 370, 0),
      _V(s * 70, 200, 70),
      58,
      46,
      RrTile.cloth,
      RrSlot.pants,
    );
    b.tube(
      _V(s * 70, 200, 70),
      _V(s * 70, 30, 20),
      44,
      36,
      RrTile.cloth,
      RrSlot.pants,
    );
    b.tube(
      _V(-s * 60, 370, 0),
      _V(-s * 70, 220, -50),
      58,
      46,
      RrTile.cloth,
      RrSlot.pants,
    );
    b.tube(
      _V(-s * 70, 220, -50),
      _V(-s * 80, 90, -170),
      44,
      36,
      RrTile.cloth,
      RrSlot.pants,
    );
    b.tube(
      _V(s * 132, 600, 0),
      _V(s * 170, 440, -80),
      42,
      32,
      RrTile.cloth,
      RrSlot.jacket,
    );
    b.tube(
      _V(-s * 132, 600, 0),
      _V(-s * 170, 460, 90),
      42,
      32,
      RrTile.cloth,
      RrSlot.jacket,
    );
    _helmet(b, const _V(0, 724, 0));
    return b.build();
  }

  static RrMesh _car({required bool truck}) {
    final b = _Builder();
    for (final x in const [-330.0, 330.0]) {
      for (final z in const [-570.0, 570.0]) {
        b.wheel(_V(x, 150, z), 150, 60, sides: 12);
      }
    }
    b.box(const _V(0, 265, 0), 375, 135, 900, RrTile.paint, RrSlot.body);
    if (truck) {
      b.box(
        const _V(0, 560, 260),
        350,
        165,
        330,
        RrTile.glass,
        RrSlot.none,
        capTile: RrTile.paint,
      );
      b.box(const _V(0, 440, -470), 362, 45, 410, RrTile.paint, RrSlot.body);
    } else {
      b.box(
        const _V(0, 500, -60),
        345,
        105,
        520,
        RrTile.glass,
        RrSlot.none,
        top: 0.84,
        topZ: 0.7,
        capTile: RrTile.paint,
      );
      // Bonnet and boot lids standing proud of the body.
      b.box(
        const _V(0, 408, 620),
        350,
        14,
        270,
        RrTile.paint,
        RrSlot.body,
        top: 0.94,
      );
      b.box(
        const _V(0, 408, -720),
        350,
        14,
        170,
        RrTile.paint,
        RrSlot.body,
        top: 0.94,
      );
    }
    for (final x in const [-392.0, 392.0]) {
      b.box(_V(x, 430, 330), 24, 26, 36, RrTile.paint, RrSlot.body);
    }
    b.box(const _V(0, 150, -905), 380, 42, 16, RrTile.metal, RrSlot.none);
    b.box(const _V(0, 150, 905), 380, 42, 16, RrTile.metal, RrSlot.none);
    for (final x in const [-275.0, 275.0]) {
      b.box(_V(x, 300, -903), 82, 40, 6, RrTile.white, RrSlot.glowRed);
      b.box(_V(x, 300, 903), 82, 40, 6, RrTile.white, RrSlot.glowWarm);
    }
    b.box(const _V(0, 250, -904), 90, 36, 5, RrTile.plate, RrSlot.none);
    b.box(const _V(0, 270, 904), 200, 50, 5, RrTile.metal, RrSlot.none);
    return b.build();
  }
}

/// A model made elsewhere and shipped as an asset: a flat list of triangles,
/// eight floats a corner (x, y, z, u, v, shade, tint slot, spare). The
/// texture coordinates are already in atlas pixels.
class RrTriMesh {
  RrTriMesh(this.data);

  static const stride = 8;
  final Float32List data;

  int get vertexCount => data.length ~/ stride;
}

/// The downloaded bike and rider (both CC0): "Another PSX Style Low-poly
/// Bike" by Duhgless and "psx male character" by 32Dev3, posed and exported
/// by a Blender script into `assets/road_rumble/models.bin`, with their
/// textures packed into `models.png`.
class RrImported {
  RrImported._(
    this.bikeHi,
    this.bike,
    this.bikeFar,
    this.riderFar,
    this.riders,
    this.runners,
  );

  /// Where each source texture sits on the sheet: bike frame, fork, front
  /// tyre, back tyre, rider, helmet.
  static const _sheet = <(double, double, double, double)>[
    (0, 0, 256, 256),
    (0, 256, 128, 128),
    (128, 256, 128, 128),
    (256, 256, 128, 128),
    (256, 0, 256, 256),
    (384, 256, 64, 64),
  ];

  /// The bike at full detail, for riders right in front of the camera.
  final RrTriMesh bikeHi;
  final RrTriMesh bike;
  final RrTriMesh bikeFar;
  final RrTriMesh riderFar;

  /// Indexed like [RrModels.riders]; the club poses reuse the punches.
  final List<RrTriMesh> riders;
  final List<RrTriMesh> runners;

  /// [sheetAt] is where the texture sheet was placed in the atlas.
  static RrImported parse(ByteData bytes, double sheetX, double sheetY) {
    final headerLength = bytes.getUint32(0, Endian.little);
    final header =
        jsonDecode(
              utf8.decode(
                bytes.buffer.asUint8List(bytes.offsetInBytes + 4, headerLength),
              ),
            )
            as Map<String, dynamic>;
    final start = 4 + headerLength;
    final meshes = <String, RrTriMesh>{};
    for (final entry
        in (header['meshes'] as List).cast<Map<String, dynamic>>()) {
      final offset = entry['offset'] as int;
      final count = (entry['count'] as int) * RrTriMesh.stride;
      final data = Float32List(count);
      for (var i = 0; i < count; i++) {
        data[i] = bytes.getFloat32(start + (offset + i) * 4, Endian.little);
      }
      for (var i = 0; i < count; i += RrTriMesh.stride) {
        final (x, y, w, h) = _sheet[data[i + 7].round()];
        data[i + 3] = sheetX + x + 0.5 + data[i + 3] * (w - 1);
        data[i + 4] = sheetY + y + 0.5 + data[i + 4] * (h - 1);
      }
      meshes[entry['name'] as String] = RrTriMesh(data);
    }
    RrTriMesh m(String name) => meshes[name]!;
    return RrImported._(
      m('bikeHi'),
      m('bike'),
      m('bikeFar'),
      m('rideFar'),
      [
        m('ride'),
        m('punchL'),
        m('punchR'),
        m('kickL'),
        m('kickR'),
        m('punchL'),
        m('punchR'),
      ],
      [m('runA'), m('runB')],
    );
  }
}
