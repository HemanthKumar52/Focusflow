import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import 'neu_container.dart';

enum NeuButtonVariant { primary, secondary, outline, ghost }
enum NeuButtonSize { small, medium, large }

class NeuButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final NeuButtonVariant variant;
  final NeuButtonSize size;
  final bool isLoading;
  final bool isFullWidth;

  const NeuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = NeuButtonVariant.primary,
    this.size = NeuButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (double vertPad, double horzPad, double fontSize) = switch (size) {
      NeuButtonSize.small => (6.0, 12.0, AppSizes.bodySmall),
      NeuButtonSize.medium => (10.0, 20.0, AppSizes.body),
      NeuButtonSize.large => (14.0, 28.0, AppSizes.bodyLarge),
    };

    final (Color bgColor, Color textColor) = switch (variant) {
      NeuButtonVariant.primary => (AppColors.primary, Colors.white),
      NeuButtonVariant.secondary => (AppColors.secondary, Colors.white),
      NeuButtonVariant.outline => (
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      NeuButtonVariant.ghost => (Colors.transparent, AppColors.primary),
    };

    Widget content = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: SizedBox(
              width: fontSize,
              height: fontSize,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: textColor,
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: Icon(icon, size: fontSize + 2, color: textColor),
          ),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );

    if (variant == NeuButtonVariant.ghost) {
      return GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: vertPad, horizontal: horzPad),
          child: content,
        ),
      );
    }

    return NeuContainer(
      onTap: isLoading ? null : onPressed,
      color: bgColor,
      borderRadius: AppSizes.radiusMd,
      padding: EdgeInsets.symmetric(vertical: vertPad, horizontal: horzPad),
      child: content,
    );
  }
}
