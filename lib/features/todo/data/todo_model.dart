import 'package:hive/hive.dart';
import '../../../core/constants/enums.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 0)
class TodoModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? notes;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  DateTime? dueDate;

  @HiveField(5)
  int priorityIndex; // maps to TaskPriority

  @HiveField(6)
  int statusIndex; // maps to TaskStatus

  @HiveField(7)
  int repeatRuleIndex; // maps to RepeatRule

  @HiveField(8)
  List<String> tags;

  @HiveField(9)
  List<SubTask> subTasks;

  @HiveField(10)
  String? projectId;

  @HiveField(11)
  DateTime? completedAt;

  @HiveField(12)
  DateTime? reminderAt;

  @HiveField(13)
  bool isDeleted;

  TodoModel({
    required this.id,
    required this.title,
    this.notes,
    required this.createdAt,
    this.dueDate,
    this.priorityIndex = 2, // normal
    this.statusIndex = 0, // notStarted
    this.repeatRuleIndex = 0, // none
    this.tags = const [],
    this.subTasks = const [],
    this.projectId,
    this.completedAt,
    this.reminderAt,
    this.isDeleted = false,
  });

  TaskPriority get priority => TaskPriority.values[priorityIndex];
  set priority(TaskPriority p) => priorityIndex = p.index;

  TaskStatus get status => TaskStatus.values[statusIndex];
  set status(TaskStatus s) => statusIndex = s.index;

  RepeatRule get repeatRule => RepeatRule.values[repeatRuleIndex];
  set repeatRule(RepeatRule r) => repeatRuleIndex = r.index;

  bool get isCompleted => statusIndex == TaskStatus.completed.index;
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isCompleted;

  TodoModel copyWith({
    String? title,
    String? notes,
    DateTime? dueDate,
    int? priorityIndex,
    int? statusIndex,
    int? repeatRuleIndex,
    List<String>? tags,
    List<SubTask>? subTasks,
    String? projectId,
    DateTime? completedAt,
    DateTime? reminderAt,
    bool? isDeleted,
  }) {
    return TodoModel(
      id: id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      dueDate: dueDate ?? this.dueDate,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      statusIndex: statusIndex ?? this.statusIndex,
      repeatRuleIndex: repeatRuleIndex ?? this.repeatRuleIndex,
      tags: tags ?? this.tags,
      subTasks: subTasks ?? this.subTasks,
      projectId: projectId ?? this.projectId,
      completedAt: completedAt ?? this.completedAt,
      reminderAt: reminderAt ?? this.reminderAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

@HiveType(typeId: 10)
class SubTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  SubTask({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}
