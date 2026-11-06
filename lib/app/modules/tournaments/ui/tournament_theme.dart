import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the tournaments module, matched to the home screen:
/// near-black surfaces, the hashforgamers.com pink -> coral -> orange brand
/// gradient for actions, and soft-edged 22px cards.
class CT {
  CT._();

  // Surfaces
  static const bg = Color(0xFF000000);
  static const surfaceLow = Color(0xFF0B0D12);
  static const surface = Color(0xFF13161E);
  static const surfaceHigh = Color(0xFF1C2130);
  static const cardTop = Color(0xFF161A24);
  static const cardBottom = Color(0xFF0E1118);

  // Text
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFA7AEBC);
  static const muted = Color(0xFF6E7686);

  // Accents (brand palette from the home screen)
  static const pink = Color(0xFFFF3E8E);
  static const primary = Color(0xFFFF6F61);
  static const primaryBright = Color(0xFFFF9A3D);
  static const secondary = Color(0xFFFF3E8E);
  static const verifiedBlue = Color(0xFF3DA9FF);
  static const success = Color(0xFF00DC00);
  static const successBright = Color(0xFF6BFF6B);
  static const error = Color(0xFFFF5A6E);
  static const gold = Color(0xFFF4C342);

  static const brand = LinearGradient(colors: [pink, primary, primaryBright]);

  // Lines / borders
  static const outline = Color(0x1AFFFFFF);
  static const hairline = Color(0x14FFFFFF);

  /// Without [borderColor]: an open row with a quiet divider. With it: a lit
  /// card (gradient surface, tinted edge, soft drop shadow).
  static BoxDecoration card({Color? borderColor}) {
    if (borderColor == null) {
      return const BoxDecoration(
        border: Border(bottom: BorderSide(color: hairline, width: 1)),
      );
    }
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [cardTop, cardBottom],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: const [
        BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 8)),
      ],
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
