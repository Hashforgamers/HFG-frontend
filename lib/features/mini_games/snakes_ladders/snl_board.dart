import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'snl_match.dart';

/// Centre of square [n] (1–100) on a board of side [side]. Squares zigzag
/// from the bottom-left: row 0 runs left→right, row 1 right→left, and so on.
/// Square 0 (not started) shares square 1's spot so tokens stay on the board.
Offset snlCellCenter(int square, double side) {
  var n = square;
  final cell = side / 10;
  if (n <= 0) n = 1;
  final i = n - 1;
  final row = i ~/ 10;
  var col = i % 10;
  if (row.isOdd) col = 9 - col;
  return Offset((col + 0.5) * cell, side - (row + 0.5) * cell);
}

/// Static board art: tiles, numbers, ladders and snakes. Paint once inside a
/// RepaintBoundary; tokens are separate widgets on top.
class SnlBoardPainter extends CustomPainter {
  const SnlBoardPainter();

  static const _rowColors = [
    (Color(0xFFFFE680), Color(0xFFFFD23F)),
    (Color(0xFFA6F28F), Color(0xFF7CD95F)),
    (Color(0xFF9FD4FF), Color(0xFF6BB8FF)),
    (Color(0xFFFFB38A), Color(0xFFFF9160)),
    (Color(0xFFD7B8FF), Color(0xFFBE92FF)),
  ];

  static const _snakeColors = [
    (Color(0xFF3DDC5A), Color(0xFF168A2E)),
    (Color(0xFFFF6B8B), Color(0xFFC21E4A)),
    (Color(0xFFB57BFF), Color(0xFF6A2FD1)),
    (Color(0xFFFFB33D), Color(0xFFD16A00)),
    (Color(0xFF3DC7FF), Color(0xFF0B79C2)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final cell = side / 10;
    _paintTiles(canvas, side, cell);
    var i = 0;
    for (final e in kSnlLadders.entries) {
      _paintLadder(canvas, side, cell, e.key, e.value, i++);
    }
    i = 0;
    for (final e in kSnlSnakes.entries) {
      _paintSnake(canvas, side, cell, e.key, e.value, i++);
    }
  }

  void _paintTiles(Canvas canvas, double side, double cell) {
    final fill = Paint();
    for (var n = 1; n <= 100; n++) {
      final row = (n - 1) ~/ 10;
      final c = snlCellCenter(n, side);
      final rect = Rect.fromCenter(center: c, width: cell, height: cell);
      final (light, dark) = _rowColors[(row ~/ 2) % _rowColors.length];
      fill.color = (n.isEven) ? light : dark;
      canvas.drawRect(rect, fill);
      // Soft top highlight for a chunky tile look.
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.18),
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
      final label = n == 100 ? '🏆' : '$n';
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: GoogleFonts.lilitaOne(
            fontSize: cell * (n == 100 ? 0.42 : 0.26),
            color: const Color(0xCC2A1A00),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        n == 100
            ? c - Offset(tp.width / 2, tp.height / 2)
            : rect.topLeft + Offset(cell * 0.08, cell * 0.04),
      );
    }
    // Grid lines.
    final grid = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (var k = 1; k < 10; k++) {
      canvas.drawLine(Offset(k * cell, 0), Offset(k * cell, side), grid);
      canvas.drawLine(Offset(0, k * cell), Offset(side, k * cell), grid);
    }
  }

