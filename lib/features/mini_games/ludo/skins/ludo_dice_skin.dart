import 'dart:math';

import 'package:flutter/material.dart';

import 'ludo_skin.dart';

/// A look for the Ludo dice, bought with HashCoins. Online, rivals see it
/// whenever its owner rolls.
class LudoDiceSkin implements LudoShopItem {
  const LudoDiceSkin({
    required this.id,
    required this.name,
    required this.tagline,
    required this.price,
    this.top = Colors.white,
    this.bottom = const Color(0xFFE5E7EB),
    this.pip = Colors.black,
    this.edge = const Color(0xFF0B0B10),
    this.glow = false,
    this.faceted = false,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String tagline;
  @override
  final int price;

  /// Body gradient, top to bottom.
  final Color top;
  final Color bottom;
  final Color pip;
  final Color edge;

  /// Pips that shine like neon tubes.
  final bool glow;

  /// Cut-gem facets across the face.
  final bool faceted;

  @override
  LudoRarity get rarity =>
      LudoRarity.forPrice(price, premium: 1000, legendary: 2500);

  static const classicId = 'dice_classic';

  static bool isDice(String id) => id.startsWith('dice_');

  static const all = <LudoDiceSkin>[
    LudoDiceSkin(
      id: classicId,
      name: 'Classic',
      tagline: 'The original dice.',
      price: 0,
    ),
    LudoDiceSkin(
      id: 'dice_ruby',
      name: 'Ruby',
      tagline: 'Casino red, white pips.',
      price: 400,
      top: Color(0xFFFF5A5F),
      bottom: Color(0xFFC1121F),
      pip: Colors.white,
    ),
    LudoDiceSkin(
      id: 'dice_bubblegum',
      name: 'Bubblegum',
      tagline: 'Sweet, pink and lucky.',
      price: 600,
      top: Color(0xFFFFA6CF),
      bottom: Color(0xFFFF4F9A),
      pip: Colors.white,
    ),
    LudoDiceSkin(
      id: 'dice_onyx',
      name: 'Onyx',
      tagline: 'Jet black with gold pips.',
      price: 600,
      top: Color(0xFF3A3A44),
      bottom: Color(0xFF0B0B10),
      pip: Color(0xFFFFD166),
      edge: Color(0xFFFFD166),
    ),
    LudoDiceSkin(
      id: 'dice_oak',
      name: 'Oak',
      tagline: 'Turned from solid wood.',
      price: 800,
      top: Color(0xFFDDA873),
      bottom: Color(0xFF8A5A2B),
      pip: Color(0xFF3B200C),
      edge: Color(0xFF3B200C),
    ),
    LudoDiceSkin(
      id: 'dice_steel',
      name: 'Steel',
      tagline: 'Heavy, cold and precise.',
      price: 1000,
      top: Color(0xFFF1F5F9),
      bottom: Color(0xFF94A3B8),
      pip: Color(0xFF1E293B),
      edge: Color(0xFF334155),
    ),
    LudoDiceSkin(
      id: 'dice_glass',
      name: 'Glass',
      tagline: 'Clear as a cold drink.',
      price: 1500,
      top: Color(0xCCE6FBFF),
      bottom: Color(0xCC7DD3E8),
      pip: Color(0xFF0E7490),
      edge: Color(0xFF67C7DD),
    ),
    LudoDiceSkin(
      id: 'dice_gold',
      name: 'Gold',
      tagline: 'Roll like royalty.',
      price: 2000,
      top: Color(0xFFFFE680),
      bottom: Color(0xFFD4A017),
      pip: Color(0xFF5C3D00),
      edge: Color(0xFF7A5A00),
    ),
    LudoDiceSkin(
      id: 'dice_neon',
      name: 'Neon',
      tagline: 'Pips that glow in the dark.',
      price: 2500,
      top: Color(0xFF17172E),
      bottom: Color(0xFF05050C),
      pip: Color(0xFF39FF88),
      edge: Color(0xFF39FF88),
      glow: true,
    ),
    LudoDiceSkin(
      id: 'dice_diamond',
      name: 'Diamond',
      tagline: 'Every roll sparkles.',
      price: 4000,
      top: Color(0xFFF2FCFF),
      bottom: Color(0xFFA5E3FF),
      pip: Color(0xFF0284C7),
      edge: Color(0xFF7CC8EE),
      faceted: true,
    ),
  ];

  /// Unknown ids (e.g. from a newer app version) fall back to Classic.
  static LudoDiceSkin byId(String? id) =>
      all.firstWhere((d) => d.id == id, orElse: () => all.first);
}

/// One dice showing [value] (1-6), or tumbling while [rolling].
class LudoDice extends StatefulWidget {
  const LudoDice({
    super.key,
    required this.skin,
    required this.value,
    this.rolling = false,
  });

  final LudoDiceSkin skin;
  final int value;
  final bool rolling;

  @override
  State<LudoDice> createState() => _LudoDiceState();
}

class _LudoDiceState extends State<LudoDice>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
  );

