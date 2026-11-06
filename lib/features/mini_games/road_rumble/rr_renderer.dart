import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'rr_atlas.dart';
import 'rr_engine.dart';
import 'rr_models.dart';
import 'rr_sprites.dart';

class _Pal {
  const _Pal({
    required this.skyTop,
    required this.skyLow,
    required this.far,
    required this.near,
    required this.ground,
    required this.groundAlt,
    required this.verge,
    required this.banks,
    this.clouds = 0.5,
  });

  final int skyTop;
  final int skyLow;
  final int far;
  final int near;
  final int ground;
  final int groundAlt;
  final int verge;

  /// How high the roadside embankments rise, in world units.
  final double banks;
  final double clouds;
}

const _pals = <RrTheme, _Pal>{
  RrTheme.forest: _Pal(
    skyTop: 0xFF4A7EC8,
    skyLow: 0xFFB4CCE4,
    far: 0xFF7484A4,
    near: 0xFF4A7050,
    ground: 0xFF5C8C50,
    groundAlt: 0xFF548448,
    verge: 0xFF9A8A68,
    banks: 2600,
  ),
  RrTheme.coast: _Pal(
    skyTop: 0xFF4A90D8,
    skyLow: 0xFFC4E0F0,
    far: 0xFF6C8E9C,
    near: 0xFF3A70A8,
    ground: 0xFFCCB888,
    groundAlt: 0xFFC2AE7E,
    verge: 0xFFB4A070,
    banks: 900,
    clouds: 0.6,
  ),
  RrTheme.desert: _Pal(
    skyTop: 0xFF5A8AC8,
    skyLow: 0xFFE4D4B4,
    far: 0xFFA06A50,
    near: 0xFFB48C60,
    ground: 0xFFB07A50,
    groundAlt: 0xFFA87248,
    verge: 0xFFBC9C70,
    banks: 1500,
    clouds: 0.3,
  ),
  RrTheme.valley: _Pal(
    skyTop: 0xFF508CD8,
    skyLow: 0xFFC0DCF0,
    far: 0xFF7A9E78,
    near: 0xFF508A4C,
    ground: 0xFF6CA850,
    groundAlt: 0xFF649E4A,
    verge: 0xFF9E8C60,
    banks: 3200,
    clouds: 0.65,
  ),
  RrTheme.peaks: _Pal(
    skyTop: 0xFF3E68B4,
    skyLow: 0xFFA8C0E0,
    far: 0xFF80828E,
    near: 0xFF58665C,
    ground: 0xFF74866A,
    groundAlt: 0xFF6C7E62,
    verge: 0xFF8C8C84,
    banks: 4200,
    clouds: 0.45,
  ),
};

class RrMenuItem {
  const RrMenuItem(
    this.label, {
    this.right = '',
    this.enabled = true,
    this.tone = 0,
  });

  final String label;
  final String right;
  final bool enabled;

  /// 0 plain, 1 highlighted (yellow), 2 good (green).
  final int tone;
}

class RrMenu {
  const RrMenu({
    required this.title,
    this.info = const [],
    required this.items,
  });

  final String title;
  final List<String> info;
  final List<RrMenuItem> items;
}

/// Paints one game frame in a 240-unit-tall space, which the screen
/// rasterises at [pixelScale]x (480 lines) and scales up unfiltered.
///
/// The world is real, if primitive, 3D: every frame the road, embankments,
/// scenery and low-polygon models are projected on the CPU into one list of
/// textured triangles and drawn back to front. There is no depth buffer and
/// the texture mapping is affine, so surfaces swim and sort like they did on
/// late-90s consoles.
class RrRenderer {
  RrRenderer() : atlas = RrAtlas(), models = RrModels() {
    _bindAtlas();
  }

  /// Re-reads the atlas after it has been extended outside [loadModels].
  @visibleForTesting
  void rebindForTest() {
    _texture.dispose();
    _bindAtlas();
  }

  void _bindAtlas() {
    _texture = ui.ImageShader(
      atlas.image,
      TileMode.clamp,
      TileMode.clamp,
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
      filterQuality: FilterQuality.none,
    );
  }

  static const int height = 240;
  static const int pixelScale = 2;

  /// Height of the strip whose left corner is the pause button.
  static const double hudH = 22;
  static const double viewH = 240;
  static const double horizon = 92;
  static const double focal = 236;
  static const double eye = 650;

  /// The camera sits this far behind the bike's position on the road.
  static const double camBack = 520;
  static const double curveScale = 2;
  static const int drawDistance = 210;
  static const double _near = 110;

  /// The cockpit art is laid out for a 224-unit view and shifted down.
  static const double _baseH = 224;

  /// Text face for the HUD and menus; null uses the platform default.
  static String? fontFamily;
  static String? titleFamily = 'Pricedown';

  /// Applied when the frame is scaled to the screen: slightly desaturated
  /// and lifted, like a composite video signal.
  static const ColorFilter wash = ColorFilter.matrix([
    0.905,
    0.086,
    0.009,
    0,
    7,
    0.026,
    0.966,
    0.009,
    0,
    7,
    0.026,
    0.086,
    0.889,
    0,
    7,
    0,
    0,
    0,
    1,
    0,
  ]);

  static const _white = Color(0xFFF6F6F6);
  static const _yellow = Color(0xFFF6C81E);
  static const _red = Color(0xFFF03A2A);

  /// The photographic dashboard, once [loadDash] has decoded it; until then
  /// (or if it fails) a drawn cockpit stands in.
  ui.Image? dash;

