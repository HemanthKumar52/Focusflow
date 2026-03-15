import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../theme/neumorphic_theme.dart';

class NeuTabBar extends StatelessWidget {
  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const NeuTabBar({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);

    return Container(
      height: 44,
      decoration: NeumorphicDecoration.inset(
        isDark: isDark,
        isNeon: isNeon,
        borderRadius: AppSizes.radiusMd,
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: isSelected
                    ? NeumorphicDecoration.raised(
                        isDark: isDark,
                        isNeon: isNeon,
                        borderRadius: AppSizes.radiusSm,
                      )
                    : null,
                alignment: Alignment.center,
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: AppSizes.bodySmall,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? (isNeon ? AppColors.primaryNeon : AppColors.primary)
                        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
