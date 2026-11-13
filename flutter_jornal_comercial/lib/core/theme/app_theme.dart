
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light => criar(
        primary: const Color(0xFFE52E67),
        primaryDark: const Color(0xFFD82B61),
        secondary: const Color(0xFF817980),
        background: const Color(0xFFFFFBFC),
        surface: Colors.white,
        text: const Color(0xFF242126),
        textLight: const Color(0xFFAAA3A8),
        border: const Color(0xFFEDE4E7),
        danger: const Color(0xFFD82B61),
      );

  static ThemeData criar({
    required Color primary,
    required Color primaryDark,
    required Color secondary,
    required Color background,
    required Color surface,
    required Color text,
    required Color textLight,
    required Color border,
    required Color danger,
  }) {
    final esquema = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      surface: surface,
      onSurface: text,
      error: danger,
    ).copyWith(
      outline: border,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: esquema,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(color: textLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
