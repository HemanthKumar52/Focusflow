import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../theme/neumorphic_theme.dart';

class NeuCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final double size;

  const NeuCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.activeColor,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final color = activeColor ?? (isNeon ? AppColors.primaryNeon : AppColors.primary);

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: value
            ? BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(size / 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              )
            : NeumorphicDecoration.inset(
                isDark: isDark,
                isNeon: isNeon,
                borderRadius: size / 3,
              ),
        child: value
            ? Icon(
                Icons.check_rounded,
                size: size * 0.65,
                color: Colors.white,
              )
            : null,
      ),
    );
  }
}
