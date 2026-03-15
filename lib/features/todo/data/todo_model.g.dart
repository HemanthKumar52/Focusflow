// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_model.dart';

class TodoModelAdapter extends TypeAdapter<TodoModel> {
  @override
  final int typeId = 0;

  @override
  TodoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TodoModel(
      id: fields[0] as String,
      title: fields[1] as String,
      notes: fields[2] as String?,
      createdAt: fields[3] as DateTime,
      dueDate: fields[4] as DateTime?,
      priorityIndex: fields[5] as int,
      statusIndex: fields[6] as int,
      repeatRuleIndex: fields[7] as int,
      tags: (fields[8] as List).cast<String>(),
      subTasks: (fields[9] as List).cast<SubTask>(),
      projectId: fields[10] as String?,
      completedAt: fields[11] as DateTime?,
      reminderAt: fields[12] as DateTime?,
      isDeleted: fields[13] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TodoModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.notes)
      ..writeByte(3)..write(obj.createdAt)
      ..writeByte(4)..write(obj.dueDate)
      ..writeByte(5)..write(obj.priorityIndex)
      ..writeByte(6)..write(obj.statusIndex)
      ..writeByte(7)..write(obj.repeatRuleIndex)
      ..writeByte(8)..write(obj.tags)
      ..writeByte(9)..write(obj.subTasks)
      ..writeByte(10)..write(obj.projectId)
      ..writeByte(11)..write(obj.completedAt)
      ..writeByte(12)..write(obj.reminderAt)
      ..writeByte(13)..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class SubTaskAdapter extends TypeAdapter<SubTask> {
  @override
  final int typeId = 10;

  @override
  SubTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SubTask(
      id: fields[0] as String,
      title: fields[1] as String,
      isCompleted: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SubTask obj) {
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
      other is SubTaskAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
