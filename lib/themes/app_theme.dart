import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.blue,
    primaryColor: Colors.blue,
    hintColor: Color.fromRGBO(58, 255, 107, 1.0),
    scaffoldBackgroundColor: Colors.black,
    textTheme: GoogleFonts.playTextTheme(
      ThemeData.dark().textTheme,
    ),
    appBarTheme: AppBarTheme(
      color: Color.fromRGBO(58, 255, 107, 1.0),
      iconTheme: IconThemeData(color: Colors.black),
      toolbarTextStyle: GoogleFonts.playTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.black).bodyMedium,
      titleTextStyle: GoogleFonts.playTextTheme(
        ThemeData.dark().textTheme,
      ).apply(bodyColor: Colors.black).titleLarge,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: Color(0xFF3AFF6B), // Using hex code for the loader color
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: Color.fromRGBO(58, 255, 107, 1.0),
      backgroundColor: Colors.black12,
    ),
  );
}
