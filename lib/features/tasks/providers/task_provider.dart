import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';
import '../data/task_model.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TaskNotifier extends StateNotifier<List<TaskModel>> {
  TaskNotifier() : super([]) {
    _loadTasks();
  }

  void _loadTasks() {
    final box = DatabaseService.tasks;
    state = box.values.where((t) => !t.isDeleted).toList();
  }

  Future<void> addTask(
    String title, {
    String? projectId,
    TaskPriority priority = TaskPriority.normal,
    EffortSize effort = EffortSize.m,
    DateTime? dueDate,
  }) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title,
      projectId: projectId,
      priorityIndex: priority.index,
      effortIndex: effort.index,
      dueDate: dueDate,
      createdAt: DateTime.now(),
    );
    await DatabaseService.tasks.put(task.id, task);
    state = [...state, task];

    // Schedule reminder notifications if the task has a due date
    if (dueDate != null) {
      _scheduleReminder(task);
    }
  }

  Future<void> updateTask(TaskModel updated) async {
    await DatabaseService.tasks.put(updated.id, updated);
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
  }

  Future<void> deleteTask(String id) async {
    final existing = DatabaseService.tasks.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(isDeleted: true);
    await DatabaseService.tasks.put(id, updated);
    state = state.where((t) => t.id != id).toList();
  }

  Future<void> updateStatus(String id, TaskStatus status) async {
    final existing = DatabaseService.tasks.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      statusIndex: status.index,
      completedAt: status == TaskStatus.completed ? DateTime.now() : null,
    );
    await DatabaseService.tasks.put(id, updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];

    // Cancel scheduled notifications when task is completed
    if (status == TaskStatus.completed) {
      NotificationService().cancelNotification(id.hashCode & 0x7FFFFFFF);
      NotificationService().cancelNotification((id.hashCode + 1) & 0x7FFFFFFF);
    }
  }

  Future<void> addTimeLog(String id, TimeLogEntry entry) async {
    final existing = DatabaseService.tasks.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      timeLog: [...existing.timeLog, entry],
    );
    await DatabaseService.tasks.put(id, updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
  }

  Future<void> addChecklistItem(String id, String title) async {
    final existing = DatabaseService.tasks.get(id);
    if (existing == null) return;
    final item = ChecklistItem(
      id: const Uuid().v4(),
      title: title,
    );
    final updated = existing.copyWith(
      checklist: [...existing.checklist, item],
    );
    await DatabaseService.tasks.put(id, updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
  }

  Future<void> toggleChecklist(String id, String itemId) async {
    final existing = DatabaseService.tasks.get(id);
    if (existing == null) return;
    final updatedChecklist = existing.checklist.map((item) {
      if (item.id == itemId) {
        item.isCompleted = !item.isCompleted;
      }
      return item;
    }).toList();
    final updated = existing.copyWith(checklist: updatedChecklist);
    await DatabaseService.tasks.put(id, updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];
  }

  void _scheduleReminder(TaskModel task) {
    if (task.dueDate == null) return;
    final notificationService = NotificationService();
    // Schedule notification 1 hour before due date
    final reminderTime = task.dueDate!.subtract(const Duration(hours: 1));
    if (reminderTime.isAfter(DateTime.now())) {
      notificationService.scheduleNotification(
        id: task.id.hashCode & 0x7FFFFFFF,
        title: 'Reminder: ${task.title}',
        body: 'Due ${_formatTime(task.dueDate!)}',
        scheduledDate: reminderTime,
        payload: 'task:${task.id}',
      );
    }
    // Also schedule at due time
    if (task.dueDate!.isAfter(DateTime.now())) {
      notificationService.scheduleNotification(
        id: (task.id.hashCode + 1) & 0x7FFFFFFF,
        title: 'Due Now: ${task.title}',
        body: 'This task is due now!',
        scheduledDate: task.dueDate!,
        payload: 'task:${task.id}',
      );
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final taskProvider =
    StateNotifierProvider<TaskNotifier, List<TaskModel>>((ref) {
  return TaskNotifier();
});

final tasksByProjectProvider =
    Provider.family<List<TaskModel>, String>((ref, projectId) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((t) => t.projectId == projectId).toList();
});

final tasksByStatusProvider =
    Provider.family<List<TaskModel>, TaskStatus>((ref, status) {
  final tasks = ref.watch(taskProvider);
  return tasks.where((t) => t.status == status).toList();
});

final kanbanTasksProvider =
    Provider<Map<TaskStatus, List<TaskModel>>>((ref) {
  final tasks = ref.watch(taskProvider);
  final map = <TaskStatus, List<TaskModel>>{};
  for (final status in TaskStatus.values) {
    map[status] = tasks
        .where((t) => t.status == status)
        .toList()
      ..sort((a, b) => a.kanbanOrder.compareTo(b.kanbanOrder));
  }
  return map;
});
