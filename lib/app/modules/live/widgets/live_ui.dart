import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveUi {
  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF2C3E50);
  static const Color surfaceSoft = Color(0xFF111111);
  static const Color stroke = Color(0x00000000);
  static const Color accent = Color(0xFF2C3E50);
  static const Color accentSoft = Color(0xFF2C3E50);
  static const Color softText = Color(0xFFE6EEF5);
  static const double radiusLg = 22;
  static const double radiusMd = 16;
  static const double radiusSm = 12;

  static BoxDecoration cardDecoration({double radius = radiusMd}) => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2C3E50).withValues(alpha: 0.55),
            const Color(0xFF000000).withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x552C3E50),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration pageDecoration() => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF000000), Color(0xFF111111), Color(0xFF000000)],
        ),
      );

  static TextStyle title = GoogleFonts.inter(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static TextStyle body = GoogleFonts.inter(
    color: softText,
    fontSize: 12,
  );

  static InputDecoration input({String? hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x99E6EEF5), fontSize: 13),
        filled: true,
        fillColor: Color(0x332C3E50),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );
}
