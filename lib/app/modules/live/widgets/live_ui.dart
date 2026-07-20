import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveUi {
  static const Color bg = Color(0xFF0C0E13);
  static const Color surface = Color(0xFF15171C);
  static const Color surfaceSoft = Color(0xFF20232A);
  static const Color stroke = Color(0xFF292D35);
  static const Color accent = Color(0xFFFF3D4D);
  static const Color accentSoft = Color(0xFFFF6673);
  static const Color softText = Color(0xFF989EAA);
  static const double radiusLg = 22;
  static const double radiusMd = 16;
  static const double radiusSm = 12;

  static BoxDecoration cardDecoration({double radius = radiusMd}) =>
      BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF1B1E24), const Color(0xFF14161B)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: stroke),
        boxShadow: [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      );

  static BoxDecoration pageDecoration() => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF111318), Color(0xFF090A0D)],
    ),
  );

  static TextStyle title = GoogleFonts.inter(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  static TextStyle body = GoogleFonts.inter(color: softText, fontSize: 12);

  static InputDecoration input({String? hint}) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFF9EA5B5), fontSize: 13),
    filled: true,
    fillColor: const Color(0xFF242934),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF363C48)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF363C48)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: accentSoft, width: 1.1),
    ),
  );
}