  Future<void> loadDash() async {
    final data = await rootBundle.load('assets/road_rumble/dash.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    dash = (await codec.getNextFrame()).image;
    codec.dispose();
  }

  /// The downloaded bike and rider, once [loadModels] has read them; until
  /// then (or if it fails) the built-in models are used.
  RrImported? imported;

  Future<void> loadModels() async {
    final data = await rootBundle.load('assets/road_rumble/models.bin');
    final png = await rootBundle.load('assets/road_rumble/models.png');
    final codec = await ui.instantiateImageCodec(png.buffer.asUint8List());
    final sheet = (await codec.getNextFrame()).image;
    codec.dispose();
    final at = atlas.addSheet(sheet);
    sheet.dispose();
    _texture.dispose();
    _bindAtlas();
    imported = RrImported.parse(data, at.dx, at.dy);
  }

  final RrAtlas atlas;
  final RrModels models;
  late ui.ImageShader _texture;
  final Paint _flat = Paint()..isAntiAlias = false;
  final Paint _smooth = Paint()..isAntiAlias = false;
  final Paint _img = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
  final Map<int, ui.Image> _skies = {};
  final Map<String, TextPainter> _texts = {};
  final Map<int, Int32List> _tints = {};

  // The frame's triangle list.
  static const int _maxVerts = 180000;
  final Float32List _pos = Float32List(_maxVerts * 2);
  final Float32List _uv = Float32List(_maxVerts * 2);
  final Int32List _col = Int32List(_maxVerts);
  int _n = 0;

  /// Opacity (0..255) of whatever is being appended. Distant things are
  /// drawn part-transparent over the hazy backdrop, so they fade in instead
  /// of popping up at the draw distance.
  int _alpha = 255;

  /// How many more bikes may use the full-detail model this frame; the
  /// nearest riders are drawn last, so the budget is spent far to near and
  /// kept small.
  int _hiBikes = 0;

  static int _fade(double z) {
    final t = ((z / (drawDistance * RrEngine.segL)) - 0.5) / 0.5;
    if (t <= 0) return 255;
    return (255 * (1 - 0.92 * t * t)).round().clamp(0, 255);
  }

  void _dim(int from) {
    for (var i = from; i < _n; i++) {
      final c = _col[i];
      _col[i] = ((((c >>> 24) * _alpha) >> 8) << 24) | (c & 0xFFFFFF);
    }
  }

  // Road cross-sections, near to far.
  static const int _maxRows = drawDistance + 48;
  final Float64List _rz = Float64List(_maxRows);
  final Float64List _rcx = Float64List(_maxRows);
  final Float64List _ry = Float64List(_maxRows);
  final Float64List _rf = Float64List(_maxRows);

  // Lateral stations across each cross-section, in road half-widths, and how
  // much of the embankment height each one carries.
  static const _lx = <double>[
    -14,
    -11,
    -8,
    -6,
    -4.5,
    -3.5,
    -2.6,
    -2.1,
    -1.6,
    -1.12,
    -1,
    -0.75,
    -0.5,
    -0.25,
    0,
    0.25,
    0.5,
    0.75,
    1,
    1.12,
    1.6,
    2.1,
    2.6,
    3.5,
    4.5,
    6,
    8,
    11,
    14,
  ];
  static const _rise = <double>[
    1.1,
    1.06,
    1,
    0.86,
    0.7,
    0.52,
    0.35,
    0.2,
    0.08,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0.08,
    0.2,
    0.35,
    0.52,
    0.7,
    0.86,
    1,
    1.06,
    1.1,
  ];

  // Stations at the road's left and right edges.
  static const int _edgeL = 10;
  static const int _edgeR = 18;
  final Float64List _ax = Float64List(_lx.length);
  final Float64List _ay = Float64List(_lx.length);
  final Float64List _bx = Float64List(_lx.length);
  final Float64List _by = Float64List(_lx.length);
  final Float64List _as = Float64List(_lx.length);
  final Float64List _bs = Float64List(_lx.length);
  final Float64List _rsc = Float64List(_maxRows);
  final Float64List _rcen = Float64List(_maxRows);

  static double _grain(int a, int b) {
    final v = sin(a * 12.9898 + b * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  // Scratch for the model being projected.
  final Float32List _mx = Float32List(16384);
  final Float32List _my = Float32List(16384);
  final Float32List _mz = Float32List(16384);

  void dispose() {
    atlas.dispose();
    dash?.dispose();
    _texture.dispose();
    for (final sky in _skies.values) {
      sky.dispose();
    }
    for (final text in _texts.values) {
      text.dispose();
    }
  }

  // ----------------------------------------------------------------- sky

  static const double _skyTile = 512;
  static const int _skyW = 256;
  static const int _skyH = 64;

  static double _lattice(int x, int y, int period, int seed) {
    final v = sin((x % period) * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// Cloud noise that wraps horizontally so the sky tile repeats cleanly.
  static double _cloud(int x, int y, int seed) {
    var total = 0.0;
    var weight = 0.0;
    for (var o = 0; o < 3; o++) {
      final cell = 32 >> o;
      final period = _skyW ~/ cell;
      final px = x / cell;
      final py = y / (cell * 0.5);
      final x0 = px.floor();
      final y0 = py.floor();
      final fx = px - x0;
      final fy = py - y0;
      final a = _lattice(x0, y0, period, seed + o);
      final b = _lattice(x0 + 1, y0, period, seed + o);
      final cc = _lattice(x0, y0 + 1, period, seed + o);
      final d = _lattice(x0 + 1, y0 + 1, period, seed + o);
      final top = a + (b - a) * fx;
      final bottom = cc + (d - cc) * fx;
      final amp = 1 / (1 << o);
      total += (top + (bottom - top) * fy) * amp;
      weight += amp;
    }
    return total / weight;
  }

  /// A small sky texture: a dithered 15-bit gradient with blocky clouds.
  ui.Image _sky(RrTheme theme) => _skies[theme.index] ??= () {
    final pal = _pals[theme]!;
    final top = Color(pal.skyTop);
    final low = Color(pal.skyLow);
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    final paint = Paint()..isAntiAlias = false;
    const bayer = [0.0, 0.5, 0.75, 0.25];
    for (var y = 0; y < _skyH; y++) {
      for (var x = 0; x < _skyW; x++) {
        final t = pow(y / (_skyH - 1), 1.3).toDouble();
        var color = Color.lerp(top, low, t)!;
        final n = _cloud(x, y, theme.index * 7 + 1);
        final density =
            ((n - (0.66 - pal.clouds * 0.2)) * 5).clamp(0.0, 1.0) *
            (1 - t * 0.55);
        if (density > 0) {
          final lit = _cloud(x, y - 3, theme.index * 7 + 1) < n
              ? 0xFFFFFFFF
              : 0xFFC8D0DC;
          color = Color.lerp(color, Color(lit), density)!;
        }
        final sun = sqrt(pow(x - 190, 2) + pow((y - 15) * 0.73, 2));
        if (sun < 5) {
          color = const Color(0xFFFFF8DC);
        } else if (sun < 20) {
          color = Color.lerp(
            color,
            const Color(0xFFFFF4C8),
            (1 - sun / 20) * 0.6,
          )!;
        }
        // Quantise to five bits a channel with an ordered dither.
        final d = bayer[(x & 1) + (y & 1) * 2];
        int q(double v) =>
            (((v * 31 + d).floor()).clamp(0, 31) * 255 / 31).round();
        c.drawRect(
          Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
          paint
            ..color = Color.fromARGB(255, q(color.r), q(color.g), q(color.b)),
        );
      }
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_skyW, _skyH);
    picture.dispose();
    return image;
  }();

  double _ridge(RrTheme theme, double u) => switch (theme) {
    RrTheme.forest => 15 + 9 * sin(u * 0.017) + 5 * sin(u * 0.041 + 1.3),
    RrTheme.peaks =>
      26 +
          13 * sin(u * 0.021) +
          9 * sin(u * 0.05 + 1.3) +
          4 * sin(u * 0.13 + 4),
    RrTheme.desert => 10 + 9 * sin(u * 0.013).abs() + 3 * sin(u * 0.05 + 2),
    RrTheme.coast => max(0.0, 9 * sin(u * 0.012) - 3) + 5,
    RrTheme.valley => 11 + 7 * sin(u * 0.012) + 4 * sin(u * 0.03 + 1),
  };

  void _backdrop(Canvas c, int w, RrEngine e) {
    final theme = e.track.theme;
    final pal = _pals[theme]!;
    final width = w.toDouble();

    final sky = _sky(theme);
    final shift = (e.skyOffset * 0.35) % _skyTile;
    for (var x = -shift; x < width; x += _skyTile) {
      c.drawImageRect(
        sky,
        Rect.fromLTWH(0, 0, _skyW.toDouble(), _skyH.toDouble()),
        Rect.fromLTWH(x, 0, _skyTile, horizon + 2),
        _img,
      );
    }

    // Two flat ranges of hills.
    final haze = Color(pal.skyLow);
    for (final (parallax, scale, tone) in const [
      (0.5, 1.0, 0.5),
      (0.9, 0.55, 0.22),
    ]) {
      final path = Path()..moveTo(0, horizon + 1);
      for (var x = 0.0; x <= width + 4; x += 4) {
        final u = x + e.skyOffset * parallax + (scale < 1 ? 300 : 0);
        path.lineTo(x, (horizon - _ridge(theme, u) * scale).roundToDouble());
      }
      path
        ..lineTo(width, horizon + 1)
        ..close();
      c.drawPath(
        path,
        _flat
          ..color = Color.lerp(
            Color(scale < 1 ? pal.near : pal.far),
            haze,
            tone,
          )!,
      );
    }
    // Far ground fades into this, so make it the land's colour seen
    // through haze.
    c.drawRect(
      Rect.fromLTRB(0, horizon, width, viewH),
      _smooth
        ..shader = ui.Gradient.linear(
          const Offset(0, horizon),
          const Offset(0, horizon + 12),
          [
            Color.lerp(Color(pal.ground), haze, 0.6)!,
            Color.lerp(Color(pal.ground), haze, 0.12)!,
          ],
        ),
    );
    _smooth.shader = null;
  }

  // ------------------------------------------------------------ geometry

  void _quad(
    double x0,
    double y0,
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
    double u0,
    double v0,
    double u1,
    double v1,
    double u2,
    double v2,
    double u3,
    double v3,
    int color, [
    int? c1,
    int? c2,
    int? c3,
  ]) {
    if (_n + 6 > _maxVerts) return;
    var i = _n * 2;
    void put(double x, double y, double u, double v) {
      _pos[i] = x;
      _pos[i + 1] = y;
      _uv[i] = u;
      _uv[i + 1] = v;
      i += 2;
    }

    put(x0, y0, u0, v0);
    put(x1, y1, u1, v1);
    put(x2, y2, u2, v2);
    put(x0, y0, u0, v0);
    put(x2, y2, u2, v2);
    put(x3, y3, u3, v3);
    if (c1 == null) {
      _col.fillRange(_n, _n + 6, color);
    } else {
      _col[_n] = color;
      _col[_n + 1] = c1;
      _col[_n + 2] = c2!;
      _col[_n + 3] = color;
      _col[_n + 4] = c2;
      _col[_n + 5] = c3!;
    }
    if (_alpha != 255) {
      _n += 6;
      _dim(_n - 6);
      return;
    }
    _n += 6;
  }

  static int _shadeColor(int rgb, double shade) {
    final r = (((rgb >> 16) & 0xFF) * shade).round().clamp(0, 255);
    final g = (((rgb >> 8) & 0xFF) * shade).round().clamp(0, 255);
    final b = ((rgb & 0xFF) * shade).round().clamp(0, 255);
    return 0xFF000000 | (r << 16) | (g << 8) | b;
  }

  /// Slot colours for a rider look (0..15) or a car colour (16..).
  Int32List _tintsFor(int key) => _tints[key] ??= () {
    final out = Int32List(RrSlot.count)
      ..[RrSlot.none] = 0xFFFFFF
      ..[RrSlot.skin] = 0xD0A078
      ..[RrSlot.wood] = 0x9A6E3A
      ..[RrSlot.glowRed] = 0xFF4030
      ..[RrSlot.glowWarm] = 0xFFF0B8
      ..[RrSlot.glowBlue] = 0x4060FF;
    // The cloth and paint tiles are mid-bright, so lift the tint to match.
    int lift(int argb) => _shadeColor(argb, 1.18) & 0xFFFFFF;
    if (key < 16) {
      final look = rrLooks[key];
      out
        ..[RrSlot.jacket] = lift(look.jacket)
        ..[RrSlot.pants] = lift(look.pants)
        ..[RrSlot.helmet] = lift(look.helmet)
        ..[RrSlot.body] = lift(look.bike);
    } else {
      out[RrSlot.body] = lift(rrCarColors[key - 16]);
    }
    return out;
  }();

  late final Int32List _sceneryTints = Int32List(RrSlot.count)
    ..[RrSlot.none] = 0xFFFFFF
    ..[RrModels.pineSlot] = 0x4C8A56
    ..[RrModels.oakSlot] = 0x78B85A
    ..[RrModels.palmSlot] = 0x6AB05E
    ..[RrModels.barnSlot] = 0xC0544A;

  double _bank(double f, double side, double height) =>
      height *
      (0.22 +
          0.78 *
              (0.5 + 0.5 * sin(f * 0.011 + side * 2.1)) *
              (0.5 + 0.5 * sin(f * 0.0043 + side * 0.7 + 1)));

  /// Height of the ground at station [k]: the embankment, plus lumps and
  /// hollows so it isn't a smooth ramp. The right-hand stations are used for
  /// both sides so the two banks differ only by [side].
  double _lift(double f, int k, double side, double height) {
    final rise = _rise[k];
    if (rise == 0) return 0;
    final lumps =
        sin(f * 0.23 + k * 1.9 + side) * 150 + sin(f * 0.61 + k * 0.7) * 70;
    return _bank(f, side, height) * rise + lumps * min(1.0, rise * 2.5);
  }

  /// Height of the ground above the road at lateral offset [ox].
  double _terrain(double f, double ox, double height) {
    final a = ox.abs();
    if (a <= 1.12) return 0;
    for (var k = _edgeR + 1; k < _lx.length - 1; k++) {
      if (a <= _lx[k + 1]) {
        final t = (a - _lx[k]) / (_lx[k + 1] - _lx[k]);
        final lo = _lift(f, k, ox.sign, height),
            hi = _lift(f, k + 1, ox.sign, height);
        return lo + (hi - lo) * t;
      }
    }
    return _lift(f, _lx.length - 1, ox.sign, height);
  }

  /// Projects [parts] (sharing one transform) and appends their faces, far
  /// to near. Rotations are roll (lean), then pitch about [pivotY], then yaw.
  void _model(
    List<RrMesh> parts,
    Int32List tints,
    double half,
    double x0,
    double y0,
    double z0, {
    double yaw = 0,
    double roll = 0,
    double pitch = 0,
    double pivotY = 0,
    double scale = 1,
  }) {
    final cr = cos(roll), sr = sin(roll);
    final cp = cos(pitch), sp = sin(pitch);
    final cw = cos(yaw), sw = sin(yaw);
    final faces = <(RrFace, int)>[];
    var offset = 0;
    for (final mesh in parts) {
      final xyz = mesh.xyz;
      final count = mesh.vertexCount;
      if (offset + count > _mx.length) break;
      for (var i = 0; i < count; i++) {
        final x = xyz[i * 3] * scale,
            y = xyz[i * 3 + 1] * scale,
            z = xyz[i * 3 + 2] * scale;
        final x1 = x * cr + y * sr;
        final y1 = -x * sr + y * cr - pivotY;
        final y2 = y1 * cp - z * sp + pivotY;
        final z2 = y1 * sp + z * cp;
        final cx = x0 + x1 * cw + z2 * sw;
        final cz = z0 - x1 * sw + z2 * cw;
        _mz[offset + i] = cz;
        if (cz > _near) {
          final s = focal / cz;
          _mx[offset + i] = half + cx * s;
          _my[offset + i] = horizon - (y0 + y2) * s;
        }
      }
      for (final face in mesh.faces) {
        faces.add((face, offset));
      }
      offset += count;
    }
    double depth((RrFace, int) f) =>
        _mz[f.$2 + f.$1.a] +
        _mz[f.$2 + f.$1.b] +
        _mz[f.$2 + f.$1.c] +
        _mz[f.$2 + f.$1.d];
    faces.sort((p, q) => depth(q).compareTo(depth(p)));
    for (final (face, o) in faces) {
      final a = o + face.a, b = o + face.b, c = o + face.c, d = o + face.d;
      if (_mz[a] <= _near ||
          _mz[b] <= _near ||
          _mz[c] <= _near ||
          _mz[d] <= _near)
        continue;
      final t = atlas.tiles[face.tile]!;
      final tw = t.width - 1, th = t.height - 1;
      final u0 = t.left + 0.5 + tw * face.u0, u1 = t.left + 0.5 + tw * face.u1;
      final v0 = t.top + 0.5 + th * face.v0, v1 = t.top + 0.5 + th * face.v1;
      final tint = tints[face.slot];
      _quad(
        _mx[a],
        _my[a],
        _mx[b],
        _my[b],
        _mx[c],
        _my[c],
        _mx[d],
        _my[d],
        u0,
        v0,
        u1,
        v0,
        u1,
        v1,
        u0,
        v1,
        _shadeColor(tint, face.shade),
        _shadeColor(tint, face.shadeB),
        _shadeColor(tint, face.shadeC),
        _shadeColor(tint, face.shadeD),
      );
    }
  }

  /// As [_model], for imported triangle meshes.
  void _triModel(
    List<RrTriMesh> parts,
    Int32List tints,
    double half,
    double x0,
    double y0,
    double z0, {
    double yaw = 0,
    double roll = 0,
    double pitch = 0,
    double pivotY = 0,
  }) {
    const stride = RrTriMesh.stride;
    final cr = cos(roll), sr = sin(roll);
    final cp = cos(pitch), sp = sin(pitch);
    final cw = cos(yaw), sw = sin(yaw);
    // (part, first vertex) of every triangle in front of the camera.
    final tris = <int>[];
    var offset = 0;
    for (var part = 0; part < parts.length; part++) {
      final data = parts[part].data;
      final count = parts[part].vertexCount;
      if (offset + count > _mx.length) break;
      for (var i = 0; i < count; i++) {
        final x = data[i * stride],
            y = data[i * stride + 1],
            z = data[i * stride + 2];
        final x1 = x * cr + y * sr;
        final y1 = -x * sr + y * cr - pivotY;
        final y2 = y1 * cp - z * sp + pivotY;
        final z2 = y1 * sp + z * cp;
        final cx = x0 + x1 * cw + z2 * sw;
        final cz = z0 - x1 * sw + z2 * cw;
        _mz[offset + i] = cz;
        if (cz > _near) {
          final s = focal / cz;
          _mx[offset + i] = half + cx * s;
          _my[offset + i] = horizon - (y0 + y2) * s;
        }
      }
      for (var i = 0; i < count; i += 3) {
        final v = offset + i;
        if (_mz[v] > _near && _mz[v + 1] > _near && _mz[v + 2] > _near) {
          tris.add((part << 20) | i);
        }
      }
      offset += count;
    }
    final starts = <int>[0];
    for (final part in parts) {
      starts.add(starts.last + part.vertexCount);
    }
    double depth(int t) {
      final v = starts[t >> 20] + (t & 0xFFFFF);
      return _mz[v] + _mz[v + 1] + _mz[v + 2];
    }

    tris.sort((p, q) => depth(q).compareTo(depth(p)));
    for (final t in tris) {
      if (_n + 3 > _maxVerts) return;
      final data = parts[t >> 20].data;
      final local = t & 0xFFFFF;
      final v = starts[t >> 20] + local;
      for (var k = 0; k < 3; k++) {
        final src = (local + k) * stride;
        final at = _n * 2;
        _pos[at] = _mx[v + k];
        _pos[at + 1] = _my[v + k];
        _uv[at] = data[src + 3];
        _uv[at + 1] = data[src + 4];
        // The rider's hoodie texture is mid-grey, so its tint needs a lift.
        final slot = data[src + 6].round();
        _col[_n] = _shadeColor(
          tints[slot],
          data[src + 5] * (slot == RrSlot.jacket ? 2.0 : 1.0),
        );
        _n++;
      }
      if (_alpha != 255) _dim(_n - 3);
    }
  }

  /// Draws a bike with its rider, or either alone, using the downloaded
  /// models when they are loaded and the built-in ones otherwise.
  void _rider3d(
    Int32List tints,
    double half,
    double x0,
    double y0,
    double z0, {
    bool bike = true,
    int? pose,
    int? runner,
    bool far = false,
    bool cop = false,
    double yaw = 0,
    double roll = 0,
    double pitch = 0,
    double pivotY = 0,
  }) {
    final imp = imported;
    if (imp != null) {
      _triModel(
        [
          if (bike)
            far
                ? imp.bikeFar
                : (z0 < 2400 && _hiBikes-- > 0 ? imp.bikeHi : imp.bike),
          if (pose != null) far ? imp.riderFar : imp.riders[pose],
          if (runner != null) imp.runners[runner],
        ],
        tints,
        half,
        x0,
        y0,
        z0,
        yaw: yaw,
        roll: roll,
        pitch: pitch,
        pivotY: pivotY,
      );
      return;
    }
    _model(
      [
        if (bike) far ? models.farBike : (cop ? models.copBike : models.bike),
        if (pose != null) far ? models.farRider : models.riders[pose],
        if (runner != null) models.runners[runner],
      ],
      tints,
      half,
      x0,
      y0,
      z0,
      yaw: yaw,
      roll: roll,
      pitch: pitch,
      pivotY: pivotY,
    );
  }

  /// A blob shadow on the ground under a model.
  void _shadow(
    double half,
    double x0,
    double y0,
    double z0,
    double yaw,
    double hw,
    double hl,
  ) {
    if (z0 - hl <= _near) return;
    final cw = cos(yaw), sw = sin(yaw);
    final t = atlas.tiles[RrTile.shadow]!;
    final xs = Float64List(4), ys = Float64List(4);
    const corners = [(-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)];
    for (var i = 0; i < 4; i++) {
      final lx = corners[i].$1 * hw + 40, lz = corners[i].$2 * hl;
      final cz = z0 - lx * sw + lz * cw;
      final s = focal / cz;
      xs[i] = half + (x0 + lx * cw + lz * sw) * s;
      ys[i] = horizon - (y0 + 6) * s;
    }
    _quad(
      xs[0],
      ys[0],
      xs[1],
      ys[1],
      xs[2],
      ys[2],
      xs[3],
      ys[3],
      t.left + 0.5,
      t.top + 0.5,
      t.right - 0.5,
      t.top + 0.5,
      t.right - 0.5,
      t.bottom - 0.5,
      t.left + 0.5,
      t.bottom - 0.5,
      0xFFFFFFFF,
    );
  }

  /// A camera-facing blob of dust or smoke.
  void _puff(
    double half,
    double x0,
    double y0,
    double z0,
    double size,
    int rgb,
    double alpha,
  ) {
    if (z0 <= _near) return;
    final s = focal / z0;
    final t = atlas.tiles[RrTile.puff]!;
    final sx = half + x0 * s, sy = horizon - y0 * s, r = size * s / 2;
    final color =
        ((alpha.clamp(0.0, 1.0) * 255).round() << 24) |
        (_shadeColor(rgb, 1.2) & 0xFFFFFF);
    _quad(
      sx - r,
      sy - r,
      sx + r,
      sy - r,
      sx + r,
      sy + r,
      sx - r,
      sy + r,
      t.left + 0.5,
      t.top + 0.5,
      t.right - 0.5,
      t.top + 0.5,
      t.right - 0.5,
      t.bottom - 0.5,
      t.left + 0.5,
      t.bottom - 0.5,
      color,
    );
  }

  int _pose(RrRider r) {
    if (r.attackT <= 0) return RrModels.poseRide;
    final left = r.attackSide < 0;
    if (r.attackKick) return left ? RrModels.poseKickL : RrModels.poseKickR;
    if (r.club) return left ? RrModels.poseClubL : RrModels.poseClubR;
    return left ? RrModels.posePunchL : RrModels.posePunchR;
  }

  void _road(Canvas c, int w, RrEngine e, double clock, {bool chase = false}) {
    const segL = RrEngine.segL;
    const roadW = RrEngine.roadW;
    final pal = _pals[e.track.theme]!;
    final half = w / 2;
    final p = e.player;

    // After a wipeout the camera pulls back and up to show the wreck.
    final pull = chase
        ? 1.0
        : (e.crashed ? (e.crashAge / 0.4).clamp(0.0, 1.0) : 0.0);
    final back = camBack + 1500 * pull;
    final camZ = p.z - back;
    final base = (camZ / segL).floor();
    final basePct = (camZ - base * segL) / segL;
    // Off the tarmac the bike (and the camera) rides up the embankment.
    final camY =
        e.heightAt(p.z) +
        eye +
        350 * pull +
        _terrain(p.z / segL, p.x, pal.banks);
    final camX = p.x * roadW;

    // Cross-sections of the road, near to far, finer close to the camera.
    var x = 0.0;
    var dx = -(e.curveAt(base) * basePct);
    var rows = 0;
    var last = base;
    for (var n = 0; n < drawDistance; n++) {
      final i = base + n;
      if (i < 0 || i + 1 >= e.segCount) break;
      final sub = n < 10 ? 4 : 1;
      for (var k = 0; k < sub; k++) {
        final f = k / sub;
        final z = (i + f) * segL - camZ;
        if (z < _near) continue;
        _rz[rows] = z;
        _rcx[rows] = (x + dx * f) * curveScale;
        _ry[rows] = e.pointY(i) + (e.pointY(i + 1) - e.pointY(i)) * f;
        _rf[rows] = i + f;
        rows++;
      }
      x += dx;
      dx += e.curveAt(i);
      last = i + 1;
    }
    if (rows < 2) return;
    _rz[rows] = last * segL - camZ;
    _rcx[rows] = x * curveScale;
    _ry[rows] = e.pointY(last);
    _rf[rows] = last.toDouble();
    rows++;

    // Everything standing in the world, far to near.
    final items = <(double, Object)>[];
    final firstSeg = _rf[0].floor() + 1;
    for (var i = firstSeg; i < last; i++) {
      final list = e.props[i];
      if (list == null) continue;
      for (final prop in list) {
        items.add((i * segL + 1, prop));
      }
    }
    final nearZ = camZ + _rz[0];
    final farZ = camZ + _rz[rows - 1];
    for (final car in e.cars) {
      if (car.z > nearZ && car.z < farZ) items.add((car.z, car));
    }
    for (final r in [...e.rivals, ...e.cops]) {
      if (r.z > nearZ && r.z < farZ) items.add((r.z, r));
    }
    if (e.crashed || chase) items.add((p.z, p));
    items.sort((a, b) => b.$1.compareTo(a.$1));

    final road = atlas.tiles[RrTile.road]!;
    final grass = atlas.tiles[RrTile.grass]!;
    final dirt = atlas.tiles[RrTile.dirt]!;
    final groundA = _shadeColor(pal.ground, 1.2);
    final groundB = _shadeColor(pal.groundAlt, 1.2);
    final verge = _shadeColor(pal.verge, 1.15);

    void section(int r, Float64List xs, Float64List ys, Float64List shades) {
      final s = focal / _rz[r];
      final centre = half + s * (-camX - _rcx[r]);
      _rsc[r] = s;
      _rcen[r] = centre;
      final key = (_rf[r] * 4).round();
      for (var k = 0; k < _lx.length; k++) {
        // Mirror the station index so both banks share one height profile.
        final lift = _lift(
          _rf[r],
          k < _edgeL ? _lx.length - 1 - k : k,
          _lx[k].sign,
          pal.banks,
        );
        xs[k] = centre + s * _lx[k] * roadW;
        ys[k] = horizon - s * (_ry[r] + lift - camY);
        // Uneven vertex lighting breaks up the flat ground.
        shades[k] = 0.8 + 0.2 * _grain(key, k);
      }
    }

    _n = 0;
    _hiBikes = 3;
    var item = 0;
    var farX = _ax, farY = _ay, nearX = _bx, nearY = _by;
    var farS = _as, nearS = _bs;
    section(rows - 1, farX, farY, farS);
    for (var r = rows - 2; r >= 0; r--) {
      section(r, nearX, nearY, nearS);

      // The strip of ground between this cross-section and the next.
      _alpha = _fade((_rz[r] + _rz[r + 1]) / 2);
      final fNear = _rf[r], fFar = _rf[r + 1];
      final seg = fNear.floor();
      final roadBase = (seg ~/ 6) * 6;
      final rv0 = road.top + (fNear - roadBase) * 16,
          rv1 = road.top + (fFar - roadBase) * 16;
      final tileBase = (seg ~/ 4) * 4;
      final gv0 = (fNear - tileBase) * 16, gv1 = (fFar - tileBase) * 16;
      final band = (seg ~/ 3).isEven;
      for (var k = 0; k < _lx.length - 1; k++) {
        final onRoad = k >= _edgeL && k < _edgeR;
        final onVerge = k == _edgeL - 1 || k == _edgeR;
        double u0, u1, v0, v1;
        int color;
        if (onRoad) {
          u0 = road.left + (_lx[k] + 1) * 128;
          u1 = road.left + (_lx[k + 1] + 1) * 128;
          v0 = rv0;
          v1 = rv1;
          color = band ? 0xFFFFFFFF : 0xFFF2F2F2;
        } else {
          final t = onVerge ? dirt : grass;
          u0 = t.left + 0.5;
          u1 = t.right - 0.5;
          v0 = t.top + gv0;
          v1 = t.top + gv1;
          // The sun is to the left: banks facing it are brighter.
          final lit = k < _edgeL - 1 ? 0.84 : (k > _edgeR ? 1.0 : 0.94);
          final base = onVerge ? verge : (band ? groundA : groundB);
          _quad(
            nearX[k],
            nearY[k],
            nearX[k + 1],
            nearY[k + 1],
            farX[k + 1],
            farY[k + 1],
            farX[k],
            farY[k],
            u0,
            v0,
            u1,
            v0,
            u1,
            v1,
            u0,
            v1,
            _shadeColor(base, lit * nearS[k]),
            _shadeColor(base, lit * nearS[k + 1]),
            _shadeColor(base, lit * farS[k + 1]),
            _shadeColor(base, lit * farS[k]),
          );
          continue;
        }
        _quad(
          nearX[k],
          nearY[k],
          nearX[k + 1],
          nearY[k + 1],
          farX[k + 1],
          farY[k + 1],
          farX[k],
          farY[k],
          u0,
          v0,
          u1,
          v0,
          u1,
          v1,
          u0,
          v1,
          color,
        );
      }

      // Armco along the outside of bends.
      final bend = e.curveAt(seg);
      if (bend.abs() > 1.2) {
        final lateral = (bend > 0 ? -1.07 : 1.07) * roadW;
        final metal = atlas.tiles[RrTile.metal]!;
        final sn = _rsc[r], sf = _rsc[r + 1];
        final xn = _rcen[r] + sn * lateral, xf = _rcen[r + 1] + sf * lateral;
        double yAt(int row, double h) =>
            horizon - _rsc[row] * (_ry[row] + h - camY);
        _quad(
          xn,
          yAt(r, 150),
          xf,
          yAt(r + 1, 150),
          xf,
          yAt(r + 1, 55),
          xn,
          yAt(r, 55),
          metal.left + 0.5,
          metal.top + 0.5,
          metal.right - 0.5,
          metal.top + 0.5,
          metal.right - 0.5,
          metal.bottom - 0.5,
          metal.left + 0.5,
          metal.bottom - 0.5,
          seg.isEven ? 0xFFE0E0E0 : 0xFFC4C4C4,
        );
        if (seg % 3 == 0) {
          final wPost = sn * 26;
          _quad(
            xn - wPost,
            yAt(r, 150),
            xn + wPost,
            yAt(r, 150),
            xn + wPost,
            yAt(r, 0),
            xn - wPost,
            yAt(r, 0),
            metal.left + 0.5,
            metal.top + 0.5,
            metal.right - 0.5,
            metal.top + 0.5,
            metal.right - 0.5,
            metal.bottom - 0.5,
            metal.left + 0.5,
            metal.bottom - 0.5,
            0xFF909090,
          );
        }
      }

      // Then whatever stands on it.
      final stripNear = camZ + _rz[r], stripFar = camZ + _rz[r + 1];
      while (item < items.length && items[item].$1 >= stripFar) {
        item++;
      }
      while (item < items.length && items[item].$1 >= stripNear) {
        final (z, thing) = items[item++];
        final t = (z - stripNear) / (stripFar - stripNear);
        final cx = _rcx[r] + (_rcx[r + 1] - _rcx[r]) * t;
        final roadY = _ry[r] + (_ry[r + 1] - _ry[r]) * t;
        final z0 = z - camZ;
        _alpha = _fade(z0);
        final yaw = atan2(-(_rcx[r + 1] - _rcx[r]), _rz[r + 1] - _rz[r]);
        double at(double ox) => ox * roadW - camX - cx;
        switch (thing) {
          case RrRoadside prop:
            if (z0 <= _near) break;
            // Pulled back, scenery between the camera and the bike would
            // block the view.
            if (pull > 0 && z0 < back + 300) break;
            final solid = models.scenery[prop.kind.name];
            if (solid != null && z0 < 11000 && z0 > 700) {
              // Each one is turned and sized a little differently.
              final seed = (z / segL).round() * 31 + (prop.x * 100).round();
              final y0 = roadY + _terrain(_rf[r], prop.x, pal.banks) - camY;
              final size = 0.85 + 0.3 * _grain(seed, 3);
              final wide = RrPropArt.worldWidth(prop.kind) * 0.4;
              _shadow(half, at(prop.x), y0, z0, 0, wide, wide);
              _model(
                [solid],
                _sceneryTints,
                half,
                at(prop.x),
                y0,
                z0,
                yaw: prop.kind == RrProp.fence || prop.kind == RrProp.barn
                    ? yaw
                    : _grain(seed, 7) * 2 * pi,
                scale: size,
              );
              break;
            }
            final rect = atlas.props[prop.kind]!;
            final s = focal / z0;
            final wide = RrPropArt.worldWidth(prop.kind) * s;
            final tall = wide * rect.height / rect.width;
            final sx = half + at(prop.x) * s;
            final sy =
                horizon -
                (roadY + _terrain(_rf[r], prop.x, pal.banks) - camY) * s;
            _quad(
              sx - wide / 2,
              sy - tall,
              sx + wide / 2,
              sy - tall,
              sx + wide / 2,
              sy,
              sx - wide / 2,
              sy,
              rect.left + 0.5,
              rect.top + 0.5,
              rect.right - 0.5,
              rect.top + 0.5,
              rect.right - 0.5,
              rect.bottom - 0.5,
              rect.left + 0.5,
              rect.bottom - 0.5,
              0xFFFFFFFF,
            );
          case RrCar car:
            final y0 = roadY + _terrain(_rf[r], car.x, pal.banks) - camY;
            final facing = car.oncoming ? yaw + pi : yaw;
            _shadow(half, at(car.x), y0, z0, yaw, 430, 960);
            _model(
              [car.look.isOdd ? models.truck : models.car],
              _tintsFor(16 + car.look ~/ 2),
              half,
              at(car.x),
              y0,
              z0,
              yaw: facing,
            );
          case RrRider rider:
            final y0 = roadY + _terrain(_rf[r], rider.x, pal.banks) - camY;
            final tints = _tintsFor(rider.look);
            if (identical(rider, p) && e.crashed) {
              _wreck(e, half, at(p.x), y0, z0, yaw, clock);
            } else if (rider.down) {
              _shadow(half, at(rider.x), y0, z0, yaw, 420, 420);
              // Rolled onto its side: lift and shift so it rests on the ground.
              _rider3d(
                tints,
                half,
                at(rider.x) - 260,
                y0 + 175,
                z0,
                cop: rider.isCop,
                yaw: yaw + 0.5,
                roll: 1.4,
              );
              _rider3d(
                tints,
                half,
                at(rider.x) + 420,
                y0 + 90,
                z0 + 120,
                bike: false,
                pose: 0,
                yaw: yaw,
                roll: -1.45,
              );
            } else {
              _shadow(half, at(rider.x), y0, z0, yaw, 190, 480);
              _rider3d(
                tints,
                half,
                at(rider.x),
                y0,
                z0,
                pose: _pose(rider),
                far: z0 > (imported == null ? 7000 : 3800),
                cop: rider.isCop,
                yaw: yaw,
                roll: rider.lean * 0.3,
              );
              if (rider.x.abs() > 1.05 && rider.speed > 1500) {
                for (var j = 0; j < 3; j++) {
                  final phase = (clock * 2.6 + j / 3 + rider.look * 0.37) % 1;
                  _puff(
                    half,
                    at(rider.x),
                    y0 + 90 + phase * 240,
                    z0 - 320 - phase * 700,
                    260 + phase * 560,
                    pal.verge,
                    0.8 * (1 - phase),
                  );
                }
              }
            }
        }
      }

      final swapX = farX, swapY = farY, swapS = farS;
      farX = nearX;
      farY = nearY;
      farS = nearS;
      nearX = swapX;
      nearY = swapY;
      nearS = swapS;
    }

    _alpha = 255;
    if (_n == 0) return;
    final vertices = ui.Vertices.raw(
      ui.VertexMode.triangles,
      Float32List.sublistView(_pos, 0, _n * 2),
      textureCoordinates: Float32List.sublistView(_uv, 0, _n * 2),
      colors: Int32List.sublistView(_col, 0, _n),
    );
    c.drawVertices(
      vertices,
      BlendMode.modulate,
      Paint()
        ..isAntiAlias = false
        ..shader = _texture,
    );
    vertices.dispose();
  }

  /// The player's bike on its side, with the thrown rider further up the road.
  void _wreck(
    RrEngine e,
    double half,
    double x0,
    double y0,
    double z0,
    double yaw,
    double clock,
  ) {
    final tints = _tintsFor(0);
    _shadow(half, x0, y0, z0, yaw, 420, 420);
    // Rolled onto its side: lift and shift so it rests on the ground.
    _rider3d(tints, half, x0 - 260, y0 + 175, z0, yaw: yaw + 0.6, roll: 1.4);
    for (var j = 0; j < 4; j++) {
      final phase = (clock * 0.9 + j / 4) % 1;
      _puff(
        half,
        x0 + 60,
        y0 + 200 + phase * 900,
        z0,
        300 + phase * 700,
        0x707070,
        0.7 * (1 - phase),
      );
    }
    final ahead = e.riderOffset;
    final rz = z0 + ahead;
    if (e.tumbling) {
      final arc = sin((ahead / max(1.0, ahead + 600)) * pi) * 500;
      _shadow(half, x0 + 150, y0, rz, yaw, 200, 260);
      _rider3d(
        tints,
        half,
        x0 + 150,
        y0 + arc,
        rz,
        bike: false,
        pose: 0,
        yaw: yaw,
        pitch: clock * 11,
        pivotY: 520,
      );
    } else {
      _shadow(half, x0 + 150, y0, rz, yaw, 170, 170);
      _rider3d(
        tints,
        half,
        x0 + 150,
        y0,
        rz,
        bike: false,
        runner: (clock * 9).floor() & 1,
        yaw: yaw + pi,
      );
    }
  }

  // ----------------------------------------------------------- dashboard

  /// Units per pixel of the dashboard photo it was cut from, and how much of
  /// its top is in view.
  static const double _dashUnit = 0.175;
  static const double _dashShown = 78;

  /// The dashboard photo with the live instruments drawn over it. Positions
  /// are given in the source photo's pixels.
  void _dashboard(Canvas c, int w, RrEngine e, double clock, double pct) {
    final img = dash!;
    final p = e.player;
    final cx = w / 2;
    const top = viewH - _dashShown;
    Offset at(double sx, double sy) =>
        Offset(cx + (sx - 724) * _dashUnit, top + (sy - 200) * _dashUnit);

    c.save();
    // The bars follow the steering and buzz with the engine.
    c.translate(cx, viewH + 40);
    c.rotate(p.lean * 0.04);
    c.translate(
      -cx - p.lean * 4,
      -viewH - 40 + (sin(clock * 46) * 0.5 * pct).roundToDouble(),
    );
    // Laid out from the source photo's size, whatever resolution the cut is.
    const wide = 1448 * _dashUnit;
    final tall = wide * img.height / img.width;
    c.drawImageRect(
      img,
      Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      Rect.fromLTWH(cx - wide / 2, top, wide, tall),
      _img,
    );

    void needle(Offset pivot, double degrees, double length) {
      final a = degrees * pi / 180;
      final tip = pivot + Offset(cos(a), sin(a)) * (length * _dashUnit);
      final line = Paint()
        ..isAntiAlias = false
        ..strokeCap = StrokeCap.square;
      c.drawLine(
        pivot,
        tip,
        line
          ..strokeWidth = 1.6
          ..color = const Color(0xFF5A1410),
      );
      c.drawLine(
        pivot,
        tip,
        line
          ..strokeWidth = 1.0
          ..color = const Color(0xFFE02A20),
      );
      c.drawCircle(pivot, 1.4, _flat..color = const Color(0xFF20201C));
    }

    // km/h sweeps from 0 at lower left, over the top, to 320 at lower right.
    final kmh = (e.mph * 1.609).clamp(0.0, 330.0);
    needle(at(506, 530), 160 + kmh / 320 * 220, 110);
    final gear = (pct * 5) - (pct * 5).floorToDouble();
    final revs = p.speed < 50
        ? 0.06
        : 0.22 + 0.62 * (pct >= 0.999 ? 1.0 : gear);
    needle(at(939, 530), 190 + revs * 162, 100);

    // Readouts: place above, race clock below.
    final place = at(724, 383);
    _text(c, '${e.place}', place.dx, place.dy, 8.5, _white);
    final time = at(724, 580);
    _text(c, clockText(e.time), time.dx, time.dy, 7.5, _white);
    final gearLabel = p.speed < 50
        ? 'N'
        : '${1 + (pct * 5).floor().clamp(0, 4)}';
    final gearAt = at(1066, 386);
    _text(
      c,
      'GEAR $gearLabel',
      gearAt.dx,
      gearAt.dy,
      6,
      const Color(0xFFF03A2A),
      align: -1,
    );

    // The centre strip shows the bike's condition; the wedges show stamina,
    // yours on the left and the nearest rider's on the right. Each is the
    // photo's full bar with the lost part blacked out.
    const dark = Color(0xFF14140F);
    final health = 1 - e.bikeDamage / 100;
    c.drawRect(
      Rect.fromPoints(
        at(606 + 200 * health.clamp(0.0, 1.0), 314),
        at(806, 345),
      ),
      _flat..color = dark,
    );
    void wedge(double x0, double slant, double value) {
      final lost = 125 * (1 - value.clamp(0.0, 1.0));
      if (lost <= 0) return;
      final path = Path()
        ..moveTo(at(x0 - 2, 464).dx, at(x0 - 2, 464).dy)
        ..lineTo(at(x0 + 70, 464).dx, at(x0 + 70, 464).dy)
        ..lineTo(
          at(x0 + 70 + slant * lost, 464 + lost).dx,
          at(0, 464 + lost).dy,
        )
        ..lineTo(at(x0 - 2 + slant * lost, 464 + lost).dx, at(0, 464 + lost).dy)
        ..close();
      c.drawPath(path, _flat..color = dark);
    }

    wedge(249, -0.57, p.stamina / p.maxStamina);
    final near = e.nearRider;
    wedge(1131, 0.57, near == null ? 0 : near.stamina / near.maxStamina);
    c.restore();

    _label(
      c,
      p.club ? 'YOU + CLUB' : 'YOU',
      cx - 118,
      viewH - 13,
      8,
      p.club ? _yellow : _white,
      align: 1,
    );
    if (near != null) {
      final blink = near.isCop && (clock * 4).floor().isEven;
      _label(
        c,
        near.name,
        cx + 118,
        viewH - 13,
        8,
        blink ? const Color(0xFF6090FF) : (near.club ? _yellow : _white),
        align: -1,
      );
    }
  }

  // ---------------------------------------------------------------- race

  /// [clock] is wall time in seconds, used only for blinking/animation.
  ///
  /// With [world] false only the cockpit, effects and HUD are painted, on a
  /// transparent frame, for laying over the WebGL view of the road.
  void race(
    Canvas canvas,
    int w,
    RrEngine e,
    double clock, {
    bool world = true,
  }) {
    final width = w.toDouble();
    final p = e.player;
    final pct = (p.speed / e.bike.topSpeed).clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, width, viewH));

    // Rattle on the dirt and on impact.
    canvas.save();
    final rough = e.offRoad && p.speed > 800;
    final jolt = e.crashed && e.crashAge < 0.35;
    if (rough || jolt) {
      final amp = jolt ? 3.0 : 1.0;
      canvas.translate(
        (sin(clock * 71) * amp).roundToDouble(),
        (cos(clock * 53) * amp).roundToDouble(),
      );
    }
    if (!e.crashed) {
      // Lean the whole view into the turn.
      canvas.translate(width / 2, horizon);
      canvas.rotate(-p.lean * 0.05);
      canvas.scale(1.08);
      canvas.translate(-width / 2, -horizon);
    }
    if (world) {
      _backdrop(canvas, w, e);
      _road(canvas, w, e, clock);
    }
    canvas.restore();

    if (pct > 0.72 && !e.crashed) {
      // Wind streaks at speed.
      final strength = (pct - 0.72) / 0.28;
      final streak = Paint()
        ..isAntiAlias = false
        ..strokeWidth = 1
        ..color = Color.fromARGB((70 * strength).round(), 255, 255, 255);
      final tick = (clock * 24).floor();
      for (var i = 0; i < 10; i++) {
        final a = _grain(tick, i) * 2 * pi;
        final near = width * (0.32 + 0.2 * _grain(i, tick));
        final dir = Offset(cos(a), sin(a) * 0.6);
        final from = Offset(width / 2, horizon + 20) + dir * near;
        canvas.drawLine(from, from + dir * (18 + 26 * strength), streak);
      }
    }
    if (e.hurtT > 0) {
      canvas.drawRect(
        Rect.fromLTRB(0, 0, width, viewH),
        _flat
          ..color = Color.fromARGB(
            (50 * e.hurtT / 0.35).round().clamp(0, 255),
            220,
            20,
            10,
          ),
      );
    }

    if (!e.crashed) {
      canvas.save();
      canvas.translate(0, viewH - _baseH);
      if (dash == null) _cockpit(canvas, w, e, clock, pct);
      // Over the WebGL view the player's own body is part of the scene.
      if (world) _arms(canvas, w, e);
      canvas.restore();
      if (!world) {
        // Over the WebGL view the race is seen from behind the bike, where
        // a dashboard would only be in the way: a small readout stands in.
        _readout(canvas, w, e);
      } else if (dash != null) {
        _dashboard(canvas, w, e, clock, pct);
      }
    }
    _popups(canvas, w, e);
    if (e.flashT > 0) {
      _spark(
        canvas,
        width / 2 + e.flashSide * width * 0.3,
        112,
        20 * (e.flashT / 0.12),
      );
    }
    if (e.copActive && (clock * 3).floor().isEven) {
      // The lights behind strobe across the top of the screen.
      canvas.drawRect(
        Rect.fromLTRB(0, 0, width, 3),
        _flat
          ..color = (clock * 1.5).floor().isEven
              ? const Color(0xFFFF2020)
              : const Color(0xFF2040FF),
      );
    }
    _overlay(canvas, w, e, clock);
    canvas.restore();
  }

  // ---------------------------------------------------------------- text

  void _text(
    Canvas c,
    String text,
    double x,
    double y,
    double size,
    Color color, {
    int align = 0,
    bool outline = false,
    bool title = false,
  }) {
    final key = '$text|$size|${color.toARGB32()}|$outline|$title';
    var tp = _texts[key];
    if (tp == null) {
      if (_texts.length > 160) {
        for (final old in _texts.values) {
          old.dispose();
        }
        _texts.clear();
      }
      final style = TextStyle(
        fontFamily: title ? titleFamily : fontFamily,
        fontSize: size,
        height: 1,
        fontWeight: title ? FontWeight.w400 : FontWeight.w800,
        letterSpacing: title ? 0.6 : 0,
        color: outline ? null : color,
        foreground: outline
            ? (Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = size * 0.22
                ..strokeJoin = StrokeJoin.round
                ..color = color)
            : null,
      );
      tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      _texts[key] = tp;
    }
    final dx = align == 0 ? -tp.width / 2 : (align > 0 ? -tp.width : 0.0);
    tp.paint(c, Offset(x + dx, y));
  }

  /// Text with a dark edge so it stays readable over the road.
  void _label(
    Canvas c,
    String text,
    double x,
    double y,
    double size,
    Color color, {
    int align = 0,
    bool title = false,
  }) {
    _text(
      c,
      text,
      x,
      y,
      size,
      const Color(0xE0000000),
      align: align,
      outline: true,
      title: title,
    );
    _text(c, text, x, y, size, color, align: align, title: title);
  }

  void _spark(Canvas c, double x, double y, double r) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final a = i * pi / 8;
      final rad = i.isEven ? r : r * 0.42;
      final pt = Offset(x + cos(a) * rad, y + sin(a) * rad);
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    c.drawPath(path, _smooth..color = const Color(0xFFFFE860));
    c.drawCircle(
      Offset(x, y),
      r * 0.35,
      _smooth..color = const Color(0xFFFFFFFF),
    );
  }

  /// A tapered, lit limb from [from] to [to].
  void _limb(
    Canvas c,
    Offset from,
    Offset to,
    double w0,
    double w1,
    Color color,
  ) {
    final d = to - from;
    final n = Offset(-d.dy, d.dx) / d.distance;
    Path quad(double a, double b, double shift) => Path()
      ..moveTo(from.dx + n.dx * (a + shift), from.dy + n.dy * (a + shift))
      ..lineTo(to.dx + n.dx * (b + shift), to.dy + n.dy * (b + shift))
      ..lineTo(to.dx - n.dx * (b - shift), to.dy - n.dy * (b - shift))
      ..lineTo(from.dx - n.dx * (a - shift), from.dy - n.dy * (a - shift))
      ..close();
    c.drawPath(
      quad(w0 / 2 + 1.2, w1 / 2 + 1.2, 0),
      _smooth..color = const Color(0xFF0C0C10),
    );
    c.drawPath(
      quad(w0 / 2, w1 / 2, 0),
      _smooth
        ..shader = ui.Gradient.linear(
          from + n * (w0 / 2),
          from - n * (w0 / 2),
          n.dy < 0
              ? [
                  Color.lerp(color, _white, 0.3)!,
                  color,
                  Color.lerp(color, const Color(0xFF000000), 0.45)!,
                ]
              : [
                  Color.lerp(color, const Color(0xFF000000), 0.45)!,
                  color,
                  Color.lerp(color, _white, 0.3)!,
                ],
          const [0, 0.5, 1],
        ),
    );
    _smooth.shader = null;
  }

  /// Speed, gear, and the state of bike and rider, at the foot of the screen.
  void _readout(Canvas c, int w, RrEngine e) {
    final p = e.player;
    final cx = w / 2;
    final soft = Paint()..isAntiAlias = true;
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - 74, viewH - 31, cx + 74, viewH - 4),
      const Radius.circular(4),
    );
    c.drawRRect(panel, soft..color = const Color(0x99100A1A));
    c.drawRRect(
      panel,
      soft
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = const Color(0x55F0E8B8),
    );
    soft.style = PaintingStyle.fill;
    final kmh = (e.mph * 1.609).round();
    _label(c, '$kmh', cx - 36, viewH - 29, 15, _white, align: 1);
    _label(
      c,
      'KM/H',
      cx - 33,
      viewH - 20,
      6,
      const Color(0xFFF0E8B8),
      align: -1,
    );
    final pct = (p.speed / e.bike.topSpeed).clamp(0.0, 1.0);
    final gear = p.speed < 50 ? 'N' : '${1 + (pct * 5).floor().clamp(0, 4)}';
    _label(
      c,
      'GEAR $gear',
      cx - 33,
      viewH - 12,
      6,
      const Color(0xFFF07020),
      align: -1,
    );
    void bar(String name, double y, double value, Color color) {
      _label(c, name, cx + 4, y - 1.5, 5.5, const Color(0xFFF0E8B8), align: -1);
      final track = Rect.fromLTRB(cx + 30, y, cx + 68, y + 4);
      c.drawRect(track, _flat..color = const Color(0xCC000000));
      c.drawRect(
        Rect.fromLTRB(
          track.left,
          y,
          track.left + track.width * value.clamp(0.0, 1.0),
          y + 4,
        ),
        _flat..color = color,
      );
    }

    final health = 1 - e.bikeDamage / 100;
    bar(
      'BIKE',
      viewH - 26,
      health,
      health > 0.35 ? const Color(0xFF5CD060) : const Color(0xFFE8392C),
    );
    bar('YOU', viewH - 18, p.stamina / p.maxStamina, const Color(0xFFF0C030));
    final near = e.nearRider;
    if (near != null) {
      bar(
        near.name.length > 6 ? near.name.substring(0, 6) : near.name,
        viewH - 10,
        near.stamina / near.maxStamina,
        near.isCop ? const Color(0xFF6090FF) : const Color(0xFFE8392C),
      );
    }
  }

