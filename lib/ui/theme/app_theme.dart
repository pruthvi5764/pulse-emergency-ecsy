import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Brand Colors (Modernized) ──────────────────────────────────────────────
  static const Color accentCyan = Color(0xFF00E5FF);
  static const Color accentBlue = Color(0xFF2979FF);
  static const Color emergencyRed = Color(0xFFFF3B30); // Vibrant iOS-style red
  static const Color backgroundBlack = Color(0xFF000000);
  static const Color surfaceBlack = Color(0xFF0A0A0A);
  static const Color cardGrey = Color(0xFF141414);

  // ─── Typography ─────────────────────────────────────────────────────────────
  static TextTheme get _darkTextTheme => GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -2),
          displayMedium: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1),
          titleLarge: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w500),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white60),
        ),
      );

  // ─── Shared widget themes ───────────────────────────────────────────────────

  static AppBarTheme get _appBarTheme => const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
          color: Colors.white,
        ),
      );

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24, width: 1.5),
          minimumSize: const Size(120, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      );

  // ─── Dark Theme (Primary) ──────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        secondary: accentCyan,
        surface: surfaceBlack,
        error: emergencyRed,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundBlack,
      textTheme: _darkTextTheme,
      appBarTheme: _appBarTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withAlpha(15)),
        ),
        color: cardGrey,
      ),
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withAlpha(15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: const TextStyle(color: Colors.white38),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        contentTextStyle: GoogleFonts.inter(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Fallback Light Theme (Now just a variation of dark or kept for compatibility)
  static ThemeData get lightTheme => darkTheme;
}
