import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 1. The "Ice & Water" Color Palette
  static const Color primaryBlue = Color(0xFF1E88E5);      // Ocean Blue
  static const Color deepBlue = Color(0xFF0D47A1);         // Deep Navy (Headings)
  static const Color lightIce = Color(0xFFE3F2FD);         // Very light blue (Backgrounds)
  static const Color accentPurple = Color(0xFF7C4DFF);     // For special buttons/AI

  // 2. The Gradient (We will use this on backgrounds)
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFE3F2FD), // Light Ice
      Colors.white,      // Fades to White
    ],
  );

  // 3. The Global Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      
      // Define Colors
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: Colors.white, // Default (we will override with gradient manually)
      
      // Define Text Styles (Poppins)
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.black87,
        displayColor: deepBlue,
      ),

      // Card Style (Floating & Rounded)
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.blue.withValues(alpha: 0.15), // Soft blue shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.only(bottom: 16),
      ),

      // App Bar Style
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: deepBlue),
        titleTextStyle: TextStyle(
          color: deepBlue, 
          fontSize: 20, 
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins' // Force Poppins
        ),
      ),

      // Button Styles
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 5,
        ),
      ),
    );
  }
}