  /// Money for an exchange of blows, floating up from where it ended.
  void _popups(Canvas c, int w, RrEngine e) {
    for (final popup in e.popups) {
      final t = popup.age / RrPopup.life;
      final alpha = (t < 0.75 ? 1.0 : (1 - t) / 0.25).clamp(0.0, 1.0);
      // It lands with a bounce, then drifts up.
      final pop = t < 0.12
          ? 0.6 + 0.6 * (t / 0.12)
          : 1.2 - 0.2 * ((t - 0.12) / 0.2).clamp(0.0, 1.0);
      final size = (popup.big ? 15.0 : 11.0) * pop;
      final x = w / 2 + (popup.big ? popup.side * 20 : popup.side * 46),
          y = (popup.big ? 96 : 124) - 34 * t;
      final rgb = popup.big ? const Color(0xFFFFD040) : const Color(0xFF8CF060);
      _text(
        c,
        popup.text,
        x,
        y,
        size,
        Color.fromARGB((230 * alpha).round(), 0, 0, 0),
        outline: true,
      );
      _text(c, popup.text, x, y, size, rgb.withValues(alpha: alpha));
    }
  }

  /// The player's own arm or boot swinging in from the edge of the view.
  void _arms(Canvas c, int w, RrEngine e) {
    final p = e.player;
    if (p.attackT <= 0) return;
    final q = 1 - p.attackT / RrEngine.attackTime;
    final ext = sin(q * pi);
    final s = p.attackSide.toDouble();
    final edge = w / 2 + s * (w / 2);
    if (p.attackKick) {
      final from = Offset(edge - s * 30, _baseH + 30);
      final ankle = Offset(edge - s * (46 + 50 * ext), 186 - 34 * ext);
      _limb(c, from, ankle, 44, 30, const Color(0xFF3A58A8));
      // Boot, pointing into the road.
      c.save();
      c.translate(ankle.dx, ankle.dy);
      c.rotate(-s * 0.5);
      final boot = RRect.fromRectAndCorners(
        Rect.fromLTRB(s < 0 ? -18 : -46, -20, s < 0 ? 46 : 18, 12),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      );
      c.drawRRect(boot.inflate(1.2), _smooth..color = const Color(0xFF0C0C10));
      c.drawRRect(
        boot,
        _smooth
          ..shader = ui.Gradient.linear(
            const Offset(0, -20),
            const Offset(0, 12),
            const [Color(0xFF5A4636), Color(0xFF2A2018)],
          ),
      );
      _smooth.shader = null;
      c.drawRect(
        Rect.fromLTRB(boot.left, 7, boot.right, 12),
        _smooth..color = const Color(0xFF16120E),
      );
      c.restore();
      return;
    }
    final from = Offset(edge + s * 26, 214);
    final wrist = Offset(edge - s * (40 + 64 * ext), 132 - 16 * ext);
    final fist = wrist + Offset(-s * 12, -7);
    if (p.club) {
      final tip = fist.translate(-s * (16 + 30 * ext), -64 + 34 * ext);
      _limb(c, fist, tip, 7, 10, const Color(0xFF9A6A30));
    }
    _limb(c, from, wrist, 46, 27, const Color(0xFF3C3C48));
    _limb(
      c,
      wrist + (from - wrist) * 0.08,
      wrist,
      30,
      29,
      const Color(0xFF20202A),
    );
    c.drawCircle(fist, 16.5, _smooth..color = const Color(0xFF0C0C10));
    c.drawCircle(
      fist,
      15,
      _smooth
        ..shader = ui.Gradient.radial(fist.translate(-4, -6), 22, const [
          Color(0xFFD8A868),
          Color(0xFF8A5C2C),
        ]),
    );
    _smooth.shader = null;
    final knuckle = (Paint()..isAntiAlias = false)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = const Color(0x90402810);
    for (var k = -1; k <= 1; k++) {
      c.drawArc(
        Rect.fromCircle(center: fist.translate(-s * 6, k * 7.0), radius: 5),
        s < 0 ? -1.0 : pi - 1.0,
        2,
        false,
        knuckle,
      );
    }
  }

