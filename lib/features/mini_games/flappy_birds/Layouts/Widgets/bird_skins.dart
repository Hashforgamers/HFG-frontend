import 'dart:math';

import 'package:flutter/material.dart';

enum BirdExtra { tuft, parrot, penguin, owl, robot, phoenix, ninja }

/// A painted bird type. Stored in Hive under "bird" as `skin:<id>`; the
/// original PNG birds keep their asset path.
class BirdSkin {
  const BirdSkin({
    required this.id,
    required this.name,
    required this.body,
    required this.bodyDark,
    required this.belly,
    required this.wing,
    required this.beak,
    required this.extra,
  });

  final String id;
  final String name;
  final Color body;
  final Color bodyDark;
  final Color belly;
  final Color wing;
  final Color beak;
  final BirdExtra extra;

  String get key => 'skin:$id';

  static const all = [
    BirdSkin(
      id: 'chick',
      name: 'Chick',
      body: Color(0xFFFFD84A),
      bodyDark: Color(0xFFF2A922),
      belly: Color(0xFFFFF1A8),
      wing: Color(0xFFFFC21A),
      beak: Color(0xFFFF8A1F),
      extra: BirdExtra.tuft,
    ),
    BirdSkin(
      id: 'parrot',
      name: 'Parrot',
      body: Color(0xFFFF4B3E),
      bodyDark: Color(0xFFC9241C),
      belly: Color(0xFFFFB23F),
      wing: Color(0xFF2E7BFF),
      beak: Color(0xFFF2F2F2),
      extra: BirdExtra.parrot,
    ),
    BirdSkin(
      id: 'penguin',
      name: 'Penguin',
      body: Color(0xFF3A3F55),
      bodyDark: Color(0xFF1E2130),
      belly: Color(0xFFF5F7FF),
      wing: Color(0xFF2A2E40),
      beak: Color(0xFFFFA928),
      extra: BirdExtra.penguin,
    ),
    BirdSkin(
      id: 'owl',
      name: 'Owl',
      body: Color(0xFFB07A4A),
      bodyDark: Color(0xFF7C5230),
      belly: Color(0xFFE9CFA4),
      wing: Color(0xFF8C5E36),
      beak: Color(0xFFFFB21F),
      extra: BirdExtra.owl,
    ),
    BirdSkin(
      id: 'robot',
      name: 'Robo',
      body: Color(0xFFB9C3D6),
      bodyDark: Color(0xFF7D889E),
      belly: Color(0xFFE4EAF5),
      wing: Color(0xFF8F9AB0),
      beak: Color(0xFFFFC21A),
      extra: BirdExtra.robot,
    ),
    BirdSkin(
      id: 'phoenix',
      name: 'Phoenix',
      body: Color(0xFFFF7A1F),
      bodyDark: Color(0xFFD9381E),
      belly: Color(0xFFFFD35C),
      wing: Color(0xFFFF3B2F),
      beak: Color(0xFFFFE45C),
      extra: BirdExtra.phoenix,
    ),
    BirdSkin(
      id: 'ninja',
      name: 'Ninja',
      body: Color(0xFF2B2B38),
      bodyDark: Color(0xFF14141C),
      belly: Color(0xFF4A4A5C),
      wing: Color(0xFF1C1C26),
      beak: Color(0xFFFFB21F),
      extra: BirdExtra.ninja,
    ),
  ];

