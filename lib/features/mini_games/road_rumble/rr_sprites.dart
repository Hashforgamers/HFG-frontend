import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'rr_engine.dart';
import 'rr_font.dart';

Color _dark(Color c, [double t = 0.35]) =>
    Color.lerp(c, const Color(0xFF000000), t)!;
Color _light(Color c, [double t = 0.35]) =>
    Color.lerp(c, const Color(0xFFFFFFFF), t)!;

/// A stack of smooth-shaded shapes: each is filled with a light-to-dark
/// gradient across its bounds and given a soft dark edge, which is what makes
/// the sprites read as lit, rounded objects rather than flat cut-outs.
class _Art {
  final List<(Path, Color, double, bool)> _shapes = [];

  void path(Path p, Color c, {double shade = 0.4, bool line = true}) =>
      _shapes.add((p, c, shade, line));

  void rect(
    double l,
    double t,
    double r,
    double b,
    Color c, {
    double shade = 0.4,
    bool line = true,
    double radius = 0,
  }) {
    final rect = Rect.fromLTRB(l, t, r, b);
    path(
      Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius))),
      c,
      shade: shade,
      line: line,
    );
  }

  void oval(
    double l,
    double t,
    double r,
    double b,
    Color c, {
    double shade = 0.4,
    bool line = true,
  }) => path(
    Path()..addOval(Rect.fromLTRB(l, t, r, b)),
    c,
    shade: shade,
    line: line,
  );

  void poly(List<double> p, Color c, {double shade = 0.4, bool line = true}) {
    final out = Path()..moveTo(p[0], p[1]);
    for (var i = 2; i < p.length; i += 2) {
      out.lineTo(p[i], p[i + 1]);
    }
    path(out..close(), c, shade: shade, line: line);
  }

  /// Union of every outlined shape, for clipping texture speckles.
  Path get silhouette {
    final out = Path();
    for (final (p, _, _, line) in _shapes) {
      if (line) out.addPath(p, Offset.zero);
    }
    return out;
  }

  void paint(Canvas canvas) {
    final fill = Paint();
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xB0101014);
    for (final (p, color, shade, line) in _shapes) {
      if (line) canvas.drawPath(p, edge);
      if (shade > 0) {
        final b = p.getBounds();
        fill.shader = ui.Gradient.linear(
          b.topLeft,
          Offset(b.right, b.top + b.height * 0.6),
          [_light(color, shade * 0.55), color, _dark(color, shade)],
          const [0, 0.45, 1],
        );
      } else {
        fill
          ..shader = null
          ..color = color;
      }
      canvas.drawPath(p, fill);
    }
  }
}

/// Roadside scenery art, drawn procedurally. The atlas rasterises each piece
/// at one texel per unit so it reads as a low-resolution texture.
class RrPropArt {
  RrPropArt._();

  static const double res = 1;

  /// Texture size of each prop, in texels.
  static Size size(RrProp kind) => switch (kind) {
    RrProp.pine || RrProp.palm => const Size(64, 112),
    RrProp.oak => const Size(96, 96),
    RrProp.cactus => const Size(40, 72),
    RrProp.rock || RrProp.bush => const Size(48, 32),
    RrProp.pole => const Size(24, 112),
    RrProp.billboard => const Size(112, 72),
    RrProp.barn => const Size(128, 96),
    RrProp.signLeft || RrProp.signRight => const Size(32, 40),
    RrProp.start || RrProp.finish => const Size(208, 104),
    RrProp.tuft => const Size(20, 12),
    RrProp.fence => const Size(48, 28),
  };

  /// World width the prop is drawn at.
  static double worldWidth(RrProp kind) => switch (kind) {
    RrProp.pine => 1500,
    RrProp.oak => 2300,
    RrProp.palm => 1500,
    RrProp.cactus => 800,
    RrProp.rock => 900,
    RrProp.bush => 900,
    RrProp.pole => 500,
    RrProp.billboard => 2600,
    RrProp.barn => 3200,
    RrProp.signLeft || RrProp.signRight => 620,
    RrProp.start || RrProp.finish => 7630,
    RrProp.tuft => 420,
    RrProp.fence => 1210,
  };

  static void _make(double w, double h, void Function(Canvas c) draw) =>
      draw(_target!);

