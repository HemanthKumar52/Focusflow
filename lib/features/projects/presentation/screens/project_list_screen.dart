import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_progress_ring.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../tasks/providers/task_provider.dart';
import '../../data/project_model.dart';
import '../../providers/project_provider.dart';

// ---------------------------------------------------------------------------
// Local filter provider
// ---------------------------------------------------------------------------

final _showArchivedProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Project List Screen
// ---------------------------------------------------------------------------

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _selectedColor = 0xFF5B3FE8;
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final showArchived = ref.watch(_showArchivedProvider);

    final projects = showArchived
        ? ref.watch(archivedProjectsProvider)
        : ref.watch(activeProjectsProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Projects',
          style: TextStyle(
            fontSize: AppSizes.heading2,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          NeuIconButton(
            icon: showArchived
                ? CupertinoIcons.archivebox_fill
                : CupertinoIcons.archivebox,
            onPressed: () {
              ref.read(_showArchivedProvider.notifier).state = !showArchived;
            },
            tooltip: showArchived ? 'Show Active' : 'Show Archived',
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: projects.isEmpty
          ? _EmptyState(isArchived: showArchived)
          : LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth < AppSizes.compactMax
                    ? 2
                    : constraints.maxWidth < AppSizes.mediumMax
                        ? 3
                        : 4;

                return GridView.builder(
                  padding: const EdgeInsets.all(AppSizes.md),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: AppSizes.md,
                    crossAxisSpacing: AppSizes.md,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    return _ProjectCard(project: projects[index]);
                  },
                );
              },
            ),
      floatingActionButton: _buildFAB(context, isDark),
    );
  }

  Widget _buildFAB(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showCreateSheet(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    _nameController.clear();
    _descController.clear();
    _selectedColor = 0xFF5B3FE8;
    _selectedDueDate = null;

    final colors = [
      0xFF5B3FE8,
      0xFF00C2A8,
      0xFFF5A623,
      0xFFE8523F,
      0xFF5AC8FA,
      0xFF34C759,
      0xFFFF6B6B,
      0xFFAF52DE,
    ];

    NeuBottomSheet.show(
      context: context,
      title: 'New Project',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSizes.md,
              right: AppSizes.md,
              bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSizes.md),
                  NeuTextField(
                    controller: _nameController,
                    hintText: 'Project name',
                    autofocus: true,
                  ),
                  const SizedBox(height: AppSizes.md),
                  NeuTextField(
                    controller: _descController,
                    hintText: 'Description (optional)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Color picker
                  _SelectorRow(
                    label: 'Color',
                    child: Wrap(
                      spacing: AppSizes.sm,
                      children: colors.map((c) {
                        final isSelected = c == _selectedColor;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => _selectedColor = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color:
                                            Color(c).withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Due date
                  _SelectorRow(
                    label: 'Due Date',
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              _selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) {
                          setSheetState(
                              () => _selectedDueDate = picked);
                        }
                      },
                      child: NeuBadge(
                        label: _selectedDueDate != null
                            ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                            : 'Pick date',
                        color: AppColors.info,
                        icon: CupertinoIcons.calendar,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  NeuButton(
                    label: 'Create Project',
                    icon: CupertinoIcons.folder_badge_plus,
                    isFullWidth: true,
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      ref.read(projectProvider.notifier).addProject(
                            name,
                            color: _selectedColor,
                            description: _descController.text.trim().isEmpty
                                ? null
                                : _descController.text.trim(),
                          );
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Project Card
// ---------------------------------------------------------------------------

class _ProjectCard extends ConsumerWidget {
  final ProjectModel project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final progress = ref.watch(projectProgressProvider(project.id));
    final projectTasks = ref.watch(tasksByProjectProvider(project.id));
    final milestoneCount = project.milestones.length;
    final projectColor = Color(project.colorValue);

    return NeuContainer(
      onTap: () => context.go('/projects/${project.id}'),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color accent bar
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: projectColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Name
          Text(
            project.name,
            style: TextStyle(
              fontSize: AppSizes.heading4,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.xs),

          // Description
          if (project.description != null && project.description!.isNotEmpty)
            Text(
              project.description!,
              style: TextStyle(
                fontSize: AppSizes.bodySmall,
                color: subtextColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

          const Spacer(),

          // Progress ring
          Center(
            child: NeuProgressRing(
              progress: progress,
              size: 56,
              strokeWidth: 5,
              progressColor: projectColor,
              center: Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  fontSize: AppSizes.caption,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.sm),

          // Health badge
          Center(
            child: NeuBadge(
              label: project.health.label,
              color: project.health.color,
            ),
          ),

          const Spacer(),

          // Task count + milestone count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.checkmark_square,
                      size: 14, color: subtextColor),
                  const SizedBox(width: 4),
                  Text(
                    '${projectTasks.length}',
                    style: TextStyle(
                        fontSize: AppSizes.caption, color: subtextColor),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.flag, size: 14, color: subtextColor),
                  const SizedBox(width: 4),
                  Text(
                    '$milestoneCount',
                    style: TextStyle(
                        fontSize: AppSizes.caption, color: subtextColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isArchived;
  const _EmptyState({required this.isArchived});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isArchived
                ? CupertinoIcons.archivebox
                : CupertinoIcons.folder,
            size: 64,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            isArchived ? 'No archived projects' : 'No projects yet',
            style: TextStyle(
              fontSize: AppSizes.heading3,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          if (!isArchived) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              'Tap + to create your first project',
              style: TextStyle(
                fontSize: AppSizes.body,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

class _SelectorRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _SelectorRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.bodySmall,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        child,
      ],
    );
  }
}
