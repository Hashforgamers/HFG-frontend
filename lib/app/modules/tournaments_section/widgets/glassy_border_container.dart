// lib/widgets/glassy_border_container.dart
import 'dart:math';
import 'package:flutter/material.dart';

class GlassyBorderContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderWidth;
  final double cornerRadius;
  final Color baseBorderColor;
  final Color highlightColor;
  final Widget? child;

  const GlassyBorderContainer({
    super.key,
    this.width = 340,
    this.height = 80,
    this.borderWidth = 1.6,
    this.cornerRadius = 14,
    this.baseBorderColor = const Color(0xFF202024), // subtle outer border
    this.highlightColor = Colors.white,             // glossy highlight
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GlassyBorderPainter(
        borderWidth: borderWidth,
        cornerRadius: cornerRadius,
        baseBorderColor: baseBorderColor,
        highlightColor: highlightColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cornerRadius),
        child: Container(
          width: width,
          height: height,
          color: Colors.white.withOpacity(0.1), // example interior color
          child: child,
        ),
      ),
    );
  }
}

class _GlassyBorderPainter extends CustomPainter {
  final double borderWidth;
  final double cornerRadius;
  final Color baseBorderColor;
  final Color highlightColor;

  _GlassyBorderPainter({
    required this.borderWidth,
    required this.cornerRadius,
    required this.baseBorderColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));

    // 1) Draw base (subtle) rounded border around whole card
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = baseBorderColor.withOpacity(0.65)
      ..isAntiAlias = true;
    canvas.drawRRect(rrect, basePaint);

    // 2) Draw glossy highlight stroke but OMIT top-right and bottom-left corner arcs
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..color = highlightColor.withOpacity(0.92)
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final left = 0.0;
    final top = 0.0;
    final right = size.width;
    final bottom = size.height;
    final r = cornerRadius;

    // Helper: draw straight segments and corner arcs (conditionally)
    // We will draw as separate segments so the skipped corners become visible gaps.

    // TOP EDGE: from (left + r) to (right - r)
    final topStart = Offset(left + r, top);
    final topEnd = Offset(right - r, top);
    canvas.drawLine(topStart, topEnd, highlightPaint);

    // TOP-RIGHT CORNER ARC -> SKIP (do not draw)
    // We intentionally do not draw arc here to create the gap at top-right.

    // RIGHT EDGE: from (right, top + r) to (right, bottom - r)
    final rightStart = Offset(right, top + r);
    final rightEnd = Offset(right, bottom - r);
    canvas.drawLine(rightStart, rightEnd, highlightPaint);

    // BOTTOM-RIGHT CORNER ARC -> draw (we want it)
    final bottomRightCenter = Offset(right - r, bottom - r);
    final brRect = Rect.fromCircle(center: bottomRightCenter, radius: r);
    // Arc from 0 to +pi/2 (right->bottom)
    canvas.drawArc(brRect, 0, pi / 2, false, highlightPaint);

    // BOTTOM EDGE: from (left + r) to (right - r)
    final bottomStart = Offset(left + r, bottom);
    final bottomEnd = Offset(right - r, bottom);
    canvas.drawLine(bottomStart, bottomEnd, highlightPaint);

    // BOTTOM-LEFT CORNER ARC -> SKIP (do not draw)
    // Intentionally left blank.

    // LEFT EDGE: from (left, top + r) to (left, bottom - r)
    final leftStart = Offset(left, top + r);
    final leftEnd = Offset(left, bottom - r);
    canvas.drawLine(leftStart, leftEnd, highlightPaint);

    // TOP-LEFT CORNER ARC -> draw (we want it)
    final topLeftCenter = Offset(left + r, top + r);
    final tlRect = Rect.fromCircle(center: topLeftCenter, radius: r);
    // Arc from -pi to -pi/2 (left->top): that's -pi to -pi/2 -> sweep pi/2
    canvas.drawArc(tlRect, -pi, pi / 2, false, highlightPaint);

    // Slight inner glow (optional): draw a very faint thinner highlight shifted top-left
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth * 0.6
      ..color = highlightColor.withOpacity(0.14)
      ..isAntiAlias = true;
    // small top-left line to enhance glossy look
    canvas.drawLine(
      Offset(left + r + 6, top + 2),
      Offset(right - r - 20, top + 2),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
