import 'package:hive/hive.dart';
import '../../../core/constants/enums.dart';

part 'project_model.g.dart';

@HiveType(typeId: 3)
class ProjectModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int colorValue;

  @HiveField(4)
  List<Milestone> milestones;

  @HiveField(5)
  int healthIndex; // maps to ProjectHealth

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime? archivedAt;

  @HiveField(8)
  bool isDeleted;

  @HiveField(9)
  List<String> linkedNoteIds;

  @HiveField(10)
  DateTime? dueDate;

  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    this.colorValue = 0xFF5B3FE8,
    this.milestones = const [],
    this.healthIndex = 0,
    required this.createdAt,
    this.archivedAt,
    this.isDeleted = false,
    this.linkedNoteIds = const [],
    this.dueDate,
  });

  ProjectHealth get health => ProjectHealth.values[healthIndex];
  bool get isArchived => archivedAt != null;

  ProjectModel copyWith({
    String? name,
    String? description,
    int? colorValue,
    List<Milestone>? milestones,
    int? healthIndex,
    DateTime? archivedAt,
    bool? isDeleted,
    List<String>? linkedNoteIds,
    DateTime? dueDate,
  }) {
    return ProjectModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      milestones: milestones ?? this.milestones,
      healthIndex: healthIndex ?? this.healthIndex,
      createdAt: createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}

@HiveType(typeId: 30)
class Milestone extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime targetDate;

  @HiveField(3)
  bool isCompleted;

  Milestone({
    required this.id,
    required this.name,
    required this.targetDate,
    this.isCompleted = false,
  });
}
