import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../todo/providers/todo_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../../study/providers/study_provider.dart';

// ---------------------------------------------------------------------------
// Date Range
// ---------------------------------------------------------------------------

enum DateRange { thisWeek, thisMonth, allTime }

final dateRangeProvider = StateProvider<DateRange>((ref) => DateRange.thisWeek);

// ---------------------------------------------------------------------------
// Analytics Data
// ---------------------------------------------------------------------------

class AnalyticsData {
  final int totalCompleted;
  final int totalItems;
  final double avgDailyCompletions;
  final int productivityStreak;
  final double totalStudyHours;
  final Map<DateTime, int> dailyTodoCompletions;
  final Map<DateTime, int> dailyTaskCompletions;
  final Map<String, int> statusDistribution;
  final Map<String, double> projectProgress;
  final Map<String, int> projectHealthIndices;
  final Map<String, int> priorityDistribution;
  final double productivityScore;
  final String grade;
  final Map<int, double> studyMinutesByDayOfWeek;
  final int totalSessions;
  final double avgSessionMinutes;
  final int mostProductiveDayOfWeek;

  const AnalyticsData({
    required this.totalCompleted,
    required this.totalItems,
    required this.avgDailyCompletions,
    required this.productivityStreak,
    required this.totalStudyHours,
    required this.dailyTodoCompletions,
    required this.dailyTaskCompletions,
    required this.statusDistribution,
    required this.projectProgress,
    required this.projectHealthIndices,
    required this.priorityDistribution,
    required this.productivityScore,
    required this.grade,
    required this.studyMinutesByDayOfWeek,
    required this.totalSessions,
    required this.avgSessionMinutes,
    required this.mostProductiveDayOfWeek,
  });

  static const empty = AnalyticsData(
    totalCompleted: 0,
    totalItems: 0,
    avgDailyCompletions: 0,
    productivityStreak: 0,
    totalStudyHours: 0,
    dailyTodoCompletions: {},
    dailyTaskCompletions: {},
    statusDistribution: {},
    projectProgress: {},
    projectHealthIndices: {},
    priorityDistribution: {},
    productivityScore: 0,
    grade: 'F',
    studyMinutesByDayOfWeek: {},
    totalSessions: 0,
    avgSessionMinutes: 0,
    mostProductiveDayOfWeek: 1,
  );
}

// ---------------------------------------------------------------------------
// Computed Analytics Provider
// ---------------------------------------------------------------------------

