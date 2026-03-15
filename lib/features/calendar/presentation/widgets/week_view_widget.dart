import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../providers/calendar_provider.dart';

class WeekViewWidget extends ConsumerWidget {
  const WeekViewWidget({super.key});

  static const double _hourHeight = 52.0;
  static const int _startHour = 6;
  static const int _endHour = 23;
  static const List<String> _dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    // Calculate Monday of the selected week
    final weekday = selectedDate.weekday; // 1=Mon, 7=Sun
    final startOfWeek = selectedDate.subtract(Duration(days: weekday - 1));
    final weekEvents = ref.watch(eventsForWeekProvider(startOfWeek));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final todayKey = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        // Day headers
        _buildDayHeaders(startOfWeek, todayKey, isDark, ref),
        const SizedBox(height: AppSizes.xs),
        // Scrollable hourly grid
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: (_endHour - _startHour + 1) * _hourHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Time column
                  _buildTimeColumn(isDark),
                  // 7 day columns
                  ...List.generate(7, (i) {
                    final day = DateTime(
                      startOfWeek.year,
                      startOfWeek.month,
                      startOfWeek.day + i,
                    );
                    final dayEvents = weekEvents[day] ?? [];
                    final isCurrentDay = day == todayKey;
                    return Expanded(
                      child: _buildDayColumn(
                        dayEvents,
                        isCurrentDay,
                        isDark,
                        context,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayHeaders(
    DateTime startOfWeek,
    DateTime today,
    bool isDark,
    WidgetRef ref,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      child: Row(
        children: [
          const SizedBox(width: 40), // time column spacer
          ...List.generate(7, (i) {
            final day = DateTime(
              startOfWeek.year,
              startOfWeek.month,
              startOfWeek.day + i,
            );
            final isToday = day == today;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(selectedDateProvider.notifier).state = day;
                  ref.read(calendarViewProvider.notifier).state = 0; // switch to day
                },
                child: Column(
                  children: [
                    Text(
                      _dayNames[i],
                      style: TextStyle(
                        fontSize: AppSizes.caption,
                        fontWeight: FontWeight.w500,
                        color: isToday
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: isToday
                          ? BoxDecoration(
                              color: AppColors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusFull),
                            )
                          : null,
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: AppSizes.bodySmall,
                          fontWeight:
                              isToday ? FontWeight.w700 : FontWeight.w500,
                          color: isToday
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(bool isDark) {
    return SizedBox(
      width: 40,
      child: Column(
        children: List.generate(_endHour - _startHour + 1, (i) {
          final hour = _startHour + i;
          return SizedBox(
            height: _hourHeight,
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  _formatHourShort(hour),
                  style: TextStyle(
                    fontSize: AppSizes.caption - 1,
                    color: isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiaryLight,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDayColumn(
    List<CalendarEvent> events,
    bool isCurrentDay,
    bool isDark,
    BuildContext context,
  ) {
    return Stack(
      children: [
        // Background hour grid lines
        Column(
          children: List.generate(_endHour - _startHour + 1, (i) {
            return Container(
              height: _hourHeight,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight)
                        .withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                  left: BorderSide(
                    color: (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiaryLight)
                        .withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
                color: isCurrentDay
                    ? AppColors.primary.withValues(alpha: 0.03)
                    : null,
              ),
            );
          }),
        ),
        // Event bars
        ...events.map((event) {
          final hour = event.dateTime.hour;
          final minute = event.dateTime.minute;
          if (hour < _startHour || hour > _endHour) {
            return const SizedBox.shrink();
          }
          final top = (hour - _startHour) * _hourHeight +
              (minute / 60.0) * _hourHeight;
          final duration = event.durationMinutes ?? 30;
          final height = (duration / 60.0) * _hourHeight;

          return Positioned(
            top: top,
            left: 1,
            right: 1,
            height: height.clamp(16.0, double.infinity),
            child: GestureDetector(
              onTap: () => _navigateToDetail(context, event),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(
                    horizontal: 2, vertical: 1),
                decoration: BoxDecoration(
                  color: event.color.withValues(alpha: isDark ? 0.4 : 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border(
                    left: BorderSide(color: event.color, width: 2),
                  ),
                ),
                child: Text(
                  event.title,
                  style: TextStyle(
                    fontSize: AppSizes.caption - 2,
                    fontWeight: FontWeight.w600,
                    color: event.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _navigateToDetail(BuildContext context, CalendarEvent event) {
    switch (event.type) {
      case 'todo':
        context.push('/todos/${event.id}');
        break;
      case 'task':
        context.push('/tasks/${event.id}');
        break;
      case 'study':
        context.push('/study/timer');
        break;
    }
  }

  String _formatHourShort(int hour) {
    if (hour == 0 || hour == 24) return '12a';
    if (hour == 12) return '12p';
    if (hour < 12) return '${hour}a';
    return '${hour - 12}p';
  }
}
