import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _primary = Color(0xFF4F46E5);

  static const _lightBg = Color(0xFFF7F7F8);
  static const _darkBg = Color(0xFF0F1115);

  static const _lightCard = Colors.white;
  static const _darkCard = Color(0xFF16181D);

  static const _lightText = Color(0xFF1F2937);
  static const _darkText = Color(0xFFE5E7EB);

  static const _mutedLight = Color(0xFF6B7280);
  static const _mutedDark = Color(0xFF9CA3AF);

  // =========================
  // LIGHT
  // =========================
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: _lightBg,

    colorScheme: const ColorScheme.light(
      primary: _primary,
      onPrimary: Colors.white,
      surface: _lightCard,
      onSurface: _lightText,
      background: _lightBg,
      onBackground: _lightText,
    ),

    textTheme: _lightTextTheme,
    primaryTextTheme: _lightTextTheme,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: _lightText,
    ),

    cardTheme: const CardThemeData(
      color: _lightCard,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: _primary.withOpacity(0.08),
      selectedColor: _primary.withOpacity(0.15),
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _lightText,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),

    dividerColor: const Color(0xFFE5E7EB),
  );

  // =========================
  // DARK
  // =========================
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: _darkBg,

    colorScheme: const ColorScheme.dark(
      primary: _primary,
      onPrimary: Colors.white,
      surface: _darkCard,
      onSurface: _darkText,
      background: _darkBg,
      onBackground: _darkText,
    ),

    textTheme: _darkTextTheme,
    primaryTextTheme: _darkTextTheme,

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: _darkText,
    ),

    cardTheme: const CardThemeData(
      color: _darkCard,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withOpacity(0.08),
      selectedColor: Colors.white.withOpacity(0.15),
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _darkText,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
    ),

    dividerColor: const Color(0xFF2A2D34),
  );

  // =========================
  // TEXT THEMES
  // =========================
  static const TextTheme _lightTextTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: _lightText,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _lightText,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: _lightText,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: _mutedLight,
    ),
  );

  static const TextTheme _darkTextTheme = TextTheme(
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: _darkText,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _darkText,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: _darkText,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: _mutedDark,
    ),
  );
}
