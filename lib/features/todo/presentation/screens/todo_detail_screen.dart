import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../../../core/widgets/neu_checkbox.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../../core/widgets/emoji_picker_widget.dart';
import '../../data/todo_model.dart';
import '../../providers/todo_provider.dart';

class TodoDetailScreen extends ConsumerStatefulWidget {
  final String todoId;
  const TodoDetailScreen({super.key, required this.todoId});

  @override
  ConsumerState<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends ConsumerState<TodoDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _tagController;
  late TextEditingController _subTaskController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
    _tagController = TextEditingController();
    _subTaskController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _tagController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  TodoModel? _findTodo(List<TodoModel> todos) {
    try {
      return todos.firstWhere((t) => t.id == widget.todoId);
    } catch (_) {
      return null;
    }
  }

  void _autoSave(TodoModel todo) {
    ref.read(todoProvider.notifier).updateTodo(todo);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todos = ref.watch(todoProvider);
    final todo = _findTodo(todos);
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    if (todo == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.exclamationmark_triangle,
                    size: 48, color: textSecondary),
                const SizedBox(height: AppSizes.md),
                Text(
                  'Todo not found',
                  style: TextStyle(
                      fontSize: AppSizes.heading4, color: textPrimary),
                ),
                const SizedBox(height: AppSizes.md),
                NeuButton(
                  label: 'Go Back',
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Initialize controllers once
    if (!_initialized) {
      _titleController.text = todo.title;
      _notesController.text = todo.notes ?? '';
      _initialized = true;
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // -- App Bar --
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.sm, AppSizes.sm, AppSizes.lg, 0),
              child: Row(
                children: [
                  NeuIconButton(
                    icon: CupertinoIcons.back,
                    onPressed: () => context.pop(),
                    tooltip: 'Back',
                  ),
                  const Spacer(),
                  NeuIconButton(
                    icon: todo.isCompleted
                        ? CupertinoIcons.checkmark_circle_fill
                        : CupertinoIcons.circle,
                    iconColor: todo.isCompleted
                        ? AppColors.success
                        : textSecondary,
                    tooltip: 'Toggle complete',
                    onPressed: () => ref
                        .read(todoProvider.notifier)
                        .toggleComplete(todo.id),
                  ),
                ],
              ),
            ),

            // -- Content --
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSizes.lg),
                children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: AppSizes.heading2,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Todo title',
                    ),
                    maxLines: null,
                    onChanged: (value) {
                      _autoSave(todo.copyWith(title: value));
                    },
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Priority selector
                  _SectionLabel(label: 'Priority', isDark: isDark),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: TaskPriority.values.map((p) {
                      final isSelected = todo.priority == p;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: p != TaskPriority.low
                                  ? AppSizes.sm
                                  : 0),
                          child: NeuContainer(
                            isPressed: isSelected,
                            onTap: () {
                              _autoSave(
                                  todo.copyWith(priorityIndex: p.index));
                            },
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.sm + 2,
                                horizontal: AppSizes.xs),
                            child: Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? p.color
                                        : p.color.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.xs),
                                Text(
                                  p.label,
                                  style: TextStyle(
                                    fontSize: AppSizes.caption,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? p.color
                                        : textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Due Date
                  _SectionLabel(label: 'Due Date', isDark: isDark),
                  const SizedBox(height: AppSizes.sm),
                  NeuContainer(
                    onTap: () => _pickDate(context, todo),
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.calendar,
                            size: AppSizes.iconMd, color: AppColors.primary),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                          todo.dueDate != null
                              ? DateFormat('MMM d, y  h:mm a')
                                  .format(todo.dueDate!)
                              : 'No due date set',
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            color: todo.dueDate != null
                                ? textPrimary
                                : textSecondary,
                          ),
                        ),
                        ),
                        if (todo.dueDate != null)
                          GestureDetector(
                            onTap: () =>
                                _autoSave(todo.copyWith(dueDate: null)),
                            child: Icon(CupertinoIcons.xmark_circle_fill,
                                size: AppSizes.iconSm,
                                color: textSecondary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Reminder
                  _SectionLabel(label: 'Reminder', isDark: isDark),
                  const SizedBox(height: AppSizes.sm),
                  NeuContainer(
                    onTap: () => _pickReminder(context, todo),
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.bell,
                            size: AppSizes.iconMd, color: AppColors.warning),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          todo.reminderAt != null
                              ? DateFormat('EEEE, MMMM d  h:mm a')
                                  .format(todo.reminderAt!)
                              : 'No reminder set',
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            color: todo.reminderAt != null
                                ? textPrimary
                                : textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (todo.reminderAt != null)
                          GestureDetector(
                            onTap: () => _autoSave(
                                todo.copyWith(reminderAt: null)),
                            child: Icon(CupertinoIcons.xmark_circle_fill,
                                size: AppSizes.iconSm,
                                color: textSecondary),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Repeat rule
                  _SectionLabel(label: 'Repeat', isDark: isDark),
                  const SizedBox(height: AppSizes.sm),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: RepeatRule.values.map((r) {
                        final isSelected = todo.repeatRule == r;
                        return Padding(
                          padding:
                              const EdgeInsets.only(right: AppSizes.sm),
                          child: GestureDetector(
                            onTap: () => _autoSave(
                                todo.copyWith(repeatRuleIndex: r.index)),
                            child: NeuBadge(
                              label: r.label,
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Tags
                  _SectionLabel(label: 'Tags', isDark: isDark),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: [
                      ...todo.tags.map((tag) => GestureDetector(
                            onTap: () {
                              final updated =
                                  List<String>.from(todo.tags)
                                    ..remove(tag);
                              _autoSave(todo.copyWith(tags: updated));
                            },
                            child: NeuBadge(
                              label: tag,
                              color: AppColors.primary,
                              icon: CupertinoIcons.xmark,
                            ),
                          )),
                      // Add tag chip
                      _AddTagChip(
                        controller: _tagController,
                        onAdd: (tag) {
                          if (tag.isNotEmpty &&
                              !todo.tags.contains(tag)) {
                            final updated =
                                List<String>.from(todo.tags)..add(tag);
                            _autoSave(todo.copyWith(tags: updated));
                          }
                          _tagController.clear();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Sub-tasks
                  _SectionLabel(label: 'Sub-tasks', isDark: isDark),
                  const SizedBox(height: AppSizes.sm),
                  ...todo.subTasks.asMap().entries.map((entry) {
                    final i = entry.key;
                    final sub = entry.value;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSizes.sm),
                      child: NeuContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.md,
                            vertical: AppSizes.sm),
                        child: Row(
                          children: [
                            NeuCheckbox(
                              value: sub.isCompleted,
                              size: 20,
                              onChanged: (_) {
                                final updated =
                                    List<SubTask>.from(todo.subTasks);
                                updated[i] = SubTask(
                                  id: sub.id,
                                  title: sub.title,
                                  isCompleted: !sub.isCompleted,
                                );
                                _autoSave(
                                    todo.copyWith(subTasks: updated));
                              },
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                sub.title,
                                style: TextStyle(
                                  fontSize: AppSizes.body,
                                  color: textPrimary,
                                  decoration: sub.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                final updated =
                                    List<SubTask>.from(todo.subTasks)
                                      ..removeAt(i);
                                _autoSave(
                                    todo.copyWith(subTasks: updated));
                              },
                              child: Icon(
                                CupertinoIcons.minus_circle,
                                size: AppSizes.iconSm,
                                color: AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  // Add sub-task field
                  NeuTextField(
                    controller: _subTaskController,
                    hintText: 'Add a sub-task...',
                    prefixIcon: CupertinoIcons.plus,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        final updated =
                            List<SubTask>.from(todo.subTasks)
                              ..add(SubTask(
                                id: const Uuid().v4(),
                                title: value.trim(),
                              ));
                        _autoSave(todo.copyWith(subTasks: updated));
                        _subTaskController.clear();
                      }
                    },
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Notes
                  Row(
                    children: [
                      _SectionLabel(label: 'Notes', isDark: isDark),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          EmojiPicker.show(context, onSelected: (emoji) {
                            _insertEmoji(_notesController, emoji);
                            _autoSave(todo.copyWith(notes: _notesController.text));
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.xs,
                            vertical: AppSizes.xs,
                          ),
                          child: Icon(
                            Icons.emoji_emotions_outlined,
                            size: AppSizes.iconSm,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  NeuTextField(
                    controller: _notesController,
                    hintText: 'Add notes or details...',
                    maxLines: 6,
                    onChanged: (value) {
                      _autoSave(todo.copyWith(notes: value));
                    },
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Delete button
                  Center(
                    child: NeuButton(
                      label: 'Delete Todo',
                      icon: CupertinoIcons.trash,
                      variant: NeuButtonVariant.outline,
                      onPressed: () => _confirmDelete(context, todo),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -- Date pickers --

  Future<void> _pickDate(BuildContext context, TodoModel todo) async {
    DateTime selected = todo.dueDate ?? DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    _autoSave(todo.copyWith(dueDate: selected));
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: selected,
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (dt) => selected = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminder(BuildContext context, TodoModel todo) async {
    DateTime selected = todo.reminderAt ?? DateTime.now();
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : AppColors.surfaceLight,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () {
                    _autoSave(todo.copyWith(reminderAt: selected));
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
            Expanded(
              child: CupertinoDatePicker(
                initialDateTime: selected,
                mode: CupertinoDatePickerMode.dateAndTime,
                onDateTimeChanged: (dt) => selected = dt,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, TodoModel todo) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Delete "${todo.title}"? This cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              ref.read(todoProvider.notifier).deleteTodo(todo.id);
              Navigator.of(ctx).pop();
              context.pop();
            },
            child: const Text('Delete'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section label
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: AppSizes.bodySmall,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add tag chip inline
// ---------------------------------------------------------------------------

class _AddTagChip extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onAdd;
  const _AddTagChip({required this.controller, required this.onAdd});

  @override
  State<_AddTagChip> createState() => _AddTagChipState();
}

class _AddTagChipState extends State<_AddTagChip> {
  bool _editing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_editing) {
      return GestureDetector(
        onTap: () => setState(() => _editing = true),
        child: NeuBadge(
          label: 'Add',
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          icon: CupertinoIcons.plus,
        ),
      );
    }

    return SizedBox(
      width: 120,
      height: 32,
      child: CupertinoTextField(
        controller: widget.controller,
        placeholder: 'Tag name',
        autofocus: true,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm, vertical: AppSizes.xs),
        style: TextStyle(fontSize: AppSizes.caption),
        onSubmitted: (v) {
          widget.onAdd(v.trim());
          setState(() => _editing = false);
        },
        onEditingComplete: () {
          widget.onAdd(widget.controller.text.trim());
          setState(() => _editing = false);
        },
      ),
    );
  }
}
