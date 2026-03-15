import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_progress_ring.dart';
import '../../data/habit_model.dart';
import '../../providers/habit_provider.dart';
import '../widgets/habit_card_widget.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeHabits = ref.watch(activeHabitsProvider);
    final todayStatus = ref.watch(todayHabitStatusProvider);

    final completedCount = activeHabits.where((h) {
      final done = todayStatus[h.id] ?? 0;
      return done >= h.targetPerDay;
    }).length;
    final totalCount = activeHabits.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    // Split into incomplete and completed today
    final incompleteHabits = activeHabits.where((h) {
      final done = todayStatus[h.id] ?? 0;
      return done < h.targetPerDay;
    }).toList();
    final completedHabits = activeHabits.where((h) {
      final done = todayStatus[h.id] ?? 0;
      return done >= h.targetPerDay;
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  Text(
                    'Habits',
                    style: TextStyle(
                      fontSize: AppSizes.heading2,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const Spacer(),
                  NeuIconButton(
                    icon: CupertinoIcons.add,
                    onPressed: () => _showAddHabitSheet(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Today's Progress Summary
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    child: NeuContainer(
                      child: Row(
                        children: [
                          NeuProgressRing(
                            progress: progress,
                            size: 72,
                            strokeWidth: 7,
                            progressColor: AppColors.success,
                            center: Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                fontSize: AppSizes.bodySmall,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today\'s Progress',
                                  style: TextStyle(
                                    fontSize: AppSizes.bodySmall,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.xs),
                                Text(
                                  '$completedCount of $totalCount habits completed',
                                  style: TextStyle(
                                    fontSize: AppSizes.heading4,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Active Habits
                  if (incompleteHabits.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSizes.md + 4,
                        top: AppSizes.md,
                        bottom: AppSizes.sm,
                      ),
                      child: Text(
                        'In Progress',
                        style: TextStyle(
                          fontSize: AppSizes.bodySmall,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...incompleteHabits.map((habit) => HabitCardWidget(
                          habit: habit,
                          completionsToday: todayStatus[habit.id] ?? 0,
                          onTap: () => _incrementHabit(habit),
                          onLongPress: () => context.go('/habits/${habit.id}'),
                        )),
                  ],

                  // Completed Today section
                  if (completedHabits.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                        left: AppSizes.md + 4,
                        top: AppSizes.lg,
                        bottom: AppSizes.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Text(
                            'Completed Today',
                            style: TextStyle(
                              fontSize: AppSizes.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...completedHabits.map((habit) => HabitCardWidget(
                          habit: habit,
                          completionsToday: todayStatus[habit.id] ?? 0,
                          onTap: () => context.go('/habits/${habit.id}'),
                          onLongPress: () => context.go('/habits/${habit.id}'),
                        )),
                  ],

                  // Empty State
                  if (activeHabits.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.xxl),
                      child: Column(
                        children: [
                          Icon(
                            CupertinoIcons.repeat,
                            size: 64,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                          const SizedBox(height: AppSizes.md),
                          Text(
                            'No habits yet',
                            style: TextStyle(
                              fontSize: AppSizes.heading4,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Text(
                            'Start building good habits by tapping the + button',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: AppSizes.body,
                              color: isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight,
                            ),
                          ),
                          const SizedBox(height: AppSizes.lg),
                          NeuButton(
                            label: 'Add First Habit',
                            icon: CupertinoIcons.add,
                            onPressed: () => _showAddHabitSheet(context),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: activeHabits.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showAddHabitSheet(context),
              backgroundColor: AppColors.primary,
              child: const Icon(CupertinoIcons.add, color: Colors.white),
            )
          : null,
    );
  }

  void _incrementHabit(HabitModel habit) {
    HapticFeedback.mediumImpact();
    ref.read(habitEntriesProvider.notifier).logEntry(
          habit.id,
          DateTime.now(),
        );
  }

  void _showAddHabitSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    int selectedColorValue = AppColors.primary.toARGB32();
    int selectedIconCodePoint = CupertinoIcons.star_fill.codePoint;
    int selectedFrequency = 0;
    int targetPerDay = 1;

    final habitColors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.danger,
      AppColors.info,
      const Color(0xFFFF6B9D),
      const Color(0xFF845EC2),
    ];

    final habitIcons = [
      CupertinoIcons.star_fill,
      CupertinoIcons.heart_fill,
      CupertinoIcons.book_fill,
      CupertinoIcons.sportscourt_fill,
      CupertinoIcons.drop_fill,
      CupertinoIcons.moon_fill,
      CupertinoIcons.music_note_2,
      CupertinoIcons.pencil,
      CupertinoIcons.person_2_fill,
      CupertinoIcons.leaf_arrow_circlepath,
      CupertinoIcons.flame_fill,
      CupertinoIcons.bell_fill,
    ];

    NeuBottomSheet.show(
      context: context,
      title: 'New Habit',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: AppSizes.md,
              right: AppSizes.md,
              top: AppSizes.md,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeuTextField(
                  controller: nameController,
                  hintText: 'e.g., Read 30 minutes',
                  labelText: 'Habit Name',
                  prefixIcon: CupertinoIcons.pencil_outline,
                ),
                const SizedBox(height: AppSizes.md),
                NeuTextField(
                  controller: descController,
                  hintText: 'Optional description',
                  labelText: 'Description',
                  prefixIcon: CupertinoIcons.text_alignleft,
                ),
                const SizedBox(height: AppSizes.lg),

                // Color picker
                Text(
                  'Color',
                  style: TextStyle(
                    fontSize: AppSizes.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: habitColors.map((color) {
                    final isSelected = color.toARGB32() == selectedColorValue;
                    return GestureDetector(
                      onTap: () => setSheetState(
                          () => selectedColorValue = color.toARGB32()),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(CupertinoIcons.checkmark,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.lg),

                // Icon picker
                Text(
                  'Icon',
                  style: TextStyle(
                    fontSize: AppSizes.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: habitIcons.map((icon) {
                    final isSelected = icon.codePoint == selectedIconCodePoint;
                    return GestureDetector(
                      onTap: () => setSheetState(
                          () => selectedIconCodePoint = icon.codePoint),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Color(selectedColorValue)
                                  .withValues(alpha: 0.2)
                              : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                          border: isSelected
                              ? Border.all(
                                  color: Color(selectedColorValue), width: 2)
                              : null,
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: isSelected
                              ? Color(selectedColorValue)
                              : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.lg),

                // Frequency
                Text(
                  'Frequency',
                  style: TextStyle(
                    fontSize: AppSizes.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: HabitFrequency.values.asMap().entries.map((e) {
                    final isSelected = e.key == selectedFrequency;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedFrequency = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm + 4,
                          vertical: AppSizes.xs + 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight),
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusFull),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          e.value.label,
                          style: TextStyle(
                            fontSize: AppSizes.bodySmall,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: AppSizes.lg),

                // Target per day
                Text(
                  'Target per day',
                  style: TextStyle(
                    fontSize: AppSizes.bodySmall,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    NeuIconButton(
                      icon: CupertinoIcons.minus,
                      size: 36,
                      onPressed: targetPerDay > 1
                          ? () =>
                              setSheetState(() => targetPerDay--)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg),
                      child: Text(
                        '$targetPerDay',
                        style: TextStyle(
                          fontSize: AppSizes.heading3,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    NeuIconButton(
                      icon: CupertinoIcons.plus,
                      size: 36,
                      onPressed: () =>
                          setSheetState(() => targetPerDay++),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xl),

                // Add button
                NeuButton(
                  label: 'Create Habit',
                  icon: CupertinoIcons.checkmark,
                  isFullWidth: true,
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    ref.read(habitProvider.notifier).addHabit(
                          name,
                          description: descController.text.trim().isNotEmpty
                              ? descController.text.trim()
                              : null,
                          colorValue: selectedColorValue,
                          iconCodePoint: selectedIconCodePoint,
                          frequency: selectedFrequency,
                          targetPerDay: targetPerDay,
                        );
                    Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          );
        },
      ),
    );
  }
}
