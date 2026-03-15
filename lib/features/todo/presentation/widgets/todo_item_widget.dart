import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_checkbox.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../data/todo_model.dart';

class TodoItemWidget extends StatefulWidget {
  final TodoModel todo;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;
  final VoidCallback? onDelete;
  final Color? tintColor;

  const TodoItemWidget({
    super.key,
    required this.todo,
    this.onToggle,
    this.onTap,
    this.onDismissed,
    this.onDelete,
    this.tintColor,
  });

  @override
  State<TodoItemWidget> createState() => _TodoItemWidgetState();
}

class _TodoItemWidgetState extends State<TodoItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _fadeAnim = Tween<double>(begin: 1.0, end: 0.4).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant TodoItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.todo.isCompleted && widget.todo.isCompleted) {
      _animController.forward();
    } else if (oldWidget.todo.isCompleted && !widget.todo.isCompleted) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDue(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dueDay = DateTime(date.year, date.month, date.day);

    if (dueDay == today) {
      return 'Today ${DateFormat.jm().format(date)}';
    } else if (dueDay == tomorrow) {
      return 'Tomorrow ${DateFormat.jm().format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    Widget item = AnimatedBuilder(
      animation: _animController,
      builder: (context, child) => Opacity(
        opacity: _fadeAnim.value,
        child: Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
      ),
      child: NeuContainer(
        onTap: widget.onTap,
        color: widget.tintColor,
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: NeuCheckbox(
                value: todo.isCompleted,
                activeColor: todo.priority.color,
                onChanged: (_) {
                  if (!todo.isCompleted) {
                    HapticFeedback.mediumImpact();
                  }
                  widget.onToggle?.call();
                },
              ),
            ),
            const SizedBox(width: AppSizes.sm + 4),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          todo.title,
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                            decoration: todo.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Priority dot
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: todo.priority.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  // Due date
                  if (todo.dueDate != null) ...[
                    const SizedBox(height: AppSizes.xs),
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.clock,
                          size: AppSizes.caption + 2,
                          color:
                              todo.isOverdue ? AppColors.danger : textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDue(todo.dueDate!),
                          style: TextStyle(
                            fontSize: AppSizes.caption,
                            color: todo.isOverdue
                                ? AppColors.danger
                                : textSecondary,
                            fontWeight: todo.isOverdue
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Tags
                  if (todo.tags.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.xs + 2),
                    Wrap(
                      spacing: AppSizes.xs,
                      runSpacing: AppSizes.xs,
                      children: todo.tags
                          .map((tag) => NeuBadge(
                                label: tag,
                                color: AppColors.primary,
                                fontSize: AppSizes.caption - 1,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap in Dismissible for swipe actions
    if (widget.onDismissed != null || widget.onDelete != null) {
      item = Dismissible(
        key: ValueKey(todo.id),
        direction: widget.onDelete != null
            ? DismissDirection.horizontal
            : DismissDirection.startToEnd,
        // Swipe right to complete
        background: Container(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
          child: const Icon(
            CupertinoIcons.checkmark_circle_fill,
            color: AppColors.success,
            size: AppSizes.iconLg,
          ),
        ),
        // Swipe left to delete
        secondaryBackground: widget.onDelete != null
            ? Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: AppSizes.lg),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: const Icon(
                  CupertinoIcons.trash_fill,
                  color: AppColors.danger,
                  size: AppSizes.iconLg,
                ),
              )
            : null,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart &&
              widget.onDelete != null) {
            return await showCupertinoDialog<bool>(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: const Text('Delete Todo'),
                    content: const Text(
                        'Are you sure you want to delete this todo?'),
                    actions: [
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Delete'),
                      ),
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ) ??
                false;
          }
          return true;
        },
        onDismissed: (direction) {
          if (direction == DismissDirection.startToEnd) {
            widget.onDismissed?.call();
          } else {
            widget.onDelete?.call();
          }
        },
        child: item,
      );
    }

    return item;
  }
}
