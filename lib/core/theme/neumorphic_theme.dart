import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class NeumorphicDecoration {
  static BoxDecoration raised({
    required bool isDark,
    bool isNeon = false,
    double borderRadius = AppSizes.radiusMd,
    Color? color,
  }) {
    final bg = color ?? (isNeon ? AppColors.surfaceNeon : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight));
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: isNeon ? AppColors.shadowNeonTop : (isDark ? AppColors.shadowDarkTop : AppColors.shadowLightTop),
          offset: const Offset(-AppSizes.shadowOffset, -AppSizes.shadowOffset),
          blurRadius: AppSizes.shadowBlur,
        ),
        BoxShadow(
          color: isNeon ? AppColors.shadowNeonBottom : (isDark ? AppColors.shadowDarkBottom : AppColors.shadowLightBottom),
          offset: const Offset(AppSizes.shadowOffset, AppSizes.shadowOffset),
          blurRadius: AppSizes.shadowBlur,
        ),
      ],
    );
  }

  static BoxDecoration pressed({
    required bool isDark,
    bool isNeon = false,
    double borderRadius = AppSizes.radiusMd,
    Color? color,
  }) {
    final bg = color ?? (isNeon ? AppColors.surfaceNeon : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight));
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: isNeon ? AppColors.shadowNeonBottom : (isDark ? AppColors.shadowDarkBottom : AppColors.shadowLightBottom),
          offset: const Offset(AppSizes.shadowOffsetPressed, AppSizes.shadowOffsetPressed),
          blurRadius: AppSizes.shadowBlurPressed,
        ),
        BoxShadow(
          color: isNeon ? AppColors.shadowNeonTop : (isDark ? AppColors.shadowDarkTop : AppColors.shadowLightTop),
          offset: const Offset(-AppSizes.shadowOffsetPressed, -AppSizes.shadowOffsetPressed),
          blurRadius: AppSizes.shadowBlurPressed,
        ),
      ],
    );
  }

  static BoxDecoration flat({
    required bool isDark,
    bool isNeon = false,
    double borderRadius = AppSizes.radiusMd,
    Color? color,
  }) {
    final bg = color ?? (isNeon ? AppColors.surfaceNeon : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight));
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  static BoxDecoration inset({
    required bool isDark,
    bool isNeon = false,
    double borderRadius = AppSizes.radiusMd,
    Color? color,
  }) {
    final bg = color ?? (isNeon ? AppColors.backgroundNeon : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight));
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: isNeon ? AppColors.shadowNeonBottom : (isDark ? AppColors.shadowDarkBottom : AppColors.shadowLightBottom),
          offset: const Offset(AppSizes.shadowOffsetPressed, AppSizes.shadowOffsetPressed),
          blurRadius: AppSizes.shadowBlurPressed,
          spreadRadius: -1,
        ),
        BoxShadow(
          color: isNeon ? AppColors.shadowNeonTop : (isDark ? AppColors.shadowDarkTop : AppColors.shadowLightTop),
          offset: const Offset(-AppSizes.shadowOffsetPressed, -AppSizes.shadowOffsetPressed),
          blurRadius: AppSizes.shadowBlurPressed,
          spreadRadius: -1,
        ),
      ],
    );
  }
}
