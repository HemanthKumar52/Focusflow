import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'neu_container.dart';

class NeuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? tooltip;

  const NeuIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 44.0,
    this.iconColor,
    this.backgroundColor,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = iconColor ??
        (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    Widget button = NeuContainer(
      onTap: onPressed,
      color: backgroundColor,
      width: size,
      height: size,
      borderRadius: size / 2,
      padding: EdgeInsets.zero,
      child: Center(
        child: Icon(icon, size: size * 0.5, color: color),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
