import 'package:flutter/material.dart';

class RainbowLoadingBar extends StatefulWidget {
  final double? width;
  final double? height;

  const RainbowLoadingBar({Key? key, this.width, this.height}) : super(key: key);

  @override
  _RainbowLoadingBarState createState() => _RainbowLoadingBarState();
}

class _RainbowLoadingBarState extends State<RainbowLoadingBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: widget.height ?? 5.0,
        width: widget.width ?? 200.0,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment(-8.0 + 8.0 * _controller.value, 0.0),
                  end: Alignment(1.0 + 8.0 * _controller.value, 0.0),
                  colors: const [
                    Colors.red,
                    Colors.orange,
                    Colors.yellow,
                    Colors.green,
                    Colors.blue,
                    Colors.indigo,
                    Colors.purple,
                    Colors.red, // Ensure the loop is smooth
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
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: RainbowLoadingBar(width: 300, height: 10)), // You can set width and height here
    ),
  ));
}
