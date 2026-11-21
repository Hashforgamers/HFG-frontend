import 'dart:math';

import 'package:flutter/material.dart';

/// How special a shop item is; the shop groups items under these headings.
enum LudoRarity {
  normal('NORMAL', Color(0xFFC9C0FF)),
  premium('PREMIUM', Color(0xFFFFD60A)),
  legendary('LEGENDARY', Color(0xFFFF5FA2));

  const LudoRarity(this.label, this.color);
  final String label;
  final Color color;

  /// Tier for an item costing [price], given where its category's premium
  /// and legendary price bands start.
  static LudoRarity forPrice(
    int price, {
    required int premium,
    required int legendary,
  }) => price >= legendary
      ? LudoRarity.legendary
      : (price >= premium ? LudoRarity.premium : LudoRarity.normal);
}

/// Something sold in the Ludo shop for HashCoins.
abstract class LudoShopItem {
  LudoRarity get rarity;

  String get id;
  String get name;
  String get tagline;

  /// HashCoins; 0 means everyone owns it.
  int get price;
}

/// A look for a player's Ludo pawns, bought with HashCoins. Skins only change
/// the drawing; every pawn keeps its seat colour so the board stays readable.
class LudoSkin implements LudoShopItem {
  const LudoSkin({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String tagline;
  @override
  final int price;

  @override
  LudoRarity get rarity =>
      LudoRarity.forPrice(price, premium: 1000, legendary: 2500);

  static const classicId = 'classic';

  static const all = <LudoSkin>[
    LudoSkin(
      id: classicId,
      name: 'Classic',
      tagline: 'The original token.',
      price: 0,
    ),
    LudoSkin(
      id: 'glossy',
      name: 'Glossy',
      tagline: 'A polished marble shine.',
      price: 500,
    ),
    LudoSkin(
      id: 'bullseye',
      name: 'Bullseye',
      tagline: 'Rings that never miss.',
      price: 800,
    ),
    LudoSkin(
      id: 'star',
      name: 'Star',
      tagline: 'For the main character.',
      price: 1200,
    ),
    LudoSkin(
      id: 'royal',
      name: 'Royal',
      tagline: 'Gold rim, crown on top.',
      price: 2000,
    ),
    LudoSkin(
      id: 'neon',
      name: 'Neon',
      tagline: 'Glows in the dark.',
      price: 2500,
    ),
    LudoSkin(
      id: 'diamond',
      name: 'Diamond',
      tagline: 'Cut, faceted, flawless.',
      price: 3000,
    ),
  ];

  /// Unknown ids (e.g. from a newer app version) fall back to Classic.
  static LudoSkin byId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);
}

/// A pawn of [color] wearing [skin].
class LudoPawn extends StatelessWidget {
  const LudoPawn({super.key, required this.skin, required this.color});

  final LudoSkin skin;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (skin.id == LudoSkin.classicId) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );
    }
    return CustomPaint(
      painter: _PawnPainter(skin.id, color),
      child: const SizedBox.expand(),
    );
  }
}

class _PawnPainter extends CustomPainter {
  const _PawnPainter(this.skin, this.color);

  final String skin;
  final Color color;

  static const _gold = Color(0xFFFFC93C);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final dark = Color.lerp(color, Colors.black, 0.45)!;
    final light = Color.lerp(color, Colors.white, 0.6)!;
    Paint fill(Color c) => Paint()..color = c;
    Paint line(Color c, double w) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeJoin = StrokeJoin.round
      ..color = c;

    // Every skin sits on the same white-rimmed disc as the classic token.
    canvas.drawCircle(c, r, fill(Colors.white));

    switch (skin) {
      case 'glossy':
        canvas.drawCircle(
          c,
          r * 0.86,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.4),
              colors: [light, color, dark],
              stops: const [0, 0.55, 1],
            ).createShader(Rect.fromCircle(center: c, radius: r * 0.86)),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: c + Offset(-r * 0.28, -r * 0.38),
            width: r * 0.5,
            height: r * 0.28,
          ),
          fill(Colors.white.withValues(alpha: 0.75)),
        );
      case 'bullseye':
        canvas.drawCircle(c, r * 0.86, fill(color));
        canvas.drawCircle(c, r * 0.6, fill(Colors.white));
        canvas.drawCircle(c, r * 0.4, fill(color));
        canvas.drawCircle(c, r * 0.16, fill(Colors.white));
      case 'star':
        canvas.drawCircle(c, r * 0.86, fill(color));
        final star = Path();
        for (var i = 0; i < 10; i++) {
          final a = -pi / 2 + i * pi / 5;
          final p = c + Offset(cos(a), sin(a)) * (r * (i.isEven ? 0.64 : 0.28));
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        star.close();
        canvas.drawPath(star, fill(Colors.white));
        canvas.drawPath(star, line(dark, r * 0.08));
      case 'royal':
        canvas.drawCircle(c, r, fill(_gold));
        canvas.drawCircle(c, r * 0.76, fill(color));
        final crown = Path()
          ..moveTo(c.dx - r * 0.46, c.dy + r * 0.3)
          ..lineTo(c.dx - r * 0.5, c.dy - r * 0.26)
          ..lineTo(c.dx - r * 0.22, c.dy)
          ..lineTo(c.dx, c.dy - r * 0.42)
          ..lineTo(c.dx + r * 0.22, c.dy)
          ..lineTo(c.dx + r * 0.5, c.dy - r * 0.26)
          ..lineTo(c.dx + r * 0.46, c.dy + r * 0.3)
          ..close();
        // White, so the crown still reads on the yellow seat.
        canvas.drawPath(crown, fill(Colors.white));
        canvas.drawPath(crown, line(dark, r * 0.07));
      case 'neon':
        canvas.drawCircle(c, r, fill(const Color(0xFF10101C)));
        canvas.drawCircle(
          c,
          r * 0.62,
          line(color, r * 0.3)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.22),
        );
        canvas.drawCircle(c, r * 0.62, line(light, r * 0.14));
        canvas.drawCircle(c, r * 0.2, fill(light));
      case 'diamond':
        canvas.drawCircle(c, r * 0.86, fill(dark));
        Offset at(int i, double k) =>
            c +
            Offset(cos(-pi / 2 + i * pi / 3), sin(-pi / 2 + i * pi / 3)) * k;
        for (var i = 0; i < 6; i++) {
          final facet = Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(at(i, r * 0.8).dx, at(i, r * 0.8).dy)
            ..lineTo(at(i + 1, r * 0.8).dx, at(i + 1, r * 0.8).dy)
            ..close();
          canvas.drawPath(
            facet,
            fill(Color.lerp(color, i.isEven ? Colors.white : dark, 0.35)!),
          );
        }
        final table = Path();
        for (var i = 0; i < 6; i++) {
          final p = at(i, r * 0.38);
          i == 0 ? table.moveTo(p.dx, p.dy) : table.lineTo(p.dx, p.dy);
        }
        table.close();
        canvas.drawPath(table, fill(light));
    }
  }

  @override
  bool shouldRepaint(_PawnPainter old) =>
      old.skin != skin || old.color != color;
}
