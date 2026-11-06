import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens for the tournaments module, matching the Hash Shop: flat
/// near-black surfaces with a faint border, solid green for the main action,
/// purple for selection and accents. No gradients or glows.
class CT {
  CT._();

  // Surfaces (StoreColors)
  static const bg = Color(0xFF050506);
  static const surfaceLow = Color(0xFF0B0B0D);
  static const surface = Color(0xFF111114);
  static const surfaceHigh = Color(0xFF1A1A1F);

  // Text
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xB3FFFFFF);
  static const muted = Color(0x8CFFFFFF);

  // Accents
  static const purple = Color(0xFF7A44C0);
  static const primary = Color(0xFFB38CFF); // purple, for accent text/icons
  static const primaryBright = Color(0xFFB38CFF);
  static const secondary = Color(0xFFB38CFF);
  static const verifiedBlue = Color(0xFF3DA9FF);
  static const success = Color(0xFF00DC00);
  static const successBright = Color(0xFF67FF67);
  static const error = Color(0xFFFF5A5F);
  static const gold = Color(0xFFF4C342);

  // Lines / borders
  static const outline = Color(0x1FFFFFFF);
  static const hairline = Color(0x14FFFFFF);

  /// Without [borderColor]: an open row with a quiet divider. With it: a flat
  /// panel like the shop's.
  static BoxDecoration card({Color? borderColor}) {
    if (borderColor == null) {
      return const BoxDecoration(
        border: Border(bottom: BorderSide(color: hairline, width: 1)),
      );
    }
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(20),
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

  /// Screen titles, as in the shop (Orbitron).
  static TextStyle screenTitle([double size = 20]) => GoogleFonts.orbitron(
    color: onSurface,
    fontSize: size,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

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
