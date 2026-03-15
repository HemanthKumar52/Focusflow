import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../../../core/widgets/neu_tab_bar.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../../core/widgets/emoji_picker_widget.dart';
import '../../data/todo_model.dart';
import '../../providers/todo_provider.dart';
import '../widgets/todo_item_widget.dart';

class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  int _tabIndex = 0;
  String _searchQuery = '';
  TaskPriority? _priorityFilter;
  String? _tagFilter;
  bool _showFilters = false;

  static const _tabLabels = ['All', 'Today', 'Upcoming', 'Completed'];

  List<TodoModel> _filterTodos(List<TodoModel> todos) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Tab filter
    List<TodoModel> filtered;
    switch (_tabIndex) {
      case 1: // Today
        filtered = todos.where((t) {
          if (t.isCompleted || t.dueDate == null) return false;
          return t.dueDate!.isBefore(todayEnd);
        }).toList();
        break;
      case 2: // Upcoming
        filtered = todos.where((t) {
          if (t.isCompleted || t.dueDate == null) return false;
          return t.dueDate!.isAfter(todayEnd.subtract(const Duration(seconds: 1)));
        }).toList();
        break;
      case 3: // Completed
        filtered = todos.where((t) => t.isCompleted).toList();
        break;
      default: // All active
        filtered = todos.where((t) => !t.isCompleted).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((t) =>
              t.title.toLowerCase().contains(query) ||
              (t.notes?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    // Priority filter
    if (_priorityFilter != null) {
      filtered = filtered
          .where((t) => t.priority == _priorityFilter)
          .toList();
    }

    // Tag filter
    if (_tagFilter != null) {
      filtered = filtered.where((t) => t.tags.contains(_tagFilter)).toList();
    }

    return filtered;
  }

  Set<String> _allTags(List<TodoModel> todos) {
    final tags = <String>{};
    for (final t in todos) {
      tags.addAll(t.tags);
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final allTodos = ref.watch(todoProvider);
    final filtered = _filterTodos(allTodos);
    final allTags = _allTags(allTodos);
    final bgColor = isNeon ? AppColors.backgroundNeon : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);
    final textPrimary = isNeon ? AppColors.textPrimaryNeon : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final textSecondary = isNeon ? AppColors.textSecondaryNeon : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // -- App Bar --
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Todos',
                      style: TextStyle(
                        fontSize: AppSizes.heading2,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  NeuIconButton(
                    icon: CupertinoIcons.line_horizontal_3_decrease,
                    tooltip: 'Filter',
                    onPressed: () =>
                        setState(() => _showFilters = !_showFilters),
                    iconColor: _showFilters ? AppColors.primary : null,
                  ),
                  const SizedBox(width: AppSizes.sm),
                  NeuIconButton(
                    icon: CupertinoIcons.plus,
                    tooltip: 'Add Todo',
                    iconColor: AppColors.primary,
                    onPressed: () => _showQuickAdd(context),
                  ),
                ],
              ),
            ),

            // -- Tab Bar --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: NeuTabBar(
                tabs: _tabLabels,
                selectedIndex: _tabIndex,
                onTabChanged: (i) => setState(() => _tabIndex = i),
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // -- Search --
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: NeuTextField(
                hintText: 'Search todos...',
                prefixIcon: CupertinoIcons.search,
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),

            // -- Filter chips --
            if (_showFilters) ...[
              const SizedBox(height: AppSizes.sm),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                  children: [
                    // Priority chips
                    ...TaskPriority.values.map((p) => Padding(
                          padding:
                              const EdgeInsets.only(right: AppSizes.xs),
                          child: GestureDetector(
                            onTap: () => setState(() =>
                                _priorityFilter =
                                    _priorityFilter == p ? null : p),
                            child: NeuBadge(
                              label: p.label,
                              color: _priorityFilter == p
                                  ? p.color
                                  : (isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight),
                              icon: CupertinoIcons.circle_fill,
                            ),
                          ),
                        )),
                    if (allTags.isNotEmpty)
                      Container(
                        width: 1,
                        height: 24,
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm, vertical: 8),
                        color: textSecondary.withValues(alpha: 0.3),
                      ),
                    // Tag chips
                    ...allTags.map((tag) => Padding(
                          padding:
                              const EdgeInsets.only(right: AppSizes.xs),
                          child: GestureDetector(
                            onTap: () => setState(() =>
                                _tagFilter =
                                    _tagFilter == tag ? null : tag),
                            child: NeuBadge(
                              label: tag,
                              color: _tagFilter == tag
                                  ? AppColors.secondary
                                  : (isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSizes.sm),

            // -- Todo List --
            Expanded(
              child: filtered.isEmpty
                  ? _EmptyState(tabIndex: _tabIndex)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final todo = filtered[index];
                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSizes.sm),
                          child: TodoItemWidget(
                            todo: todo,
                            onToggle: () => ref
                                .read(todoProvider.notifier)
                                .toggleComplete(todo.id),
                            onTap: () =>
                                context.push('/todos/${todo.id}'),
                            onDismissed: () => ref
                                .read(todoProvider.notifier)
                                .toggleComplete(todo.id),
                            onDelete: () => ref
                                .read(todoProvider.notifier)
                                .deleteTodo(todo.id),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _insertEmoji(TextEditingController controller, String emoji) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
  }

  void _showQuickAdd(BuildContext context) {
    final controller = TextEditingController();
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('New Todo'),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSizes.sm),
          child: Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: 'What do you need to do?',
                  autofocus: true,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      ref.read(todoProvider.notifier).addTodo(value.trim());
                      Navigator.of(ctx).pop();
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  EmojiPicker.show(ctx, onSelected: (emoji) {
                    _insertEmoji(controller, emoji);
                  });
                },
                child: const Icon(
                  Icons.emoji_emotions_outlined,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(todoProvider.notifier)
                    .addTodo(controller.text.trim());
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state per tab
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final int tabIndex;
  const _EmptyState({required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final textPrimary = isNeon ? AppColors.textPrimaryNeon : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final textSecondary = isNeon ? AppColors.textSecondaryNeon : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    final (IconData icon, String title, String subtitle) = switch (tabIndex) {
      1 => (
          CupertinoIcons.calendar_today,
          'Nothing due today',
          'All clear for today. Add a task or enjoy the calm.',
        ),
      2 => (
          CupertinoIcons.calendar,
          'No upcoming todos',
          'Plan ahead by adding todos with future due dates.',
        ),
      3 => (
          CupertinoIcons.checkmark_seal,
          'No completed todos yet',
          'Complete a todo by swiping right or tapping the checkbox.',
        ),
      _ => (
          CupertinoIcons.tray,
          'No todos yet',
          'Tap + to add your first todo and start getting things done.',
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              style: TextStyle(
                fontSize: AppSizes.heading4,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.body,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
