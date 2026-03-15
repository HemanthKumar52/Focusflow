import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../projects/providers/project_provider.dart';
import '../../data/task_model.dart';

class TaskCardWidget extends ConsumerWidget {
  final TaskModel task;
  final VoidCallback? onTap;

  const TaskCardWidget({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Resolve project name
    final projects = ref.watch(projectProvider);
    final project = task.projectId != null
        ? projects.cast<dynamic>().firstWhere(
              (p) => p.id == task.projectId,
              orElse: () => null,
            )
        : null;

    final statusColor = task.status.color;

    return NeuContainer(
      onTap: onTap ?? () => context.go('/tasks/${task.id}'),
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Status indicator left edge
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppSizes.radiusMd),
                  bottomLeft: Radius.circular(AppSizes.radiusMd),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: priority dot + title
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: task.priority.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: AppSizes.body,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSizes.sm),

                    // Middle: effort badge, project badge, due date
                    Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.xs,
                      children: [
                        NeuBadge(
                          label: task.effort.label,
                          color: AppColors.primary,
                        ),
                        if (project != null)
                          NeuBadge(
                            label: project.name,
                            color: Color(project.colorValue),
                          ),
                        if (task.dueDate != null)
                          NeuBadge(
                            label: task.dueDate!.friendlyDate,
                            color: task.dueDate!.isPast && !task.isCompleted
                                ? AppColors.danger
                                : AppColors.info,
                            icon: CupertinoIcons.calendar,
                          ),
                      ],
                    ),

                    // Bottom: checklist progress + time logged
                    if (task.checklist.isNotEmpty ||
                        task.totalTimeLogged > Duration.zero) ...[
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        children: [
                          if (task.checklist.isNotEmpty) ...[
                            Expanded(
                              child: _ChecklistProgress(task: task),
                            ),
                            const SizedBox(width: AppSizes.sm),
                          ],
                          if (task.totalTimeLogged > Duration.zero)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.clock,
                                  size: AppSizes.iconSm - 2,
                                  color: subtextColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDuration(task.totalTimeLogged),
                                  style: TextStyle(
                                    fontSize: AppSizes.caption,
                                    color: subtextColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}

class _ChecklistProgress extends StatelessWidget {
  final TaskModel task;
  const _ChecklistProgress({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final completed = task.checklist.where((c) => c.isCompleted).length;
    final total = task.checklist.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor:
                  (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
                      .withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.xs),
        Text(
          '$completed/$total',
          style: TextStyle(
            fontSize: AppSizes.caption,
            color: subtextColor,
          ),
        ),
      ],
    );
  }
}
