import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hash/app/modules/chat/theme/chat_palette.dart';

/// WhatsApp-style chat backdrop: a dark fill with a faint, tilted
/// "HASH HUB" wordmark tiled across it.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChatPalette.roomBg,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _WordmarkPainter(
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.045),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _WordmarkPainter extends CustomPainter {
  _WordmarkPainter({required this.style});

  final TextStyle style;

  static const String _label = 'HASH HUB';
  static const double _angle = -math.pi / 7;
  static const double _gapX = 34;
  static const double _gapY = 38;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final word = TextPainter(
      text: TextSpan(text: _label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final stepX = word.width + _gapX;
    final stepY = word.height + _gapY;
    // The grid is rotated about the centre, so it has to span the diagonal
    // to keep the corners covered.
    final reach = size.longestSide * 0.75 + stepX;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(_angle);

    var row = 0;
    for (var y = -reach; y < reach; y += stepY, row++) {
      // Offset every other row so the words read as a pattern, not columns.
      final shift = row.isOdd ? stepX / 2 : 0.0;
      for (var x = -reach - shift; x < reach; x += stepX) {
        word.paint(canvas, Offset(x, y));
      }
    }
    canvas.restore();
    word.dispose();
  }

  @override
  bool shouldRepaint(_WordmarkPainter oldDelegate) =>
      oldDelegate.style != style;
}
