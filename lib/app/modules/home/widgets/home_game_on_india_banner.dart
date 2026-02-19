import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeGameOnIndiaBanner extends StatefulWidget {
  const HomeGameOnIndiaBanner({super.key});

  @override
  State<HomeGameOnIndiaBanner> createState() => _HomeGameOnIndiaBannerState();
}

class _HomeGameOnIndiaBannerState extends State<HomeGameOnIndiaBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  Text _titleText() {
    final triColorShader = const LinearGradient(
      colors: [
        Color(0xFFFF9933),
        // Color(0xFFFF9933),
        Colors.white,
        // Colors.white,
        Color(0xff00DC00),
        Color(0xff00DC00),
      ],
      // stops: [0.0, 0.33, 0.33, 0.66, 0.66, 1.0],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(const Rect.fromLTWH(0, 0, 700, 140));

    return Text(
      'Game On, India!',
      style: GoogleFonts.tulpenOne(
        fontSize: 100,
        fontWeight: FontWeight.normal,
        foreground: Paint()..shader = triColorShader,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5.0),
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            _titleText(),
            AnimatedBuilder(
              animation: _shineController,
              builder: (context, child) {
                final value = _shineController.value;
                final start = -1.6 + (3.2 * value);
                final end = start + 0.8;
                return ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                    stops: const [0.35, 0.5, 0.65],
                    begin: Alignment(start, 0),
                    end: Alignment(end, 0),
                  ).createShader(bounds),
                  child: child,
                );
              },
              child: _titleText(),
            ),
          ],
        ),
      ),
    );
  }
}
