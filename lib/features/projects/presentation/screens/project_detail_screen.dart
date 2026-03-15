import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/neu_progress_ring.dart';
import '../../../../core/widgets/neu_tab_bar.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../notes/providers/note_provider.dart';
import '../../../tasks/data/task_model.dart';
import '../../../tasks/presentation/widgets/task_card_widget.dart';
import '../../../tasks/providers/task_provider.dart';
import '../../data/project_model.dart';
import '../../providers/project_provider.dart';

// ---------------------------------------------------------------------------
// Local state
// ---------------------------------------------------------------------------

final _tabIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final _projectViewModeProvider =
    StateProvider.autoDispose<ViewLayout>((ref) => ViewLayout.list);

// ---------------------------------------------------------------------------
// Project Detail Screen
// ---------------------------------------------------------------------------

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _milestoneNameController = TextEditingController();
  DateTime? _milestoneDate;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _milestoneNameController.dispose();
    super.dispose();
  }

  ProjectModel? _findProject(List<ProjectModel> projects) {
    try {
      return projects.firstWhere((p) => p.id == widget.projectId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final projects = ref.watch(projectProvider);
    final project = _findProject(projects);
    final tabIndex = ref.watch(_tabIndexProvider);

    if (project == null) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(backgroundColor: bgColor, elevation: 0),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.exclamationmark_triangle,
                  size: 48, color: subtextColor),
              const SizedBox(height: AppSizes.md),
              Text('Project not found',
                  style:
                      TextStyle(fontSize: AppSizes.heading3, color: textColor)),
            ],
          ),
        ),
      );
    }

    final progress = ref.watch(projectProgressProvider(project.id));
    final projectColor = Color(project.colorValue);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: NeuIconButton(
          icon: CupertinoIcons.back,
          onPressed: () => context.go('/projects'),
        ),
        actions: [
          NeuIconButton(
            icon: CupertinoIcons.pencil,
            onPressed: () => _showEditSheet(context, project),
          ),
          const SizedBox(width: AppSizes.xs),
          NeuIconButton(
            icon: CupertinoIcons.archivebox,
            onPressed: () {
              ref.read(projectProvider.notifier).archiveProject(project.id);
              context.go('/projects');
            },
            tooltip: 'Archive',
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: projectColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    project.name,
                    style: TextStyle(
                      fontSize: AppSizes.heading2,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
                NeuBadge(
                  label: project.health.label,
                  color: project.health.color,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Row(
              children: [
                NeuProgressRing(
                  progress: progress,
                  size: 44,
                  strokeWidth: 4,
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
                const SizedBox(width: AppSizes.md),
                if (project.description != null)
                  Expanded(
                    child: Text(
                      project.description!,
                      style: TextStyle(
                          fontSize: AppSizes.bodySmall, color: subtextColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: NeuTabBar(
              tabs: const ['Overview', 'Tasks', 'Notes', 'Milestones'],
              selectedIndex: tabIndex,
              onTabChanged: (i) =>
                  ref.read(_tabIndexProvider.notifier).state = i,
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Tab content
          Expanded(
            child: IndexedStack(
              index: tabIndex,
              children: [
                _OverviewTab(projectId: widget.projectId),
                _TasksTab(projectId: widget.projectId),
                _NotesTab(project: project),
                _MilestonesTab(
                  project: project,
                  nameController: _milestoneNameController,
                  milestoneDate: _milestoneDate,
                  onDateChanged: (d) => setState(() => _milestoneDate = d),
                  onAdd: () {
                    final name = _milestoneNameController.text.trim();
                    if (name.isEmpty || _milestoneDate == null) return;
                    ref.read(projectProvider.notifier).addMilestone(
                          project.id,
                          name,
                          _milestoneDate!,
                        );
                    _milestoneNameController.clear();
                    setState(() => _milestoneDate = null);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSheet(BuildContext context, ProjectModel project) {
    _nameController.text = project.name;
    _descController.text = project.description ?? '';
    int editColor = project.colorValue;
    DateTime? editDue = project.dueDate;

    final colors = [
      0xFF5B3FE8, 0xFF00C2A8, 0xFFF5A623, 0xFFE8523F,
      0xFF5AC8FA, 0xFF34C759, 0xFFFF6B6B, 0xFFAF52DE,
    ];

    NeuBottomSheet.show(
      context: context,
      title: 'Edit Project',
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
                  ),
                  const SizedBox(height: AppSizes.md),
                  NeuTextField(
                    controller: _descController,
                    hintText: 'Description',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppSizes.md),
                  _SelectorRow(
                    label: 'Color',
                    child: Wrap(
                      spacing: AppSizes.sm,
                      children: colors.map((c) {
                        final isSelected = c == editColor;
                        return GestureDetector(
                          onTap: () => setSheetState(() => editColor = c),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Color(c),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  _SelectorRow(
                    label: 'Due Date',
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: editDue ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) {
                          setSheetState(() => editDue = picked);
                        }
                      },
                      child: NeuBadge(
                        label: editDue != null
                            ? '${editDue!.day}/${editDue!.month}/${editDue!.year}'
                            : 'Pick date',
                        color: AppColors.info,
                        icon: CupertinoIcons.calendar,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  NeuButton(
                    label: 'Save Changes',
                    icon: CupertinoIcons.checkmark,
                    isFullWidth: true,
                    onPressed: () {
                      final name = _nameController.text.trim();
                      if (name.isEmpty) return;
                      final updated = project.copyWith(
                        name: name,
                        description: _descController.text.trim().isEmpty
                            ? null
                            : _descController.text.trim(),
                        colorValue: editColor,
                        dueDate: editDue,
                      );
                      ref.read(projectProvider.notifier).updateProject(updated);
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
// Overview Tab
// ---------------------------------------------------------------------------

class _OverviewTab extends ConsumerWidget {
  final String projectId;
  const _OverviewTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final tasks = ref.watch(tasksByProjectProvider(projectId));
    final totalTasks = tasks.length;
    final completed = tasks.where((t) => t.isCompleted).length;
    final overdue = tasks
        .where((t) =>
            t.dueDate != null && t.dueDate!.isPast && !t.isCompleted)
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats row
          Row(
            children: [
              _StatCard(
                label: 'Total',
                value: '$totalTasks',
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSizes.sm),
              _StatCard(
                label: 'Done',
                value: '$completed',
                color: AppColors.success,
              ),
              const SizedBox(width: AppSizes.sm),
              _StatCard(
                label: 'Overdue',
                value: '$overdue',
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.lg),

          // Recent activity
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: AppSizes.heading4,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          if (tasks.isEmpty)
            NeuContainer(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Center(
                child: Text(
                  'No tasks yet. Add some from the Tasks tab.',
                  style:
                      TextStyle(fontSize: AppSizes.bodySmall, color: subtextColor),
                ),
              ),
            )
          else
            ..._recentActivity(tasks, isDark, textColor, subtextColor),
        ],
      ),
    );
  }

  List<Widget> _recentActivity(List<TaskModel> tasks, bool isDark,
      Color textColor, Color subtextColor) {
    // Show recently modified tasks
    final sorted = List<TaskModel>.from(tasks)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(5).map((t) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.sm),
        child: NeuContainer(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: t.status.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: TextStyle(
                          fontSize: AppSizes.body, color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${t.status.label} - ${t.createdAt.friendlyDate}',
                      style: TextStyle(
                          fontSize: AppSizes.caption, color: subtextColor),
                    ),
                  ],
                ),
              ),
              NeuBadge(label: t.priority.label, color: t.priority.color),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: NeuContainer(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: AppSizes.heading2,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.caption,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tasks Tab
// ---------------------------------------------------------------------------

class _TasksTab extends ConsumerWidget {
  final String projectId;
  const _TasksTab({required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tasks = ref.watch(tasksByProjectProvider(projectId));
    final viewMode = ref.watch(_projectViewModeProvider);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_square,
              size: 48,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No tasks in this project',
              style: TextStyle(
                fontSize: AppSizes.body,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Row(
            children: [
              NeuIconButton(
                icon: viewMode == ViewLayout.list
                    ? CupertinoIcons.square_grid_2x2
                    : CupertinoIcons.list_bullet,
                size: 36,
                onPressed: () {
                  ref.read(_projectViewModeProvider.notifier).state =
                      viewMode == ViewLayout.list
                          ? ViewLayout.kanban
                          : ViewLayout.list;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Expanded(
          child: viewMode == ViewLayout.list
              ? _ProjectListView(tasks: tasks)
              : _ProjectKanbanView(tasks: tasks),
        ),
      ],
    );
  }
}

class _ProjectListView extends StatelessWidget {
  final List<TaskModel> tasks;
  const _ProjectListView({required this.tasks});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      itemCount: tasks.length,
      itemBuilder: (context, index) => TaskCardWidget(task: tasks[index]),
    );
  }
}

class _ProjectKanbanView extends ConsumerWidget {
  final List<TaskModel> tasks;
  const _ProjectKanbanView({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = [
      TaskStatus.notStarted,
      TaskStatus.inProgress,
      TaskStatus.pending,
      TaskStatus.completed,
    ];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        final columnTasks =
            tasks.where((t) => t.status == status).toList();
        final screenWidth = MediaQuery.of(context).size.width;
        final columnWidth = (screenWidth * 0.7).clamp(240.0, 300.0);

        return DragTarget<TaskModel>(
          onWillAcceptWithDetails: (d) => d.data.status != status,
          onAcceptWithDetails: (d) {
            ref.read(taskProvider.notifier).updateStatus(d.data.id, status);
          },
          builder: (context, candidates, rejected) {
            return Container(
              width: columnWidth,
              margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: candidates.isNotEmpty
                    ? status.color.withValues(alpha: 0.08)
                    : (isDark
                        ? AppColors.backgroundDark
                        : AppColors.backgroundLight),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: status.color.withValues(alpha: 0.15),
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          status.label,
                          style: TextStyle(
                            fontSize: AppSizes.bodySmall,
                            fontWeight: FontWeight.w600,
                            color: status.color,
                          ),
                        ),
                        const Spacer(),
                        NeuBadge(
                          label: '${columnTasks.length}',
                          color: status.color,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Expanded(
                    child: columnTasks.isEmpty
                        ? Center(
                            child: Text(
                              'Drop here',
                              style: TextStyle(
                                fontSize: AppSizes.caption,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight,
                              ),
                            ),
                          )
                        : ListView(
                            children: columnTasks.map((t) {
                              return LongPressDraggable<TaskModel>(
                                data: t,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: SizedBox(
                                    width: columnWidth - AppSizes.md,
                                    child: Opacity(
                                      opacity: 0.85,
                                      child: TaskCardWidget(task: t),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.3,
                                  child: TaskCardWidget(task: t),
                                ),
                                child: TaskCardWidget(task: t),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Notes Tab
// ---------------------------------------------------------------------------

class _NotesTab extends ConsumerWidget {
  final ProjectModel project;
  const _NotesTab({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final allNotes = ref.watch(noteProvider);
    final linkedNotes = allNotes
        .where((n) => project.linkedNoteIds.contains(n.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              NeuButton(
                label: 'Link Note',
                icon: CupertinoIcons.link,
                variant: NeuButtonVariant.outline,
                size: NeuButtonSize.small,
                onPressed: () => _showLinkNoteSheet(context, ref, project),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          Expanded(
            child: linkedNotes.isEmpty
                ? Center(
                    child: Text(
                      'No linked notes',
                      style: TextStyle(
                          fontSize: AppSizes.body, color: subtextColor),
                    ),
                  )
                : ListView.builder(
                    itemCount: linkedNotes.length,
                    itemBuilder: (context, index) {
                      final note = linkedNotes[index];
                      return NeuCard(
                        title: note.title,
                        onTap: () => context.go('/notes/${note.id}'),
                        child: Text(
                          note.body.isEmpty
                              ? 'Empty note'
                              : note.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: AppSizes.bodySmall,
                            color: subtextColor,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showLinkNoteSheet(
      BuildContext context, WidgetRef ref, ProjectModel project) {
    final allNotes = ref.read(noteProvider);
    final unlinked =
        allNotes.where((n) => !project.linkedNoteIds.contains(n.id)).toList();

    NeuBottomSheet.show(
      context: context,
      title: 'Link a Note',
      child: unlinked.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(AppSizes.lg),
              child: Center(child: Text('No available notes to link')),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: unlinked.length,
              itemBuilder: (context, index) {
                final note = unlinked[index];
                return ListTile(
                  leading: const Icon(CupertinoIcons.doc_text),
                  title: Text(note.title),
                  onTap: () {
                    final updated = project.copyWith(
                      linkedNoteIds: [...project.linkedNoteIds, note.id],
                    );
                    ref.read(projectProvider.notifier).updateProject(updated);
                    Navigator.of(context).pop();
                  },
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Milestones Tab
// ---------------------------------------------------------------------------

class _MilestonesTab extends StatelessWidget {
  final ProjectModel project;
  final TextEditingController nameController;
  final DateTime? milestoneDate;
  final ValueChanged<DateTime?> onDateChanged;
  final VoidCallback onAdd;

  const _MilestonesTab({
    required this.project,
    required this.nameController,
    required this.milestoneDate,
    required this.onDateChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtextColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final milestones = List<Milestone>.from(project.milestones)
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add milestone form
          NeuContainer(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Milestone',
                  style: TextStyle(
                    fontSize: AppSizes.heading4,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                NeuTextField(
                  controller: nameController,
                  hintText: 'Milestone name',
                ),
                const SizedBox(height: AppSizes.sm),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: milestoneDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 3)),
                          );
                          onDateChanged(picked);
                        },
                        child: NeuBadge(
                          label: milestoneDate != null
                              ? milestoneDate!.friendlyDate
                              : 'Target date',
                          color: AppColors.info,
                          icon: CupertinoIcons.calendar,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    NeuButton(
                      label: 'Add',
                      icon: CupertinoIcons.add,
                      size: NeuButtonSize.small,
                      onPressed: onAdd,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // Timeline
          if (milestones.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Text(
                  'No milestones yet',
                  style:
                      TextStyle(fontSize: AppSizes.body, color: subtextColor),
                ),
              ),
            )
          else
            ...milestones.asMap().entries.map((entry) {
              final index = entry.key;
              final ms = entry.value;
              final isLast = index == milestones.length - 1;
              final isPast = ms.targetDate.isBefore(DateTime.now());
              final markerColor = ms.isCompleted
                  ? AppColors.success
                  : isPast
                      ? AppColors.danger
                      : AppColors.primary;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timeline line + marker
                    SizedBox(
                      width: 32,
                      child: Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: markerColor,
                              shape: BoxShape.circle,
                              border: ms.isCompleted
                                  ? null
                                  : Border.all(
                                      color: markerColor
                                          .withValues(alpha: 0.3),
                                      width: 3,
                                    ),
                            ),
                            child: ms.isCompleted
                                ? const Icon(Icons.check,
                                    size: 10, color: Colors.white)
                                : null,
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: (isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight)
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    // Milestone card
                    Expanded(
                      child: Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSizes.md),
                        child: NeuContainer(
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ms.name,
                                      style: TextStyle(
                                        fontSize: AppSizes.body,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                        decoration: ms.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: AppSizes.xs),
                                    Text(
                                      ms.targetDate.friendlyDate,
                                      style: TextStyle(
                                        fontSize: AppSizes.caption,
                                        color: isPast && !ms.isCompleted
                                            ? AppColors.danger
                                            : subtextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              NeuBadge(
                                label: ms.isCompleted
                                    ? 'Done'
                                    : isPast
                                        ? 'Overdue'
                                        : 'Pending',
                                color: markerColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
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
