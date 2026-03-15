import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceLight,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: Colors.white,
    ),
    textTheme: _buildTextTheme(Brightness.light),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundLight,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiaryLight,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 4,
      ),
    ),
    dividerColor: AppColors.textTertiaryLight.withValues(alpha: 0.2),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: AppColors.primary,
      brightness: Brightness.light,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceDark,
      error: AppColors.danger,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: Colors.white,
    ),
    textTheme: _buildTextTheme(Brightness.dark),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundDark,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textTertiaryDark,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 4,
      ),
    ),
    dividerColor: AppColors.textTertiaryDark.withValues(alpha: 0.2),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: AppColors.primaryLight,
      brightness: Brightness.dark,
    ),
  );

  static ThemeData neonTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.backgroundNeon,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryNeon,
      secondary: AppColors.secondaryNeon,
      surface: AppColors.surfaceNeon,
      error: AppColors.dangerNeon,
      onPrimary: Color(0xFF0A0A1A),
      onSecondary: Color(0xFF0A0A1A),
      onSurface: AppColors.textPrimaryNeon,
      onError: Colors.white,
    ),
    textTheme: _buildNeonTextTheme(),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundNeon,
      foregroundColor: AppColors.textPrimaryNeon,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundNeon,
      selectedItemColor: AppColors.primaryNeon,
      unselectedItemColor: AppColors.textTertiaryNeon,
      elevation: 0,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryNeon,
      foregroundColor: Color(0xFF0A0A1A),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceNeon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: Color(0x3300D4FF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: Color(0x3300D4FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        borderSide: const BorderSide(color: AppColors.primaryNeon),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm + 4,
      ),
    ),
    dividerColor: AppColors.textTertiaryNeon.withValues(alpha: 0.2),
    cupertinoOverrideTheme: const CupertinoThemeData(
      primaryColor: AppColors.primaryNeon,
      brightness: Brightness.dark,
    ),
  );

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light
        ? AppColors.textPrimaryLight
        : AppColors.textPrimaryDark;
    final secondary = brightness == Brightness.light
        ? AppColors.textSecondaryLight
        : AppColors.textSecondaryDark;

    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: TextStyle(fontSize: AppSizes.heading1, fontWeight: FontWeight.w700, color: color, height: 1.2),
        displayMedium: TextStyle(fontSize: AppSizes.heading2, fontWeight: FontWeight.w700, color: color, height: 1.2),
        displaySmall: TextStyle(fontSize: AppSizes.heading3, fontWeight: FontWeight.w600, color: color, height: 1.3),
        headlineMedium: TextStyle(fontSize: AppSizes.heading4, fontWeight: FontWeight.w600, color: color, height: 1.3),
        titleLarge: TextStyle(fontSize: AppSizes.bodyLarge, fontWeight: FontWeight.w600, color: color, height: 1.4),
        titleMedium: TextStyle(fontSize: AppSizes.body, fontWeight: FontWeight.w600, color: color, height: 1.4),
        bodyLarge: TextStyle(fontSize: AppSizes.bodyLarge, fontWeight: FontWeight.w400, color: color, height: 1.6, letterSpacing: 0.6),
        bodyMedium: TextStyle(fontSize: AppSizes.body, fontWeight: FontWeight.w400, color: color, height: 1.6, letterSpacing: 0.6),
        bodySmall: TextStyle(fontSize: AppSizes.bodySmall, fontWeight: FontWeight.w400, color: secondary, height: 1.5),
        labelLarge: TextStyle(fontSize: AppSizes.body, fontWeight: FontWeight.w600, color: color),
        labelSmall: TextStyle(fontSize: AppSizes.caption, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.5),
      ),
    );
  }

  static TextTheme _buildNeonTextTheme() {
    const color = AppColors.textPrimaryNeon;
    const secondary = AppColors.textSecondaryNeon;

    return GoogleFonts.interTextTheme(
      TextTheme(
        displayLarge: const TextStyle(fontSize: AppSizes.heading1, fontWeight: FontWeight.w700, color: color, height: 1.2),
        displayMedium: const TextStyle(fontSize: AppSizes.heading2, fontWeight: FontWeight.w700, color: color, height: 1.2),
        displaySmall: const TextStyle(fontSize: AppSizes.heading3, fontWeight: FontWeight.w600, color: color, height: 1.3),
        headlineMedium: const TextStyle(fontSize: AppSizes.heading4, fontWeight: FontWeight.w600, color: color, height: 1.3),
        titleLarge: const TextStyle(fontSize: AppSizes.bodyLarge, fontWeight: FontWeight.w600, color: color, height: 1.4),
        titleMedium: const TextStyle(fontSize: AppSizes.body, fontWeight: FontWeight.w600, color: color, height: 1.4),
        bodyLarge: const TextStyle(fontSize: AppSizes.bodyLarge, fontWeight: FontWeight.w400, color: color, height: 1.6, letterSpacing: 0.6),
        bodyMedium: const TextStyle(fontSize: AppSizes.body, fontWeight: FontWeight.w400, color: color, height: 1.6, letterSpacing: 0.6),
        bodySmall: const TextStyle(fontSize: AppSizes.bodySmall, fontWeight: FontWeight.w400, color: secondary, height: 1.5),
        labelLarge: const TextStyle(fontSize: AppSizes.body, fontWeight: FontWeight.w600, color: color),
        labelSmall: const TextStyle(fontSize: AppSizes.caption, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.5),
      ),
    );
  }
}
