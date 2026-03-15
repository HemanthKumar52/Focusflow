import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../data/habit_model.dart';
import '../../providers/habit_provider.dart';

class HabitDetailScreen extends ConsumerStatefulWidget {
  final String habitId;

  const HabitDetailScreen({super.key, required this.habitId});

  @override
  ConsumerState<HabitDetailScreen> createState() => _HabitDetailScreenState();
}

class _HabitDetailScreenState extends ConsumerState<HabitDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final habits = ref.watch(habitProvider);
    final habit = habits.where((h) => h.id == widget.habitId).firstOrNull;

    if (habit == null) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: const Center(child: Text('Habit not found')),
      );
    }

    final habitColor = Color(habit.colorValue);
    final streak = ref.watch(habitStreakProvider(habit.id));
    final bestStreak = ref.watch(bestStreakProvider(habit.id));
    final completionRate = ref.watch(habitCompletionRateProvider(habit.id));
    final weeklyData = ref.watch(weeklyHabitDataProvider(habit.id));
    final allEntries = ref.watch(habitEntriesProvider);
    final todayStatus = ref.watch(todayHabitStatusProvider);

    final habitEntries = allEntries
        .where((e) => e.habitId == habit.id)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final completionsToday = todayStatus[habit.id] ?? 0;

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
                  NeuIconButton(
                    icon: CupertinoIcons.back,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Spacer(),
                  NeuIconButton(
                    icon: CupertinoIcons.pencil,
                    onPressed: () => _showEditSheet(context, habit),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  NeuIconButton(
                    icon: CupertinoIcons.delete,
                    iconColor: AppColors.danger,
                    onPressed: () => _confirmDelete(context, habit),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 100),
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.sm,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: habitColor.withValues(
                                alpha: isDark ? 0.25 : 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusMd),
                          ),
                          child: Icon(
                            IconData(habit.iconCodePoint,
                                fontFamily: CupertinoIcons.iconFont,
                                fontPackage:
                                    CupertinoIcons.iconFontPackage),
                            size: 28,
                            color: habitColor,
                          ),
                        ),
                        const SizedBox(width: AppSizes.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name,
                                style: TextStyle(
                                  fontSize: AppSizes.heading3,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              if (habit.description != null &&
                                  habit.description!.isNotEmpty) ...[
                                const SizedBox(height: AppSizes.xs),
                                Text(
                                  habit.description!,
                                  style: TextStyle(
                                    fontSize: AppSizes.body,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSizes.xs),
                              NeuBadge(
                                label: HabitFrequency
                                    .values[habit.frequency.clamp(
                                        0,
                                        HabitFrequency.values.length - 1)]
                                    .label,
                                color: habitColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.md),

                  // Stats Row
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            label: 'Current Streak',
                            value: '$streak',
                            unit: 'days',
                            icon: CupertinoIcons.flame_fill,
                            color: AppColors.warning,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: _StatCard(
                            label: 'Best Streak',
                            value: '$bestStreak',
                            unit: 'days',
                            icon: CupertinoIcons.rosette,
                            color: AppColors.secondary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: _StatCard(
                            label: 'Rate (30d)',
                            value: '${(completionRate * 100).round()}',
                            unit: '%',
                            icon: CupertinoIcons.chart_bar_fill,
                            color: AppColors.primary,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Today's Progress
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    child: NeuContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today',
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
                              // Progress dots
                              ...List.generate(
                                  habit.targetPerDay.clamp(0, 10), (i) {
                                final filled = i < completionsToday;
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(right: 6),
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: filled
                                          ? habitColor
                                          : habitColor.withValues(
                                              alpha:
                                                  isDark ? 0.2 : 0.15),
                                      border: filled
                                          ? null
                                          : Border.all(
                                              color: habitColor
                                                  .withValues(alpha: 0.4),
                                              width: 2,
                                            ),
                                    ),
                                  ),
                                );
                              }),
                              if (habit.targetPerDay > 10)
                                Text(
                                  '$completionsToday / ${habit.targetPerDay}',
                                  style: TextStyle(
                                    fontSize: AppSizes.body,
                                    fontWeight: FontWeight.w600,
                                    color: habitColor,
                                  ),
                                ),
                              const Spacer(),
                              NeuButton(
                                label: completionsToday >=
                                        habit.targetPerDay
                                    ? 'Done!'
                                    : 'Log',
                                icon: completionsToday >=
                                        habit.targetPerDay
                                    ? CupertinoIcons.checkmark_seal_fill
                                    : CupertinoIcons.plus,
                                variant: completionsToday >=
                                        habit.targetPerDay
                                    ? NeuButtonVariant.secondary
                                    : NeuButtonVariant.primary,
                                size: NeuButtonSize.small,
                                onPressed: () =>
                                    _logWithOptionalNote(context, habit),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Weekly View
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    child: NeuContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Last 7 Days',
                            style: TextStyle(
                              fontSize: AppSizes.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children:
                                List.generate(7, (i) {
                              final date = DateTime.now()
                                  .subtract(Duration(days: 6 - i));
                              final entry = weeklyData[i];
                              final completed = entry != null &&
                                  entry.completionCount >=
                                      habit.targetPerDay;
                              final partial = entry != null &&
                                  entry.completionCount > 0 &&
                                  !completed;

                              return Column(
                                children: [
                                  Text(
                                    DateFormat.E().format(date).substring(0, 2),
                                    style: TextStyle(
                                      fontSize: AppSizes.caption,
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                    ),
                                  ),
                                  const SizedBox(height: AppSizes.xs),
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: completed
                                          ? habitColor
                                          : partial
                                              ? habitColor.withValues(
                                                  alpha: 0.4)
                                              : (isDark
                                                  ? AppColors.surfaceDark
                                                  : AppColors.surfaceLight),
                                      border: !completed && !partial
                                          ? Border.all(
                                              color: habitColor.withValues(
                                                  alpha: 0.2),
                                              width: 1.5,
                                            )
                                          : null,
                                    ),
                                    child: completed
                                        ? const Icon(
                                            CupertinoIcons.checkmark,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : partial
                                            ? Center(
                                                child: Text(
                                                  '${entry.completionCount}',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                            : null,
                                  ),
                                  const SizedBox(height: AppSizes.xs),
                                  Text(
                                    '${date.day}',
                                    style: TextStyle(
                                      fontSize: AppSizes.caption,
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiaryLight,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // Monthly Heatmap (30 days)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    child: NeuContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Activity',
                            style: TextStyle(
                              fontSize: AppSizes.bodySmall,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: AppSizes.md),
                          _buildHeatmap(
                            habit,
                            habitEntries,
                            habitColor,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSizes.lg),

                  // History List
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSizes.md + 4,
                      bottom: AppSizes.sm,
                    ),
                    child: Text(
                      'Recent History',
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
                  if (habitEntries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSizes.lg),
                      child: Center(
                        child: Text(
                          'No entries yet. Tap "Log" to start tracking!',
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      ),
                    ),
                  ...habitEntries.take(20).map((entry) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.xs,
                        ),
                        child: NeuContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.sm + 2,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: entry.completionCount >=
                                          habit.targetPerDay
                                      ? AppColors.success
                                      : habitColor,
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm + 4),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat.yMMMd()
                                          .format(entry.date),
                                      style: TextStyle(
                                        fontSize: AppSizes.body,
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors
                                                .textPrimaryLight,
                                      ),
                                    ),
                                    if (entry.note != null &&
                                        entry.note!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        entry.note!,
                                        style: TextStyle(
                                          fontSize: AppSizes.bodySmall,
                                          color: isDark
                                              ? AppColors
                                                  .textSecondaryDark
                                              : AppColors
                                                  .textSecondaryLight,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Text(
                                '${entry.completionCount}/${habit.targetPerDay}',
                                style: TextStyle(
                                  fontSize: AppSizes.bodySmall,
                                  fontWeight: FontWeight.w600,
                                  color: entry.completionCount >=
                                          habit.targetPerDay
                                      ? AppColors.success
                                      : habitColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap(
    HabitModel habit,
    List<HabitEntry> entries,
    Color habitColor,
    bool isDark,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Build a map for quick lookups
    final entryMap = <String, int>{};
    for (final entry in entries) {
      final key =
          '${entry.date.year}-${entry.date.month}-${entry.date.day}';
      entryMap[key] = entry.completionCount;
    }

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(30, (i) {
        final date = today.subtract(Duration(days: 29 - i));
        final key = '${date.year}-${date.month}-${date.day}';
        final count = entryMap[key] ?? 0;
        final intensity = habit.targetPerDay > 0
            ? (count / habit.targetPerDay).clamp(0.0, 1.0)
            : 0.0;

        return Tooltip(
          message:
              '${DateFormat.MMMd().format(date)}: $count/${habit.targetPerDay}',
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: count > 0
                  ? habitColor.withValues(alpha: 0.2 + (intensity * 0.8))
                  : (isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight),
            ),
          ),
        );
      }),
    );
  }

  void _logWithOptionalNote(BuildContext context, HabitModel habit) {
    final noteController = TextEditingController();

    NeuBottomSheet.show(
      context: context,
      title: 'Log Entry',
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuTextField(
              controller: noteController,
              hintText: 'How did it go? (optional)',
              labelText: 'Note',
              prefixIcon: CupertinoIcons.text_badge_checkmark,
            ),
            const SizedBox(height: AppSizes.lg),
            NeuButton(
              label: 'Log Completion',
              icon: CupertinoIcons.checkmark,
              isFullWidth: true,
              onPressed: () {
                final note = noteController.text.trim();
                ref.read(habitEntriesProvider.notifier).logEntry(
                      habit.id,
                      DateTime.now(),
                      note: note.isNotEmpty ? note : null,
                    );
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, HabitModel habit) {
    final nameController = TextEditingController(text: habit.name);
    final descController =
        TextEditingController(text: habit.description ?? '');
    int selectedColorValue = habit.colorValue;
    int selectedFrequency = habit.frequency;
    int targetPerDay = habit.targetPerDay;

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

    NeuBottomSheet.show(
      context: context,
      title: 'Edit Habit',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeuTextField(
                  controller: nameController,
                  hintText: 'Habit name',
                  labelText: 'Name',
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
                  children:
                      HabitFrequency.values.asMap().entries.map((e) {
                    final isSelected = e.key == selectedFrequency;
                    return GestureDetector(
                      onTap: () => setSheetState(
                          () => selectedFrequency = e.key),
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
                              ? Border.all(
                                  color: AppColors.primary, width: 1.5)
                              : null,
                        ),
                        child: Text(
                          e.value.label,
                          style: TextStyle(
                            fontSize: AppSizes.bodySmall,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
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
                          ? () => setSheetState(() => targetPerDay--)
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

                NeuButton(
                  label: 'Save Changes',
                  icon: CupertinoIcons.checkmark,
                  isFullWidth: true,
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final updated = habit.copyWith(
                      name: name,
                      description: descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : null,
                      colorValue: selectedColorValue,
                      frequency: selectedFrequency,
                      targetPerDay: targetPerDay,
                    );
                    ref.read(habitProvider.notifier).updateHabit(updated);
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

  void _confirmDelete(BuildContext context, HabitModel habit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        title: Text(
          'Delete Habit?',
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        content: Text(
          'This will permanently delete "${habit.name}" and all its history.',
          style: TextStyle(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(habitProvider.notifier).deleteHabit(habit.id);
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.all(AppSizes.sm + 4),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: AppSizes.xs),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: AppSizes.heading3,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: AppSizes.caption,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.caption,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
