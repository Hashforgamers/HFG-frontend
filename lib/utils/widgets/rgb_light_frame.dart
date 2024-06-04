import 'package:flutter/material.dart';
import 'dart:math';

class RGBLightFrame extends StatefulWidget {
  final double width;
  final double height;
  final double strokeWidth;
  final double borderRadius;
  final Duration duration;

  RGBLightFrame({
    required this.width,
    required this.height,
    this.strokeWidth = 2.0,
    this.borderRadius = 16.0,
    this.duration = const Duration(seconds: 2),
  });

  @override
  _RGBLightFrameState createState() => _RGBLightFrameState();
}

class _RGBLightFrameState extends State<RGBLightFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
    _animation = Tween<double>(begin: 0, end: 2 * pi).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RGBFramePainter(
        animation: _animation,
        strokeWidth: widget.strokeWidth,
        borderRadius: widget.borderRadius,
      ),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
      ),
    );
  }
}

class RGBFramePainter extends CustomPainter {
  final Animation<double> animation;
  final double strokeWidth;
  final double borderRadius;

  RGBFramePainter({
    required this.animation,
    required this.strokeWidth,
    required this.borderRadius,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = SweepGradient(
      colors: [
        Colors.red,
        Colors.yellow,
        Colors.green,
        Colors.cyan,
        Colors.blue,
        Colors.purpleAccent,
        Colors.red,
      ],
      stops: [0.0, 1 / 6, 2 / 6, 3 / 6, 4 / 6, 5 / 6, 1.0],
      transform: GradientRotation(animation.value),
    );

    paint.shader = gradient.createShader(rect);

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
          Radius.circular(borderRadius)));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
