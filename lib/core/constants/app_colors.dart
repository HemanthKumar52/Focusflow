import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Light Theme
  static const Color backgroundLight = Color(0xFFE8E8F0);
  static const Color surfaceLight = Color(0xFFF0EFFE);
  static const Color shadowLightTop = Color(0xCCFFFFFF); // rgba(255,255,255,0.8)
  static const Color shadowLightBottom = Color(0x26000000); // rgba(0,0,0,0.15)

  // Dark Theme
  static const Color backgroundDark = Color(0xFF121220);
  static const Color surfaceDark = Color(0xFF1C1C30);
  static const Color shadowDarkTop = Color(0x33FFFFFF); // rgba(255,255,255,0.2)
  static const Color shadowDarkBottom = Color(0x4D000000); // rgba(0,0,0,0.3)

  // Accent Colors
  static const Color primary = Color(0xFF5B3FE8); // deep purple
  static const Color primaryLight = Color(0xFF7B63FF);
  static const Color secondary = Color(0xFF00C2A8); // teal
  static const Color secondaryLight = Color(0xFF33D4BE);

  // Semantic Colors
  static const Color warning = Color(0xFFF5A623); // amber
  static const Color danger = Color(0xFFE8523F); // coral red
  static const Color success = Color(0xFF34C759); // Apple green
  static const Color info = Color(0xFF5AC8FA); // blue

  // Priority Colors
  static const Color priorityUrgent = Color(0xFFE8523F);
  static const Color priorityHigh = Color(0xFFF5A623);
  static const Color priorityNormal = Color(0xFF5B3FE8);
  static const Color priorityLow = Color(0xFF8E8E93);

  // Status Colors
  static const Color statusNotStarted = Color(0xFF8E8E93);
  static const Color statusInProgress = Color(0xFF5B3FE8);
  static const Color statusPending = Color(0xFFF5A623);
  static const Color statusCompleted = Color(0xFF34C759);
  static const Color statusArchived = Color(0xFFAEAEB2);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF636366);
  static const Color textTertiaryLight = Color(0xFF8E8E93);
  static const Color textPrimaryDark = Color(0xFFF2F2F7);
  static const Color textSecondaryDark = Color(0xFFAEAEB2);
  static const Color textTertiaryDark = Color(0xFF636366);

  // Neon Theme
  static const Color backgroundNeon = Color(0xFF0A0A1A);
  static const Color surfaceNeon = Color(0xFF0F1525);
  static const Color shadowNeonTop = Color(0x4000D4FF); // ice blue glow
  static const Color shadowNeonBottom = Color(0x66000000);
  static const Color primaryNeon = Color(0xFF00D4FF);
  static const Color secondaryNeon = Color(0xFF00FFA3);
  static const Color textPrimaryNeon = Color(0xFFE0F0FF);
  static const Color textSecondaryNeon = Color(0xFF7EB8D8);
  static const Color textTertiaryNeon = Color(0xFF4A6A80);
  static const Color dangerNeon = Color(0xFFFF3366);

  /// Detect if the current theme is neon by checking the scaffold background color.
  static bool isNeonTheme(BuildContext context) {
    return Theme.of(context).scaffoldBackgroundColor == backgroundNeon;
  }
}
