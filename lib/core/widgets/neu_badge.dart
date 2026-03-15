import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../theme/neumorphic_theme.dart';

class NeuBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? textColor;
  final double fontSize;
  final IconData? icon;

  const NeuBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
    this.fontSize = AppSizes.caption,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm + 2,
        vertical: AppSizes.xs,
      ),
      decoration: NeumorphicDecoration.raised(
        isDark: isDark,
        isNeon: isNeon,
        borderRadius: AppSizes.radiusFull,
        color: color.withValues(alpha: isDark ? 0.3 : 0.15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
