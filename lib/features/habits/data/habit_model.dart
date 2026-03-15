import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 6)
class HabitModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int iconCodePoint;

  @HiveField(4)
  int colorValue;

  @HiveField(5)
  int frequency; // index into HabitFrequency enum

  @HiveField(6)
  int targetPerDay;

  @HiveField(7)
  int? reminderHour;

  @HiveField(8)
  int? reminderMinute;

  @HiveField(9)
  DateTime createdAt;

  @HiveField(10)
  bool isArchived;

  @HiveField(11)
  bool isDeleted;

  HabitModel({
    required this.id,
    required this.name,
    this.description,
    required this.iconCodePoint,
    required this.colorValue,
    this.frequency = 0,
    this.targetPerDay = 1,
    this.reminderHour,
    this.reminderMinute,
    required this.createdAt,
    this.isArchived = false,
    this.isDeleted = false,
  });

  HabitModel copyWith({
    String? name,
    String? description,
    int? iconCodePoint,
    int? colorValue,
    int? frequency,
    int? targetPerDay,
    int? reminderHour,
    int? reminderMinute,
    bool? isArchived,
    bool? isDeleted,
  }) {
    return HabitModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      frequency: frequency ?? this.frequency,
      targetPerDay: targetPerDay ?? this.targetPerDay,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

@HiveType(typeId: 60)
class HabitEntry extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String habitId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int completionCount;

  @HiveField(4)
  String? note;

  HabitEntry({
    required this.id,
    required this.habitId,
    required this.date,
    this.completionCount = 1,
    this.note,
  });

  HabitEntry copyWith({
    int? completionCount,
    String? note,
  }) {
    return HabitEntry(
      id: id,
      habitId: habitId,
      date: date,
      completionCount: completionCount ?? this.completionCount,
      note: note ?? this.note,
    );
  }
}
