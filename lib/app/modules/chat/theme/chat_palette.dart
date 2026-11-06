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

  // WhatsApp-dark tones used by the conversation screen.
  static const Color roomBg = Color(0xFF0B141A);
  static const Color roomBar = Color(0xFF1F2C34);
  static const Color bubbleIn = Color(0xFF202C33);
  static const Color bubbleOut = Color(0xFF005C4B);
  static const Color roomText = Color(0xFFE9EDEF);
  static const Color roomTextMuted = Color(0xFF8696A0);
  static const Color roomAccent = Color(0xFF00A884);
  static const Color tickSeen = Color(0xFF53BDEB);
  static const Color avatarFill = Color(0xFF2A3942);
  static const Color chipSelected = Color(0xFF0A332C);
  static const Color chipSelectedText = Color(0xFFD9FDD3);

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
