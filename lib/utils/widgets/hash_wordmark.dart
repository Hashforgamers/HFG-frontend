import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HashWordmark extends StatelessWidget {
  final double fontSize;
  final double letterSpacing;
  final Color color;
  final Color accentColor;

  const HashWordmark({
    super.key,
    this.fontSize = 24,
    this.letterSpacing = 7,
    this.color = Colors.white,
    this.accentColor = const Color(0xFFA6FF00),
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.michroma(
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          color: color,
        ),
        children: [
          const TextSpan(text: 'H'),
          TextSpan(
            text: 'Λ',
            style: TextStyle(
              color: accentColor,
              fontSize: fontSize * 1.18,
              letterSpacing: letterSpacing,
            ),
          ),
          const TextSpan(text: 'SH'),
        ],
      ),
      maxLines: 1,
    );
  }
}
