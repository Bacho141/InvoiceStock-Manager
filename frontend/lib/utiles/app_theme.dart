import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData themeData = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7717E8),
      primary: const Color(0xFF7717E8),
      secondary: const Color(0xFFB388FF),
      background: const Color(0xFFF8F8FA),
      surface: Colors.white,
      error: const Color(0xFFEB5757),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: const Color(0xFF2C3E50),
      onSurface: const Color(0xFF2C3E50),
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F8FA),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF7717E8).withOpacity(0.08),
      labelStyle: const TextStyle(color: Color(0xFF7717E8)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF7717E8),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Color(0xFF7717E8),
      ),
      bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF2C3E50)),
      bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFFB0B0C3)),
    ),
  );
}