  void _triBar(Canvas c, double x, double y, double w, double h, double value) {
    final rect = Rect.fromLTWH(x, y, w, h);
    c.drawRect(rect.inflate(0.8), _smooth..color = const Color(0xFF000000));
    c.drawRect(
      rect,
      _smooth
        ..shader = ui.Gradient.linear(
          rect.centerLeft,
          rect.centerRight,
          const [Color(0xFFE82A20), Color(0xFFF2D020), Color(0xFF38C838)],
          const [0.1, 0.5, 0.9],
        ),
    );
    _smooth.shader = null;
    final gone = w * (1 - value.clamp(0.0, 1.0));
    if (gone > 0) {
      c.drawRect(
        Rect.fromLTWH(x + w - gone, y, gone, h),
        _smooth..color = const Color(0xFF1A1A20),
      );
    }
    c.drawRect(
      Rect.fromLTWH(x, y, w, h * 0.35),
      _smooth..color = const Color(0x30FFFFFF),
    );
  }

  void _gauge(
    Canvas c,
    Offset o,
    double r,
    double value,
    List<String> marks,
    String unit, {
    double redFrom = 2,
  }) {
    const start = pi * 0.75;
    const sweep = pi * 1.5;
    c.drawCircle(
      o,
      r + 2.6,
      _smooth
        ..shader = ui.Gradient.linear(
          o.translate(-r, -r),
          o.translate(r, r),
          const [Color(0xFFE8E8F0), Color(0xFF4A4A56), Color(0xFFB8B8C4)],
          const [0, 0.55, 1],
        ),
    );
    c.drawCircle(
      o,
      r,
      _smooth
        ..shader = ui.Gradient.radial(
          o.translate(-r * 0.25, -r * 0.3),
          r * 1.3,
          const [Color(0xFFFFFFF8), Color(0xFFD4D0C0)],
        ),
    );
    _smooth.shader = null;
    if (redFrom < 1) {
      c.drawArc(
        Rect.fromCircle(center: o, radius: r - 2.2),
        start + sweep * redFrom,
        sweep * (1 - redFrom),
        false,
        (Paint()..isAntiAlias = false)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..color = const Color(0xFFE02A20),
      );
    }
    final tick = (Paint()..isAntiAlias = false)
      ..color = const Color(0xFF16161A)
      ..strokeWidth = 0.9;
    final steps = (marks.length - 1) * 2;
    for (var i = 0; i <= steps; i++) {
      final a = start + sweep * i / steps;
      final dir = Offset(cos(a), sin(a));
      c.drawLine(
        o + dir * (r - (i.isEven ? 5.0 : 3.0)),
        o + dir * (r - 0.8),
        tick,
      );
      if (i.isEven) {
        final at = o + dir * (r - 9.5);
        _text(
          c,
          marks[i ~/ 2],
          at.dx,
          at.dy - r * 0.11,
          r * 0.22,
          const Color(0xFF16161A),
        );
      }
    }
    _text(c, unit, o.dx, o.dy + r * 0.42, r * 0.17, const Color(0xFF50505A));
    final a = start + sweep * value.clamp(0.0, 1.03);
    final dir = Offset(cos(a), sin(a));
    c.drawLine(
      o - dir * (r * 0.18),
      o + dir * (r - 4),
      (Paint()..isAntiAlias = false)
        ..color = const Color(0xFFE02818)
        ..strokeWidth = 1.7
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(o, r * 0.13, _smooth..color = const Color(0xFF16161A));
  }

  void _cockpit(Canvas c, int w, RrEngine e, double clock, double pct) {
    final p = e.player;
    final cx = w / 2;
    c.save();
    // The bars follow the steering and buzz with the engine.
    c.translate(cx, _baseH);
    c.rotate(p.lean * 0.045);
    c.translate(-cx - p.lean * 5, -_baseH + sin(clock * 46) * 0.5 * pct);

    // Handlebars and grips.
    for (final s in const [-1.0, 1.0]) {
      final bar = Path()
        ..moveTo(cx + s * 96, 196)
        ..lineTo(cx + s * 178, 184)
        ..lineTo(cx + s * 182, 194)
        ..lineTo(cx + s * 100, 210)
        ..close();
      c.drawPath(bar, _smooth..color = const Color(0xFF17171C));
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + s * 196, 187),
            width: 42,
            height: 13,
          ),
          const Radius.circular(5),
        ),
        _smooth..color = const Color(0xFF0E0E12),
      );
      c.drawRect(
        Rect.fromCenter(
          center: Offset(cx + s * 196, 183.5),
          width: 38,
          height: 2,
        ),
        _smooth..color = const Color(0xFF34343E),
      );
    }

    // Fairing.
    final dash = Rect.fromCenter(
      center: Offset(cx, 266),
      width: 320,
      height: 200,
    );
    c.drawOval(dash.inflate(2), _smooth..color = const Color(0xFF050507));
    c.drawOval(
      dash,
      _smooth
        ..shader = ui.Gradient.linear(
          dash.topCenter,
          dash.topCenter.translate(0, 60),
          const [Color(0xFF3A3A44), Color(0xFF17171C), Color(0xFF0C0C10)],
          const [0, 0.25, 1],
        ),
    );
    _smooth.shader = null;
    c.drawArc(
      dash.deflate(2),
      pi * 1.18,
      pi * 0.64,
      false,
      (Paint()..isAntiAlias = false)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x70A0A0B0),
    );

    // Gauges: km/h on the left, revs on the right.
    final kmh = e.mph * 1.609;
    _gauge(c, Offset(cx - 56, 201), 25, kmh / 320, const [
      '0',
      '80',
      '160',
      '240',
      '320',
    ], 'km/h');
    final gear = (pct * 5) - (pct * 5).floorToDouble();
    final revs = p.speed < 50 ? 0.08 : 0.25 + 0.6 * (pct >= 0.999 ? 1.0 : gear);
    _gauge(
      c,
      Offset(cx + 56, 202),
      21,
      revs,
      const ['0', '3', '6', '9', '12'],
      'RPM x1000',
      redFrom: 0.8,
    );

    // Centre stack: stamina, place, clock.
    final panel = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - 21, 169, cx + 21, 220),
      const Radius.circular(4),
    );
    c.drawRRect(panel, _smooth..color = const Color(0xFF08080A));
    c.drawRRect(
      panel,
      (Paint()..isAntiAlias = false)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF50505C),
    );
    _triBar(c, cx - 17, 173, 34, 5.5, p.stamina / p.maxStamina);
    _text(c, '${e.place}', cx, 181, 17, _white);
    // Digital gear readout beside the race clock.
    final gearLabel = p.speed < 50
        ? 'N'
        : '${1 + (pct * 5).floor().clamp(0, 4)}';
    c.drawRect(
      Rect.fromLTWH(cx - 18, 199.5, 11, 11),
      _smooth..color = const Color(0xFF14261A),
    );
    _text(c, gearLabel, cx - 12.5, 200.5, 9, const Color(0xFF58E858));
    _text(c, clockText(e.time), cx + 5, 201, 8.5, const Color(0xFFD0D0DA));
    c.drawRect(
      Rect.fromLTWH(cx - 17, 212.5, 34, 3),
      _smooth..color = const Color(0xFF26262E),
    );
    c.drawRect(
      Rect.fromLTWH(cx - 17, 212.5, 34 * (1 - e.bikeDamage / 100), 3),
      _smooth..color = const Color(0xFFE08020),
    );
    c.restore();

    // Names sit level on the dash corners.
    final left = max(6.0, cx - 172);
    _triBar(c, left, 198, 30, 5, p.stamina / p.maxStamina);
    _label(
      c,
      p.club ? 'YOU + CLUB' : 'YOU',
      left,
      205,
      9,
      p.club ? _yellow : _white,
      align: -1,
    );
    final near = e.nearRider;
    if (near != null) {
      final right = min(w - 6.0, cx + 172);
      _triBar(c, right - 30, 198, 30, 5, near.stamina / near.maxStamina);
      final blink = near.isCop && (clock * 4).floor().isEven;
      _label(
        c,
        near.name,
        right,
        205,
        9,
        blink ? const Color(0xFF6090FF) : (near.club ? _yellow : _white),
        align: 1,
      );
    }
  }

  void _overlay(Canvas c, int w, RrEngine e, double clock) {
    final cx = w / 2;
    final width = w.toDouble();

    // Pause, and how far through the race everyone is.
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(5, 5, 16, 16),
        const Radius.circular(3),
      ),
      _smooth..color = const Color(0x70000000),
    );
    c.drawRect(const Rect.fromLTWH(10, 9, 2.4, 8), _smooth..color = _white);
    c.drawRect(const Rect.fromLTWH(14.6, 9, 2.4, 8), _smooth..color = _white);
    const barW = 110.0;
    final bx = cx - barW / 2;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bx - 2, 6, barW + 4, 5),
        const Radius.circular(2.5),
      ),
      _smooth..color = const Color(0x80000000),
    );
    for (final r in e.rivals) {
      final x = bx + (r.z / e.finishZ).clamp(0.0, 1.0) * barW;
      c.drawRect(Rect.fromLTWH(x - 0.5, 7, 1, 3), _smooth..color = _red);
    }
    c.drawCircle(
      Offset(bx + e.progress * barW, 8.5),
      2.6,
      _smooth..color = _white,
    );
    _label(c, ordinal(e.place), width - 8, 5, 12, _yellow, align: 1);

    final starting = e.countdown > 0;
    if (starting || (e.time < 0.9 && e.outcome == RrOutcome.none)) {
      // Start lights: three reds, then green.
      final lit = starting ? (4 - e.countdown.ceil()).clamp(0, 3) : 3;
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, 36), width: 84, height: 30),
          const Radius.circular(5),
        ),
        _smooth..color = const Color(0xFF101014),
      );
      for (var i = 0; i < 3; i++) {
        final on = i < lit;
        final color = !on
            ? const Color(0xFF30262A)
            : (starting ? const Color(0xFFFF2A20) : const Color(0xFF40F050));
        c.drawCircle(
          Offset(cx - 26 + i * 26, 36),
          9.5,
          _smooth..color = const Color(0xFF000000),
        );
        c.drawCircle(Offset(cx - 26 + i * 26, 36), 8, _smooth..color = color);
        if (on)
          c.drawCircle(
            Offset(cx - 28.5 + i * 26, 33.5),
            2.5,
            _smooth..color = const Color(0x90FFFFFF),
          );
      }
      if (starting) {
        _label(c, '${e.track.name}  -  LEVEL ${e.level}', cx, 58, 10, _white);
      } else {
        _label(c, 'GO!', cx, 56, 30, const Color(0xFF58E858), title: true);
      }
      return;
    }
    final msg = e.message;
    if (msg != null) {
      final big = e.outcome != RrOutcome.none;
      final color = switch (e.outcome) {
        RrOutcome.busted || RrOutcome.wrecked => _red,
        RrOutcome.finished => _yellow,
        RrOutcome.none => _white,
      };
      _label(c, msg, cx, big ? 44 : 30, big ? 36 : 18, color, title: true);
    }
    if (e.copActive && (clock * 4).floor().isEven) {
      _label(
        c,
        'POLICE',
        cx,
        15,
        10,
        (clock * 2).floor().isEven ? _red : const Color(0xFF6090FF),
      );
    }
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

  static String clockText(double seconds) {
    final s = seconds.floor();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  // --------------------------------------------------------------- menus

  static const double _menuTop = 46;
  static const double _rowH = 22;
  static const double _menuLeft = 22;
  static const int artCount = 8;

  /// Menu backdrops, `assets/road_rumble/menu/menu_0.jpg` … `menu_7.jpg`.
  /// Any that are missing fall back to a still of the road.
  final List<ui.Image?> art = List.filled(artCount, null);

  Future<void> loadArt() async {
    for (var i = 0; i < artCount; i++) {
      try {
        final data = await rootBundle.load(
          'assets/road_rumble/menu/menu_$i.jpg',
        );
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        art[i] = (await codec.getNextFrame()).image;
        codec.dispose();
      } catch (_) {
        // Not supplied; the road scene is used instead.
      }
    }
  }

  static double _menuSplit(int w) => w * 0.54;

  /// Which menu row is at game position ([x], [y]), if any.
  static int? menuHit(RrMenu m, int w, double x, double y) {
    if (x < 6 || x > _menuSplit(w)) return null;
    final row = ((y - _menuTop) / _rowH).floor();
    if (row < 0 || row >= m.items.length || !m.items[row].enabled) return null;
    return row;
  }

  void _paragraph(
    Canvas c,
    String text,
    double x,
    double y,
    double width,
    double size,
    Color color,
  ) {
    final key = 'p|$text|$size|$width|${color.toARGB32()}';
    final tp = _texts[key] ??= (TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: size,
          height: 1.25,
          fontWeight: FontWeight.w700,
          color: color,
          shadows: const [
            Shadow(offset: Offset(0.6, 0.6), color: Color(0xE0000000)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width));
    tp.paint(c, Offset(x, y));
  }

  /// A menu in the style of a mid-90s console front end: artwork dimmed
  /// behind a list down the left, with notes for the screen on the right and
  /// letterbox bars top and bottom. [artIndex] picks the backdrop; without
  /// one, a still of [scene] is used.
  void menu(
    Canvas c,
    int w,
    RrMenu m, {
    RrEngine? scene,
    int artIndex = -1,
    bool clear = false,
  }) {
    final width = w.toDouble();
    const full = viewH;
    const bar = 14.0;
    final picture = artIndex >= 0 && artIndex < artCount ? art[artIndex] : null;
    // [clear] leaves the frame see-through so the WebGL view shows behind.
    if (!clear)
      c.drawRect(
        Rect.fromLTRB(0, 0, width, full),
        _flat..color = const Color(0xFF0C0816),
      );
    if (picture != null) {
      // Cover the frame, cropping whichever dimension overflows.
      final view = Rect.fromLTRB(0, bar, width, full - bar);
      final scale = max(
        view.width / picture.width,
        view.height / picture.height,
      );
      final sw = view.width / scale, sh = view.height / scale;
      c.drawImageRect(
        picture,
        Rect.fromLTWH(
          (picture.width - sw) / 2,
          (picture.height - sh) / 2,
          sw,
          sh,
        ),
        view,
        _img,
      );
    } else if (scene != null) {
      c.save();
      c.clipRect(Rect.fromLTRB(0, bar, width, full - bar));
      _backdrop(c, w, scene);
      _road(c, w, scene, 0, chase: true);
      c.restore();
    }
    // Dim the art, more so under the list and toward the foot.
    final frame = Rect.fromLTRB(0, 0, width, full);
    final soft = Paint()..isAntiAlias = true;
    c.drawRect(
      frame,
      soft
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(width, 0),
          const [Color(0xE00A0614), Color(0xA00A0614), Color(0x300A0614)],
          const [0, 0.5, 1],
        ),
    );
    c.drawRect(
      frame,
      soft
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, full),
          const [
            Color(0xB0000000),
            Color(0x00000000),
            Color(0x00000000),
            Color(0xC0000000),
          ],
          const [0, 0.22, 0.7, 1],
        ),
    );
    soft.shader = null;

    const cream = Color(0xFFF0E8B8);
    const orange = Color(0xFFF07020);
    const ember = Color(0xFFB83A10);
    final split = _menuSplit(w);

    // Title: racing stripes run off the left edge into the name, with a
    // rule under it that fades toward the notes.
    Path slant(double l, double t, double r, double b, [double lean = 6]) =>
        Path()
          ..moveTo(l + lean, t)
          ..lineTo(r + lean, t)
          ..lineTo(r, b)
          ..lineTo(l, b)
          ..close();
    c.drawPath(slant(-8, 17, 6, 38), soft..color = orange);
    c.drawPath(slant(9, 17, 13, 38), soft..color = ember);
    _label(c, m.title, _menuLeft, 19, 20, cream, align: -1, title: true);
    c.drawRect(
      Rect.fromLTRB(_menuLeft - 14, 40.5, split, 42),
      soft
        ..shader = ui.Gradient.linear(
          const Offset(_menuLeft - 14, 0),
          Offset(split, 0),
          const [orange, Color(0x00F07020)],
        ),
    );
    soft.shader = null;

    // Each row is a slanted plate; the one to press is lit.
    var y = _menuTop;
    for (final item in m.items) {
      final hot = item.tone == 1 && item.enabled;
      final plate = slant(
        _menuLeft - 16,
        y + 1.5,
        split - 8,
        y + _rowH - 1.5,
        5,
      );
      if (hot) {
        c.drawPath(
          plate,
          soft
            ..shader = ui.Gradient.linear(
              Offset(0, y),
              Offset(0, y + _rowH),
              const [Color(0xFFFF8A30), ember],
            ),
        );
        soft.shader = null;
      } else {
        c.drawPath(
          plate,
          soft..color = Color(item.enabled ? 0x8C140C20 : 0x50140C20),
        );
      }
      c.drawPath(
        plate,
        soft
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = Color(hot ? 0xFFFFD0A0 : 0x40F0E8B8),
      );
      soft.style = PaintingStyle.fill;
      final accent = !item.enabled
          ? const Color(0xFF6C665C)
          : (hot ? cream : (item.tone == 2 ? const Color(0xFF8CE070) : orange));
      c.drawPath(
        slant(_menuLeft - 16, y + 1.5, _menuLeft - 13, y + _rowH - 1.5, 5),
        soft..color = accent,
      );
      final color = !item.enabled
          ? const Color(0xFF8C8478)
          : (hot
                ? const Color(0xFFFFFFFF)
                : (item.tone == 2 ? const Color(0xFF8CE070) : cream));
      _label(c, item.label, _menuLeft - 4, y + 4.5, 12.5, color, align: -1);
      if (item.right.isNotEmpty) {
        _label(c, item.right, split - 16, y + 6, 10, color, align: 1);
      }
      y += _rowH;
    }

    // Notes for the screen sit on a card of their own.
    if (m.info.isNotEmpty) {
      final left = split + 4, right = width - 12;
      final lines = m.info.fold<int>(
        0,
        (n, line) =>
            n + 1 + line.length ~/ max(1, ((right - left - 16) / 6.4).floor()),
      );
      final card = Rect.fromLTRB(
        left,
        _menuTop + 1.5,
        right,
        min(full - 14, _menuTop + 14 + lines * 12.0),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(card, const Radius.circular(3)),
        soft..color = const Color(0x8C140C20),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(card, const Radius.circular(3)),
        soft
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = const Color(0x40F0E8B8),
      );
      soft.style = PaintingStyle.fill;
      c.drawRect(
        Rect.fromLTRB(card.left + 3, card.top, card.left + 34, card.top + 1.8),
        soft..color = orange,
      );
      _paragraph(
        c,
        m.info.join('\n'),
        card.left + 8,
        card.top + 7,
        card.width - 16,
        9.5,
        cream,
      );
    }
  }
}
