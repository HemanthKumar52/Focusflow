import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../settings/providers/user_provider.dart';
import '../../../todo/providers/todo_provider.dart';
import '../../../todo/presentation/widgets/todo_item_widget.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final greeting = ref.watch(greetingProvider);
    final allTodos = ref.watch(todoProvider);
    final overdueTodos = ref.watch(overdueProvider);
    final completedTodos = ref.watch(completedTodosProvider);

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final weekEnd = todayStart.add(const Duration(days: 7));

    // Due today only (not overdue)
    final dueTodayOnly = allTodos.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      return t.dueDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
          t.dueDate!.isBefore(todayEnd);
    }).toList();

    // Completed today
    final completedToday = completedTodos.where((t) {
      return t.completedAt != null &&
          t.completedAt!.isAfter(todayStart) &&
          t.completedAt!.isBefore(todayEnd);
    }).toList();

    // Upcoming (due this week but not today, not overdue)
    final upcoming = allTodos.where((t) {
      if (t.isCompleted || t.dueDate == null) return false;
      return t.dueDate!.isAfter(todayEnd.subtract(const Duration(seconds: 1))) &&
          t.dueDate!.isBefore(weekEnd);
    }).toList();

    final allDone =
        overdueTodos.isEmpty && dueTodayOnly.isEmpty && upcoming.isEmpty;

    final bgColor = isNeon ? AppColors.backgroundNeon : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);
    final textPrimary = isNeon ? AppColors.textPrimaryNeon : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final textSecondary = isNeon ? AppColors.textSecondaryNeon : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // -- Header --
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: AppSizes.heading1,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      DateFormat('EEEE, MMMM d').format(now),
                      style: TextStyle(
                        fontSize: AppSizes.bodyLarge,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -- Quick Add --
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg, vertical: AppSizes.sm),
                child: _QuickAddField(ref: ref),
              ),
            ),

            // -- Stats Row --
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg, vertical: AppSizes.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Overdue',
                        count: overdueTodos.length,
                        color: AppColors.danger,
                        icon: CupertinoIcons.exclamationmark_triangle_fill,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _StatCard(
                        label: 'Due Today',
                        count: dueTodayOnly.length,
                        color: AppColors.primary,
                        icon: CupertinoIcons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _StatCard(
                        label: 'Done',
                        count: completedToday.length,
                        color: AppColors.success,
                        icon: CupertinoIcons.checkmark_seal_fill,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // -- Empty state --
            if (allDone)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.xxl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          size: 64,
                          color: AppColors.success.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'All caught up!',
                          style: TextStyle(
                            fontSize: AppSizes.heading3,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'You have no pending tasks. Enjoy your day\nor add something new above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // -- Overdue Section --
            if (overdueTodos.isNotEmpty) ...[
              _SectionHeader(
                title: 'Overdue',
                count: overdueTodos.length,
                color: AppColors.danger,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                sliver: SliverList.builder(
                  itemCount: overdueTodos.length,
                  itemBuilder: (context, index) {
                    final todo = overdueTodos[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSizes.sm),
                      child: TodoItemWidget(
                        todo: todo,
                        tintColor: AppColors.danger.withValues(alpha: 0.08),
                        onToggle: () => ref
                            .read(todoProvider.notifier)
                            .toggleComplete(todo.id),
                        onTap: () => context.push('/todos/${todo.id}'),
                        onDismissed: () => ref
                            .read(todoProvider.notifier)
                            .toggleComplete(todo.id),
                      ),
                    );
                  },
                ),
              ),
            ],

            // -- Due Today Section --
            if (dueTodayOnly.isNotEmpty) ...[
              _SectionHeader(
                title: 'Due Today',
                count: dueTodayOnly.length,
                color: AppColors.primary,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                sliver: SliverList.builder(
                  itemCount: dueTodayOnly.length,
                  itemBuilder: (context, index) {
                    final todo = dueTodayOnly[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSizes.sm),
                      child: TodoItemWidget(
                        todo: todo,
                        onToggle: () => ref
                            .read(todoProvider.notifier)
                            .toggleComplete(todo.id),
                        onTap: () => context.push('/todos/${todo.id}'),
                        onDismissed: () => ref
                            .read(todoProvider.notifier)
                            .toggleComplete(todo.id),
                      ),
                    );
                  },
                ),
              ),
            ],

            // -- Upcoming Section --
            if (upcoming.isNotEmpty) ...[
              _SectionHeader(
                title: 'Upcoming',
                count: upcoming.length,
                color: AppColors.info,
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                sliver: SliverList.builder(
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    final todo = upcoming[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSizes.sm),
                      child: TodoItemWidget(
                        todo: todo,
                        onToggle: () => ref
                            .read(todoProvider.notifier)
                            .toggleComplete(todo.id),
                        onTap: () => context.push('/todos/${todo.id}'),
                        onDismissed: () => ref
                            .read(todoProvider.notifier)
                            .toggleComplete(todo.id),
                      ),
                    );
                  },
                ),
              ),
            ],

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSizes.xxl + AppSizes.xl),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-add inline text field
// ---------------------------------------------------------------------------

class _QuickAddField extends StatefulWidget {
  final WidgetRef ref;
  const _QuickAddField({required this.ref});

  @override
  State<_QuickAddField> createState() => _QuickAddFieldState();
}

class _QuickAddFieldState extends State<_QuickAddField> {
  final _controller = TextEditingController();

  void _submit(String value) {
    final text = value.trim();
    if (text.isEmpty) return;
    widget.ref.read(todoProvider.notifier).addTodo(
          text,
          dueDate: DateTime.now(),
        );
    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeuTextField(
      controller: _controller,
      hintText: 'Quick add a todo for today...',
      prefixIcon: CupertinoIcons.plus_circle_fill,
      suffixIcon: CupertinoIcons.arrow_right_circle_fill,
      onSuffixTap: () => _submit(_controller.text),
      onSubmitted: _submit,
      textInputAction: TextInputAction.done,
    );
  }
}

// ---------------------------------------------------------------------------
// Stat card widget
// ---------------------------------------------------------------------------

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.md, horizontal: AppSizes.sm),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppSizes.iconMd),
          const SizedBox(height: AppSizes.xs),
          Text(
            '$count',
            style: TextStyle(
              fontSize: AppSizes.heading3,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.caption,
              color: AppColors.isNeonTheme(context)
                  ? AppColors.textSecondaryNeon
                  : (Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section header sliver
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.sm),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.heading4,
                fontWeight: FontWeight.w700,
                color: isNeon
                    ? AppColors.textPrimaryNeon
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            NeuBadge(label: '$count', color: color),
          ],
        ),
      ),
    );
  }
}