  void _paintLadder(
    Canvas canvas,
    double side,
    double cell,
    int from,
    int to,
    int index,
  ) {
    final a = snlCellCenter(from, side);
    final b = snlCellCenter(to, side);
    final dir = b - a;
    final len = dir.distance;
    if (len == 0) return;
    final n = Offset(-dir.dy / len, dir.dx / len) * (cell * 0.2);
    final outline = Paint()
      ..color = const Color(0xFF3A1F05)
      ..strokeWidth = cell * 0.16
      ..strokeCap = StrokeCap.round;
    final wood = Paint()
      ..color = const Color(0xFFC98A3D)
      ..strokeWidth = cell * 0.09
      ..strokeCap = StrokeCap.round;

    // Rungs first so the rails sit on top.
    final rungs = max(2, (len / (cell * 0.42)).floor());
    for (var r = 1; r < rungs; r++) {
      final p = a + dir * (r / rungs);
      canvas.drawLine(p - n, p + n, outline..strokeWidth = cell * 0.11);
      canvas.drawLine(
        p - n,
        p + n,
        Paint()
          ..color = const Color(0xFFE0A85A)
          ..strokeWidth = cell * 0.05
          ..strokeCap = StrokeCap.round,
      );
    }
    outline.strokeWidth = cell * 0.16;
    for (final s in [n, -n]) {
      canvas.drawLine(a + s, b + s, outline);
      canvas.drawLine(a + s, b + s, wood);
    }
  }

  void _paintSnake(
    Canvas canvas,
    double side,
    double cell,
    int head,
    int tail,
    int index,
  ) {
    final h = snlCellCenter(head, side);
    final t = snlCellCenter(tail, side);
    final dir = t - h;
    final len = dir.distance;
    if (len == 0) return;
    final normal = Offset(-dir.dy / len, dir.dx / len);
    final wiggle = min(cell * 1.1, len * 0.35) * (index.isEven ? 1 : -1);

    final path = Path()
      ..moveTo(h.dx, h.dy)
      ..cubicTo(
        (h + dir * 0.3 + normal * wiggle).dx,
        (h + dir * 0.3 + normal * wiggle).dy,
        (h + dir * 0.7 - normal * wiggle).dx,
        (h + dir * 0.7 - normal * wiggle).dy,
        t.dx,
        t.dy,
      );

    final (light, dark) = _snakeColors[index % _snakeColors.length];
    final width = cell * 0.3;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width + cell * 0.08
        ..color = const Color(0xFF0B0B10),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..shader = LinearGradient(
          colors: [light, dark],
        ).createShader(Rect.fromPoints(h, t)),
    );
    // Belly stripe dots along the body.
    final metric = path.computeMetrics().first;
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.45);
    for (
      var d = metric.length * 0.12;
      d < metric.length * 0.9;
      d += cell * 0.32
    ) {
      final pos = metric.getTangentForOffset(d)?.position;
      if (pos != null) canvas.drawCircle(pos, width * 0.14, dot);
    }

    // Head with eyes and tongue.
    final headR = width * 0.78;
    final forward = metric.getTangentForOffset(0)?.vector ?? const Offset(0, 1);
    final back = -forward / (forward.distance == 0 ? 1 : forward.distance);
    canvas.drawCircle(
      h,
      headR + cell * 0.04,
      Paint()..color = const Color(0xFF0B0B10),
    );
    canvas.drawCircle(h, headR, Paint()..color = light);
    final side90 = Offset(-back.dy, back.dx);
    for (final s in [1.0, -1.0]) {
      final eye = h + side90 * (headR * 0.42 * s) + back * (headR * 0.25);
      canvas.drawCircle(eye, headR * 0.3, Paint()..color = Colors.white);
      canvas.drawCircle(
        eye + back * (headR * 0.08),
        headR * 0.15,
        Paint()..color = const Color(0xFF0B0B10),
      );
    }
    final tongueStart = h + back * headR;
    final tongueEnd = tongueStart + back * (headR * 0.7);
    final tongue = Paint()
      ..color = const Color(0xFFE8392C)
      ..strokeWidth = cell * 0.04
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tongueStart, tongueEnd, tongue);
    canvas.drawLine(
      tongueEnd,
      tongueEnd + (back + side90) * (headR * 0.25),
      tongue,
    );
    canvas.drawLine(
      tongueEnd,
      tongueEnd + (back - side90) * (headR * 0.25),
      tongue,
    );
  }

  @override
  bool shouldRepaint(SnlBoardPainter oldDelegate) => false;
}
