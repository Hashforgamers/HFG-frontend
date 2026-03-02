import 'package:flutter/material.dart';

class ChatPalette {
  static const Color bgTop = Color(0xFF15171D);
  static const Color bgBottom = Color(0xFF0C0E13);

  static const Color surface = Color(0xFF1A1D23);
  static const Color surfaceAlt = Color(0xFF232833);
  static const Color inputFill = Color(0xFF242934);
  static const Color border = Color(0xFF363C48);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9EA5B5);

  static const Color primary = Color(0xFFFF7A00);
  static const Color primaryDark = Color(0xFFE05A00);
  static const Color accent = Color(0xFFFFB347);
  static const Color primaryGlow = Color(0xFFFFA726);
  static const Color success = Color(0xFF62D281);

  static const LinearGradient pageGradient = LinearGradient(
    colors: [bgTop, bgBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF272C36), Color(0xFF1E222B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mineBubbleGradient = LinearGradient(
    colors: [Color(0xFFFFA726), Color(0xFFFF6D00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
