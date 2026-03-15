import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/database_service.dart';
import '../../../core/services/notification_service.dart';
import '../data/todo_model.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TodoNotifier extends StateNotifier<List<TodoModel>> {
  TodoNotifier() : super([]) {
    _loadTodos();
  }

  void _loadTodos() {
    final box = DatabaseService.todos;
    state = box.values.where((t) => !t.isDeleted).toList();
  }

  Future<void> addTodo(
    String title, {
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.normal,
    List<String> tags = const [],
  }) async {
    final todo = TodoModel(
      id: const Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priorityIndex: priority.index,
      tags: tags,
    );
    await DatabaseService.todos.put(todo.id, todo);
    state = [...state, todo];

    // Schedule reminder notifications if the todo has a due date
    if (dueDate != null) {
      _scheduleReminder(todo);
    }
  }

  Future<void> updateTodo(TodoModel updated) async {
    await DatabaseService.todos.put(updated.id, updated);
    state = [
      for (final t in state)
        if (t.id == updated.id) updated else t,
    ];
  }

  Future<void> deleteTodo(String id) async {
    final existing = DatabaseService.todos.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(isDeleted: true);
    await DatabaseService.todos.put(id, updated);
    state = state.where((t) => t.id != id).toList();
  }

  Future<void> toggleComplete(String id) async {
    final existing = DatabaseService.todos.get(id);
    if (existing == null) return;

    final isNowComplete = !existing.isCompleted;
    final updated = existing.copyWith(
      statusIndex: isNowComplete
          ? TaskStatus.completed.index
          : TaskStatus.notStarted.index,
      completedAt: isNowComplete ? DateTime.now() : null,
    );
    await DatabaseService.todos.put(id, updated);
    state = [
      for (final t in state)
        if (t.id == id) updated else t,
    ];

    // Cancel scheduled notifications when completing a todo
    if (isNowComplete) {
      NotificationService().cancelNotification(id.hashCode & 0x7FFFFFFF);
      NotificationService().cancelNotification((id.hashCode + 1) & 0x7FFFFFFF);
    }
  }

  Future<void> reorderTodos(List<TodoModel> reordered) async {
    state = reordered;
  }

  void _scheduleReminder(TodoModel todo) {
    if (todo.dueDate == null) return;
    final notificationService = NotificationService();
    // Schedule notification 1 hour before due date
    final reminderTime = todo.dueDate!.subtract(const Duration(hours: 1));
    if (reminderTime.isAfter(DateTime.now())) {
      notificationService.scheduleNotification(
        id: todo.id.hashCode & 0x7FFFFFFF,
        title: 'Reminder: ${todo.title}',
        body: 'Due ${_formatTime(todo.dueDate!)}',
        scheduledDate: reminderTime,
        payload: 'todo:${todo.id}',
      );
    }
    // Also schedule at due time
    if (todo.dueDate!.isAfter(DateTime.now())) {
      notificationService.scheduleNotification(
        id: (todo.id.hashCode + 1) & 0x7FFFFFFF,
        title: 'Due Now: ${todo.title}',
        body: 'This task is due now!',
        scheduledDate: todo.dueDate!,
        payload: 'todo:${todo.id}',
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

final todoProvider =
    StateNotifierProvider<TodoNotifier, List<TodoModel>>((ref) {
  return TodoNotifier();
});

final todayTodosProvider = Provider<List<TodoModel>>((ref) {
  final todos = ref.watch(todoProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final todayEnd = todayStart.add(const Duration(days: 1));

  return todos.where((t) {
    if (t.isCompleted) return false;
    if (t.dueDate == null) return false;
    // Due today or overdue
    return t.dueDate!.isBefore(todayEnd);
  }).toList();
});

final completedTodosProvider = Provider<List<TodoModel>>((ref) {
  final todos = ref.watch(todoProvider);
  return todos.where((t) => t.isCompleted).toList();
});

final overdueProvider = Provider<List<TodoModel>>((ref) {
  final todos = ref.watch(todoProvider);
  return todos.where((t) => t.isOverdue).toList();
});
