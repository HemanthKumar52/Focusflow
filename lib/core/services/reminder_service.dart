import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/enums.dart';
import 'notification_service.dart';
import 'database_service.dart';

enum ReminderPriority { urgent, high, normal, low }

class ReminderService {
  final NotificationService _notificationService;

  ReminderService(this._notificationService);

  /// Schedule auto-reminders based on priority and due date.
  ///
  /// Priority Urgent: 24h + 2h before due
  /// Priority High: 12h before due
  /// Priority Normal: 9 AM on due date
  /// Priority Low: 9 AM on due date only if incomplete
  Future<void> scheduleAutoReminder({
    required String id,
    required String title,
    required String body,
    required DateTime dueDate,
    required ReminderPriority priority,
    bool isCompleted = false,
  }) async {
    // Cancel any existing reminders for this item
    await cancelReminder(id);

    final now = DateTime.now();

    switch (priority) {
      case ReminderPriority.urgent:
        // 24 hours before due
        final reminder24h = dueDate.subtract(const Duration(hours: 24));
        if (reminder24h.isAfter(now)) {
          await _scheduleAt(
            id: '${id}_24h',
            title: '⏰ Due Tomorrow: $title',
            body: body,
            scheduledDate: reminder24h,
          );
        }
        // 2 hours before due
        final reminder2h = dueDate.subtract(const Duration(hours: 2));
        if (reminder2h.isAfter(now)) {
          await _scheduleAt(
            id: '${id}_2h',
            title: '🔴 Due Soon: $title',
            body: '$body - Due in 2 hours!',
            scheduledDate: reminder2h,
          );
        }
        break;

      case ReminderPriority.high:
        // 12 hours before due
        final reminder12h = dueDate.subtract(const Duration(hours: 12));
        if (reminder12h.isAfter(now)) {
          await _scheduleAt(
            id: '${id}_12h',
            title: '🟠 Due Today: $title',
            body: body,
            scheduledDate: reminder12h,
          );
        }
        break;

      case ReminderPriority.normal:
        // 9 AM on due date
        final reminderMorning = DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0);
        if (reminderMorning.isAfter(now)) {
          await _scheduleAt(
            id: '${id}_morning',
            title: '📋 Due Today: $title',
            body: body,
            scheduledDate: reminderMorning,
          );
        }
        break;

      case ReminderPriority.low:
        // 9 AM on due date, only if incomplete
        if (!isCompleted) {
          final reminderMorning = DateTime(dueDate.year, dueDate.month, dueDate.day, 9, 0);
          if (reminderMorning.isAfter(now)) {
            await _scheduleAt(
              id: '${id}_low',
              title: '📝 Reminder: $title',
              body: body,
              scheduledDate: reminderMorning,
            );
          }
        }
        break;
    }

