import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../todo/providers/todo_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../study/providers/study_provider.dart';

// ---------------------------------------------------------------------------
// CalendarEvent — computed view model (not persisted)
// ---------------------------------------------------------------------------

class CalendarEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final String type; // 'todo' | 'task' | 'study'
  final int priorityIndex;
  final int statusIndex;
  final Color color;
  final int? durationMinutes;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.type,
    this.priorityIndex = 2,
    this.statusIndex = 0,
    required this.color,
    this.durationMinutes,
  });
}

// ---------------------------------------------------------------------------
// View state providers
// ---------------------------------------------------------------------------

/// 0 = Day, 1 = Week, 2 = Month
final calendarViewProvider = StateProvider<int>((ref) => 2);

final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// ---------------------------------------------------------------------------
// Aggregation
// ---------------------------------------------------------------------------

DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

final calendarEventsProvider =
    Provider<Map<DateTime, List<CalendarEvent>>>((ref) {
  final todos = ref.watch(todoProvider);
  final tasks = ref.watch(taskProvider);
  final sessions = ref.watch(studySessionProvider);

  final map = <DateTime, List<CalendarEvent>>{};

  void addEvent(DateTime date, CalendarEvent event) {
    final key = _dateOnly(date);
    map.putIfAbsent(key, () => []);
    map[key]!.add(event);
  }

  // Todos
  for (final todo in todos) {
    if (todo.dueDate != null) {
      addEvent(
        todo.dueDate!,
        CalendarEvent(
          id: todo.id,
          title: todo.title,
          dateTime: todo.dueDate!,
          type: 'todo',
          priorityIndex: todo.priorityIndex,
          statusIndex: todo.statusIndex,
          color: AppColors.primary, // purple for todos
        ),
      );
    }
  }

  // Tasks
  for (final task in tasks) {
    if (task.dueDate != null) {
      addEvent(
        task.dueDate!,
        CalendarEvent(
          id: task.id,
          title: task.title,
          dateTime: task.dueDate!,
          type: 'task',
          priorityIndex: task.priorityIndex,
          statusIndex: task.statusIndex,
          color: AppColors.info, // blue for tasks
        ),
      );
    }
  }

  // Study sessions
  for (final session in sessions) {
    addEvent(
      session.startTime,
      CalendarEvent(
        id: session.id,
        title: 'Study Session',
        dateTime: session.startTime,
        type: 'study',
        priorityIndex: 2,
        statusIndex: session.isCompleted ? 3 : 0,
        color: AppColors.secondary, // teal for study
        durationMinutes: session.durationMinutes,
      ),
    );
  }

  // Sort events within each day by time
  for (final key in map.keys) {
    map[key]!.sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  return map;
});

// ---------------------------------------------------------------------------
// Filtered providers
// ---------------------------------------------------------------------------

final eventsForSelectedDateProvider = Provider<List<CalendarEvent>>((ref) {
  final selected = ref.watch(selectedDateProvider);
  final allEvents = ref.watch(calendarEventsProvider);
  return allEvents[_dateOnly(selected)] ?? [];
});

final eventsForDateProvider =
    Provider.family<List<CalendarEvent>, DateTime>((ref, date) {
  final allEvents = ref.watch(calendarEventsProvider);
  return allEvents[_dateOnly(date)] ?? [];
});

final eventsForWeekProvider =
    Provider.family<Map<DateTime, List<CalendarEvent>>, DateTime>(
        (ref, startOfWeek) {
  final allEvents = ref.watch(calendarEventsProvider);
  final map = <DateTime, List<CalendarEvent>>{};
  for (int i = 0; i < 7; i++) {
    final day = _dateOnly(startOfWeek.add(Duration(days: i)));
    map[day] = allEvents[day] ?? [];
  }
  return map;
});
