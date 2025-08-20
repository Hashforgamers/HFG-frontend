import 'dart:ui';
import 'package:flutter/material.dart';

class RainbowGlowingLoader extends StatefulWidget {
  final double size;

  const RainbowGlowingLoader({super.key, this.size = 80});

  @override
  State<RainbowGlowingLoader> createState() => _RainbowGlowingLoaderState();
}

class _RainbowGlowingLoaderState extends State<RainbowGlowingLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const _rainbowGradient = SweepGradient(
    colors: [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.blue,
      Colors.purple,
      Colors.red, // loop
    ],
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildGlowCircle({required double size, required double blur}) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: _rainbowGradient,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double outerSize = widget.size;
    final double innerSize = outerSize * 0.82;

    return RepaintBoundary(
      child: SizedBox(
        width: outerSize,
        height: outerSize,
        child: RotationTransition(
          turns: _controller,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Efficient single blurred glow
              _buildGlowCircle(size: outerSize, blur: 12.0),

              // Main rotating color ring
              Container(
                width: outerSize,
                height: outerSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _rainbowGradient,
                ),
              ),

              // Black inner cut-out
              Container(
                width: innerSize,
                height: innerSize,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