  static BirdSkin? fromKey(String key) {
    if (!key.startsWith('skin:')) return null;
    final id = key.substring(5);
    for (final s in all) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Draws a [BirdSkin] facing right in a box with a 1.4:1 aspect ratio.
/// [flap] in -1..1 swings the wing.
class BirdSkinPainter extends CustomPainter {
  BirdSkinPainter(this.skin, {this.flap = 0});

  final BirdSkin skin;
  final double flap;

  static const _outline = Color(0xFF0B0B10);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = w * 0.045;
    final line = Paint()
      ..color = _outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    Paint fill(Color c) => Paint()..color = c;

    void shape(Path p, Color c) {
      canvas.drawPath(p, fill(c));
      canvas.drawPath(p, line);
    }

    final center = Offset(w * 0.46, h * 0.54);
    final body = Rect.fromCenter(
      center: center,
      width: w * 0.7,
      height: h * 0.84,
    );

    // Tail.
    final tail = Path();
    switch (skin.extra) {
      case BirdExtra.parrot:
        tail
          ..moveTo(w * 0.16, h * 0.5)
          ..lineTo(w * 0.0, h * 0.72)
          ..lineTo(w * 0.06, h * 0.82)
          ..lineTo(w * 0.22, h * 0.66)
          ..close();
        shape(tail, const Color(0xFF2FBF3A));
      case BirdExtra.phoenix:
        for (final (dy, len) in [(0.36, 0.2), (0.52, 0.26), (0.68, 0.2)]) {
          final t = Path()
            ..moveTo(w * 0.18, h * (dy - 0.06))
            ..quadraticBezierTo(
              w * (0.18 - len),
              h * dy,
              w * (0.16 - len),
              h * (dy + 0.1),
            )
            ..quadraticBezierTo(
              w * 0.1,
              h * (dy + 0.02),
              w * 0.2,
              h * (dy + 0.08),
            )
            ..close();
          shape(
            t,
            dy == 0.52 ? const Color(0xFFFFC21A) : const Color(0xFFFF3B2F),
          );
        }
      case BirdExtra.robot:
        break;
      default:
        tail
          ..moveTo(w * 0.16, h * 0.46)
          ..lineTo(w * 0.03, h * 0.4)
          ..lineTo(w * 0.07, h * 0.62)
          ..lineTo(w * 0.17, h * 0.62)
          ..close();
        shape(tail, skin.bodyDark);
    }

    // Head extras drawn behind the body.
    switch (skin.extra) {
      case BirdExtra.owl:
        for (final x in [0.3, 0.62]) {
          final ear = Path()
            ..moveTo(w * (x - 0.07), h * 0.2)
            ..lineTo(w * (x - 0.03), h * 0.02)
            ..lineTo(w * (x + 0.08), h * 0.18)
            ..close();
          shape(ear, skin.bodyDark);
        }
      case BirdExtra.phoenix:
        for (final (x, top) in [(0.36, 0.0), (0.47, -0.06), (0.58, 0.02)]) {
          final flame = Path()
            ..moveTo(w * (x - 0.06), h * 0.2)
            ..quadraticBezierTo(
              w * (x - 0.04),
              h * (top + 0.08),
              w * (x + 0.02),
              h * top,
            )
            ..quadraticBezierTo(
              w * (x + 0.02),
              h * 0.1,
              w * (x + 0.07),
              h * 0.2,
            )
            ..close();
          shape(flame, const Color(0xFFFFC21A));
        }
      case BirdExtra.robot:
        canvas.drawLine(
          Offset(w * 0.5, h * 0.16),
          Offset(w * 0.54, h * 0.0),
          line,
        );
        canvas.drawCircle(
          Offset(w * 0.54, h * 0.02),
          w * 0.045,
          fill(const Color(0xFFFF453A)),
        );
        canvas.drawCircle(Offset(w * 0.54, h * 0.02), w * 0.045, line);
      case BirdExtra.tuft:
        final tuft = Path()
          ..moveTo(w * 0.44, h * 0.16)
          ..quadraticBezierTo(w * 0.4, h * 0.0, w * 0.5, h * 0.02)
          ..quadraticBezierTo(w * 0.47, h * 0.08, w * 0.52, h * 0.15)
          ..close();
        shape(tuft, skin.bodyDark);
      case BirdExtra.parrot:
        final crest = Path()
          ..moveTo(w * 0.4, h * 0.18)
          ..quadraticBezierTo(w * 0.34, h * 0.0, w * 0.5, h * 0.04)
          ..quadraticBezierTo(w * 0.46, h * 0.1, w * 0.54, h * 0.16)
          ..close();
        shape(crest, skin.body);
      default:
        break;
    }

    // Body with a soft vertical shade.
    final bodyPath = skin.extra == BirdExtra.robot
        ? (Path()..addRRect(
            RRect.fromRectAndRadius(body, Radius.circular(w * 0.16)),
          ))
        : (Path()..addOval(body));
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skin.body, skin.bodyDark],
        ).createShader(body),
    );
    // Belly.
    canvas.save();
    canvas.clipPath(bodyPath);
    final belly = Rect.fromCenter(
      center: Offset(w * 0.56, h * 0.74),
      width: w * 0.56,
      height: h * 0.6,
    );
    canvas.drawOval(belly, fill(skin.belly));
    // Gloss.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.34, h * 0.3),
        width: w * 0.2,
        height: h * 0.12,
      ),
      fill(Colors.white.withValues(alpha: 0.35)),
    );
    if (skin.extra == BirdExtra.ninja) {
      final band = Rect.fromLTWH(0, h * 0.26, w, h * 0.14);
      canvas.drawRect(band, fill(const Color(0xFFE8392C)));
    }
    if (skin.extra == BirdExtra.robot) {
      for (final y in [0.62, 0.74]) {
        canvas.drawLine(
          Offset(w * 0.4, h * y),
          Offset(w * 0.72, h * y),
          Paint()
            ..color = skin.bodyDark
            ..strokeWidth = stroke * 0.6,
        );
      }
    }
    canvas.restore();
    canvas.drawPath(bodyPath, line);

    // Ninja headband tails.
    if (skin.extra == BirdExtra.ninja) {
      final wave = flap * h * 0.05;
      for (final dy in [0.0, 0.1]) {
        final ribbon = Path()
          ..moveTo(w * 0.13, h * (0.3 + dy))
          ..quadraticBezierTo(
            w * 0.04,
            h * (0.26 + dy) + wave,
            w * -0.02,
            h * (0.34 + dy) - wave,
          )
          ..lineTo(w * 0.02, h * (0.42 + dy))
          ..quadraticBezierTo(
            w * 0.07,
            h * (0.36 + dy),
            w * 0.14,
            h * (0.4 + dy),
          )
          ..close();
        shape(ribbon, const Color(0xFFE8392C));
      }
    }

    // Eyes.
    switch (skin.extra) {
      case BirdExtra.owl:
        for (final x in [0.44, 0.66]) {
          final c = Offset(w * x, h * 0.4);
          canvas.drawCircle(c, w * 0.12, fill(const Color(0xFFFFB21F)));
          canvas.drawCircle(c, w * 0.12, line);
          canvas.drawCircle(c, w * 0.075, fill(Colors.white));
          canvas.drawCircle(c + Offset(w * 0.02, 0), w * 0.045, fill(_outline));
        }
      case BirdExtra.robot:
        final visor = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.48, h * 0.28, w * 0.34, h * 0.2),
          Radius.circular(w * 0.06),
        );
        canvas.drawRRect(visor, fill(const Color(0xFF12203A)));
        canvas.drawRRect(visor, line);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.62, h * 0.33, w * 0.14, h * 0.1),
            Radius.circular(w * 0.03),
          ),
          fill(const Color(0xFF3BE8FF)),
        );
      case BirdExtra.ninja:
        final c = Offset(w * 0.64, h * 0.33);
        final eye = Path()
          ..moveTo(c.dx - w * 0.1, c.dy)
          ..quadraticBezierTo(
            c.dx,
            c.dy - h * 0.1,
            c.dx + w * 0.1,
            c.dy - h * 0.02,
          )
          ..quadraticBezierTo(c.dx, c.dy + h * 0.06, c.dx - w * 0.1, c.dy)
          ..close();
        shape(eye, Colors.white);
        canvas.drawCircle(
          c + Offset(w * 0.03, -h * 0.01),
          w * 0.03,
          fill(_outline),
        );
      default:
        final c = Offset(w * 0.64, h * 0.36);
        canvas.drawCircle(c, w * 0.12, fill(Colors.white));
        canvas.drawCircle(c, w * 0.12, line);
        canvas.drawCircle(
          c + Offset(w * 0.035, h * 0.01),
          w * 0.055,
          fill(_outline),
        );
        canvas.drawCircle(
          c + Offset(w * 0.05, -h * 0.03),
          w * 0.02,
          fill(Colors.white),
        );
        if (skin.extra == BirdExtra.phoenix) {
          canvas.drawLine(
            c + Offset(-w * 0.1, -h * 0.17),
            c + Offset(w * 0.1, -h * 0.12),
            line,
          );
        }
    }

    // Beak.
    if (skin.extra == BirdExtra.parrot) {
      final beak = Path()
        ..moveTo(w * 0.76, h * 0.4)
        ..quadraticBezierTo(w * 1.0, h * 0.38, w * 0.94, h * 0.66)
        ..quadraticBezierTo(w * 0.86, h * 0.56, w * 0.76, h * 0.6)
        ..close();
      shape(beak, skin.beak);
    } else {
      final top = Path()
        ..moveTo(w * 0.74, h * 0.46)
        ..quadraticBezierTo(w * 0.96, h * 0.44, w * 0.99, h * 0.55)
        ..lineTo(w * 0.76, h * 0.57)
        ..close();
      final bottom = Path()
        ..moveTo(w * 0.76, h * 0.57)
        ..lineTo(w * 0.93, h * 0.58)
        ..quadraticBezierTo(w * 0.88, h * 0.68, w * 0.76, h * 0.67)
        ..close();
      shape(bottom, Color.lerp(skin.beak, Colors.black, 0.18)!);
      shape(top, skin.beak);
    }

    // Wing, pivoting at its root with the flap.
    canvas.save();
    final pivot = Offset(w * 0.4, h * 0.56);
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(-flap * 0.55);
    final wingRect = Rect.fromLTWH(-w * 0.24, -h * 0.1, w * 0.3, h * 0.26);
    final wing = skin.extra == BirdExtra.robot
        ? (Path()..addRRect(
            RRect.fromRectAndRadius(wingRect, Radius.circular(w * 0.05)),
          ))
        : (Path()..addOval(wingRect));
    shape(wing, skin.wing);
    if (skin.extra == BirdExtra.parrot) {
      canvas.save();
      canvas.clipPath(wing);
      canvas.drawRect(
        Rect.fromLTWH(-w * 0.24, h * 0.06, w * 0.3, h * 0.1),
        fill(const Color(0xFFFFE45C)),
      );
      canvas.restore();
      canvas.drawPath(wing, line);
    }
    canvas.restore();

    // Penguin feet.
    if (skin.extra == BirdExtra.penguin) {
      for (final x in [0.44, 0.58]) {
        final foot = Path()
          ..addOval(Rect.fromLTWH(w * x, h * 0.9, w * 0.12, h * 0.1));
        shape(foot, skin.beak);
      }
    }
    // Cheek blush for the cute ones.
    if (skin.extra == BirdExtra.tuft || skin.extra == BirdExtra.penguin) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.66, h * 0.58),
          width: w * 0.1,
          height: h * 0.07,
        ),
        fill(const Color(0x66FF5A7A)),
      );
    }
  }

  @override
  bool shouldRepaint(BirdSkinPainter old) =>
      old.skin != skin || (old.flap - flap).abs() > 0.001;
}

/// Wing phase for a bird flapping at [speed] cycles per second.
double wingFlap(double seconds, {double speed = 3}) =>
    sin(seconds * speed * 2 * pi);
