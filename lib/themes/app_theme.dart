import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    hintColor: Color(0xffDE3A3A),
    scaffoldBackgroundColor: Colors.black,
    textTheme: GoogleFonts.playTextTheme(
      ThemeData.dark().textTheme,
    ),
    appBarTheme: AppBarTheme(
      color: Color(0xff0F0F0F),
      iconTheme: IconThemeData(color: Color(0xffDE3A3A)),
      toolbarTextStyle: GoogleFonts.playTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor:  Color(0xffDE3A3A)).bodyMedium,
      titleTextStyle: GoogleFonts.playTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor:  Color(0xffDE3A3A)).titleLarge,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Color(0xffDE3A3A), // Using hex code for the loader color
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Color(0xffDE3A3A),
      backgroundColor: Colors.black12,
    ),
  );
}
