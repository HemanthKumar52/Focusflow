import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_progress_ring.dart';
import '../../data/study_model.dart';
import '../../providers/study_provider.dart';
import '../widgets/heatmap_widget.dart';

class StudyDashboardScreen extends ConsumerWidget {
  const StudyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final plans = ref.watch(studyPlanProvider);
    final sessions = ref.watch(studySessionProvider);
    final todaySessions = ref.watch(todaySessionsProvider);
    final streak = ref.watch(studyStreakProvider);

    // Determine the active plan (first non-expired plan, or the first one).
    final now = DateTime.now();
    final activePlan = plans.isNotEmpty
        ? plans.firstWhere(
            (p) => p.endDate.isAfter(now),
            orElse: () => plans.first,
          )
        : null;

    // Compute progress for active plan.
    double planProgress = 0;
    int currentWeek = 0;
    List<StudyTopic> topicsDueToday = [];

    if (activePlan != null) {
      final totalTopics = activePlan.weeklyTopics
          .fold<int>(0, (sum, bucket) => sum + bucket.topics.length);
      final masteredOrStudied = activePlan.weeklyTopics.fold<int>(
        0,
        (sum, bucket) => sum + bucket.topics.where((t) {
          final status = StudyTopicStatus.values[t.statusIndex];
          return status == StudyTopicStatus.studied ||
              status == StudyTopicStatus.mastered;
        }).length,
      );
      planProgress = totalTopics > 0 ? masteredOrStudied / totalTopics : 0;

      final daysSinceStart =
          now.difference(activePlan.startDate).inDays;
      currentWeek = (daysSinceStart ~/ 7) + 1;

      // Topics due for review today (spaced repetition).
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      for (final bucket in activePlan.weeklyTopics) {
        for (final topic in bucket.topics) {
          if (topic.nextReviewDate != null &&
              topic.nextReviewDate!.isBefore(todayEnd) &&
              StudyTopicStatus.values[topic.statusIndex] !=
                  StudyTopicStatus.mastered) {
            topicsDueToday.add(topic);
          }
          // Also include topics that have never been studied in the current week's bucket.
          if (topic.lastStudied == null &&
              bucket.weekNumber <= currentWeek &&
              !topicsDueToday.contains(topic)) {
            topicsDueToday.add(topic);
          }
        }
      }
    }

    // Build heatmap data from sessions.
    final Map<DateTime, int> heatmapData = {};
    for (final session in sessions) {
      if (session.isCompleted) {
        final day = DateTime(
          session.startTime.year,
          session.startTime.month,
          session.startTime.day,
        );
        heatmapData[day] = (heatmapData[day] ?? 0) + 1;
      }
    }

    // Weekly progress: sessions per day this week.
    final weekStart =
        now.subtract(Duration(days: now.weekday - 1));
    final List<int> weeklySessionCounts = List.generate(7, (i) {
      final day = DateTime(weekStart.year, weekStart.month, weekStart.day)
          .add(Duration(days: i));
      final dayEnd = day.add(const Duration(days: 1));
      return sessions
          .where((s) =>
              s.isCompleted &&
              s.startTime.isAfter(day.subtract(const Duration(seconds: 1))) &&
              s.startTime.isBefore(dayEnd))
          .length;
    });

