import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../data/study_model.dart';
import '../../providers/study_provider.dart';

class StudyPlanEditorScreen extends ConsumerStatefulWidget {
  final String? planId;

  const StudyPlanEditorScreen({super.key, this.planId});

  @override
  ConsumerState<StudyPlanEditorScreen> createState() =>
      _StudyPlanEditorScreenState();
}

class _StudyPlanEditorScreenState extends ConsumerState<StudyPlanEditorScreen> {
  final _nameController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 28));
  int _sessionsPerWeek = 5;
  int _sessionDuration = 25;
  final List<_WeekEditorState> _weeklyTopics = [];
  bool _isEditing = false;

  // Duration options as neumorphic selectable buttons.
  static const List<int> _durationOptions = [15, 25, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    if (widget.planId != null) {
      _isEditing = true;
      // Load plan data after the first frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadPlan());
    } else {
      _initWeeks();
    }
  }

  void _loadPlan() {
    final plans = ref.read(studyPlanProvider);
    final plan = plans.where((p) => p.id == widget.planId).firstOrNull;
    if (plan == null) return;

    setState(() {
      _nameController.text = plan.name;
      _startDate = plan.startDate;
      _endDate = plan.endDate;
      _sessionsPerWeek = plan.sessionsPerWeek;
      _sessionDuration = plan.sessionDurationMinutes;

      _weeklyTopics.clear();
      final totalWeeks = plan.totalWeeks.clamp(1, 52);
      for (int w = 1; w <= totalWeeks; w++) {
        final bucket = plan.weeklyTopics
            .where((b) => b.weekNumber == w)
            .firstOrNull;
        _weeklyTopics.add(_WeekEditorState(
          weekNumber: w,
          topics: bucket?.topics
                  .map((t) => _TopicEntry(
                        name: t.name,
                        url: t.resourceUrls.isNotEmpty
                            ? t.resourceUrls.first
                            : '',
                        statusIndex: t.statusIndex,
                      ))
                  .toList() ??
              [],
        ));
      }
    });
  }

  void _initWeeks() {
    final totalWeeks =
        _endDate.difference(_startDate).inDays ~/ 7;
    _weeklyTopics.clear();
    for (int w = 1; w <= totalWeeks.clamp(1, 52); w++) {
      _weeklyTopics.add(_WeekEditorState(weekNumber: w, topics: []));
    }
  }

  void _recalculateWeeks() {
    final totalWeeks =
        (_endDate.difference(_startDate).inDays ~/ 7).clamp(1, 52);
    while (_weeklyTopics.length < totalWeeks) {
      _weeklyTopics.add(_WeekEditorState(
        weekNumber: _weeklyTopics.length + 1,
        topics: [],
      ));
    }
    while (_weeklyTopics.length > totalWeeks) {
      _weeklyTopics.removeLast();
    }
    setState(() {});
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (result != null) {
      setState(() {
        if (isStart) {
          _startDate = result;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = result;
        }
        _recalculateWeeks();
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plan name')),
      );
      return;
    }

    final notifier = ref.read(studyPlanProvider.notifier);

    if (_isEditing && widget.planId != null) {
      final plans = ref.read(studyPlanProvider);
      final existingPlan =
          plans.where((p) => p.id == widget.planId).firstOrNull;
      if (existingPlan != null) {
        final weeklyBuckets = _weeklyTopics.map((w) {
          return WeeklyTopicBucket(
            weekNumber: w.weekNumber,
            topics: w.topics.map((t) {
              return StudyTopic(
                id: t.name.hashCode.toString(),
                name: t.name,
                statusIndex: t.statusIndex,
                resourceUrls: t.url.isNotEmpty ? [t.url] : [],
              );
            }).toList(),
          );
        }).toList();

        final updated = existingPlan.copyWith(
          name: name,
          startDate: _startDate,
          endDate: _endDate,
          sessionsPerWeek: _sessionsPerWeek,
          sessionDurationMinutes: _sessionDuration,
          weeklyTopics: weeklyBuckets,
        );
        await notifier.updatePlan(updated);
      }
    } else {
      await notifier.addPlan(
        name,
        _startDate,
        _endDate,
        sessionsPerWeek: _sessionsPerWeek,
      );

      // Add topics to newly created plan.
      final plans = ref.read(studyPlanProvider);
      final newPlan = plans.last;

      // Update with session duration and topics.
      final weeklyBuckets = _weeklyTopics.map((w) {
        return WeeklyTopicBucket(
          weekNumber: w.weekNumber,
          topics: w.topics.map((t) {
            return StudyTopic(
              id: t.name.hashCode.toString(),
              name: t.name,
              statusIndex: t.statusIndex,
              resourceUrls: t.url.isNotEmpty ? [t.url] : [],
            );
          }).toList(),
        );
      }).toList();

      final updated = newPlan.copyWith(
        sessionDurationMinutes: _sessionDuration,
        weeklyTopics: weeklyBuckets,
      );
      await notifier.updatePlan(updated);
    }

    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Plan'),
        content:
            const Text('Are you sure you want to delete this study plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.planId != null) {
      await ref.read(studyPlanProvider.notifier).deletePlan(widget.planId!);
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.sm, AppSizes.sm, AppSizes.lg, AppSizes.sm),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(CupertinoIcons.back, color: textPrimary),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Plan' : 'New Study Plan',
                      style: TextStyle(
                        fontSize: AppSizes.heading3,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (_isEditing)
                    IconButton(
                      icon: const Icon(CupertinoIcons.trash,
                          color: AppColors.danger),
                      onPressed: _delete,
                    ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                children: [
                  const SizedBox(height: AppSizes.sm),

                  // Plan name
                  NeuTextField(
                    controller: _nameController,
                    labelText: 'Plan Name',
                    hintText: 'e.g., Spring Semester Calculus',
                    prefixIcon: CupertinoIcons.book,
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Date range
                  Text(
                    'Schedule',
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Row(
                    children: [
                      Expanded(
                        child: NeuContainer(
                          onTap: () => _pickDate(true),
                          padding: const EdgeInsets.all(AppSizes.sm + 4),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.calendar,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start',
                                      style: TextStyle(
                                        fontSize: AppSizes.caption,
                                        color: textSecondary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM d, y')
                                          .format(_startDate),
                                      style: TextStyle(
                                        fontSize: AppSizes.body,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: NeuContainer(
                          onTap: () => _pickDate(false),
                          padding: const EdgeInsets.all(AppSizes.sm + 4),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.calendar,
                                  size: 18, color: AppColors.secondary),
                              const SizedBox(width: AppSizes.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End',
                                      style: TextStyle(
                                        fontSize: AppSizes.caption,
                                        color: textSecondary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM d, y').format(_endDate),
                                      style: TextStyle(
                                        fontSize: AppSizes.body,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Sessions per week slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sessions per Week',
                        style: TextStyle(
                          fontSize: AppSizes.bodySmall,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                      NeuBadge(
                        label: '$_sessionsPerWeek',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),
                  NeuContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm, vertical: AppSizes.xs),
                    child: Slider(
                      value: _sessionsPerWeek.toDouble(),
                      min: 1,
                      max: 14,
                      divisions: 13,
                      activeColor: AppColors.primary,
                      inactiveColor:
                          AppColors.primary.withValues(alpha: 0.2),
                      onChanged: (v) =>
                          setState(() => _sessionsPerWeek = v.round()),
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Session duration picker
                  Text(
                    'Session Duration',
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: _durationOptions.map((mins) {
                      final isSelected = _sessionDuration == mins;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 3),
                          child: NeuContainer(
                            onTap: () =>
                                setState(() => _sessionDuration = mins),
                            isPressed: isSelected,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.sm + 2),
                            child: Center(
                              child: Text(
                                '${mins}m',
                                style: TextStyle(
                                  fontSize: AppSizes.body,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? AppColors.primary
                                      : textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  // Weekly Topics Editor
                  Text(
                    'Weekly Topics',
                    style: TextStyle(
                      fontSize: AppSizes.heading4,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  ..._weeklyTopics.map((week) => _WeekSection(
                        week: week,
                        isDark: isDark,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        onChanged: () => setState(() {}),
                      )),
                  const SizedBox(height: AppSizes.xl),

                  // Save button
                  NeuButton(
                    label: _isEditing ? 'Update Plan' : 'Create Plan',
                    icon: CupertinoIcons.checkmark_alt,
                    onPressed: _save,
                    isFullWidth: true,
                  ),

                  if (_isEditing) ...[
                    const SizedBox(height: AppSizes.md),
                    NeuButton(
                      label: 'Delete Plan',
                      icon: CupertinoIcons.trash,
                      variant: NeuButtonVariant.outline,
                      onPressed: _delete,
                      isFullWidth: true,
                    ),
                  ],

                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal state helpers
// ---------------------------------------------------------------------------

class _TopicEntry {
  String name;
  String url;
  int statusIndex;

  _TopicEntry({
    required this.name,
    this.url = '',
    this.statusIndex = 0,
  });
}

class _WeekEditorState {
  int weekNumber;
  List<_TopicEntry> topics;
  bool isExpanded;

  _WeekEditorState({
    required this.weekNumber,
    required this.topics,
    bool isExpanded = false,
  }) : isExpanded = isExpanded;
}

// ---------------------------------------------------------------------------
// Week section (expandable)
// ---------------------------------------------------------------------------

class _WeekSection extends StatefulWidget {
  final _WeekEditorState week;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onChanged;

  const _WeekSection({
    required this.week,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onChanged,
  });

  @override
  State<_WeekSection> createState() => _WeekSectionState();
}

class _WeekSectionState extends State<_WeekSection> {
  final _topicNameController = TextEditingController();
  final _topicUrlController = TextEditingController();

  @override
  void dispose() {
    _topicNameController.dispose();
    _topicUrlController.dispose();
    super.dispose();
  }

  void _addTopic() {
    final name = _topicNameController.text.trim();
    if (name.isEmpty) return;
    widget.week.topics.add(_TopicEntry(
      name: name,
      url: _topicUrlController.text.trim(),
    ));
    _topicNameController.clear();
    _topicUrlController.clear();
    widget.onChanged();
  }

  Color _statusColor(StudyTopicStatus status) {
    switch (status) {
      case StudyTopicStatus.notStarted:
        return AppColors.statusNotStarted;
      case StudyTopicStatus.studied:
        return AppColors.info;
      case StudyTopicStatus.revisionNeeded:
        return AppColors.warning;
      case StudyTopicStatus.mastered:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final week = widget.week;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: NeuContainer(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Header
            InkWell(
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              onTap: () {
                setState(() => week.isExpanded = !week.isExpanded);
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Row(
                  children: [
                    Icon(
                      week.isExpanded
                          ? CupertinoIcons.chevron_down
                          : CupertinoIcons.chevron_right,
                      size: 16,
                      color: widget.textSecondary,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      'Week ${week.weekNumber}',
                      style: TextStyle(
                        fontSize: AppSizes.body,
                        fontWeight: FontWeight.w600,
                        color: widget.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    NeuBadge(
                      label: '${week.topics.length} topics',
                      color: AppColors.secondary,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            if (week.isExpanded) ...[
              Divider(
                height: 1,
                color: widget.isDark
                    ? AppColors.textTertiaryDark.withValues(alpha: 0.2)
                    : AppColors.textTertiaryLight.withValues(alpha: 0.2),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  children: [
                    // Existing topics
                    ...week.topics.asMap().entries.map((entry) {
                      final index = entry.key;
                      final topic = entry.value;
                      final status =
                          StudyTopicStatus.values[topic.statusIndex];
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSizes.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic.name,
                                    style: TextStyle(
                                      fontSize: AppSizes.body,
                                      color: widget.textPrimary,
                                    ),
                                  ),
                                  if (topic.url.isNotEmpty)
                                    Text(
                                      topic.url,
                                      style: TextStyle(
                                        fontSize: AppSizes.caption,
                                        color: AppColors.info,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            NeuBadge(
                              label: status.label,
                              color: _statusColor(status),
                            ),
                            const SizedBox(width: AppSizes.xs),
                            GestureDetector(
                              onTap: () {
                                week.topics.removeAt(index);
                                widget.onChanged();
                              },
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                size: 18,
                                color: AppColors.danger
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add topic fields
                    const SizedBox(height: AppSizes.sm),
                    NeuTextField(
                      controller: _topicNameController,
                      hintText: 'Topic name',
                      prefixIcon: CupertinoIcons.bookmark,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    NeuTextField(
                      controller: _topicUrlController,
                      hintText: 'Resource URL (optional)',
                      prefixIcon: CupertinoIcons.link,
                    ),
                    const SizedBox(height: AppSizes.sm),
                    NeuButton(
                      label: 'Add Topic',
                      icon: CupertinoIcons.add,
                      size: NeuButtonSize.small,
                      variant: NeuButtonVariant.secondary,
                      onPressed: _addTopic,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
