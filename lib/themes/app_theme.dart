import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: DesignTokens.primaryColor,
    scaffoldBackgroundColor: DesignTokens.backgroundColor,
    colorScheme: ColorScheme.dark(
      primary: DesignTokens.primaryColor,
      secondary: DesignTokens.primaryColor,
      surface: DesignTokens.surfaceColor,
      background: DesignTokens.backgroundColor,
    ),
    textTheme: GoogleFonts.playTextTheme(
      ThemeData.dark().textTheme.copyWith(
        bodyLarge: TextStyle(
          fontSize: DesignTokens.fontSizeMd,
          color: DesignTokens.textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: DesignTokens.fontSizeSm,
          color: DesignTokens.textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: DesignTokens.fontSizeXl,
          color: DesignTokens.textPrimaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    appBarTheme: AppBarTheme(
      color: DesignTokens.surfaceColor,
      elevation: 0,
      iconTheme: IconThemeData(color: DesignTokens.primaryColor),
      titleTextStyle: GoogleFonts.playTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: DesignTokens.primaryColor).titleLarge,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLg,
          vertical: DesignTokens.spacingMd,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DesignTokens.surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        borderSide: BorderSide(color: DesignTokens.primaryColor),
      ),
      contentPadding: EdgeInsets.all(DesignTokens.spacingMd),
    ),
    cardTheme: CardTheme(
      color: DesignTokens.surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: DesignTokens.primaryColor,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: DesignTokens.primaryColor,
      backgroundColor: DesignTokens.surfaceColor,
      unselectedItemColor: DesignTokens.textSecondaryColor,
    ),
  );
}
