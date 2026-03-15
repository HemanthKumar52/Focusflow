import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

class NeuBottomSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  final double maxHeightFraction;

  const NeuBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.maxHeightFraction = 0.9,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    double maxHeightFraction = 0.9,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NeuBottomSheet(
        title: title,
        maxHeightFraction: maxHeightFraction,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxHeight = MediaQuery.of(context).size.height * maxHeightFraction;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSizes.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                title!,
                style: TextStyle(
                  fontSize: AppSizes.heading4,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ),
            Divider(
              height: 1,
              color: (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
                  .withValues(alpha: 0.2),
            ),
          ] else
            const SizedBox(height: AppSizes.sm),
          Flexible(child: child),
        ],
      ),
    );
  }
}
