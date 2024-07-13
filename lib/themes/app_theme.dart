import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    hintColor: Color(0xff00D701),
    scaffoldBackgroundColor: Colors.black,
    textTheme: GoogleFonts.playTextTheme(
      ThemeData.dark().textTheme,
    ),
    appBarTheme: AppBarTheme(
      color: Color(0xff00D701),
      iconTheme: IconThemeData(color: Colors.black),
      toolbarTextStyle: GoogleFonts.playTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.black).bodyMedium,
      titleTextStyle: GoogleFonts.playTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.black).titleLarge,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Color(0xff00D701), // Using hex code for the loader color
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Color(0xff00D701),
      backgroundColor: Colors.black12,
    ),
  );
}
