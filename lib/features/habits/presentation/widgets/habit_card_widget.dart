import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../data/habit_model.dart';
import '../../providers/habit_provider.dart';

class HabitCardWidget extends ConsumerWidget {
  final HabitModel habit;
  final int completionsToday;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const HabitCardWidget({
    super.key,
    required this.habit,
    required this.completionsToday,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habitColor = Color(habit.colorValue);
    final streak = ref.watch(habitStreakProvider(habit.id));
    final completionRate = ref.watch(habitCompletionRateProvider(habit.id));
    final isCompleted = completionsToday >= habit.targetPerDay;

    return NeuContainer(
      onTap: onTap,
      onLongPress: onLongPress,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs + 2,
      ),
      child: Row(
        children: [
          // Color accent bar on the left
          Container(
            width: 4,
            height: 80,
            decoration: BoxDecoration(
              color: habitColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppSizes.radiusMd),
              ),
            ),
          ),

          const SizedBox(width: AppSizes.sm + 4),

          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: habitColor.withValues(alpha: isDark ? 0.25 : 0.12),
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Icon(
              IconData(habit.iconCodePoint, fontFamily: CupertinoIcons.iconFont, fontPackage: CupertinoIcons.iconFontPackage),
              size: 20,
              color: habitColor,
            ),
          ),

          const SizedBox(width: AppSizes.sm + 4),

          // Name + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: AppSizes.body,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (habit.description != null &&
                    habit.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    habit.description!,
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSizes.xs),
                // Progress dots + streak
                Row(
                  children: [
                    // Progress dots
                    ...List.generate(habit.targetPerDay.clamp(0, 10), (i) {
                      final filled = i < completionsToday;
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: filled
                                ? habitColor
                                : habitColor.withValues(alpha: isDark ? 0.2 : 0.15),
                            border: filled
                                ? null
                                : Border.all(
                                    color: habitColor.withValues(alpha: 0.4),
                                    width: 1.5,
                                  ),
                          ),
                        ),
                      );
                    }),
                    if (habit.targetPerDay > 10)
                      Text(
                        '$completionsToday/${habit.targetPerDay}',
                        style: TextStyle(
                          fontSize: AppSizes.caption,
                          color: habitColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const Spacer(),
                    // Streak badge
                    if (streak > 0)
                      NeuBadge(
                        label: '$streak day${streak > 1 ? 's' : ''}',
                        color: AppColors.warning,
                        icon: CupertinoIcons.flame_fill,
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSizes.sm),

          // Completion rate mini bar
          SizedBox(
            width: 4,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: RotatedBox(
                quarterTurns: 2,
                child: LinearProgressIndicator(
                  value: completionRate,
                  backgroundColor:
                      habitColor.withValues(alpha: isDark ? 0.15 : 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(habitColor),
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSizes.sm + 4),
        ],
      ),
    );
  }
}
