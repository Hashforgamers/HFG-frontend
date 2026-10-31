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

class AppLoaderSize {
  static const double screenWidth = 180.0;
  static const double screenHeight = 4.0;
  static const double buttonWidth = 100.0;
  static const double buttonHeight = 3.0;
}

class AppLinearLoader extends StatelessWidget {
  final double width;
  final double height;
  final bool centered;

  const AppLinearLoader({
    super.key,
    this.width = AppLoaderSize.screenWidth,
    this.height = AppLoaderSize.screenHeight,
    this.centered = false,
  });

  const AppLinearLoader.screen({super.key})
    : width = AppLoaderSize.screenWidth,
      height = AppLoaderSize.screenHeight,
      centered = true;

  const AppLinearLoader.button({super.key})
    : width = AppLoaderSize.buttonWidth,
      height = AppLoaderSize.buttonHeight,
      centered = true;

  @override
  Widget build(BuildContext context) {
    final loader = RepaintBoundary(
      child: RainbowLoadingBar(width: width, height: height),
    );
    if (!centered) return loader;
    return Center(child: loader);
  }
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
