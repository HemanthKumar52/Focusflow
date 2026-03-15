import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/database_service.dart';
import '../data/study_model.dart';

// ---------------------------------------------------------------------------
// Study Plan Notifier
// ---------------------------------------------------------------------------

class StudyPlanNotifier extends StateNotifier<List<StudyPlanModel>> {
  StudyPlanNotifier() : super([]) {
    _loadPlans();
  }

  void _loadPlans() {
    final box = DatabaseService.studyPlans;
    state = box.values.where((p) => !p.isDeleted).toList();
  }

  Future<void> addPlan(
    String name,
    DateTime startDate,
    DateTime endDate, {
    int sessionsPerWeek = 5,
  }) async {
    final plan = StudyPlanModel(
      id: const Uuid().v4(),
      name: name,
      startDate: startDate,
      endDate: endDate,
      sessionsPerWeek: sessionsPerWeek,
      createdAt: DateTime.now(),
    );
    await DatabaseService.studyPlans.put(plan.id, plan);
    state = [...state, plan];
  }

  Future<void> updatePlan(StudyPlanModel updated) async {
    await DatabaseService.studyPlans.put(updated.id, updated);
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p,
    ];
  }

  Future<void> deletePlan(String id) async {
    final existing = DatabaseService.studyPlans.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(isDeleted: true);
    await DatabaseService.studyPlans.put(id, updated);
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> addWeeklyTopic(
    String planId,
    int weekNumber,
    String topicName,
  ) async {
    final existing = DatabaseService.studyPlans.get(planId);
    if (existing == null) return;

    final topics = List<WeeklyTopicBucket>.from(existing.weeklyTopics);
    final bucketIndex = topics.indexWhere((b) => b.weekNumber == weekNumber);

    final newTopic = StudyTopic(
      id: const Uuid().v4(),
      name: topicName,
    );

    if (bucketIndex >= 0) {
      final bucket = topics[bucketIndex];
      topics[bucketIndex] = WeeklyTopicBucket(
        weekNumber: weekNumber,
        topics: [...bucket.topics, newTopic],
      );
    } else {
      topics.add(WeeklyTopicBucket(
        weekNumber: weekNumber,
        topics: [newTopic],
      ));
    }

    final updated = existing.copyWith(weeklyTopics: topics);
    await DatabaseService.studyPlans.put(planId, updated);
    state = [
      for (final p in state)
        if (p.id == planId) updated else p,
    ];
  }

  Future<void> updateTopicStatus(
    String planId,
    String topicId,
    StudyTopicStatus status,
  ) async {
    final existing = DatabaseService.studyPlans.get(planId);
    if (existing == null) return;

    final topics = existing.weeklyTopics.map((bucket) {
      final updatedTopics = bucket.topics.map((topic) {
        if (topic.id == topicId) {
          topic.statusIndex = status.index;
          topic.lastStudied = DateTime.now();
          topic.reviewCount = topic.reviewCount + 1;
          topic.nextReviewDate = calculateNextReview(topic);
        }
        return topic;
      }).toList();
      return WeeklyTopicBucket(
        weekNumber: bucket.weekNumber,
        topics: updatedTopics,
      );
    }).toList();

    final updated = existing.copyWith(weeklyTopics: topics);
    await DatabaseService.studyPlans.put(planId, updated);
    state = [
      for (final p in state)
        if (p.id == planId) updated else p,
    ];
  }

  /// Spaced repetition based on Ebbinghaus forgetting curve.
  /// Interval increases exponentially: 1, 3, 7, 14, 30, 60 days ...
  DateTime calculateNextReview(StudyTopic topic) {
    final now = DateTime.now();
    final reviewCount = topic.reviewCount;
    // Intervals in days following a modified Ebbinghaus curve
    final intervals = [1, 3, 7, 14, 30, 60, 120];
    final intervalDays = reviewCount < intervals.length
        ? intervals[reviewCount]
        : (60 * pow(1.5, reviewCount - intervals.length + 1)).round();
    return now.add(Duration(days: intervalDays));
  }
}

// ---------------------------------------------------------------------------
// Study Session Notifier
// ---------------------------------------------------------------------------

