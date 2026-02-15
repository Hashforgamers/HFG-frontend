import 'package:flutter/material.dart';

class ChatPalette {
  static const Color bgTop = Color(0xFF0B0B0C);
  static const Color bgBottom = Color(0xFF000000);

  static const Color surface = Color(0xFF000000);
  static const Color surfaceAlt = Color(0xFF1C1C1E);
  static const Color inputFill = Color(0xFF1C1C1E);
  static const Color border = Color(0xFF2C2C2E);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF9A9AA0);

  static const Color primary = Color(0xFF4F8CFF);
  static const Color primaryDark = Color(0xFF2D5FEA);
  static const Color accent = Color(0xFFC084FC);

  static const LinearGradient pageGradient = LinearGradient(
    colors: [bgTop, bgBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1A1A1C), Color(0xFF131315)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mineBubbleGradient = LinearGradient(
    colors: [Color(0xFF2D5FEA), Color(0xFF4F8CFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
