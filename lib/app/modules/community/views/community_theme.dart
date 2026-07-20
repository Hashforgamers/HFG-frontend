import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the Community Tournament module, aligned to the app's
/// overall HASH theme: black surfaces, neon green actions, restrained purple
/// esports accents, white text, and soft outlined cards.
class CT {
  CT._();

  // Surfaces
  static const bg = Color(0xFF000000);
  static const surfaceLow = Color(0xFF090909);
  static const surface = Color(0xFF101010);
  static const surfaceHigh = Color(0xFF1A1A1A);
  static const cardTop = Color(0xFF121212);
  static const cardBottom = Color(0xFF090909);

  // Text
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFB8B8B8);
  static const muted = Color(0xFF777777);

  // Accents (from the app theme)
  static const primary = Color(0xFF00DC00);
  static const primaryBright = Color(0xFF55F05A);
  static const secondary = Color(0xFF745CFF);
  static const verifiedBlue = Color(0xFF0096F1);
  static const success = Color(0xFF00C853);
  static const successBright = Color(0xFF55E878);
  static const error = Color(0xFFFF6B6B);

  // Lines / borders
  static const outline = Color(0xFF292929);
  static const hairline = Color(0x1FFFFFFF);

  /// Default content groups stay open and use only a quiet divider. Passing a
  /// [borderColor] opts into a contained panel for high-priority information.
  static BoxDecoration card({Color? borderColor}) {
    if (borderColor == null) {
      return const BoxDecoration(
        border: Border(bottom: BorderSide(color: hairline, width: 1)),
      );
    }
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [cardTop, cardBottom],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor, width: 1),
    );
  }

  static List<BoxShadow> glow(
    Color color, {
    double blur = 24,
    double opacity = 0.35,
  }) => [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: -4,
    ),
  ];

  // Typography helpers
  static TextStyle display(
    double size, {
    Color color = onSurface,
    FontWeight w = FontWeight.w800,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color,
    height: 1.15,
    letterSpacing: -0.4,
  );

  static TextStyle headline(
    double size, {
    Color color = onSurface,
    FontWeight w = FontWeight.w700,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color,
    height: 1.3,
  );

  static TextStyle body(
    double size, {
    Color color = onSurfaceVariant,
    FontWeight w = FontWeight.w400,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color,
    height: 1.5,
  );

  static TextStyle mono(
    double size, {
    Color color = muted,
    FontWeight w = FontWeight.w500,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: w,
    color: color,
    letterSpacing: 0.8,
  );
}
