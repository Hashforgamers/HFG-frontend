import 'package:flutter/material.dart';

class ChatPalette {
  static const Color bgTop = Color(0xFF000000);
  static const Color bgBottom = Color(0xFF000000);

  static const Color surface = Color(0xFF090909);
  static const Color surfaceAlt = Color(0xFF151515);
  static const Color inputFill = Color(0xFF101010);
  static const Color border = Color(0xFF292929);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF8F8F8F);

  static const Color primary = Color(0xFF00DC00);
  static const Color primaryDark = Color(0xFF00A900);
  static const Color accent = Color(0xFF745CFF);
  static const Color primaryGlow = Color(0xFF55F05A);
  static const Color success = Color(0xFF55E878);

  static const LinearGradient pageGradient = LinearGradient(
    colors: [bgTop, bgBottom],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF101010), Color(0xFF090909)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mineBubbleGradient = LinearGradient(
    colors: [Color(0xFF00DC00), Color(0xFF00A900)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
