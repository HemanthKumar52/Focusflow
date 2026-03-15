import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_container.dart';

/// GitHub-style activity heatmap showing study sessions per day.
///
/// Takes a [data] map of `DateTime -> int` (date to session count)
/// and renders a 13-week grid (91 days) with colored squares.
class HeatmapWidget extends StatelessWidget {
  final Map<DateTime, int> data;

  const HeatmapWidget({super.key, required this.data});

  /// Normalise a DateTime to midnight so lookups are consistent.
  static DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Lookup count for a given date.
  int _countFor(DateTime date) {
    final key = _normalise(date);
    for (final entry in data.entries) {
      final entryKey = _normalise(entry.key);
      if (entryKey == key) return entry.value;
    }
    return 0;
  }

  Color _colorForCount(int count, bool isDark) {
    if (count <= 0) {
      return isDark
          ? AppColors.surfaceDark.withValues(alpha: 0.5)
          : AppColors.shadowLightBottom.withValues(alpha: 0.12);
    }
    if (count == 1) return const Color(0xFF9BE9A8);
    if (count == 2) return const Color(0xFF40C463);
    return const Color(0xFF216E39);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Build 13 weeks of data ending today.
    final today = _normalise(DateTime.now());
    const totalWeeks = 13;
    const daysPerWeek = 7;

    // Find the Monday of the earliest week.
    final endDay = today;
    final startDay =
        endDay.subtract(Duration(days: totalWeeks * daysPerWeek - 1));
    // Align to Monday.
    final startMonday =
        startDay.subtract(Duration(days: (startDay.weekday - 1) % 7));

    // Collect all weeks as columns.
    final List<List<DateTime?>> weeks = [];
    DateTime cursor = startMonday;
    while (cursor.isBefore(endDay.add(const Duration(days: 1)))) {
      final List<DateTime?> week = [];
      for (int d = 0; d < daysPerWeek; d++) {
        final day = cursor.add(Duration(days: d));
        if (day.isAfter(endDay)) {
          week.add(null);
        } else {
          week.add(day);
        }
      }
      weeks.add(week);
      cursor = cursor.add(const Duration(days: daysPerWeek));
    }

    const double cellSize = 14.0;
    const double cellGap = 3.0;

    // Month labels: detect when a new month starts in each week column.
    final List<String> monthLabels = [];
    final List<int> monthPositions = [];
    int? lastMonth;
    for (int w = 0; w < weeks.length; w++) {
      // Use the Monday (first day) of the week.
      final firstDay = weeks[w].firstWhere((d) => d != null, orElse: () => null);
      if (firstDay != null && firstDay.month != lastMonth) {
        monthLabels.add(DateFormat('MMM').format(firstDay));
        monthPositions.add(w);
        lastMonth = firstDay.month;
      }
    }

    const dayLabels = ['', 'M', '', 'W', '', 'F', ''];
    const double labelWidth = 20.0;

    return NeuContainer(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: TextStyle(
              fontSize: AppSizes.heading4,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Month labels row
          SizedBox(
            height: 16,
            child: Row(
              children: [
                const SizedBox(width: labelWidth),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          for (int i = 0; i < monthLabels.length; i++)
                            Positioned(
                              left: monthPositions[i] * (cellSize + cellGap),
                              child: Text(
                                monthLabels[i],
                                style: TextStyle(
                                  fontSize: AppSizes.caption,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.xs),

          // Heatmap grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Column(
                children: List.generate(daysPerWeek, (i) {
                  return SizedBox(
                    width: labelWidth,
                    height: cellSize + cellGap,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        dayLabels[i],
                        style: TextStyle(
                          fontSize: AppSizes.caption - 1,
                          color: textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              // Grid cells
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (int w = 0; w < weeks.length; w++)
                        Column(
                          children: [
                            for (int d = 0; d < daysPerWeek; d++)
                              Padding(
                                padding: const EdgeInsets.all(cellGap / 2),
                                child: _HeatmapCell(
                                  date: weeks[w][d],
                                  count: weeks[w][d] != null
                                      ? _countFor(weeks[w][d]!)
                                      : 0,
                                  color: _colorForCount(
                                    weeks[w][d] != null
                                        ? _countFor(weeks[w][d]!)
                                        : 0,
                                    isDark,
                                  ),
                                  size: cellSize,
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(fontSize: AppSizes.caption, color: textSecondary),
              ),
              const SizedBox(width: 4),
              _LegendSquare(color: _colorForCount(0, isDark), size: 10),
              const SizedBox(width: 2),
              _LegendSquare(color: _colorForCount(1, isDark), size: 10),
              const SizedBox(width: 2),
              _LegendSquare(color: _colorForCount(2, isDark), size: 10),
              const SizedBox(width: 2),
              _LegendSquare(color: _colorForCount(3, isDark), size: 10),
              const SizedBox(width: 4),
              Text(
                'More',
                style: TextStyle(fontSize: AppSizes.caption, color: textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapCell extends StatelessWidget {
  final DateTime? date;
  final int count;
  final Color color;
  final double size;

  const _HeatmapCell({
    required this.date,
    required this.count,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return SizedBox(width: size, height: size);
    }

    return Tooltip(
      message: '${DateFormat('MMM d, y').format(date!)} - $count session${count == 1 ? '' : 's'}',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _LegendSquare extends StatelessWidget {
  final Color color;
  final double size;

  const _LegendSquare({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
