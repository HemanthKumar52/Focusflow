import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../providers/calendar_provider.dart';

class DayViewWidget extends ConsumerWidget {
  const DayViewWidget({super.key});

  static const int _startHour = 6;
  static const int _endHour = 23;
  static const double _hourHeight = 64.0;
  static const double _timeColumnWidth = 56.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final events = ref.watch(eventsForSelectedDateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    // Split events into all-day (midnight / no specific time) and timed
    final allDayEvents = <CalendarEvent>[];
    final timedEvents = <CalendarEvent>[];
    for (final event in events) {
      if (event.dateTime.hour == 0 && event.dateTime.minute == 0) {
        allDayEvents.add(event);
      } else {
        timedEvents.add(event);
      }
    }

    return Column(
      children: [
        // All-day section
        if (allDayEvents.isNotEmpty) _buildAllDaySection(allDayEvents, isDark),
        // Hourly timeline
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: (_endHour - _startHour + 1) * _hourHeight,
              child: Stack(
                children: [
                  // Hour lines
                  ...List.generate(_endHour - _startHour + 1, (i) {
                    final hour = _startHour + i;
                    return Positioned(
                      top: i * _hourHeight,
                      left: 0,
                      right: 0,
                      child: _buildHourRow(hour, isDark),
                    );
                  }),
                  // Event blocks
                  ...timedEvents.map((event) =>
                      _buildEventBlock(event, isDark, context)),
                  // Current time indicator
                  if (isToday) _buildCurrentTimeIndicator(now),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllDaySection(List<CalendarEvent> events, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.md, AppSizes.sm, AppSizes.md, AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Day',
            style: TextStyle(
              fontSize: AppSizes.bodySmall,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          ...events.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.xs),
                child: NeuContainer(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: AppSizes.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: e.color,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Icon(_iconForType(e.type), size: AppSizes.iconSm,
                          color: e.color),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          e.title,
                          style: TextStyle(
                            fontSize: AppSizes.bodySmall,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          Divider(
            color: (isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight)
                .withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildHourRow(int hour, bool isDark) {
    final label = _formatHour(hour);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _timeColumnWidth,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSizes.sm),
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: AppSizes.caption,
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: (isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight)
                .withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _buildEventBlock(
      CalendarEvent event, bool isDark, BuildContext context) {
    final hour = event.dateTime.hour;
    final minute = event.dateTime.minute;
    if (hour < _startHour || hour > _endHour) return const SizedBox.shrink();

    final top =
        (hour - _startHour) * _hourHeight + (minute / 60.0) * _hourHeight;
    final duration = event.durationMinutes ?? 30;
    final height = (duration / 60.0) * _hourHeight;

    return Positioned(
      top: top,
      left: _timeColumnWidth + AppSizes.xs,
      right: AppSizes.md,
      height: height.clamp(24.0, double.infinity),
      child: NeuContainer(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm, vertical: AppSizes.xs),
        color: event.color.withValues(alpha: isDark ? 0.3 : 0.15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_iconForType(event.type),
                    size: AppSizes.iconSm - 4, color: event.color),
                const SizedBox(width: AppSizes.xs),
                Expanded(
                  child: Text(
                    event.title,
                    style: TextStyle(
                      fontSize: AppSizes.caption,
                      fontWeight: FontWeight.w600,
                      color: event.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (height > 32)
              Text(
                '${_formatHour(hour)}:${minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: AppSizes.caption - 1,
                  color: event.color.withValues(alpha: 0.7),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(DateTime now) {
    if (now.hour < _startHour || now.hour > _endHour) {
      return const SizedBox.shrink();
    }
    final top = (now.hour - _startHour) * _hourHeight +
        (now.minute / 60.0) * _hourHeight;
    return Positioned(
      top: top,
      left: _timeColumnWidth - 4,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.danger,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(height: 2, color: AppColors.danger),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12 AM';
    if (hour == 12) return '12 PM';
    if (hour < 12) return '$hour AM';
    return '${hour - 12} PM';
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'todo':
        return CupertinoIcons.checkmark_circle;
      case 'task':
        return CupertinoIcons.square_stack;
      case 'study':
        return CupertinoIcons.book;
      default:
        return CupertinoIcons.circle;
    }
  }
}
