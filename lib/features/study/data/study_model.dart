import 'package:hive/hive.dart';
import '../../../core/constants/enums.dart';

part 'study_model.g.dart';

@HiveType(typeId: 4)
class StudyPlanModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<WeeklyTopicBucket> weeklyTopics;

  @HiveField(3)
  DateTime startDate;

  @HiveField(4)
  DateTime endDate;

  @HiveField(5)
  int sessionsPerWeek;

  @HiveField(6)
  int sessionDurationMinutes; // default pomodoro 25 min

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  bool isDeleted;

  StudyPlanModel({
    required this.id,
    required this.name,
    this.weeklyTopics = const [],
    required this.startDate,
    required this.endDate,
    this.sessionsPerWeek = 5,
    this.sessionDurationMinutes = 25,
    required this.createdAt,
    this.isDeleted = false,
  });

  int get totalWeeks =>
      endDate.difference(startDate).inDays ~/ 7;

  StudyPlanModel copyWith({
    String? name,
    List<WeeklyTopicBucket>? weeklyTopics,
    DateTime? startDate,
    DateTime? endDate,
    int? sessionsPerWeek,
    int? sessionDurationMinutes,
    bool? isDeleted,
  }) {
    return StudyPlanModel(
      id: id,
      name: name ?? this.name,
      weeklyTopics: weeklyTopics ?? this.weeklyTopics,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sessionsPerWeek: sessionsPerWeek ?? this.sessionsPerWeek,
      sessionDurationMinutes: sessionDurationMinutes ?? this.sessionDurationMinutes,
      createdAt: createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

@HiveType(typeId: 40)
class WeeklyTopicBucket extends HiveObject {
  @HiveField(0)
  int weekNumber;

  @HiveField(1)
  List<StudyTopic> topics;

  WeeklyTopicBucket({
    required this.weekNumber,
    this.topics = const [],
  });
}

@HiveType(typeId: 41)
class StudyTopic extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int statusIndex; // maps to StudyTopicStatus

  @HiveField(3)
  List<String> resourceUrls;

  @HiveField(4)
  DateTime? lastStudied;

  @HiveField(5)
  DateTime? nextReviewDate; // spaced repetition

  @HiveField(6)
  int reviewCount;

  StudyTopic({
    required this.id,
    required this.name,
    this.statusIndex = 0,
    this.resourceUrls = const [],
    this.lastStudied,
    this.nextReviewDate,
    this.reviewCount = 0,
  });

  StudyTopicStatus get status => StudyTopicStatus.values[statusIndex];
}

@HiveType(typeId: 42)
class StudySession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String planId;

  @HiveField(2)
  String? topicId;

  @HiveField(3)
  DateTime startTime;

  @HiveField(4)
  DateTime? endTime;

  @HiveField(5)
  int durationMinutes;

  @HiveField(6)
  bool isCompleted;

  StudySession({
    required this.id,
    required this.planId,
    this.topicId,
    required this.startTime,
    this.endTime,
    this.durationMinutes = 25,
    this.isCompleted = false,
  });
}