    // Recent sessions (last 5 completed).
    final recentSessions = sessions
        .where((s) => s.isCompleted)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    final last5 = recentSessions.take(5).toList();

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: plans.isEmpty
            ? _EmptyState(
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              )
            : CustomScrollView(
                slivers: [
                  // -- App Bar --
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.sm),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Study',
                            style: TextStyle(
                              fontSize: AppSizes.heading1,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          NeuContainer(
                            onTap: () => context.push('/study/plan/new'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                              vertical: AppSizes.sm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.add,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  'New Plan',
                                  style: TextStyle(
                                    fontSize: AppSizes.bodySmall,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // -- Active Study Plan Card --
                  if (activePlan != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg, vertical: AppSizes.sm),
                        child: NeuContainer(
                          onTap: () =>
                              context.push('/study/plan/${activePlan.id}'),
                          padding: const EdgeInsets.all(AppSizes.md),
                          child: Row(
                            children: [
                              NeuProgressRing(
                                progress: planProgress,
                                size: 72,
                                strokeWidth: 7,
                                progressColor: AppColors.primary,
                                center: Text(
                                  '${(planProgress * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: AppSizes.bodySmall,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSizes.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activePlan.name,
                                      style: TextStyle(
                                        fontSize: AppSizes.heading4,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: AppSizes.xs),
                                    Row(
                                      children: [
                                        NeuBadge(
                                          label: 'Week $currentWeek',
                                          color: AppColors.info,
                                        ),
                                        const SizedBox(width: AppSizes.sm),
                                        Icon(
                                          CupertinoIcons.bolt_fill,
                                          size: 14,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${todaySessions.length} today',
                                          style: TextStyle(
                                            fontSize: AppSizes.bodySmall,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                CupertinoIcons.chevron_right,
                                size: 18,
                                color: textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // -- Today's Focus Section --
                  if (topicsDueToday.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Today's Focus",
                              style: TextStyle(
                                fontSize: AppSizes.heading4,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            NeuBadge(
                              label: '${topicsDueToday.length} topics',
                              color: AppColors.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.lg),
                          itemCount: topicsDueToday.length,
                          itemBuilder: (context, index) {
                            final topic = topicsDueToday[index];
                            final status =
                                StudyTopicStatus.values[topic.statusIndex];
                            return Padding(
                              padding: const EdgeInsets.only(right: AppSizes.sm),
                              child: NeuContainer(
                                width: 160,
                                padding: const EdgeInsets.all(AppSizes.sm + 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      topic.name,
                                      style: TextStyle(
                                        fontSize: AppSizes.body,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    NeuBadge(
                                      label: status.label,
                                      color: _statusColor(status),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg, vertical: AppSizes.sm),
                        child: NeuButton(
                          label: 'Start Session',
                          icon: CupertinoIcons.play_fill,
                          onPressed: () => context.push('/study/timer'),
                          isFullWidth: true,
                        ),
                      ),
                    ),
                  ],

                  // -- Streak Counter --
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg, vertical: AppSizes.sm),
                      child: NeuContainer(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.md,
                          horizontal: AppSizes.lg,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.flame_fill,
                              color: streak > 0
                                  ? AppColors.warning
                                  : textSecondary,
                              size: 28,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Text(
                              '$streak day streak',
                              style: TextStyle(
                                fontSize: AppSizes.heading4,
                                fontWeight: FontWeight.w700,
                                color: streak > 0
                                    ? AppColors.warning
                                    : textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // -- Activity Heatmap --
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg, vertical: AppSizes.sm),
                      child: HeatmapWidget(data: heatmapData),
                    ),
                  ),

                  // -- Weekly Progress --
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg, vertical: AppSizes.sm),
                      child: _WeeklyProgressChart(
                        sessionCounts: weeklySessionCounts,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                      ),
                    ),
                  ),

                  // -- Recent Sessions --
                  if (last5.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.sm),
                        child: Text(
                          'Recent Sessions',
                          style: TextStyle(
                            fontSize: AppSizes.heading4,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                      sliver: SliverList.builder(
                        itemCount: last5.length,
                        itemBuilder: (context, index) {
                          final session = last5[index];
                          // Try to find the topic name.
                          String topicName = 'Study Session';
                          if (session.topicId != null && activePlan != null) {
                            for (final bucket in activePlan.weeklyTopics) {
                              for (final topic in bucket.topics) {
                                if (topic.id == session.topicId) {
                                  topicName = topic.name;
                                }
                              }
                            }
                          }
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSizes.sm),
                            child: NeuContainer(
                              padding: const EdgeInsets.all(AppSizes.sm + 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(
                                          AppSizes.radiusSm),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        CupertinoIcons.book_fill,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSizes.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          topicName,
                                          style: TextStyle(
                                            fontSize: AppSizes.body,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          DateFormat('MMM d, h:mm a')
                                              .format(session.startTime),
                                          style: TextStyle(
                                            fontSize: AppSizes.caption,
                                            color: textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  NeuBadge(
                                    label: '${session.durationMinutes}m',
                                    color: AppColors.secondary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  // -- Plan List (if multiple) --
                  if (plans.length > 1) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.sm),
                        child: Text(
                          'All Plans',
                          style: TextStyle(
                            fontSize: AppSizes.heading4,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                      sliver: SliverList.builder(
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSizes.sm),
                            child: NeuContainer(
                              onTap: () =>
                                  context.push('/study/plan/${plan.id}'),
                              padding: const EdgeInsets.all(AppSizes.sm + 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      plan.name,
                                      style: TextStyle(
                                        fontSize: AppSizes.body,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    CupertinoIcons.chevron_right,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                ],
                              ),
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
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final Color textPrimary;
  final Color textSecondary;

  const _EmptyState({
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.book_fill,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              'No Study Plans Yet',
              style: TextStyle(
                fontSize: AppSizes.heading3,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Create your first study plan to start\ntracking your learning progress.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppSizes.body,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            NeuButton(
              label: 'Create Plan',
              icon: CupertinoIcons.add,
              onPressed: () => context.push('/study/plan/new'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekly Progress Bar Chart
// ---------------------------------------------------------------------------

class _WeeklyProgressChart extends StatelessWidget {
  final List<int> sessionCounts;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;

  const _WeeklyProgressChart({
    required this.sessionCounts,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final maxCount = sessionCounts.fold<int>(1, (a, b) => a > b ? a : b);
    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const barMaxHeight = 80.0;

    return NeuContainer(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Week',
            style: TextStyle(
              fontSize: AppSizes.heading4,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          SizedBox(
            height: barMaxHeight + 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final height = maxCount > 0
                    ? (sessionCounts[i] / maxCount) * barMaxHeight
                    : 0.0;
                final isToday = i == (DateTime.now().weekday - 1);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (sessionCounts[i] > 0)
                      Text(
                        '${sessionCounts[i]}',
                        style: TextStyle(
                          fontSize: AppSizes.caption,
                          fontWeight: FontWeight.w600,
                          color: isToday ? AppColors.primary : textSecondary,
                        ),
                      ),
                    const SizedBox(height: 2),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      width: 28,
                      height: height < 4 && sessionCounts[i] > 0
                          ? 4
                          : height,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.4),
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                    if (height == 0 && sessionCounts[i] == 0)
                      Container(
                        width: 28,
                        height: 2,
                        color: isDark
                            ? AppColors.textTertiaryDark
                                .withValues(alpha: 0.2)
                            : AppColors.textTertiaryLight
                                .withValues(alpha: 0.2),
                      ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      dayLabels[i],
                      style: TextStyle(
                        fontSize: AppSizes.caption,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        color: isToday ? AppColors.primary : textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
