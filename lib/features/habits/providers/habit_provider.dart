import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database_service.dart';
import '../data/habit_model.dart';

// ---------------------------------------------------------------------------
// Habit Notifier
// ---------------------------------------------------------------------------

class HabitNotifier extends StateNotifier<List<HabitModel>> {
  HabitNotifier() : super([]) {
    _loadHabits();
  }

  void _loadHabits() {
    final box = DatabaseService.habits;
    state = box.values.where((h) => !h.isDeleted).toList();
  }

  Future<void> addHabit(
    String name, {
    int colorValue = 0xFF5B3FE8,
    int iconCodePoint = 0xF54B, // CupertinoIcons.star_fill
    int frequency = 0,
    int targetPerDay = 1,
    int? reminderHour,
    int? reminderMinute,
    String? description,
  }) async {
    final habit = HabitModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      frequency: frequency,
      targetPerDay: targetPerDay,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      createdAt: DateTime.now(),
    );
    await DatabaseService.habits.put(habit.id, habit);
    state = [...state, habit];
  }

  Future<void> updateHabit(HabitModel updated) async {
    await DatabaseService.habits.put(updated.id, updated);
    state = [
      for (final h in state)
        if (h.id == updated.id) updated else h,
    ];
  }

  Future<void> deleteHabit(String id) async {
    final existing = DatabaseService.habits.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(isDeleted: true);
    await DatabaseService.habits.put(id, updated);
    state = state.where((h) => h.id != id).toList();
  }

  Future<void> archiveHabit(String id) async {
    final existing = DatabaseService.habits.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(isArchived: !existing.isArchived);
    await DatabaseService.habits.put(id, updated);
    state = [
      for (final h in state)
        if (h.id == id) updated else h,
    ];
  }
}

// ---------------------------------------------------------------------------
// Habit Entry Notifier
// ---------------------------------------------------------------------------

class HabitEntryNotifier extends StateNotifier<List<HabitEntry>> {
  HabitEntryNotifier() : super([]) {
    _loadEntries();
  }

  void _loadEntries() {
    final box = DatabaseService.habitEntries;
    state = box.values.toList();
  }