  static Canvas? _target;
  static const _tire = Color(0xFF18181C);
  static const _chrome = Color(0xFFB4B4BE);

  /// Paints [kind] at the canvas origin.
  static void paint(Canvas canvas, RrProp kind) {
    _target = canvas;
    _prop(kind);
    _target = null;
  }

  static void _speckle(
    Canvas c,
    _Art a,
    Rect area,
    Color color,
    int count,
    int seed,
  ) {
    final rng = Random(seed);
    final paint = Paint()..color = color;
    c.save();
    c.clipPath(a.silhouette);
    for (var i = 0; i < count; i++) {
      final x = area.left + rng.nextDouble() * area.width;
      final y = area.top + rng.nextDouble() * area.height;
      c.drawOval(
        Rect.fromLTWH(x, y, 1 + rng.nextDouble() * 2.2, 0.8 + rng.nextDouble()),
        paint,
      );
    }
    c.restore();
  }

  static void _prop(RrProp kind) {
    const trunk = Color(0xFF6A4424);
    switch (kind) {
      case RrProp.pine:
        return _make(64, 112, (c) {
          const g = Color(0xFF1F6B3A);
          (_Art()..rect(29, 88, 35, 110, trunk, shade: 0.5)).paint(c);
          final a = _Art();
          for (final (apex, base, hw) in const [
            (54.0, 98.0, 30.0),
            (34.0, 76.0, 25.0),
            (16.0, 54.0, 19.0),
            (2.0, 32.0, 13.0),
          ]) {
            a.poly(
              [
                32,
                apex,
                32 - hw,
                base,
                32 - hw * 0.4,
                base - 4,
                32,
                base,
                32 + hw * 0.4,
                base - 4,
                32 + hw,
                base,
              ],
              g,
              shade: 0.55,
            );
          }
          a.paint(c);
          _speckle(
            c,
            a,
            const Rect.fromLTRB(3, 2, 61, 98),
            const Color(0x70082810),
            130,
            1,
          );
          _speckle(
            c,
            a,
            const Rect.fromLTRB(3, 2, 36, 98),
            const Color(0x5090D890),
            70,
            2,
          );
        });
      case RrProp.oak:
        return _make(96, 96, (c) {
          const g = Color(0xFF3A8A2E);
          (_Art()
                ..poly([42, 94, 44, 58, 52, 58, 55, 94], trunk, shade: 0.5)
                ..poly([46, 66, 32, 50, 35, 48, 48, 60], trunk)
                ..poly([50, 66, 64, 50, 61, 48, 49, 60], trunk))
              .paint(c);
          final a = _Art();
          a.oval(4, 30, 46, 68, _dark(g, 0.22), shade: 0.45);
          a.oval(48, 28, 93, 70, _dark(g, 0.25), shade: 0.45);
          a.oval(26, 34, 72, 74, _dark(g, 0.12), shade: 0.45);
          a.oval(14, 8, 60, 50, g, shade: 0.45);
          a.oval(40, 4, 84, 46, g, shade: 0.45);
          a.paint(c);
          _speckle(
            c,
            a,
            const Rect.fromLTRB(4, 4, 93, 74),
            const Color(0x70103810),
            220,
            3,
          );
          _speckle(
            c,
            a,
            const Rect.fromLTRB(10, 6, 64, 46),
            const Color(0x60B8F090),
            110,
            4,
          );
        });
      case RrProp.palm:
        return _make(64, 112, (c) {
          const g = Color(0xFF2E9A3E);
          final a = _Art();
          a.poly(
            [28, 110, 31, 70, 33, 34, 37, 34, 36, 70, 34, 110],
            const Color(0xFF8A6A3A),
            shade: 0.5,
          );
          for (var y = 44.0; y < 108; y += 7) {
            a.rect(
              30,
              y,
              36,
              y + 0.8,
              const Color(0x805A4424),
              shade: 0,
              line: false,
            );
          }
          a.poly([35, 34, 10, 46, 5, 60, 22, 44], _dark(g, 0.25));
          a.poly([35, 34, 58, 46, 62, 60, 46, 44], _dark(g, 0.3));
          a.poly([35, 34, 6, 22, 1, 34, 20, 31], g);
          a.poly([35, 34, 62, 22, 63, 36, 48, 31], g);
          a.poly([35, 34, 14, 6, 8, 15, 26, 27], _light(g, 0.15));
          a.poly([35, 34, 54, 6, 60, 16, 44, 27], _light(g, 0.1));
          a.poly([35, 34, 30, 2, 39, 2], g);
          a.oval(30, 32, 36, 38, const Color(0xFF5A3A1A));
          a.oval(35, 33, 41, 39, const Color(0xFF5A3A1A));
          a.paint(c);
        });
      case RrProp.cactus:
        return _make(40, 72, (c) {
          const g = Color(0xFF3C8C3C);
          final a = _Art();
          a.rect(6, 24, 11, 40, g, shade: 0.5, radius: 2.5);
          a.rect(6, 36, 18, 41, g, shade: 0.5, radius: 2.5);
          a.rect(29, 16, 34, 34, g, shade: 0.5, radius: 2.5);
          a.rect(22, 30, 34, 35, g, shade: 0.5, radius: 2.5);
          a.rect(16, 6, 24, 70, g, shade: 0.55, radius: 4);
          a.rect(
            19.6,
            9,
            20.2,
            68,
            const Color(0x60103010),
            shade: 0,
            line: false,
          );
          a.paint(c);
        });
      case RrProp.rock:
        return _make(48, 32, (c) {
          const g = Color(0xFF8A8A90);
          final a = _Art();
          a.poly([3, 30, 8, 14, 20, 4, 36, 8, 44, 20, 46, 30], g, shade: 0.55);
          a.poly(
            [8, 14, 20, 4, 30, 7, 18, 16],
            _light(g, 0.35),
            shade: 0.2,
            line: false,
          );
          a.paint(c);
          _speckle(
            c,
            a,
            const Rect.fromLTRB(3, 4, 46, 30),
            const Color(0x50303038),
            40,
            5,
          );
        });
      case RrProp.bush:
        return _make(48, 32, (c) {
          const g = Color(0xFF3F8F34);
          final a = _Art();
          a.oval(2, 12, 24, 31, _dark(g, 0.2), shade: 0.45);
          a.oval(24, 10, 46, 31, _dark(g, 0.25), shade: 0.45);
          a.oval(10, 3, 38, 30, g, shade: 0.45);
          a.paint(c);
          _speckle(
            c,
            a,
            const Rect.fromLTRB(2, 3, 46, 31),
            const Color(0x70103810),
            70,
            6,
          );
          _speckle(
            c,
            a,
            const Rect.fromLTRB(8, 4, 30, 20),
            const Color(0x60B8F090),
            35,
            7,
          );
        });
      case RrProp.tuft:
        return _make(20, 12, (c) {
          const g = Color(0xFF5A9A3A);
          final a = _Art();
          for (final (x, tip, top) in const [
            (3.0, 1.0, 4.0),
            (7.0, 6.0, 1.0),
            (11.0, 12.0, 3.0),
            (15.0, 18.0, 5.0),
            (9.0, 10.0, 0.5),
          ]) {
            a.poly([x - 1.5, 12, tip, top, x + 1.5, 12], g, shade: 0.5);
          }
          a.paint(c);
        });
      case RrProp.fence:
        return _make(48, 28, (c) {
          const wood = Color(0xFFD8D0C0);
          final a = _Art();
          a.rect(0, 9, 48, 12, wood, shade: 0.35);
          a.rect(0, 17, 48, 20, wood, shade: 0.35);
          a.rect(6, 4, 10, 27, wood, shade: 0.45);
          a.rect(30, 4, 34, 27, wood, shade: 0.45);
          a.paint(c);
        });
      case RrProp.pole:
        return _make(24, 112, (c) {
          final a = _Art();
          a.rect(10, 4, 14, 110, trunk, shade: 0.55);
          a.rect(2, 10, 22, 13, trunk, shade: 0.45);
          a.rect(3, 6, 5, 10, _chrome, shade: 0, line: false);
          a.rect(19, 6, 21, 10, _chrome, shade: 0, line: false);
          a.paint(c);
        });
      case RrProp.billboard:
        return _make(112, 72, (c) {
          final a = _Art();
          a.rect(20, 42, 25, 70, trunk, shade: 0.5);
          a.rect(87, 42, 92, 70, trunk, shade: 0.5);
          a.rect(
            3,
            3,
            109,
            45,
            const Color(0xFF3A3A44),
            shade: 0.3,
            radius: 1.5,
          );
          a.paint(c);
          // A little landscape poster.
          const poster = Rect.fromLTRB(6, 6, 106, 42);
          c.save();
          c.clipRect(poster);
          c.drawRect(
            poster,
            Paint()
              ..shader = ui.Gradient.linear(
                poster.topCenter,
                poster.bottomCenter,
                const [Color(0xFF2A56B0), Color(0xFF9CC8F0)],
              ),
          );
          c.drawOval(
            const Rect.fromLTRB(-10, 28, 70, 70),
            Paint()..color = const Color(0xFF3A8A3A),
          );
          c.drawOval(
            const Rect.fromLTRB(50, 32, 130, 70),
            Paint()..color = const Color(0xFF2A6A2E),
          );
          c.restore();
          RrFont.center(
            c,
            'HASH',
            56,
            9,
            const Color(0xFFFFE040),
            scale: 2,
            shadow: const Color(0xFF101020),
          );
          RrFont.center(
            c,
            'FOR GAMERS',
            56,
            28,
            const Color(0xFFFFFFFF),
            shadow: const Color(0xFF101020),
          );
        });
      case RrProp.barn:
        return _make(128, 96, (c) {
          const red = Color(0xFFA83228);
          final a = _Art();
          a.rect(14, 46, 114, 94, red, shade: 0.45);
          a.poly([24, 46, 64, 20, 104, 46], _dark(red, 0.15), shade: 0.4);
          a.poly(
            [6, 48, 64, 10, 122, 48, 114, 48, 64, 17, 14, 48],
            const Color(0xFF5A4A44),
            shade: 0.5,
          );
          a.rect(52, 62, 76, 94, _dark(red, 0.4), shade: 0.3);
          a.rect(56, 30, 72, 42, const Color(0xFF282830), shade: 0.3);
          a.paint(c);
          final p = Paint()
            ..color = const Color(0xFFF0E8D8)
            ..strokeWidth = 1.6;
          c.drawLine(const Offset(53, 63), const Offset(75, 93), p);
          c.drawLine(const Offset(75, 63), const Offset(53, 93), p);
          final plank = Paint()..color = const Color(0x40200808);
          for (var x = 22.0; x < 112; x += 7) {
            c.drawRect(Rect.fromLTWH(x, 48, 0.7, 46), plank);
          }
        });
      case RrProp.signLeft:
      case RrProp.signRight:
        return _make(32, 40, (c) {
          if (kind == RrProp.signLeft) {
            c.translate(32, 0);
            c.scale(-1, 1);
          }
          final a = _Art();
          a.rect(14.5, 22, 17.5, 38, _chrome, shade: 0.5);
          a.rect(3, 3, 29, 23, const Color(0xFFF2C81E), shade: 0.3, radius: 2);
          a.poly(
            [9, 6, 15, 6, 22, 13, 15, 20, 9, 20, 16, 13],
            const Color(0xFF16161A),
            shade: 0,
            line: false,
          );
          a.paint(c);
        });
      case RrProp.start:
      case RrProp.finish:
        return _make(208, 104, (c) {
          final a = _Art();
          a.rect(4, 8, 12, 102, _chrome, shade: 0.6);
          a.rect(196, 8, 204, 102, _chrome, shade: 0.6);
          a.rect(4, 6, 204, 32, const Color(0xFFF4F4F4), shade: 0.2, radius: 1);
          for (var i = 0; i < 6; i++) {
            for (var j = 0; j < 6; j++) {
              if ((i + j).isOdd) continue;
              a.rect(
                6.0 + i * 4,
                8.0 + j * 4,
                10.0 + i * 4,
                12.0 + j * 4,
                _tire,
                shade: 0,
                line: false,
              );
              a.rect(
                178.0 + i * 4,
                8.0 + j * 4,
                182.0 + i * 4,
                12.0 + j * 4,
                _tire,
                shade: 0,
                line: false,
              );
            }
          }
          a.paint(c);
          RrFont.center(
            c,
            kind == RrProp.start ? 'START' : 'FINISH',
            104,
            12,
            const Color(0xFFD82020),
            scale: 2,
          );
        });
    }
  }
}
