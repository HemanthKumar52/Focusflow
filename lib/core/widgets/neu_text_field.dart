import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../theme/neumorphic_theme.dart';

class NeuTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final int maxLines;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final bool autofocus;

  const NeuTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.onSubmitted,
    this.obscureText = false,
    this.maxLines = 1,
    this.textInputAction,
    this.keyboardType,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final textColor = isNeon ? AppColors.textPrimaryNeon : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final hintColor = isNeon ? AppColors.textTertiaryNeon : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: TextStyle(
              fontSize: AppSizes.bodySmall,
              fontWeight: FontWeight.w600,
              color: isNeon ? AppColors.textSecondaryNeon : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
        ],
        Container(
          decoration: NeumorphicDecoration.inset(
            isDark: isDark,
            isNeon: isNeon,
            borderRadius: AppSizes.radiusMd,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            obscureText: obscureText,
            maxLines: maxLines,
            textInputAction: textInputAction,
            keyboardType: keyboardType,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: TextStyle(fontSize: AppSizes.body, color: textColor),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: hintColor),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, size: AppSizes.iconMd, color: hintColor)
                  : null,
              suffixIcon: suffixIcon != null
                  ? GestureDetector(
                      onTap: onSuffixTap,
                      child: Icon(suffixIcon, size: AppSizes.iconMd, color: hintColor),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm + 4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