final analyticsDataProvider = Provider<AnalyticsData>((ref) {
  final todos = ref.watch(todoProvider);
  final tasks = ref.watch(taskProvider);
  final projects = ref.watch(projectProvider);
  final sessions = ref.watch(studySessionProvider);
  final range = ref.watch(dateRangeProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Determine the start date for filtering
  late final DateTime rangeStart;
  switch (range) {
    case DateRange.thisWeek:
      // Monday of current week
      rangeStart = today.subtract(Duration(days: today.weekday - 1));
      break;
    case DateRange.thisMonth:
      rangeStart = DateTime(now.year, now.month, 1);
      break;
    case DateRange.allTime:
      rangeStart = DateTime(2000);
      break;
  }

  // Filter items by range (use completedAt or createdAt)
  bool inRange(DateTime? date) {
    if (date == null) return false;
    return !date.isBefore(rangeStart);
  }

  // -- Completed counts --
  final completedTodos =
      todos.where((t) => t.isCompleted && inRange(t.completedAt)).toList();
  final completedTasks =
      tasks.where((t) => t.isCompleted && inRange(t.completedAt)).toList();
  final totalCompleted = completedTodos.length + completedTasks.length;
  final totalItems = todos.length + tasks.length;

  // -- Days in range --
  final daysInRange = now.difference(rangeStart).inDays + 1;
  final avgDaily =
      daysInRange > 0 ? totalCompleted / daysInRange : 0.0;

  // -- Daily completions for line chart --
  final dailyTodoCompletions = <DateTime, int>{};
  final dailyTaskCompletions = <DateTime, int>{};

  for (final todo in completedTodos) {
    if (todo.completedAt != null) {
      final day = DateTime(
        todo.completedAt!.year,
        todo.completedAt!.month,
        todo.completedAt!.day,
      );
      dailyTodoCompletions[day] = (dailyTodoCompletions[day] ?? 0) + 1;
    }
  }
  for (final task in completedTasks) {
    if (task.completedAt != null) {
      final day = DateTime(
        task.completedAt!.year,
        task.completedAt!.month,
        task.completedAt!.day,
      );
      dailyTaskCompletions[day] = (dailyTaskCompletions[day] ?? 0) + 1;
    }
  }

  // -- Productivity streak (consecutive days with completions going backward) --
  int streak = 0;
  DateTime checkDate = today;
  bool allowedSkip = true; // allow today to be missing on first check
  while (true) {
    final dayKey = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final hasTodo = dailyTodoCompletions.containsKey(dayKey);
    final hasTask = dailyTaskCompletions.containsKey(dayKey);
    if (hasTodo || hasTask) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
      allowedSkip = false;
    } else if (allowedSkip) {
      // Today has no completions yet; check yesterday instead
      allowedSkip = false;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      break;
    }
  }

  // -- Status distribution --
  final statusDist = <String, int>{};
  for (final status in TaskStatus.values) {
    if (status == TaskStatus.archived) continue;
    final count = todos.where((t) => t.status == status).length +
        tasks.where((t) => t.status == status).length;
    if (count > 0) {
      statusDist[status.label] = count;
    }
  }

  // -- Project progress --
  final projProgress = <String, double>{};
  final projHealthIndices = <String, int>{};
  for (final project in projects.where((p) => !p.isArchived)) {
    final projectTasks =
        tasks.where((t) => t.projectId == project.id).toList();
    if (projectTasks.isEmpty) {
      projProgress[project.name] = 0.0;
    } else {
      final done = projectTasks.where((t) => t.isCompleted).length;
      projProgress[project.name] = done / projectTasks.length;
    }
    projHealthIndices[project.name] = project.healthIndex;
  }

  // -- Priority distribution --
  final priorityDist = <String, int>{};
  for (final priority in TaskPriority.values) {
    final count = todos.where((t) => t.priority == priority).length +
        tasks.where((t) => t.priority == priority).length;
    if (count > 0) {
      priorityDist[priority.label] = count;
    }
  }

  // -- Study analytics --
  final filteredSessions = sessions
      .where((s) => s.isCompleted && inRange(s.startTime))
      .toList();

  double totalStudyMinutes = 0;
  final studyByDay = <int, double>{
    1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0,
  };
  for (final session in filteredSessions) {
    totalStudyMinutes += session.durationMinutes;
    final dow = session.startTime.weekday; // 1=Mon..7=Sun
    studyByDay[dow] = (studyByDay[dow] ?? 0) + session.durationMinutes;
  }

  final totalStudyHours = totalStudyMinutes / 60.0;
  final totalSessionCount = filteredSessions.length;
  final avgSessionMin = totalSessionCount > 0
      ? totalStudyMinutes / totalSessionCount
      : 0.0;

  // Most productive day of week
  int mostProductiveDay = 1;
  double maxMinutes = 0;
  studyByDay.forEach((day, minutes) {
    if (minutes > maxMinutes) {
      maxMinutes = minutes;
      mostProductiveDay = day;
    }
  });

  // -- Productivity score --
  final completionRate = totalItems > 0 ? totalCompleted / totalItems : 0.0;
  final streakBonus =
      streak >= 30 ? 1.0 : streak / 30.0;
  final studyBonus =
      totalStudyHours >= 20 ? 1.0 : totalStudyHours / 20.0;

  // On-time rate: items completed before dueDate / items that have a dueDate
  int onTimeCount = 0;
  int withDueDateCount = 0;
  for (final todo in todos) {
    if (todo.dueDate != null) {
      withDueDateCount++;
      if (todo.isCompleted &&
          todo.completedAt != null &&
          !todo.completedAt!.isAfter(todo.dueDate!)) {
        onTimeCount++;
      }
    }
  }
  for (final task in tasks) {
    if (task.dueDate != null) {
      withDueDateCount++;
      if (task.isCompleted &&
          task.completedAt != null &&
          !task.completedAt!.isAfter(task.dueDate!)) {
        onTimeCount++;
      }
    }
  }
  final onTimeRate =
      withDueDateCount > 0 ? onTimeCount / withDueDateCount : 0.0;

  final score = completionRate * 40 +
      streakBonus * 20 +
      studyBonus * 20 +
      onTimeRate * 20;

  String grade;
  if (score >= 90) {
    grade = 'A+';
  } else if (score >= 80) {
    grade = 'A';
  } else if (score >= 70) {
    grade = 'B';
  } else if (score >= 60) {
    grade = 'C';
  } else if (score >= 50) {
    grade = 'D';
  } else {
    grade = 'F';
  }

  return AnalyticsData(
    totalCompleted: totalCompleted,
    totalItems: totalItems,
    avgDailyCompletions: avgDaily,
    productivityStreak: streak,
    totalStudyHours: totalStudyHours,
    dailyTodoCompletions: dailyTodoCompletions,
    dailyTaskCompletions: dailyTaskCompletions,
    statusDistribution: statusDist,
    projectProgress: projProgress,
    projectHealthIndices: projHealthIndices,
    priorityDistribution: priorityDist,
    productivityScore: score,
    grade: grade,
    studyMinutesByDayOfWeek: studyByDay,
    totalSessions: totalSessionCount,
    avgSessionMinutes: avgSessionMin,
    mostProductiveDayOfWeek: mostProductiveDay,
  );
});
