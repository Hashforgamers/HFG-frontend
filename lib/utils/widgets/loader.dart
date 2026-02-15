import 'package:flutter/material.dart';

class RainbowLoadingBar extends StatefulWidget {
  final double width;
  final double height;

  const RainbowLoadingBar({
    super.key,
    this.width = 200.0,
    this.height = 3.0,
  });

  @override
  State<RainbowLoadingBar> createState() => _RainbowLoadingBarState();
}

class _RainbowLoadingBarState extends State<RainbowLoadingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -8.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(_animation.value, 0.0),
                end: Alignment(_animation.value + 8.0, 0.0),
                colors: const [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  const Color(0xff00DC00),
                  Colors.blue,
                  Colors.indigo,
                  Colors.purple,
                  Colors.red, // for smooth wrap
                ],
                stops: const [
                  0.0,
                  1 / 7,
                  2 / 7,
                  3 / 7,
                  4 / 7,
                  5 / 7,
                  6 / 7,
                  1.0,
                ],
              ).createShader(bounds);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          );
        },
      ),
    );
  }
}
