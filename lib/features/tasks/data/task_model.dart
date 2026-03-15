import 'package:hive/hive.dart';
import '../../../core/constants/enums.dart';

part 'task_model.g.dart';

@HiveType(typeId: 2)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int statusIndex;

  @HiveField(4)
  int priorityIndex;

  @HiveField(5)
  int effortIndex; // maps to EffortSize

  @HiveField(6)
  String? projectId;

  @HiveField(7)
  List<ChecklistItem> checklist;

  @HiveField(8)
  List<String> attachmentUrls;

  @HiveField(9)
  List<TimeLogEntry> timeLog;

  @HiveField(10)
  List<ActivityLogEntry> activityLog;

  @HiveField(11)
  DateTime? dueDate;

  @HiveField(12)
  DateTime? reminderAt;

  @HiveField(13)
  String? blockedByTaskId;

  @HiveField(14)
  DateTime createdAt;

  @HiveField(15)
  DateTime? completedAt;

  @HiveField(16)
  bool isDeleted;

  @HiveField(17)
  List<String> tags;

  @HiveField(18)
  int kanbanOrder;

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.statusIndex = 0,
    this.priorityIndex = 2,
    this.effortIndex = 2, // M
    this.projectId,
    this.checklist = const [],
    this.attachmentUrls = const [],
    this.timeLog = const [],
    this.activityLog = const [],
    this.dueDate,
    this.reminderAt,
    this.blockedByTaskId,
    required this.createdAt,
    this.completedAt,
    this.isDeleted = false,
    this.tags = const [],
    this.kanbanOrder = 0,
  });

  TaskStatus get status => TaskStatus.values[statusIndex];
  set status(TaskStatus s) => statusIndex = s.index;

  TaskPriority get priority => TaskPriority.values[priorityIndex];
  set priority(TaskPriority p) => priorityIndex = p.index;

  EffortSize get effort => EffortSize.values[effortIndex];

  bool get isCompleted => statusIndex == TaskStatus.completed.index;
  bool get isBlocked => blockedByTaskId != null;

  Duration get totalTimeLogged => timeLog.fold(
        Duration.zero,
        (total, entry) => total + entry.duration,
      );

  TaskModel copyWith({
    String? title,
    String? description,
    int? statusIndex,
    int? priorityIndex,
    int? effortIndex,
    String? projectId,
    List<ChecklistItem>? checklist,
    List<String>? attachmentUrls,
    List<TimeLogEntry>? timeLog,
    List<ActivityLogEntry>? activityLog,
    DateTime? dueDate,
    DateTime? reminderAt,
    String? blockedByTaskId,
    DateTime? completedAt,
    bool? isDeleted,
    List<String>? tags,
    int? kanbanOrder,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      statusIndex: statusIndex ?? this.statusIndex,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      effortIndex: effortIndex ?? this.effortIndex,
      projectId: projectId ?? this.projectId,
      checklist: checklist ?? this.checklist,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      timeLog: timeLog ?? this.timeLog,
      activityLog: activityLog ?? this.activityLog,
      dueDate: dueDate ?? this.dueDate,
      reminderAt: reminderAt ?? this.reminderAt,
      blockedByTaskId: blockedByTaskId ?? this.blockedByTaskId,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      tags: tags ?? this.tags,
      kanbanOrder: kanbanOrder ?? this.kanbanOrder,
    );
  }
}

@HiveType(typeId: 20)
class ChecklistItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  ChecklistItem({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}

@HiveType(typeId: 21)
class TimeLogEntry extends HiveObject {
  @HiveField(0)
  DateTime startTime;

  @HiveField(1)
  DateTime endTime;

  @HiveField(2)
  String? note;

  TimeLogEntry({
    required this.startTime,
    required this.endTime,
    this.note,
  });

  Duration get duration => endTime.difference(startTime);
}

@HiveType(typeId: 22)
class ActivityLogEntry extends HiveObject {
  @HiveField(0)
  DateTime timestamp;

  @HiveField(1)
  String message;

  ActivityLogEntry({
    required this.timestamp,
    required this.message,
  });
}
