import 'package:flutter/material.dart';

class AppTheme {
  static const Color navy = Color(0xFF1F2C3F);
  static const Color slate = Color(0xFF8A94A6);
  static const Color surfaceLight = Color(0xFFF4F6FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0F1722);
  static const Color cardDark = Color(0xFF1A2433);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.light,
      primary: navy,
      surface: surfaceLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceLight,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: surfaceLight,
        foregroundColor: Colors.black,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFE9EDF4),
        selectedColor: navy,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Color(0xFFDCE6F7),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.dark,
      primary: const Color(0xFFBFD4FF),
      surface: surfaceDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: surfaceDark,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF243044),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF243044),
        selectedColor: const Color(0xFF4A6288),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Color(0xFF121C2A),
        indicatorColor: Color(0xFF2C3A4E),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2C3A4E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
