import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'rr_engine.dart';
import 'rr_models.dart';
import 'rr_sprites.dart';

/// One texture holding every surface in the game: grainy low-resolution
/// material tiles generated from noise, plus the roadside scenery. Everything
/// is sampled without filtering.
class RrAtlas {
  RrAtlas() {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    _materials(c);
    _scenery(c);
    final picture = recorder.endRecording();
    image = picture.toImageSync(width, height);
    picture.dispose();
  }

  static const int width = 1024;
  static const int height = 384;
  static const double roadW = 256;
  static const double roadH = 96;

  late ui.Image image;
  final Map<RrTile, Rect> tiles = {};
  final Map<RrProp, Rect> props = {};

  /// Appends a sheet of model textures below everything else and returns
  /// where it landed.
  Offset addSheet(ui.Image sheet) {
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder);
    final at = Offset(0, image.height.toDouble());
    c.drawImage(image, Offset.zero, Paint());
    c.drawImage(sheet, at, Paint());
    final picture = recorder.endRecording();
    final grown = picture.toImageSync(
      max(image.width, sheet.width),
      image.height + sheet.height,
    );
    picture.dispose();
    image.dispose();
    image = grown;
    return at;
  }

  void dispose() => image.dispose();

  static double _hash(int x, int y, int seed) {
    final v = sin(x * 127.1 + y * 311.7 + seed * 74.7) * 43758.5453;
    return v - v.floorToDouble();
  }

  /// Smooth noise summed over a few octaves, 0..1.
  static double _noise(double x, double y, int seed) {
    var total = 0.0;
    var weight = 0.0;
    for (var o = 0; o < 4; o++) {
      final f = 1 << o;
      final px = x * f / 16;
      final py = y * f / 16;
      final x0 = px.floor();
      final y0 = py.floor();
      final fx = px - x0;
      final fy = py - y0;
      final a = _hash(x0, y0, seed + o);
      final b = _hash(x0 + 1, y0, seed + o);
      final cc = _hash(x0, y0 + 1, seed + o);
      final d = _hash(x0 + 1, y0 + 1, seed + o);
      final top = a + (b - a) * fx;
      final bottom = cc + (d - cc) * fx;
      final amp = 1 / f;
      total += (top + (bottom - top) * fy) * amp;
      weight += amp;
    }
    return total / weight;
  }

  void _texels(
    Canvas c,
    RrTile tile,
    Rect at,
    Color Function(int x, int y) texel,
  ) {
    tiles[tile] = at;
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < at.height; y++) {
      for (var x = 0; x < at.width; x++) {
        c.drawRect(
          Rect.fromLTWH(at.left + x, at.top + y, 1, 1),
          paint..color = texel(x, y),
        );
      }
    }
  }

  static Color _grey(double v, [double r = 1, double g = 1, double b = 1]) {
    int ch(double m) => (v * m * 255).round().clamp(0, 255);
    return Color.fromARGB(255, ch(r), ch(g), ch(b));
  }

  void _materials(Canvas c) {
    Rect slot(int i) => Rect.fromLTWH(256.0 + i * 64, 0, 64, 64);

    // Asphalt with the lane markings painted on: four lanes, a double yellow
    // centre and solid white edges. Six road segments tall, so the dashes
    // run three on, three off.
    _texels(c, RrTile.road, const Rect.fromLTWH(0, 0, roadW, roadH), (x, y) {
      final grain = _noise(x * 1.7, y * 1.7, 1) * 0.5 + _hash(x, y, 2) * 0.5;
      var v = 0.40 + grain * 0.16;
      // Darker wheel tracks down each lane.
      final lane = ((x % 64) - 32).abs();
      if (lane < 14) v -= 0.025;
      if (_hash(x ~/ 3, y ~/ 9, 3) > 0.985) v -= 0.1;
      final wear = 0.72 + 0.28 * _hash(x, y, 4);
      if (x >= 6 && x < 10 || x >= 246 && x < 250) return _grey(0.86 * wear);
      if ((x >= 62 && x < 65 || x >= 191 && x < 194) && y < 48) {
        return _grey(0.84 * wear);
      }
      if (x >= 123 && x < 126 || x >= 130 && x < 133) {
        return _grey(0.82 * wear, 1, 0.82, 0.25);
      }
      return _grey(v, 0.98, 0.99, 1.04);
    });

    _texels(c, RrTile.grass, slot(0), (x, y) {
      final v =
          0.62 + _noise(x * 2.0, y * 2.0, 5) * 0.26 + _hash(x, y, 6) * 0.16;
      return _grey(v.clamp(0.0, 1.0), 0.96, 1, 0.9);
    });
    _texels(c, RrTile.dirt, slot(1), (x, y) {
      final v =
          0.66 + _noise(x * 1.4, y * 1.4, 7) * 0.2 + _hash(x, y, 8) * 0.14;
      final stone = _hash(x ~/ 2, y ~/ 2, 9) > 0.95 ? 0.14 : 0.0;
      return _grey((v - stone).clamp(0.0, 1.0));
    });
    _texels(c, RrTile.cloth, slot(2), (x, y) {
      // Creases across the weave.
      final fold = 0.035 * sin(y * 0.23 + _noise(x * 1.0, y * 1.0, 30) * 5);
      final v =
          0.74 +
          fold +
          _noise(x * 2.0, y * 2.0, 10) * 0.16 +
          _hash(x, y, 11) * 0.08;
      return _grey(v.clamp(0.0, 1.0));
    });
    _texels(c, RrTile.leather, slot(3), (x, y) {
      final v =
          0.13 + _noise(x * 2.5, y * 2.5, 12) * 0.1 + _hash(x, y, 13) * 0.05;
      return _grey(v, 1, 0.97, 0.94);
    });
    _texels(c, RrTile.metal, slot(4), (x, y) {
      final streak = _hash(x, 0, 14) * 0.12;
      final v =
          0.44 +
          0.2 * sin(y * 0.19 + 0.6).abs() +
          streak +
          _hash(x, y, 15) * 0.05;
      return _grey(v.clamp(0.0, 1.0), 0.98, 0.99, 1.03);
    });
    _texels(c, RrTile.tyre, slot(5), (x, y) {
      final groove = (y % 8) < 2 || ((x + y ~/ 8 * 5) % 16) < 2;
      final v = (groove ? 0.07 : 0.16) + _hash(x, y, 16) * 0.05;
      return _grey(v);
    });
    // Wraps once round the helmet: u 0.75 is the back, 0.25 the visor.
    _texels(c, RrTile.helmet, slot(6), (x, y) {
      var v =
          0.84 + _noise(x * 1.0, y * 1.0, 17) * 0.1 + _hash(x, y, 18) * 0.04;
      final back = (x - 48).abs();
      if (back < 3) v *= 0.42; // centre stripe
      if (back >= 3 && back < 5) v = 1.0;
      if (x > 6 && x < 26 && y > 22 && y < 40)
        v = 0.12 + (y - 22) * 0.008; // visor
      if (y > 56) v *= 0.4; // rim
      if (y < 12) v = min(1.0, v + 0.1);
      return _grey(v.clamp(0.0, 1.0));
    });
    // Race leathers, wrapped round the torso: dark side panels and
    // shoulder yoke, a pale number board on the back (u 0.75), a belt.
    _texels(c, RrTile.suit, const Rect.fromLTWH(896, 68, 64, 64), (x, y) {
      var v =
          0.8 + _noise(x * 2.0, y * 2.0, 32) * 0.12 + _hash(x, y, 33) * 0.06;
      v += 0.03 * sin(y * 0.5 + _noise(x * 1.0, y * 1.0, 34) * 6);
      final side = min((x - 0).abs(), min((x - 32).abs(), (x - 64).abs()));
      if (side < 5) v *= 0.3;
      if (y < 9) v *= 0.34;
      if (y > 57) v = 0.16;
      final board = (x - 48).abs() < 9 && y > 18 && y < 40;
      if (board) {
        v = 1.0;
        // A blocky race number.
        final gx = (x - 41) ~/ 3, gy = (y - 21) ~/ 3;
        const digit = ['.###.', '...#.', '.###.', '.#...', '.###.', '.....'];
        if (gy >= 0 && gy < 6 && gx >= 0 && gx < 5 && digit[gy][gx] == '#')
          v = 0.14;
      } else if ((x - 48).abs() < 11 && y > 16 && y < 42) {
        v *= 0.4;
      }
      return _grey(v.clamp(0.0, 1.0));
    });
    // Trousers: seams and a dark knee slider half way down the limb.
    _texels(c, RrTile.leg, const Rect.fromLTWH(832, 68, 64, 64), (x, y) {
      var v =
          0.78 + _noise(x * 2.0, y * 2.0, 35) * 0.14 + _hash(x, y, 36) * 0.06;
      if (x % 32 < 2) v *= 0.55;
      if (y > 24 && y < 40 && (x % 32) > 10 && (x % 32) < 24) v *= 0.38;
      return _grey(v.clamp(0.0, 1.0));
    });
    _texels(c, RrTile.paint, slot(7), (x, y) {
      var v =
          0.82 + _noise(x * 0.8, y * 0.8, 19) * 0.1 + _hash(x, y, 20) * 0.04;
      if (y == 40 || x == 31) v *= 0.7;
      if (y < 5) v = min(1.0, v + 0.12);
      return _grey(v.clamp(0.0, 1.0));
    });
    _texels(c, RrTile.glass, slot(8), (x, y) {
      final glint = (x + y > 44 && x + y < 58) ? 0.2 : 0.0;
      final v = 0.2 + y / 64 * 0.12 + glint + _hash(x, y, 21) * 0.03;
      return _grey(v, 0.8, 0.95, 1.25);
    });
    _texels(c, RrTile.plate, slot(9), (x, y) {
      final border = x < 4 || x > 59 || y < 6 || y > 57;
      final glyph =
          y > 18 &&
          y < 46 &&
          (x ~/ 8).isOdd &&
          _hash(x ~/ 4, y ~/ 7, 22) > 0.35;
      return border || glyph ? _grey(0.16) : _grey(0.86, 1, 0.98, 0.84);
    });
    _texels(
      c,
      RrTile.white,
      slot(10),
      (x, y) => _grey(0.92 + _hash(x, y, 23) * 0.08),
    );
    // Foliage, tinted per tree; bark; stone.
    _texels(c, RrTile.leaf, const Rect.fromLTWH(768, 68, 64, 64), (x, y) {
      final clump = _noise(x * 3.0, y * 3.0, 40);
      var v = 0.46 + clump * 0.44 + _hash(x, y, 41) * 0.2;
      // Gaps between sprays of leaves.
      if (_noise(x * 7.0, y * 7.0, 42) < 0.36) v *= 0.6;
      return _grey(v.clamp(0.0, 1.0), 0.98, 1, 0.92);
    });
    _texels(c, RrTile.bark, const Rect.fromLTWH(704, 68, 64, 64), (x, y) {
      final ridge = 0.5 + 0.5 * sin(x * 0.9 + _noise(x * 1.0, y * 0.4, 43) * 7);
      final v = 0.2 + ridge * 0.16 + _hash(x, y, 44) * 0.07;
      return _grey(v, 1, 0.74, 0.5);
    });
    _texels(c, RrTile.rock, const Rect.fromLTWH(640, 68, 64, 64), (x, y) {
      var v = 0.4 + _noise(x * 2.4, y * 2.4, 45) * 0.32 + _hash(x, y, 46) * 0.1;
      if (_noise(x * 5.0, y * 1.5, 47) > 0.66) v *= 0.7;
      return _grey(v.clamp(0.0, 1.0), 1, 0.99, 0.96);
    });
    // A soft white blob for dust and smoke, drawn below the first row.
    _texels(c, RrTile.puff, const Rect.fromLTWH(960, 68, 32, 32), (x, y) {
      final dx = (x - 15.5) / 16;
      final dy = (y - 15.5) / 16;
      final a =
          (1.1 - sqrt(dx * dx + dy * dy) * 1.25).clamp(0.0, 1.0) *
          (0.55 + _hash(x, y, 31) * 0.3);
      return Color.fromARGB((a * 255).round(), 255, 255, 255);
    });
    _texels(c, RrTile.shadow, slot(11), (x, y) {
      final dx = (x - 31.5) / 32;
      final dy = (y - 31.5) / 32;
      final a = (1.25 - sqrt(dx * dx + dy * dy) * 1.35).clamp(0.0, 1.0) * 0.62;
      return Color.fromARGB((a * 255).round(), 0, 0, 0);
    });
  }

  /// Packs the scenery art in rows under the material tiles, with grain
  /// laid over each so it sits with the rest of the textures.
  void _scenery(Canvas c) {
    var x = 0.0;
    var y = 136.0;
    var rowH = 0.0;
    final rng = Random(41);
    final grain = Paint()
      ..isAntiAlias = false
      ..blendMode = BlendMode.srcATop;
    for (final kind in RrProp.values) {
      final size = RrPropArt.size(kind);
      if (x + size.width > width) {
        x = 0;
        y += rowH + 4;
        rowH = 0;
      }
      final at = Rect.fromLTWH(x, y, size.width, size.height);
      props[kind] = at;
      c.saveLayer(at, Paint());
      c.save();
      c.translate(x, y);
      c.clipRect(Offset.zero & size);
      RrPropArt.paint(c, kind);
      c.restore();
      final count = (size.width * size.height * 0.3).round();
      for (var i = 0; i < count; i++) {
        final dark = rng.nextBool();
        c.drawRect(
          Rect.fromLTWH(
            x + rng.nextInt(size.width.toInt()),
            y + rng.nextInt(size.height.toInt()),
            1,
            1,
          ),
          grain
            ..color = dark ? const Color(0x38000000) : const Color(0x24FFFFFF),
        );
      }
      c.restore();
      x += size.width + 4;
      rowH = max(rowH, size.height);
    }
  }
}
