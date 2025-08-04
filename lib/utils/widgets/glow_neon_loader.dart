import 'package:flutter/material.dart';

class RainbowGlowingLoader extends StatefulWidget {
  final double size;

  const RainbowGlowingLoader({super.key, this.size = 80}); // default size: 80

  @override
  State<RainbowGlowingLoader> createState() => _RainbowGlowingLoaderState();
}

class _RainbowGlowingLoaderState extends State<RainbowGlowingLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<double> blurLevels = [3, 6, 12, 24];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBlurredCircle(double blur, double size) {
    return Container(
      height: size,
      width: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Colors.red,
            Colors.orange,
            Colors.yellow,
            Colors.green,
            Colors.cyan,
            Colors.blue,
            Colors.purple,
            Colors.red,
          ],
        ),
      ),
      child: Container(color: Colors.transparent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double outerSize = widget.size;
    final double innerSize = outerSize * 0.88;

    return Center(
      child: RotationTransition(
        turns: _controller,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (var blur in blurLevels) _buildBlurredCircle(blur, outerSize),
            Container(
              height: outerSize,
              width: outerSize,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                  ],
                ),
              ),
            ),
            Container(
              height: innerSize,
              width: innerSize,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