  bool get _painted => widget.skin.id != LudoDiceSkin.classicId;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(LudoDice old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (widget.rolling && _painted) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_painted) {
      return Image.asset(
        widget.rolling
            ? 'assets/ludo/images/dice/draw.gif'
            : 'assets/ludo/images/dice/${widget.value.clamp(1, 6)}.png',
        fit: BoxFit.contain,
      );
    }
    if (!widget.rolling) return _face(widget.value);
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) => Transform.rotate(
        angle: _spin.value * 2 * pi,
        // Six faces flash by on every turn.
        child: _face(1 + (_spin.value * 6).floor() % 6),
      ),
    );
  }

  Widget _face(int value) => AspectRatio(
    aspectRatio: 1,
    child: CustomPaint(painter: _DicePainter(widget.skin, value.clamp(1, 6))),
  );
}

class _DicePainter extends CustomPainter {
  const _DicePainter(this.skin, this.value);

  final LudoDiceSkin skin;
  final int value;

  // Pip positions on a 3x3 grid, per face.
  static const _pips = <int, List<(int, int)>>{
    1: [(1, 1)],
    2: [(0, 0), (2, 2)],
    3: [(0, 0), (1, 1), (2, 2)],
    4: [(0, 0), (2, 0), (0, 2), (2, 2)],
    5: [(0, 0), (2, 0), (1, 1), (0, 2), (2, 2)],
    6: [(0, 0), (2, 0), (0, 1), (2, 1), (0, 2), (2, 2)],
  };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final body = RRect.fromRectAndRadius(
      (Offset.zero & Size(s, s)).deflate(s * 0.06),
      Radius.circular(s * 0.2),
    );
    canvas.drawRRect(
      body.shift(Offset(0, s * 0.04)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [skin.top, skin.bottom],
        ).createShader(body.outerRect),
    );

    canvas.save();
    canvas.clipRRect(body);
    if (skin.faceted) {
      final c = Offset(s / 2, s / 2);
      final cut = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02
        ..color = Colors.white.withValues(alpha: 0.7);
      for (var i = 0; i < 8; i++) {
        final a = i * pi / 4;
        final wedge = Path()
          ..moveTo(c.dx, c.dy)
          ..lineTo(c.dx + cos(a) * s, c.dy + sin(a) * s)
          ..lineTo(c.dx + cos(a + pi / 4) * s, c.dy + sin(a + pi / 4) * s)
          ..close();
        if (i.isEven) {
          canvas.drawPath(
            wedge,
            Paint()..color = Colors.white.withValues(alpha: 0.28),
          );
        }
        canvas.drawPath(wedge, cut);
      }
    }
    // Gloss across the top-left corner.
    canvas.drawOval(
      Rect.fromLTWH(-s * 0.2, -s * 0.45, s * 1.1, s * 0.8),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
    canvas.restore();

    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.045
        ..color = skin.edge,
    );

    for (final (col, row) in _pips[value]!) {
      final at = Offset(s * (0.28 + 0.22 * col), s * (0.28 + 0.22 * row));
      if (skin.glow) {
        canvas.drawCircle(
          at,
          s * 0.11,
          Paint()
            ..color = skin.pip
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.07),
        );
      }
      canvas.drawCircle(at, s * 0.075, Paint()..color = skin.pip);
    }
  }

  @override
  bool shouldRepaint(_DicePainter old) =>
      old.skin != skin || old.value != value;
}
