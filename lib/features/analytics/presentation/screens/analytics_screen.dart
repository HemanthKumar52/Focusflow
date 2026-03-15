import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../../core/widgets/neu_card.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_progress_ring.dart';
import '../../../../core/widgets/neu_tab_bar.dart';
import '../../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(analyticsDataProvider);
    final rangeIndex = ref.watch(dateRangeProvider).index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // -- App Bar --
          SliverAppBar(
            pinned: true,
            title: Text(
              'Analytics',
              style: TextStyle(
                fontSize: AppSizes.heading3,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
            ),
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),

          // -- Date Range Selector --
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: NeuTabBar(
                tabs: const ['This Week', 'This Month', 'All Time'],
                selectedIndex: rangeIndex,
                onTabChanged: (index) {
                  ref.read(dateRangeProvider.notifier).state =
                      DateRange.values[index];
                },
              ),
            ),
          ),

          // -- Content --
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: AppSizes.sm),

                // Overview Cards
                _OverviewCardsRow(data: data),
                const SizedBox(height: AppSizes.md),

                // Completion Rate Chart
                _CompletionRateChart(data: data),
                const SizedBox(height: AppSizes.sm),

                // Status Distribution
                _StatusDistribution(data: data),
                const SizedBox(height: AppSizes.sm),

                // Project Progress
                if (data.projectProgress.isNotEmpty) ...[
                  _ProjectProgressSection(data: data),
                  const SizedBox(height: AppSizes.sm),
                ],

                // Study Analytics
                _StudyAnalyticsSection(data: data),
                const SizedBox(height: AppSizes.sm),

                // Priority Distribution
                _PriorityDistribution(data: data),
                const SizedBox(height: AppSizes.sm),

                // Productivity Score
                _ProductivityScoreCard(data: data),
                const SizedBox(height: AppSizes.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Overview Cards Row
// =============================================================================

class _OverviewCardsRow extends StatelessWidget {
  final AnalyticsData data;
  const _OverviewCardsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completionPct = data.totalItems > 0
        ? (data.totalCompleted / data.totalItems * 100).round()
        : 0;

    final cards = [
      _OverviewCardData(
        icon: CupertinoIcons.checkmark_circle_fill,
        iconColor: AppColors.success,
        value: '${data.totalCompleted}',
        label: 'Completed',
        subtitle: '$completionPct%',
        trendUp: data.totalCompleted > 0,
      ),
      _OverviewCardData(
        icon: CupertinoIcons.chart_bar_fill,
        iconColor: AppColors.primary,
        value: data.avgDailyCompletions.toStringAsFixed(1),
        label: 'Daily Avg',
        subtitle: 'items/day',
        trendUp: data.avgDailyCompletions >= 1,
      ),
      _OverviewCardData(
        icon: CupertinoIcons.flame_fill,
        iconColor: AppColors.warning,
        value: '${data.productivityStreak}',
        label: 'Streak',
        subtitle: 'days',
        trendUp: data.productivityStreak >= 3,
      ),
      _OverviewCardData(
        icon: CupertinoIcons.book_fill,
        iconColor: AppColors.info,
        value: data.totalStudyHours.toStringAsFixed(1),
        label: 'Study Hours',
        subtitle: 'total',
        trendUp: data.totalStudyHours >= 1,
      ),
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSizes.sm),
        itemBuilder: (context, index) {
          final card = cards[index];
          return SizedBox(
            width: 140,
            child: NeuContainer(
              padding: const EdgeInsets.all(AppSizes.sm + 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(card.icon, size: 20, color: card.iconColor),
                      const Spacer(),
                      Icon(
                        card.trendUp
                            ? CupertinoIcons.arrow_up_right
                            : CupertinoIcons.arrow_down_right,
                        size: 14,
                        color: card.trendUp
                            ? AppColors.success
                            : AppColors.danger,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.value,
                    style: TextStyle(
                      fontSize: AppSizes.heading2,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.label,
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    card.subtitle,
                    style: TextStyle(
                      fontSize: AppSizes.caption,
                      color: isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewCardData {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String subtitle;
  final bool trendUp;

  const _OverviewCardData({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.subtitle,
    required this.trendUp,
  });
}

// =============================================================================
// Completion Rate Chart
// =============================================================================

class _CompletionRateChart extends StatelessWidget {
  final AnalyticsData data;
  const _CompletionRateChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Merge all dates and sort
    final allDates = <DateTime>{
      ...data.dailyTodoCompletions.keys,
      ...data.dailyTaskCompletions.keys,
    }.toList()
      ..sort();

    // If no data, show placeholder
    if (allDates.isEmpty) {
      return NeuCard(
        title: 'Completion Rate',
        child: SizedBox(
          height: 200,
          child: Center(
            child: Text(
              'No completions yet',
              style: TextStyle(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ),
        ),
      );
    }

    // Build spots
    final todoSpots = <FlSpot>[];
    final taskSpots = <FlSpot>[];
    final labels = <String>[];

    for (int i = 0; i < allDates.length; i++) {
      final date = allDates[i];
      todoSpots.add(FlSpot(
        i.toDouble(),
        (data.dailyTodoCompletions[date] ?? 0).toDouble(),
      ));
      taskSpots.add(FlSpot(
        i.toDouble(),
        (data.dailyTaskCompletions[date] ?? 0).toDouble(),
      ));
      labels.add(DateFormat('d/M').format(date));
    }

    final maxY = [
      ...todoSpots.map((s) => s.y),
      ...taskSpots.map((s) => s.y),
    ].fold<double>(1, math.max);

    return NeuCard(
      title: 'Completion Rate',
      child: SizedBox(
        height: 220,
        child: Padding(
          padding: const EdgeInsets.only(top: AppSizes.sm, right: AppSizes.sm),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY + 1,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: math.max(1, (maxY / 4).ceilToDouble()),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
                      .withValues(alpha: 0.2),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: math.max(1, (allDates.length / 6).ceilToDouble()),
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          labels[idx],
                          style: TextStyle(
                            fontSize: AppSizes.caption,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: math.max(1, (maxY / 4).ceilToDouble()),
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: AppSizes.caption,
                          color: isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Todos line (purple)
                LineChartBarData(
                  spots: todoSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: allDates.length <= 14,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.primary,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.3),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Tasks line (blue)
                LineChartBarData(
                  spots: taskSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: AppColors.info,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: allDates.length <= 14,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.info,
                      strokeWidth: 0,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.info.withValues(alpha: 0.25),
                        AppColors.info.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) =>
                      isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Status Distribution (Pie Chart)
// =============================================================================

class _StatusDistribution extends StatelessWidget {
  final AnalyticsData data;
  const _StatusDistribution({required this.data});

  static const _statusColors = {
    'Not Started': AppColors.statusNotStarted,
    'In Progress': AppColors.statusInProgress,
    'Pending': AppColors.statusPending,
    'Completed': AppColors.statusCompleted,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dist = data.statusDistribution;

    if (dist.isEmpty) {
      return NeuCard(
        title: 'Status Distribution',
        child: SizedBox(
          height: 160,
          child: Center(
            child: Text(
              'No items yet',
              style: TextStyle(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ),
        ),
      );
    }

    final total = dist.values.fold<int>(0, (a, b) => a + b);

    final sections = dist.entries.map((entry) {
      final color = _statusColors[entry.key] ?? AppColors.textTertiaryLight;
      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        color: color,
        radius: 50,
        title: '${pct.round()}%',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return NeuCard(
      title: 'Status Distribution',
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 36,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Wrap(
            spacing: AppSizes.md,
            runSpacing: AppSizes.xs,
            children: dist.entries.map((entry) {
              final color = _statusColors[entry.key] ?? AppColors.textTertiaryLight;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.key} (${entry.value})',
                    style: TextStyle(
                      fontSize: AppSizes.caption,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Project Progress
// =============================================================================

class _ProjectProgressSection extends StatelessWidget {
  final AnalyticsData data;
  const _ProjectProgressSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Sort by completion percentage descending
    final entries = data.projectProgress.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return NeuCard(
      title: 'Project Progress',
      child: Column(
        children: entries.map((entry) {
          final healthIndex = data.projectHealthIndices[entry.key] ?? 0;
          final health = ProjectHealth.values[healthIndex.clamp(0, ProjectHealth.values.length - 1)];
          final pct = (entry.value * 100).round();

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm + 4),
            child: Row(
              children: [
                NeuProgressRing(
                  progress: entry.value,
                  size: 48,
                  strokeWidth: 5,
                  progressColor: _progressColor(entry.value),
                  center: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: AppSizes.caption,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm + 4),
                Expanded(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: AppSizes.body,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                NeuBadge(
                  label: health.label,
                  color: health.color,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _progressColor(double value) {
    if (value >= 0.75) return AppColors.success;
    if (value >= 0.4) return AppColors.warning;
    return AppColors.primary;
  }
}

// =============================================================================
// Study Analytics
// =============================================================================

class _StudyAnalyticsSection extends StatelessWidget {
  final AnalyticsData data;
  const _StudyAnalyticsSection({required this.data});

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final mostProductiveLabel =
        _dayLabels[(data.mostProductiveDayOfWeek - 1).clamp(0, 6)];

    // Bar chart data
    final maxMinutes = data.studyMinutesByDayOfWeek.values
        .fold<double>(1, math.max);

    final barGroups = List.generate(7, (i) {
      final dayIndex = i + 1; // 1=Mon..7=Sun
      final minutes = data.studyMinutesByDayOfWeek[dayIndex] ?? 0;
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: minutes,
            width: 20,
            color: AppColors.secondary,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxMinutes,
              color: (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight)
                  .withValues(alpha: 0.12),
            ),
          ),
        ],
      );
    });

    return NeuCard(
      title: 'Study Analytics',
      child: Column(
        children: [
          // Summary row
          Row(
            children: [
              _StudyStat(
                label: 'Total Hours',
                value: data.totalStudyHours.toStringAsFixed(1),
                icon: CupertinoIcons.time,
              ),
              _StudyStat(
                label: 'Sessions',
                value: '${data.totalSessions}',
                icon: CupertinoIcons.play_circle,
              ),
              _StudyStat(
                label: 'Avg Duration',
                value: '${data.avgSessionMinutes.round()}m',
                icon: CupertinoIcons.timer,
              ),
              _StudyStat(
                label: 'Best Day',
                value: mostProductiveLabel,
                icon: CupertinoIcons.star_fill,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),

          // Bar chart
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxMinutes + 5,
                barGroups: barGroups,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: math.max(1, (maxMinutes / 4).ceilToDouble()),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight)
                        .withValues(alpha: 0.15),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: math.max(1, (maxMinutes / 4).ceilToDouble()),
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}m',
                          style: TextStyle(
                            fontSize: AppSizes.caption,
                            color: isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiaryLight,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= _dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _dayLabels[idx],
                            style: TextStyle(
                              fontSize: AppSizes.caption,
                              color: textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()} min',
                        TextStyle(
                          fontSize: AppSizes.caption,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StudyStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.body,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.caption,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Priority Distribution (Horizontal Bar Chart)
// =============================================================================

class _PriorityDistribution extends StatelessWidget {
  final AnalyticsData data;
  const _PriorityDistribution({required this.data});

  static const _priorityColors = {
    'Urgent': AppColors.priorityUrgent,
    'High': AppColors.priorityHigh,
    'Normal': AppColors.priorityNormal,
    'Low': AppColors.priorityLow,
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dist = data.priorityDistribution;

    if (dist.isEmpty) {
      return NeuCard(
        title: 'Priority Distribution',
        child: SizedBox(
          height: 80,
          child: Center(
            child: Text(
              'No items yet',
              style: TextStyle(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ),
        ),
      );
    }

    final maxVal = dist.values.fold<int>(1, math.max);
    // Order: Urgent, High, Normal, Low
    final orderedKeys = ['Urgent', 'High', 'Normal', 'Low'];

    return NeuCard(
      title: 'Priority Distribution',
      child: Column(
        children: orderedKeys.where((k) => dist.containsKey(k)).map((key) {
          final count = dist[key] ?? 0;
          final color = _priorityColors[key] ?? AppColors.textTertiaryLight;
          final fraction = maxVal > 0 ? count / maxVal : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 18,
                      backgroundColor: (isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiaryLight)
                          .withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                SizedBox(
                  width: 28,
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// =============================================================================
// Productivity Score
// =============================================================================

class _ProductivityScoreCard extends StatelessWidget {
  final AnalyticsData data;
  const _ProductivityScoreCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = data.productivityScore.round();
    final grade = data.grade;

    Color gradeColor;
    if (score >= 80) {
      gradeColor = AppColors.success;
    } else if (score >= 60) {
      gradeColor = AppColors.warning;
    } else {
      gradeColor = AppColors.danger;
    }

    return NeuCard(
      title: 'Productivity Score',
      child: Column(
        children: [
          const SizedBox(height: AppSizes.sm),
          Center(
            child: NeuProgressRing(
              progress: score / 100.0,
              size: 140,
              strokeWidth: 12,
              progressColor: gradeColor,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: AppSizes.heading1,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  Text(
                    grade,
                    style: TextStyle(
                      fontSize: AppSizes.heading4,
                      fontWeight: FontWeight.w700,
                      color: gradeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // Breakdown
          _ScoreBreakdownRow(
            label: 'Completion Rate',
            weight: '40%',
            value: data.totalItems > 0
                ? '${(data.totalCompleted / data.totalItems * 100).round()}%'
                : '0%',
            color: AppColors.primary,
          ),
          _ScoreBreakdownRow(
            label: 'Streak Bonus',
            weight: '20%',
            value: '${data.productivityStreak} days',
            color: AppColors.warning,
          ),
          _ScoreBreakdownRow(
            label: 'Study Time',
            weight: '20%',
            value: '${data.totalStudyHours.toStringAsFixed(1)}h',
            color: AppColors.info,
          ),
          _ScoreBreakdownRow(
            label: 'On-Time Delivery',
            weight: '20%',
            value: '${_onTimePercent(data)}%',
            color: AppColors.success,
          ),
        ],
      ),
    );
  }

  int _onTimePercent(AnalyticsData data) {
    // Derive on-time rate from score components.
    // Score = completionRate*40 + streakBonus*20 + studyBonus*20 + onTimeRate*20
    // onTimeRate*20 = score - (completionRate*40 + streakBonus*20 + studyBonus*20)
    final completionRate =
        data.totalItems > 0 ? data.totalCompleted / data.totalItems : 0.0;
    final streakBonus = math.min(data.productivityStreak / 30.0, 1.0);
    final studyBonus = math.min(data.totalStudyHours / 20.0, 1.0);
    final otherContrib = completionRate * 40 + streakBonus * 20 + studyBonus * 20;
    final onTimePart = data.productivityScore - otherContrib;
    final onTimeRate = (onTimePart / 20).clamp(0.0, 1.0);
    return (onTimeRate * 100).round();
  }
}

class _ScoreBreakdownRow extends StatelessWidget {
  final String label;
  final String weight;
  final String value;
  final Color color;

  const _ScoreBreakdownRow({
    required this.label,
    required this.weight,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs + 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.bodySmall,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            weight,
            style: TextStyle(
              fontSize: AppSizes.caption,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: AppSizes.bodySmall,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
