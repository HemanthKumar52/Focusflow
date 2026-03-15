import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_tab_bar.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../projects/providers/project_provider.dart';
import '../../data/task_model.dart';
import '../../providers/task_provider.dart';
import '../widgets/task_card_widget.dart';

// ---------------------------------------------------------------------------
// Local state providers
// ---------------------------------------------------------------------------

final _viewModeProvider = StateProvider<ViewLayout>((ref) => ViewLayout.list);
final _sortModeProvider = StateProvider<_SortMode>((ref) => _SortMode.dueDate);

final _filterPriorityProvider =
    StateProvider<TaskPriority?>((ref) => null);
final _filterProjectIdProvider = StateProvider<String?>((ref) => null);
final _filterStatusProvider = StateProvider<TaskStatus?>((ref) => null);
final _filterTagProvider = StateProvider<String?>((ref) => null);

enum _SortMode { dueDate, priority, created }

final _filteredSortedTasksProvider = Provider<List<TaskModel>>((ref) {
  var tasks = ref.watch(taskProvider);
  final filterPriority = ref.watch(_filterPriorityProvider);
  final filterProject = ref.watch(_filterProjectIdProvider);
  final filterStatus = ref.watch(_filterStatusProvider);
  final filterTag = ref.watch(_filterTagProvider);
  final sortMode = ref.watch(_sortModeProvider);

  if (filterPriority != null) {
    tasks = tasks.where((t) => t.priority == filterPriority).toList();
  }
  if (filterProject != null) {
    tasks = tasks.where((t) => t.projectId == filterProject).toList();
  }
  if (filterStatus != null) {
    tasks = tasks.where((t) => t.status == filterStatus).toList();
  }
  if (filterTag != null) {
    tasks = tasks.where((t) => t.tags.contains(filterTag)).toList();
  }

  tasks = List.of(tasks);
  switch (sortMode) {
    case _SortMode.dueDate:
      tasks.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    case _SortMode.priority:
      tasks.sort((a, b) => a.priorityIndex.compareTo(b.priorityIndex));
    case _SortMode.created:
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  return tasks;
});

// ---------------------------------------------------------------------------
// Task Board Screen
// ---------------------------------------------------------------------------

class TaskBoardScreen extends ConsumerStatefulWidget {
  const TaskBoardScreen({super.key});

  @override
  ConsumerState<TaskBoardScreen> createState() => _TaskBoardScreenState();
}

class _TaskBoardScreenState extends ConsumerState<TaskBoardScreen> {
  final _newTaskController = TextEditingController();
  final _newTaskFocusNode = FocusNode();

  @override
  void dispose() {
    _newTaskController.dispose();
    _newTaskFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final viewMode = ref.watch(_viewModeProvider);
    final tasks = ref.watch(_filteredSortedTasksProvider);
    final bgColor = isNeon ? AppColors.backgroundNeon : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          'Tasks',
          style: TextStyle(
            fontSize: AppSizes.heading2,
            fontWeight: FontWeight.w700,
            color: isNeon
                ? AppColors.textPrimaryNeon
                : (isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight),
          ),
        ),
        actions: [
          NeuIconButton(
            icon: viewMode == ViewLayout.list
                ? CupertinoIcons.square_grid_2x2
                : CupertinoIcons.list_bullet,
            onPressed: () {
              ref.read(_viewModeProvider.notifier).state =
                  viewMode == ViewLayout.list
                      ? ViewLayout.kanban
                      : ViewLayout.list;
            },
            tooltip: viewMode == ViewLayout.list
                ? 'Kanban View'
                : 'List View',
          ),
          const SizedBox(width: AppSizes.xs),
          NeuIconButton(
            icon: CupertinoIcons.line_horizontal_3_decrease,
            onPressed: () => _showFilterSheet(context),
            tooltip: 'Filter',
          ),
          const SizedBox(width: AppSizes.xs),
          PopupMenuButton<_SortMode>(
            icon: Icon(
              CupertinoIcons.arrow_up_arrow_down,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            onSelected: (s) =>
                ref.read(_sortModeProvider.notifier).state = s,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: _SortMode.dueDate,
                child: Text('Sort by Due Date'),
              ),
              const PopupMenuItem(
                value: _SortMode.priority,
                child: Text('Sort by Priority'),
              ),
              const PopupMenuItem(
                value: _SortMode.created,
                child: Text('Sort by Created'),
              ),
            ],
          ),
          const SizedBox(width: AppSizes.sm),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: NeuTabBar(
              tabs: const ['List', 'Kanban'],
              selectedIndex: viewMode == ViewLayout.list ? 0 : 1,
              onTabChanged: (i) {
                ref.read(_viewModeProvider.notifier).state =
                    i == 0 ? ViewLayout.list : ViewLayout.kanban;
              },
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Expanded(
            child: tasks.isEmpty
                ? _EmptyState()
                : viewMode == ViewLayout.list
                    ? _ListViewBody(tasks: tasks)
                    : _KanbanViewBody(tasks: tasks),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(context, isDark),
    );
  }

  Widget _buildFAB(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: () => _showCreateTaskSheet(context),
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

  void _showCreateTaskSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = ref.read(projectProvider);
    String? selectedProjectId;
    TaskPriority selectedPriority = TaskPriority.normal;
    EffortSize selectedEffort = EffortSize.m;
    DateTime? selectedDueDate;

    NeuBottomSheet.show(
      context: context,
      title: 'New Task',
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
                    controller: _newTaskController,
                    focusNode: _newTaskFocusNode,
                    hintText: 'Task title',
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Priority row
                  _SelectorRow(
                    label: 'Priority',
                    child: Wrap(
                      spacing: AppSizes.sm,
                      children: TaskPriority.values.map((p) {
                        final isSelected = p == selectedPriority;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedPriority = p),
                          child: NeuBadge(
                            label: p.label,
                            color: isSelected ? p.color : (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Effort row
                  _SelectorRow(
                    label: 'Effort',
                    child: Wrap(
                      spacing: AppSizes.sm,
                      children: EffortSize.values.map((e) {
                        final isSelected = e == selectedEffort;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedEffort = e),
                          child: NeuBadge(
                            label: e.label,
                            color: isSelected ? AppColors.primary : (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Project selector
                  if (projects.isNotEmpty)
                    _SelectorRow(
                      label: 'Project',
                      child: DropdownButton<String?>(
                        value: selectedProjectId,
                        isExpanded: true,
                        hint: Text(
                          'None',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                        underline: const SizedBox(),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...projects.map((p) => DropdownMenuItem<String?>(
                                value: p.id,
                                child: Text(p.name),
                              )),
                        ],
                        onChanged: (v) =>
                            setSheetState(() => selectedProjectId = v),
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
                              selectedDueDate ?? DateTime.now(),
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365 * 3)),
                        );
                        if (picked != null) {
                          setSheetState(() => selectedDueDate = picked);
                        }
                      },
                      child: NeuBadge(
                        label: selectedDueDate != null
                            ? '${selectedDueDate!.day}/${selectedDueDate!.month}/${selectedDueDate!.year}'
                            : 'Pick date',
                        color: AppColors.info,
                        icon: CupertinoIcons.calendar,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  NeuButton(
                    label: 'Create Task',
                    icon: CupertinoIcons.add,
                    isFullWidth: true,
                    onPressed: () {
                      final title = _newTaskController.text.trim();
                      if (title.isEmpty) return;
                      ref.read(taskProvider.notifier).addTask(
                            title,
                            projectId: selectedProjectId,
                            priority: selectedPriority,
                            effort: selectedEffort,
                            dueDate: selectedDueDate,
                          );
                      _newTaskController.clear();
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

  void _showFilterSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projects = ref.read(projectProvider);

    NeuBottomSheet.show(
      context: context,
      title: 'Filter Tasks',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final filterPriority = ref.watch(_filterPriorityProvider);
          final filterProject = ref.watch(_filterProjectIdProvider);
          final filterStatus = ref.watch(_filterStatusProvider);

          return Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Priority filter
                  _SelectorRow(
                    label: 'Priority',
                    child: Wrap(
                      spacing: AppSizes.sm,
                      children: [
                        GestureDetector(
                          onTap: () {
                            ref.read(_filterPriorityProvider.notifier).state =
                                null;
                            setSheetState(() {});
                          },
                          child: NeuBadge(
                            label: 'All',
                            color: filterPriority == null
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight),
                          ),
                        ),
                        ...TaskPriority.values.map((p) {
                          final isSelected = filterPriority == p;
                          return GestureDetector(
                            onTap: () {
                              ref
                                  .read(_filterPriorityProvider.notifier)
                                  .state = p;
                              setSheetState(() {});
                            },
                            child: NeuBadge(
                              label: p.label,
                              color: isSelected ? p.color : (isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Status filter
                  _SelectorRow(
                    label: 'Status',
                    child: Wrap(
                      spacing: AppSizes.sm,
                      children: [
                        GestureDetector(
                          onTap: () {
                            ref.read(_filterStatusProvider.notifier).state =
                                null;
                            setSheetState(() {});
                          },
                          child: NeuBadge(
                            label: 'All',
                            color: filterStatus == null
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiaryLight),
                          ),
                        ),
                        ...TaskStatus.values
                            .where((s) => s != TaskStatus.archived)
                            .map((s) {
                          final isSelected = filterStatus == s;
                          return GestureDetector(
                            onTap: () {
                              ref.read(_filterStatusProvider.notifier).state =
                                  s;
                              setSheetState(() {});
                            },
                            child: NeuBadge(
                              label: s.label,
                              color: isSelected ? s.color : (isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiaryLight),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Project filter
                  if (projects.isNotEmpty)
                    _SelectorRow(
                      label: 'Project',
                      child: Wrap(
                        spacing: AppSizes.sm,
                        children: [
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(_filterProjectIdProvider.notifier)
                                  .state = null;
                              setSheetState(() {});
                            },
                            child: NeuBadge(
                              label: 'All',
                              color: filterProject == null
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiaryLight),
                            ),
                          ),
                          ...projects.map((p) {
                            final isSelected = filterProject == p.id;
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(_filterProjectIdProvider.notifier)
                                    .state = p.id;
                                setSheetState(() {});
                              },
                              child: NeuBadge(
                                label: p.name,
                                color: isSelected
                                    ? Color(p.colorValue)
                                    : (isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiaryLight),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppSizes.lg),

                  NeuButton(
                    label: 'Clear Filters',
                    variant: NeuButtonVariant.outline,
                    isFullWidth: true,
                    icon: CupertinoIcons.xmark_circle,
                    onPressed: () {
                      ref.read(_filterPriorityProvider.notifier).state = null;
                      ref.read(_filterProjectIdProvider.notifier).state = null;
                      ref.read(_filterStatusProvider.notifier).state = null;
                      ref.read(_filterTagProvider.notifier).state = null;
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
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.checkmark_square_fill,
            size: 64,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No tasks yet',
            style: TextStyle(
              fontSize: AppSizes.heading3,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Tap + to create your first task',
            style: TextStyle(
              fontSize: AppSizes.body,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// List View
// ---------------------------------------------------------------------------

class _ListViewBody extends ConsumerWidget {
  final List<TaskModel> tasks;
  const _ListViewBody({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statuses = [
      TaskStatus.notStarted,
      TaskStatus.inProgress,
      TaskStatus.pending,
      TaskStatus.completed,
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        final statusTasks =
            tasks.where((t) => t.status == status).toList();
        if (statusTasks.isEmpty) return const SizedBox.shrink();

        return _ExpandableSection(
          status: status,
          tasks: statusTasks,
          isDark: isDark,
        );
      },
    );
  }
}

class _ExpandableSection extends StatefulWidget {
  final TaskStatus status;
  final List<TaskModel> tasks;
  final bool isDark;

  const _ExpandableSection({
    required this.status,
    required this.tasks,
    required this.isDark,
  });

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            margin: const EdgeInsets.only(bottom: AppSizes.sm),
            decoration: BoxDecoration(
              color: widget.status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: widget.status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    widget.status.label,
                    style: TextStyle(
                      fontSize: AppSizes.body,
                      fontWeight: FontWeight.w600,
                      color: widget.status.color,
                    ),
                  ),
                ),
                NeuBadge(
                  label: '${widget.tasks.length}',
                  color: widget.status.color,
                ),
                const SizedBox(width: AppSizes.sm),
                Icon(
                  _isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: AppSizes.iconSm,
                  color: widget.status.color,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          ...widget.tasks.map(
            (t) => TaskCardWidget(task: t),
          ),
        const SizedBox(height: AppSizes.sm),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kanban View
// ---------------------------------------------------------------------------

class _KanbanViewBody extends ConsumerWidget {
  final List<TaskModel> tasks;
  const _KanbanViewBody({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = [
      TaskStatus.notStarted,
      TaskStatus.inProgress,
      TaskStatus.pending,
      TaskStatus.completed,
    ];

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      itemCount: statuses.length,
      itemBuilder: (context, index) {
        final status = statuses[index];
        final columnTasks =
            tasks.where((t) => t.status == status).toList();

        return _KanbanColumn(
          status: status,
          tasks: columnTasks,
          onAccept: (task) {
            ref.read(taskProvider.notifier).updateStatus(task.id, status);
          },
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final TaskStatus status;
  final List<TaskModel> tasks;
  final ValueChanged<TaskModel> onAccept;

  const _KanbanColumn({
    required this.status,
    required this.tasks,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = (screenWidth * 0.75).clamp(260.0, 320.0);

    return DragTarget<TaskModel>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: columnWidth,
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: isHighlighted
                ? status.color.withValues(alpha: 0.08)
                : (isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            border: isHighlighted
                ? Border.all(
                    color: status.color.withValues(alpha: 0.4), width: 2)
                : null,
          ),
          child: Column(
            children: [
              // Column header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.sm,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontSize: AppSizes.body,
                          fontWeight: FontWeight.w600,
                          color: status.color,
                        ),
                      ),
                    ),
                    NeuBadge(
                      label: '${tasks.length}',
                      color: status.color,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              // Tasks
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          'Drop tasks here',
                          style: TextStyle(
                            fontSize: AppSizes.bodySmall,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return LongPressDraggable<TaskModel>(
                            data: task,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: columnWidth - AppSizes.md * 2,
                                child: Opacity(
                                  opacity: 0.85,
                                  child: TaskCardWidget(task: task),
                                ),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: TaskCardWidget(task: task),
                            ),
                            child: TaskCardWidget(task: task),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
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