class StudySessionNotifier extends StateNotifier<List<StudySession>> {
  StudySessionNotifier() : super([]) {
    _loadSessions();
  }

  void _loadSessions() {
    final box = DatabaseService.studySessions;
    state = box.values.toList();
  }

  Future<void> addSession(StudySession session) async {
    await DatabaseService.studySessions.put(session.id, session);
    state = [...state, session];
  }

  Future<void> completeSession(String id) async {
    final existing = DatabaseService.studySessions.get(id);
    if (existing == null) return;
    existing.isCompleted = true;
    existing.endTime = DateTime.now();
    await existing.save();
    state = [
      for (final s in state)
        if (s.id == id) existing else s,
    ];
  }
}

// ---------------------------------------------------------------------------
// Active Timer Notifier (Pomodoro)
// ---------------------------------------------------------------------------

class ActiveTimerState {
  final int secondsRemaining;
  final bool isRunning;
  final bool isPaused;
  final String? sessionId;

  const ActiveTimerState({
    this.secondsRemaining = 25 * 60,
    this.isRunning = false,
    this.isPaused = false,
    this.sessionId,
  });

  ActiveTimerState copyWith({
    int? secondsRemaining,
    bool? isRunning,
    bool? isPaused,
    String? sessionId,
  }) {
    return ActiveTimerState(
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      sessionId: sessionId ?? this.sessionId,
    );
  }
}

class ActiveTimerNotifier extends StateNotifier<ActiveTimerState> {
  ActiveTimerNotifier() : super(const ActiveTimerState());

  void start({int durationMinutes = 25, String? sessionId}) {
    state = ActiveTimerState(
      secondsRemaining: durationMinutes * 60,
      isRunning: true,
      isPaused: false,
      sessionId: sessionId,
    );
  }

  void tick() {
    if (!state.isRunning || state.isPaused) return;
    if (state.secondsRemaining <= 0) {
      state = state.copyWith(isRunning: false);
      return;
    }
    state = state.copyWith(secondsRemaining: state.secondsRemaining - 1);
  }

  void pause() {
    state = state.copyWith(isPaused: true);
  }

  void resume() {
    state = state.copyWith(isPaused: false);
  }

  void reset() {
    state = const ActiveTimerState();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final studyPlanProvider =
    StateNotifierProvider<StudyPlanNotifier, List<StudyPlanModel>>((ref) {
  return StudyPlanNotifier();
});

final studySessionProvider =
    StateNotifierProvider<StudySessionNotifier, List<StudySession>>((ref) {
  return StudySessionNotifier();
});

final activeTimerProvider =
    StateNotifierProvider<ActiveTimerNotifier, ActiveTimerState>((ref) {
  return ActiveTimerNotifier();
});

final todaySessionsProvider = Provider<List<StudySession>>((ref) {
  final sessions = ref.watch(studySessionProvider);
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  return sessions
      .where((s) => s.startTime.isAfter(todayStart))
      .toList();
});

final studyStreakProvider = Provider<int>((ref) {
  final sessions = ref.watch(studySessionProvider);
  if (sessions.isEmpty) return 0;

  // Group completed sessions by date, walk backwards to compute streak
  final completedSessions = sessions.where((s) => s.isCompleted).toList()
    ..sort((a, b) => b.startTime.compareTo(a.startTime));

  if (completedSessions.isEmpty) return 0;

  int streak = 0;
  DateTime checkDate = DateTime.now();

  while (true) {
    final dayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final hasSession = completedSessions.any(
      (s) => s.startTime.isAfter(dayStart) && s.startTime.isBefore(dayEnd),
    );

    if (hasSession) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    } else {
      // Allow today to be missing (streak still valid from yesterday)
      if (streak == 0) {
        checkDate = checkDate.subtract(const Duration(days: 1));
        final prevDayStart = DateTime(checkDate.year, checkDate.month, checkDate.day);
        final prevDayEnd = prevDayStart.add(const Duration(days: 1));
        final hasPrev = completedSessions.any(
          (s) => s.startTime.isAfter(prevDayStart) && s.startTime.isBefore(prevDayEnd),
        );
        if (hasPrev) {
          streak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
          continue;
        }
      }
      break;
    }
  }

  return streak;
});
