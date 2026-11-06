import 'dart:math';

import 'package:flutter/material.dart';

import '../constants.dart';
import 'ludo_skin.dart';

/// What a premium board is made of; drives the procedural texture.
enum LudoBoardMaterial {
  flat,
  wood,
  steel,
  marble,
  gold,
  ice,
  obsidian,
  diamond,
  glass,
  frosted,
}

/// A look for the Ludo board, bought with HashCoins. Online, the whole table
/// plays on the host's board; the layout and seat colours never change.
class LudoBoardTheme implements LudoShopItem {
  const LudoBoardTheme({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
    this.cell = Colors.white,
    this.grid = Colors.black,
    this.seatBlend = Colors.black,
    this.seatMix = 0,
    this.padBlend = Colors.white,
    this.padMix = 0.75,
    this.star = const Color(0xFFFFD93D),
    this.neon = false,
    this.material = LudoBoardMaterial.flat,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String tagline;
  @override
  final int price;

  /// Track squares and the lines between them.
  final Color cell;
  final Color grid;

  /// Each seat colour is pulled [seatMix] of the way towards [seatBlend].
  final Color seatBlend;
  final double seatMix;

  /// The yard the pawns wait in: the seat colour mixed into [padBlend].
  final Color padBlend;
  final double padMix;
  final Color star;

  /// Dark yards outlined in glowing seat colour instead of filled.
  final bool neon;

  /// Premium boards get a grain, sheen or facets and a bevelled frame.
  final LudoBoardMaterial material;
  bool get premium => material != LudoBoardMaterial.flat;

  @override
  LudoRarity get rarity =>
      LudoRarity.forPrice(price, premium: 3000, legendary: 8000);

  static const classicId = 'board_classic';

  static bool isBoard(String id) => id.startsWith('board_');

  static const all = <LudoBoardTheme>[
    LudoBoardTheme(
      id: classicId,
      name: 'Classic',
      tagline: 'The original board.',
      price: 0,
    ),
    LudoBoardTheme(
      id: 'board_candy',
      name: 'Candy',
      tagline: 'Soft pastels, sweet wins.',
      price: 1500,
      cell: Color(0xFFFFF6FB),
      grid: Color(0xFFE9A6C6),
      seatBlend: Colors.white,
      seatMix: 0.3,
      padMix: 0.8,
      star: Color(0xFFFF8FB8),
    ),
    LudoBoardTheme(
      id: 'board_timber',
      name: 'Timber',
      tagline: 'A hand-carved wooden set.',
      price: 1500,
      cell: Color(0xFFF1DDB3),
      grid: Color(0xFF8A5A2B),
      seatBlend: Color(0xFF6B3E1A),
      seatMix: 0.28,
      padBlend: Color(0xFFF7E8C8),
      padMix: 0.72,
      star: Color(0xFFB9772E),
      material: LudoBoardMaterial.wood,
    ),
    LudoBoardTheme(
      id: 'board_midnight',
      name: 'Midnight',
      tagline: 'Easy on the eyes after dark.',
      price: 2000,
      cell: Color(0xFF1C1C30),
      grid: Color(0xFF3B3B60),
      seatBlend: Colors.black,
      seatMix: 0.22,
      padBlend: Color(0xFF101020),
      padMix: 0.78,
    ),
    LudoBoardTheme(
      id: 'board_royal',
      name: 'Royal',
      tagline: 'Velvet purple, trimmed in gold.',
      price: 3000,
      cell: Color(0xFF2B1055),
      grid: Color(0xFFD4AF37),
      seatBlend: Color(0xFF2B1055),
      seatMix: 0.18,
      padBlend: Color(0xFF1A0838),
      padMix: 0.7,
      star: Color(0xFFD4AF37),
    ),
    LudoBoardTheme(
      id: 'board_neon',
      name: 'Neon Grid',
      tagline: 'Arcade lights on a black table.',
      price: 4000,
      cell: Color(0xFF08080F),
      grid: Color(0xFF2C2C4A),
      padBlend: Color(0xFF08080F),
      padMix: 0.88,
      star: Color(0xFF7DF9FF),
      neon: true,
    ),
    LudoBoardTheme(
      id: 'board_mahogany',
      name: 'Mahogany',
      tagline: 'Solid hardwood with a deep grain.',
      price: 5000,
      cell: Color(0xFFD29A5E),
      grid: Color(0xFF45240F),
      seatBlend: Color(0xFF5A3216),
      seatMix: 0.3,
      padBlend: Color(0xFFEBC998),
      padMix: 0.7,
      star: Color(0xFF45240F),
      material: LudoBoardMaterial.wood,
    ),
    LudoBoardTheme(
      id: 'board_steel',
      name: 'Brushed Steel',
      tagline: 'Machined, riveted, built to last.',
      price: 6000,
      cell: Color(0xFFC6CCD5),
      grid: Color(0xFF475569),
      seatBlend: Color(0xFF64748B),
      seatMix: 0.3,
      padBlend: Color(0xFFE5E7EB),
      padMix: 0.74,
      star: Color(0xFF334155),
      material: LudoBoardMaterial.steel,
    ),
    LudoBoardTheme(
      id: 'board_marble',
      name: 'Marble',
      tagline: 'Polished stone with grey veins.',
      price: 6000,
      cell: Color(0xFFF4F1EC),
      grid: Color(0xFF9A948A),
      seatBlend: Colors.white,
      seatMix: 0.14,
      padMix: 0.82,
      star: Color(0xFFB08D57),
      material: LudoBoardMaterial.marble,
    ),
    LudoBoardTheme(
      id: 'board_rose',
      name: 'Rose Quartz',
      tagline: 'Blush-pink stone, softly veined.',
      price: 6000,
      cell: Color(0xFFFFD9E8),
      grid: Color(0xFFD6739F),
      seatBlend: Color(0xFFFFB3D1),
      seatMix: 0.3,
      padBlend: Color(0xFFFFF0F6),
      padMix: 0.8,
      star: Color(0xFFE0457F),
      material: LudoBoardMaterial.marble,
    ),
    LudoBoardTheme(
      id: 'board_glass',
      name: 'Glass',
      tagline: 'Crystal clear, catching the light.',
      price: 7000,
      cell: Color(0xFFE9FBFF),
      grid: Color(0xFF8FD8EA),
      seatBlend: Color(0xFFE3FAFF),
      seatMix: 0.42,
      padMix: 0.86,
      star: Color(0xFF22B8CF),
      material: LudoBoardMaterial.glass,
    ),
    LudoBoardTheme(
      id: 'board_frosted',
      name: 'Frosted Glass',
      tagline: 'Soft, milky and smooth.',
      price: 7000,
      cell: Color(0xFFEEF2F6),
      grid: Color(0xFFB4C0CC),
      seatBlend: Color(0xFFF1F5F9),
      seatMix: 0.36,
      padMix: 0.9,
      star: Color(0xFF8493A6),
      material: LudoBoardMaterial.frosted,
    ),
    LudoBoardTheme(
      id: 'board_ice',
      name: 'Frozen',
      tagline: 'Carved from a block of ice.',
      price: 7000,
      cell: Color(0xFFDDF2FF),
      grid: Color(0xFF7FB6D9),
      seatBlend: Color(0xFFBFE6FF),
      seatMix: 0.3,
      padMix: 0.8,
      star: Color(0xFF38A3D9),
      material: LudoBoardMaterial.ice,
    ),
    LudoBoardTheme(
      id: 'board_gold',
      name: 'Solid Gold',
      tagline: 'Twenty-four carats of flex.',
      price: 8000,
      cell: Color(0xFFF1C84B),
      grid: Color(0xFF8A6A12),
      seatBlend: Color(0xFFB8860B),
      seatMix: 0.3,
      padBlend: Color(0xFFFFEBA8),
      padMix: 0.7,
      star: Color(0xFF7A5A00),
      material: LudoBoardMaterial.gold,
    ),
    LudoBoardTheme(
      id: 'board_obsidian',
      name: 'Obsidian',
      tagline: 'Volcanic glass, cracked with lava.',
      price: 8000,
      cell: Color(0xFF16141C),
      grid: Color(0xFF4A2E2A),
      seatBlend: Colors.black,
      seatMix: 0.35,
      padBlend: Color(0xFF0B0A0E),
      padMix: 0.8,
      star: Color(0xFFFF7A1A),
      material: LudoBoardMaterial.obsidian,
    ),
    LudoBoardTheme(
      id: 'board_pink_diamond',
      name: 'Pink Diamond',
      tagline: 'The rarest cut, in hot pink.',
      price: 10000,
      cell: Color(0xFFFFD1E6),
      grid: Color(0xFFE0457F),
      seatBlend: Color(0xFFFF9CC8),
      seatMix: 0.34,
      padBlend: Color(0xFFFFF0F7),
      padMix: 0.82,
      star: Color(0xFFD81B74),
      material: LudoBoardMaterial.diamond,
    ),
    LudoBoardTheme(
      id: 'board_diamond',
      name: 'Diamond',
      tagline: 'Cut from a single flawless stone.',
      price: 10000,
      cell: Color(0xFFE6F6FF),
      grid: Color(0xFF7CC8EE),
      seatBlend: Color(0xFFB9ECFF),
      seatMix: 0.34,
      padMix: 0.82,
      star: Color(0xFF38BDF8),
      material: LudoBoardMaterial.diamond,
    ),
  ];

  /// Unknown ids (e.g. from a newer app version) fall back to Classic.
  static LudoBoardTheme byId(String? id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}

/// The board surface under the pawns, wearing [theme].
class LudoBoardSurface extends StatelessWidget {
  const LudoBoardSurface({super.key, required this.theme, this.child});

  final LudoBoardTheme theme;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (theme.id == LudoBoardTheme.classicId) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/ludo/images/board.png'),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        child: child,
      );
    }
    // The texture is costly to draw, so it keeps its own layer while pawns
    // animate above it.
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: CustomPaint(painter: _BoardPainter(theme))),
        ?child,
      ],
    );
  }
}