    // Schedule overdue escalation if the due date is approaching
    await _scheduleOverdueEscalation(
      id: id,
      title: title,
      body: body,
      dueDate: dueDate,
    );
  }

  /// Schedule overdue escalation reminders:
  /// 1h after due, 4h after due, next morning at 9 AM
  Future<void> _scheduleOverdueEscalation({
    required String id,
    required String title,
    required String body,
    required DateTime dueDate,
  }) async {
    final now = DateTime.now();

    // 1 hour after due
    final overdue1h = dueDate.add(const Duration(hours: 1));
    if (overdue1h.isAfter(now)) {
      await _scheduleAt(
        id: '${id}_overdue_1h',
        title: '⚠️ Overdue: $title',
        body: '$body - 1 hour overdue',
        scheduledDate: overdue1h,
      );
    }

    // 4 hours after due
    final overdue4h = dueDate.add(const Duration(hours: 4));
    if (overdue4h.isAfter(now)) {
      await _scheduleAt(
        id: '${id}_overdue_4h',
        title: '🚨 Still Overdue: $title',
        body: '$body - 4 hours overdue!',
        scheduledDate: overdue4h,
      );
    }

    // Next morning at 9 AM
    final nextMorning = dueDate.add(const Duration(days: 1));
    final overdueNextMorning = DateTime(nextMorning.year, nextMorning.month, nextMorning.day, 9, 0);
    if (overdueNextMorning.isAfter(now)) {
      await _scheduleAt(
        id: '${id}_overdue_morning',
        title: '📌 Overdue Task: $title',
        body: '$body - This was due yesterday',
        scheduledDate: overdueNextMorning,
      );
    }
  }

  /// Schedule daily digest notification at the configured hour (default 8 AM).
  Future<void> scheduleDailyDigest({int hour = 8}) async {
    final now = DateTime.now();
    var digestTime = DateTime(now.year, now.month, now.day, hour, 0);

    // If today's digest time has passed, schedule for tomorrow
    if (digestTime.isBefore(now)) {
      digestTime = digestTime.add(const Duration(days: 1));
    }

    await _scheduleAt(
      id: 'daily_digest',
      title: '📊 Your Daily Focus',
      body: 'Check your tasks and plan your day',
      scheduledDate: digestTime,
    );
  }

  /// Cancel all reminders associated with a given item ID.
  Future<void> cancelReminder(String id) async {
    final suffixes = ['_24h', '_12h', '_2h', '_morning', '_low', '_overdue_1h', '_overdue_4h', '_overdue_morning'];
    for (final suffix in suffixes) {
      await _notificationService.cancelNotification(_generateNotificationId('$id$suffix'));
    }
  }

  /// Reschedule reminders for all active (incomplete) items.
  Future<void> reschedule() async {
    // Cancel all existing notifications
    await _notificationService.cancelAll();

    // Reschedule daily digest
    await scheduleDailyDigest();

    // Reschedule todo reminders
    final todos = DatabaseService.todos.values.where((t) => !t.isCompleted && t.dueDate != null);
    for (final todo in todos) {
      await scheduleAutoReminder(
        id: 'todo_${todo.id}',
        title: todo.title,
        body: todo.notes ?? '',
        dueDate: todo.dueDate!,
        priority: _mapStringToPriority(todo.priority.label),
        isCompleted: todo.isCompleted,
      );
    }

    // Reschedule task reminders
    final tasks = DatabaseService.tasks.values.where((t) => t.status != TaskStatus.completed && t.dueDate != null);
    for (final task in tasks) {
      await scheduleAutoReminder(
        id: 'task_${task.id}',
        title: task.title,
        body: task.description ?? '',
        dueDate: task.dueDate!,
        priority: _mapStringToPriority(task.priority.label),
        isCompleted: task.status == TaskStatus.completed,
      );
    }
  }

  /// Suggest optimal reminder times based on user activity patterns.
  /// Only activates after 7+ days of usage data.
  List<DateTime> suggestReminderTimes() {
    final settingsBox = DatabaseService.settings;
    final firstUseDate = settingsBox.get('firstUseDate') as DateTime?;
    if (firstUseDate == null) {
      settingsBox.put('firstUseDate', DateTime.now());
      return [];
    }

    final daysSinceFirstUse = DateTime.now().difference(firstUseDate).inDays;
    if (daysSinceFirstUse < 7) return [];

    // Analyze activity patterns from completed items
    final completedTodos = DatabaseService.todos.values.where((t) => t.isCompleted);
    final Map<int, int> hourFrequency = {};

    for (final todo in completedTodos) {
      if (todo.completedAt != null) {
        final hour = todo.completedAt!.hour;
        hourFrequency[hour] = (hourFrequency[hour] ?? 0) + 1;
      }
    }

    if (hourFrequency.isEmpty) return [];

    // Sort hours by frequency and return top 3 active hours
    final sortedHours = hourFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final now = DateTime.now();
    return sortedHours.take(3).map((entry) {
      return DateTime(now.year, now.month, now.day, entry.key, 0);
    }).toList();
  }

  ReminderPriority _mapStringToPriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'urgent':
        return ReminderPriority.urgent;
      case 'high':
        return ReminderPriority.high;
      case 'low':
        return ReminderPriority.low;
      default:
        return ReminderPriority.normal;
    }
  }

  Future<void> _scheduleAt({
    required String id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await _notificationService.scheduleNotification(
      id: _generateNotificationId(id),
      title: title,
      body: body,
      scheduledDate: scheduledDate,
    );
  }

  /// Generate a stable integer notification ID from a string key.
  int _generateNotificationId(String key) {
    return key.hashCode & 0x7FFFFFFF;
  }
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return ReminderService(notificationService);
});
