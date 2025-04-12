import 'package:flutter/material.dart';

class DottedVerticalDivider extends StatelessWidget {
  final double height;
  final double dotSize;
  final double spacing;
  final Color color;

  const DottedVerticalDivider({
    Key? key,
    this.height = 100,
    this.dotSize = 4,
    this.spacing = 4,
    this.color = Colors.grey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: DottedLinePainter(
          dotSize: dotSize,
          spacing: spacing,
          color: color,
        ),
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final double dotSize;
  final double spacing;
  final Color color;

  DottedLinePainter({
    required this.dotSize,
    required this.spacing,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double y = 0;
    while (y < size.height) {
      canvas.drawCircle(Offset(size.width / 2, y), dotSize / 2, paint);
      y += dotSize + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