  Future<void> logEntry(
    String habitId,
    DateTime date, {
    int count = 1,
    String? note,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Check if entry already exists for this habit+date
    final existingIndex = state.indexWhere(
      (e) =>
          e.habitId == habitId &&
          e.date.year == dateOnly.year &&
          e.date.month == dateOnly.month &&
          e.date.day == dateOnly.day,
    );

    if (existingIndex >= 0) {
      // Update existing entry
      final existing = state[existingIndex];
      final updated = existing.copyWith(
        completionCount: existing.completionCount + count,
        note: note ?? existing.note,
      );
      await DatabaseService.habitEntries.put(updated.id, updated);
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex) updated else state[i],
      ];
    } else {
      // Create new entry
      final entry = HabitEntry(
        id: const Uuid().v4(),
        habitId: habitId,
        date: dateOnly,
        completionCount: count,
        note: note,
      );
      await DatabaseService.habitEntries.put(entry.id, entry);
      state = [...state, entry];
    }
  }

  Future<void> removeEntry(String id) async {
    await DatabaseService.habitEntries.delete(id);
    state = state.where((e) => e.id != id).toList();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final habitProvider =
    StateNotifierProvider<HabitNotifier, List<HabitModel>>((ref) {
  return HabitNotifier();
});

final activeHabitsProvider = Provider<List<HabitModel>>((ref) {
  final habits = ref.watch(habitProvider);
  return habits.where((h) => !h.isArchived && !h.isDeleted).toList();
});

final habitEntriesProvider =
    StateNotifierProvider<HabitEntryNotifier, List<HabitEntry>>((ref) {
  return HabitEntryNotifier();
});

final todayHabitStatusProvider = Provider<Map<String, int>>((ref) {
  final entries = ref.watch(habitEntriesProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final Map<String, int> result = {};
  for (final entry in entries) {
    if (entry.date.year == today.year &&
        entry.date.month == today.month &&
        entry.date.day == today.day) {
      result[entry.habitId] = entry.completionCount;
    }
  }
  return result;
});

final habitStreakProvider =
    Provider.family<int, String>((ref, habitId) {
  final entries = ref.watch(habitEntriesProvider);
  final habits = ref.watch(habitProvider);

  final habit = habits.where((h) => h.id == habitId).firstOrNull;
  if (habit == null) return 0;

  final habitEntries = entries
      .where((e) => e.habitId == habitId && e.completionCount >= habit.targetPerDay)
      .toList();

  if (habitEntries.isEmpty) return 0;

  // Sort by date descending
  habitEntries.sort((a, b) => b.date.compareTo(a.date));

  // Check if today or yesterday has an entry (streak must be current)
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final mostRecent = habitEntries.first.date;
  final mostRecentDate = DateTime(mostRecent.year, mostRecent.month, mostRecent.day);

  if (mostRecentDate.isBefore(yesterday)) return 0;

  // Count consecutive days
  int streak = 1;
  for (int i = 0; i < habitEntries.length - 1; i++) {
    final current = DateTime(
      habitEntries[i].date.year,
      habitEntries[i].date.month,
      habitEntries[i].date.day,
    );
    final previous = DateTime(
      habitEntries[i + 1].date.year,
      habitEntries[i + 1].date.month,
      habitEntries[i + 1].date.day,
    );
    final diff = current.difference(previous).inDays;
    if (diff == 1) {
      streak++;
    } else if (diff > 1) {
      break;
    }
    // diff == 0 means same day, skip duplicates
  }

  return streak;
});

final habitCompletionRateProvider =
    Provider.family<double, String>((ref, habitId) {
  final entries = ref.watch(habitEntriesProvider);
  final habits = ref.watch(habitProvider);

  final habit = habits.where((h) => h.id == habitId).firstOrNull;
  if (habit == null) return 0.0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thirtyDaysAgo = today.subtract(const Duration(days: 30));

  final relevantEntries = entries.where((e) =>
      e.habitId == habitId &&
      !e.date.isBefore(thirtyDaysAgo) &&
      e.completionCount >= habit.targetPerDay);

  final completedDays = relevantEntries.length;
  // Max 30 days or days since creation
  final createdDate = DateTime(habit.createdAt.year, habit.createdAt.month, habit.createdAt.day);
  final startDate = createdDate.isAfter(thirtyDaysAgo) ? createdDate : thirtyDaysAgo;
  final totalDays = today.difference(startDate).inDays + 1;

  if (totalDays <= 0) return 0.0;
  return (completedDays / totalDays).clamp(0.0, 1.0);
});

final weeklyHabitDataProvider =
    Provider.family<List<HabitEntry?>, String>((ref, habitId) {
  final entries = ref.watch(habitEntriesProvider);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  final List<HabitEntry?> weekData = [];
  for (int i = 6; i >= 0; i--) {
    final date = today.subtract(Duration(days: i));
    final entry = entries
        .where((e) =>
            e.habitId == habitId &&
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day)
        .firstOrNull;
    weekData.add(entry);
  }
  return weekData;
});

final bestStreakProvider =
    Provider.family<int, String>((ref, habitId) {
  final entries = ref.watch(habitEntriesProvider);
  final habits = ref.watch(habitProvider);

  final habit = habits.where((h) => h.id == habitId).firstOrNull;
  if (habit == null) return 0;

  final habitEntries = entries
      .where((e) => e.habitId == habitId && e.completionCount >= habit.targetPerDay)
      .toList();

  if (habitEntries.isEmpty) return 0;

  // Sort by date ascending
  habitEntries.sort((a, b) => a.date.compareTo(b.date));

  int bestStreak = 1;
  int currentStreak = 1;

  for (int i = 1; i < habitEntries.length; i++) {
    final current = DateTime(
      habitEntries[i].date.year,
      habitEntries[i].date.month,
      habitEntries[i].date.day,
    );
    final previous = DateTime(
      habitEntries[i - 1].date.year,
      habitEntries[i - 1].date.month,
      habitEntries[i - 1].date.day,
    );
    final diff = current.difference(previous).inDays;
    if (diff == 1) {
      currentStreak++;
      if (currentStreak > bestStreak) bestStreak = currentStreak;
    } else if (diff > 1) {
      currentStreak = 1;
    }
    // diff == 0 means same day, skip
  }

  return bestStreak;
});