/// Draws the 15x15 board: four 6x6 yards, the cross-shaped track with each
/// seat's start square and home column, the safe stars and the centre.
class _BoardPainter extends CustomPainter {
  const _BoardPainter(this.theme);

  final LudoBoardTheme theme;

  // Per seat: yard corner, start square, and the home column's first square
  // plus its direction towards the centre.
  static const _seats = [
    (LudoColor.green, (0, 0), (1, 6), (1, 7), (1, 0)),
    (LudoColor.yellow, (9, 0), (8, 1), (7, 1), (0, 1)),
    (LudoColor.blue, (9, 9), (13, 8), (13, 7), (-1, 0)),
    (LudoColor.red, (0, 9), (6, 13), (7, 13), (0, -1)),
  ];
  static const _stars = [(6, 2), (12, 6), (8, 12), (2, 8)];

  Color _seat(Color c) => Color.lerp(c, theme.seatBlend, theme.seatMix)!;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 15;
    Rect cell(num x, num y, [num w = 1, num h = 1]) =>
        Rect.fromLTWH(x * u, y * u, w * u, h * u);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, u * 0.045)
      ..color = theme.grid;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..color = theme.cell);

    // Track squares: the three-wide arms of the cross.
    final coloured = <(int, int), Color>{};
    for (final (color, _, start, home, step) in _seats) {
      coloured[start] = _seat(color);
      for (var i = 0; i < 5; i++) {
        coloured[(home.$1 + step.$1 * i, home.$2 + step.$2 * i)] = _seat(color);
      }
    }
    for (var x = 0; x < 15; x++) {
      for (var y = 0; y < 15; y++) {
        final onArm = (x >= 6 && x <= 8) != (y >= 6 && y <= 8);
        if (!onArm) continue;
        final tint = coloured[(x, y)];
        if (tint != null) {
          canvas.drawRect(
            cell(x, y),
            Paint()..color = theme.neon ? tint.withValues(alpha: 0.55) : tint,
          );
        }
      }
    }

    // Yards.
    _yards(canvas, u, cell, line);
    _texture(canvas, size, u);

    for (var x = 0; x < 15; x++) {
      for (var y = 0; y < 15; y++) {
        if ((x >= 6 && x <= 8) != (y >= 6 && y <= 8)) {
          if (theme.premium) {
            // Calm the texture on the track so squares stay easy to read.
            canvas.drawRect(
              cell(x, y),
              Paint()
                ..color = (coloured[(x, y)] ?? theme.cell).withValues(
                  alpha: 0.6,
                ),
            );
          }
          canvas.drawRect(cell(x, y), line);
        }
      }
    }
    for (final (x, y) in _stars) {
      final c = cell(x, y).center;
      final star = Path();
      for (var i = 0; i < 10; i++) {
        final a = -pi / 2 + i * pi / 5;
        final p = c + Offset(cos(a), sin(a)) * (u * (i.isEven ? 0.38 : 0.16));
        i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(star..close(), Paint()..color = theme.star);
    }

    for (final (color, corner, _, _, _) in _seats) {
      final seat = _seat(color);
      // Sockets where the four pawns wait.
      for (final (dx, dy) in const [(2, 2), (2, 4), (4, 2), (4, 4)]) {
        canvas.drawCircle(
          Offset((corner.$1 + dx) * u, (corner.$2 + dy) * u),
          u * 0.42,
          Paint()..color = seat.withValues(alpha: theme.neon ? 0.3 : 0.35),
        );
      }
    }

    // Centre: one triangle per seat, pointing home.
    final mid = Offset(7.5 * u, 7.5 * u);
    final corners = [
      Offset(6 * u, 6 * u),
      Offset(9 * u, 6 * u),
      Offset(9 * u, 9 * u),
      Offset(6 * u, 9 * u),
    ];
    // Sides in order: top (yellow), right (blue), bottom (red), left (green).
    const sideSeat = [1, 2, 3, 0];
    for (var i = 0; i < 4; i++) {
      final a = corners[i];
      final b = corners[(i + 1) % 4];
      final wedge = Path()
        ..moveTo(mid.dx, mid.dy)
        ..lineTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..close();
      canvas.drawPath(wedge, Paint()..color = _seat(_seats[sideSeat[i]].$1));
      canvas.drawPath(wedge, line);
    }
    if (theme.premium) _frame(canvas, size, u);
    canvas.restore();
  }

  void _yards(
    Canvas canvas,
    double u,
    Rect Function(num, num, [num, num]) cell,
    Paint line,
  ) {
    for (final (color, corner, _, _, _) in _seats) {
      final seat = _seat(color);
      final yard = cell(corner.$1, corner.$2, 6, 6);
      final pad = RRect.fromRectAndRadius(
        cell(corner.$1 + 1, corner.$2 + 1, 4, 4),
        Radius.circular(u * 0.7),
      );
      if (theme.neon) {
        canvas.drawRect(yard, Paint()..color = theme.cell);
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.22
          ..color = seat
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.25);
        canvas.drawRRect(pad, glow);
        canvas.drawRRect(pad, Paint()..color = theme.cell);
        canvas.drawRRect(
          pad,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.1
            ..color = seat,
        );
        canvas.drawRect(yard.deflate(u * 0.05), line..color = seat);
        line.color = theme.grid;
      } else {
        canvas.drawRect(
          yard,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(seat, Colors.white, 0.18)!,
                Color.lerp(seat, Colors.black, 0.18)!,
              ],
            ).createShader(yard),
        );
        canvas.drawRRect(
          pad,
          Paint()..color = Color.lerp(seat, theme.padBlend, theme.padMix)!,
        );
      }
    }
  }

  /// The material's grain, sheen or facets, laid over the whole surface in
  /// translucent light and dark so the seat colours show through.
  void _texture(Canvas canvas, Size size, double u) {
    final rng = Random(theme.material.index * 97 + 5);
    final w = size.width;
    Paint ink(Color c, double a, [double width = 1]) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..color = c.withValues(alpha: a);
    void sheen(double at, double alpha) {
      final band = Rect.fromLTWH(0, 0, w, w);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: alpha),
              Colors.white.withValues(alpha: 0),
            ],
            stops: [at - 0.12, at, at + 0.12],
          ).createShader(band),
      );
    }

    /// A random point inside one of the four yards, clear of the track.
    Offset inYard() {
      final corner = _seats[rng.nextInt(4)].$2;
      return Offset(
        (corner.$1 + 0.5 + rng.nextDouble() * 5) * u,
        (corner.$2 + 0.5 + rng.nextDouble() * 5) * u,
      );
    }

    void sparkle(Offset c, double r, Color color) {
      final star = Path()
        ..moveTo(c.dx, c.dy - r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
        ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
        ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r);
      canvas.drawPath(star, Paint()..color = color);
    }

    /// A jagged line wandering from [from] roughly along [angle].
    Path crack(Offset from, double angle, int steps, double stride) {
      final path = Path()..moveTo(from.dx, from.dy);
      var p = from;
      var a = angle;
      for (var i = 0; i < steps; i++) {
        a += (rng.nextDouble() - 0.5) * 1.1;
        p += Offset(cos(a), sin(a)) * (stride * (0.5 + rng.nextDouble()));
        path.lineTo(p.dx, p.dy);
      }
      return path;
    }

    switch (theme.material) {
      case LudoBoardMaterial.flat:
        break;
      case LudoBoardMaterial.wood:
        for (var i = 0; i < 90; i++) {
          final y = rng.nextDouble() * w;
          final wave = u * (0.1 + rng.nextDouble() * 0.35);
          final phase = rng.nextDouble() * 6;
          final grain = Path()..moveTo(0, y);
          for (var x = 0.0; x <= w; x += u * 0.75) {
            grain.lineTo(x, y + sin(x / (u * 2.2) + phase) * wave);
          }
          canvas.drawPath(
            grain,
            i.isEven
                ? ink(Colors.black, 0.05 + rng.nextDouble() * 0.12, u * 0.06)
                : ink(Colors.white, 0.04 + rng.nextDouble() * 0.08, u * 0.05),
          );
        }
        for (var k = 0; k < 3; k++) {
          final c = Offset(rng.nextDouble() * w, rng.nextDouble() * w);
          for (var r = 1; r <= 4; r++) {
            canvas.drawOval(
              Rect.fromCenter(
                center: c,
                width: u * 0.5 * r,
                height: u * 0.22 * r,
              ),
              ink(Colors.black, 0.12, u * 0.05),
            );
          }
        }
      case LudoBoardMaterial.steel:
        for (var i = 0; i < 170; i++) {
          final y = rng.nextDouble() * w;
          final x = rng.nextDouble() * w;
          canvas.drawLine(
            Offset(x, y),
            Offset(x + w * (0.2 + rng.nextDouble() * 0.6), y),
            ink(
              i.isEven ? Colors.white : Colors.black,
              0.05 + rng.nextDouble() * 0.09,
            ),
          );
        }
        sheen(0.3, 0.3);
        sheen(0.72, 0.18);
        // Rivets at the corners of each yard.
        for (final (_, corner, _, _, _) in _seats) {
          for (final (dx, dy) in const [
            (0.4, 0.4),
            (5.6, 0.4),
            (0.4, 5.6),
            (5.6, 5.6),
          ]) {
            final c = Offset((corner.$1 + dx) * u, (corner.$2 + dy) * u);
            canvas.drawCircle(
              c,
              u * 0.16,
              Paint()..color = const Color(0xFF475569),
            );
            canvas.drawCircle(
              c - Offset(u * 0.04, u * 0.04),
              u * 0.09,
              Paint()..color = const Color(0xFFE2E8F0),
            );
          }
        }
      case LudoBoardMaterial.marble:
        for (var i = 0; i < 11; i++) {
          final vein = crack(
            Offset(rng.nextDouble() * w, rng.nextDouble() * w * 0.3),
            pi / 2 + (rng.nextDouble() - 0.5),
            16,
            u * 1.1,
          );
          canvas.drawPath(
            vein,
            ink(
              const Color(0xFF6B6B76),
              0.12 + rng.nextDouble() * 0.2,
              u * (0.04 + rng.nextDouble() * 0.12),
            )..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.06),
          );
        }
        sheen(0.4, 0.22);
      case LudoBoardMaterial.gold:
        for (var i = 0; i < 220; i++) {
          canvas.drawCircle(
            Offset(rng.nextDouble() * w, rng.nextDouble() * w),
            u * 0.04,
            Paint()
              ..color = (i.isEven ? Colors.white : const Color(0xFF6B4E00))
                  .withValues(alpha: 0.18),
          );
        }
        sheen(0.22, 0.42);
        sheen(0.55, 0.28);
        sheen(0.85, 0.36);
        for (var i = 0; i < 9; i++) {
          sparkle(
            inYard(),
            u * (0.25 + rng.nextDouble() * 0.3),
            Colors.white.withValues(alpha: 0.85),
          );
        }
      case LudoBoardMaterial.ice:
        for (var i = 0; i < 14; i++) {
          canvas.drawPath(
            crack(
              Offset(rng.nextDouble() * w, rng.nextDouble() * w),
              rng.nextDouble() * 2 * pi,
              7,
              u * 0.9,
            ),
            ink(Colors.white, 0.75, u * 0.05),
          );
        }
        canvas.drawRect(
          Offset.zero & size,
          Paint()
            ..shader = RadialGradient(
              radius: 0.75,
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.4),
              ],
            ).createShader(Offset.zero & size),
        );
        sheen(0.35, 0.3);
      case LudoBoardMaterial.obsidian:
        sheen(0.3, 0.1);
        for (var i = 0; i < 10; i++) {
          final lava = crack(
            Offset(rng.nextDouble() * w, rng.nextDouble() * w),
            rng.nextDouble() * 2 * pi,
            9,
            u * 0.9,
          );
          canvas.drawPath(
            lava,
            ink(const Color(0xFFFF5A1F), 0.85, u * 0.2)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, u * 0.18),
          );
          canvas.drawPath(lava, ink(const Color(0xFFFFD166), 0.95, u * 0.05));
        }
      case LudoBoardMaterial.glass:
        // Hard-edged reflections sweeping across the pane.
        for (final (at, width, alpha) in const [
          (0.18, 0.1, 0.42),
          (0.33, 0.035, 0.3),
          (0.7, 0.16, 0.26),
        ]) {
          final x = w * 2 * at;
          final streak = Path()
            ..moveTo(x, 0)
            ..lineTo(x + w * 2 * width, 0)
            ..lineTo(x + w * 2 * width - w, w)
            ..lineTo(x - w, w)
            ..close();
          canvas.drawPath(
            streak,
            Paint()..color = Colors.white.withValues(alpha: alpha),
          );
        }
        // Each yard is its own bevelled pane.
        for (final (_, corner, _, _, _) in _seats) {
          final pane = Rect.fromLTWH(
            corner.$1 * u,
            corner.$2 * u,
            6 * u,
            6 * u,
          ).deflate(u * 0.12);
          canvas.drawRect(pane, ink(Colors.white, 0.8, u * 0.07));
          canvas.drawRect(
            pane.deflate(u * 0.12),
            ink(const Color(0xFF22B8CF), 0.25, u * 0.04),
          );
        }
      case LudoBoardMaterial.frosted:
        for (var i = 0; i < 1400; i++) {
          canvas.drawCircle(
            Offset(rng.nextDouble() * w, rng.nextDouble() * w),
            u * (0.02 + rng.nextDouble() * 0.04),
            Paint()
              ..color = (i % 3 == 0 ? const Color(0xFF64748B) : Colors.white)
                  .withValues(alpha: 0.1 + rng.nextDouble() * 0.16),
          );
        }
        canvas.drawRect(
          Offset.zero & size,
          Paint()..color = Colors.white.withValues(alpha: 0.22),
        );
        sheen(0.3, 0.3);
        sheen(0.75, 0.2);
      case LudoBoardMaterial.diamond:
        // A field of triangular facets catching the light differently.
        final step = u * 1.5;
        for (var gy = 0; gy * step < w; gy++) {
          for (var gx = 0; gx * step < w; gx++) {
            final o = Offset(gx * step, gy * step);
            // Split each square along alternating diagonals.
            final a = o + Offset(step, 0);
            final b = o + Offset(step, step);
            final c = o + Offset(0, step);
            final halves = (gx + gy).isEven
                ? [
                    [o, a, c],
                    [a, b, c],
                  ]
                : [
                    [o, a, b],
                    [o, b, c],
                  ];
            for (final pts in halves) {
              final facet = Path()..addPolygon(pts, true);
              final light = rng.nextDouble();
              canvas.drawPath(
                facet,
                Paint()
                  ..color = light > 0.45
                      ? Colors.white.withValues(alpha: (light - 0.45) * 0.6)
                      : theme.grid.withValues(alpha: (0.45 - light) * 0.35),
              );
              canvas.drawPath(facet, ink(Colors.white, 0.35, u * 0.03));
            }
          }
        }
        sheen(0.3, 0.35);
        for (var i = 0; i < 12; i++) {
          sparkle(
            inYard(),
            u * (0.2 + rng.nextDouble() * 0.3),
            Colors.white.withValues(alpha: 0.95),
          );
        }
    }
  }

  /// A bevelled rim, lit from the top-left.
  void _frame(Canvas canvas, Size size, double u) {
    final t = u * 0.22;
    final rim = (Offset.zero & size).deflate(t / 2);
    canvas.drawRect(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = t
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(theme.grid, Colors.white, 0.6)!,
            theme.grid,
            Color.lerp(theme.grid, Colors.black, 0.45)!,
          ],
        ).createShader(rim),
    );
  }

  @override
  bool shouldRepaint(_BoardPainter old) => old.theme != theme;
}
