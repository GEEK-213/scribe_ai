import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors from your HTML
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color primaryBlue = Color(0xFF2B8CEE);    // Primary
  static const Color glassSurface = Color(0x0DFFFFFF);   // 5% White
  static const Color glassBorder = Color(0x1AFFFFFF);    // 10% White
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: primaryBlue,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }
}