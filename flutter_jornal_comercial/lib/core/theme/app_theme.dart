
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light => criar(
        primary: const Color(0xFF315C63),
        primaryDark: const Color(0xFF264A50),
        secondary: const Color(0xFF687276),
        background: const Color(0xFFF3F5F4),
        surface: const Color(0xFFFFFFFF),
        text: const Color(0xFF273033),
        textLight: const Color(0xFF687276),
        border: const Color(0xFFD6DCDD),
        danger: const Color(0xFFB42318),
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
      onSecondary: Colors.white,
      surface: surface,
      onSurface: text,
      error: danger,
      onError: Colors.white,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: textLight,
      outline: border,
      outlineVariant: border,
      error: danger,
      onError: Colors.white,
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
          borderSide: BorderSide(
            color: primary,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withValues(alpha: 0.55),
          elevation: 0,
          overlayColor: primaryDark.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
