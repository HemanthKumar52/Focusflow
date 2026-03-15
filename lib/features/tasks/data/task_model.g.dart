// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_model.dart';

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 2;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      statusIndex: fields[3] as int,
      priorityIndex: fields[4] as int,
      effortIndex: fields[5] as int,
      projectId: fields[6] as String?,
      checklist: (fields[7] as List).cast<ChecklistItem>(),
      attachmentUrls: (fields[8] as List).cast<String>(),
      timeLog: (fields[9] as List).cast<TimeLogEntry>(),
      activityLog: (fields[10] as List).cast<ActivityLogEntry>(),
      dueDate: fields[11] as DateTime?,
      reminderAt: fields[12] as DateTime?,
      blockedByTaskId: fields[13] as String?,
      createdAt: fields[14] as DateTime,
      completedAt: fields[15] as DateTime?,
      isDeleted: fields[16] as bool,
      tags: (fields[17] as List).cast<String>(),
      kanbanOrder: fields[18] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.description)
      ..writeByte(3)..write(obj.statusIndex)
      ..writeByte(4)..write(obj.priorityIndex)
      ..writeByte(5)..write(obj.effortIndex)
      ..writeByte(6)..write(obj.projectId)
      ..writeByte(7)..write(obj.checklist)
      ..writeByte(8)..write(obj.attachmentUrls)
      ..writeByte(9)..write(obj.timeLog)
      ..writeByte(10)..write(obj.activityLog)
      ..writeByte(11)..write(obj.dueDate)
      ..writeByte(12)..write(obj.reminderAt)
      ..writeByte(13)..write(obj.blockedByTaskId)
      ..writeByte(14)..write(obj.createdAt)
      ..writeByte(15)..write(obj.completedAt)
      ..writeByte(16)..write(obj.isDeleted)
      ..writeByte(17)..write(obj.tags)
      ..writeByte(18)..write(obj.kanbanOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class ChecklistItemAdapter extends TypeAdapter<ChecklistItem> {
  @override
  final int typeId = 20;

  @override
  ChecklistItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChecklistItem(
      id: fields[0] as String,
      title: fields[1] as String,
      isCompleted: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ChecklistItem obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItemAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class TimeLogEntryAdapter extends TypeAdapter<TimeLogEntry> {
  @override
  final int typeId = 21;

  @override
  TimeLogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TimeLogEntry(
      startTime: fields[0] as DateTime,
      endTime: fields[1] as DateTime,
      note: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TimeLogEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)..write(obj.startTime)
      ..writeByte(1)..write(obj.endTime)
      ..writeByte(2)..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeLogEntryAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class ActivityLogEntryAdapter extends TypeAdapter<ActivityLogEntry> {
  @override
  final int typeId = 22;

  @override
  ActivityLogEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ActivityLogEntry(
      timestamp: fields[0] as DateTime,
      message: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ActivityLogEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)..write(obj.timestamp)
      ..writeByte(1)..write(obj.message);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogEntryAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
