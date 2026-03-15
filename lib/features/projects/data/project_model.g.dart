// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_model.dart';

class ProjectModelAdapter extends TypeAdapter<ProjectModel> {
  @override
  final int typeId = 3;

  @override
  ProjectModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProjectModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      colorValue: fields[3] as int,
      milestones: (fields[4] as List).cast<Milestone>(),
      healthIndex: fields[5] as int,
      createdAt: fields[6] as DateTime,
      archivedAt: fields[7] as DateTime?,
      isDeleted: fields[8] as bool,
      linkedNoteIds: (fields[9] as List).cast<String>(),
      dueDate: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProjectModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.description)
      ..writeByte(3)..write(obj.colorValue)
      ..writeByte(4)..write(obj.milestones)
      ..writeByte(5)..write(obj.healthIndex)
      ..writeByte(6)..write(obj.createdAt)
      ..writeByte(7)..write(obj.archivedAt)
      ..writeByte(8)..write(obj.isDeleted)
      ..writeByte(9)..write(obj.linkedNoteIds)
      ..writeByte(10)..write(obj.dueDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class MilestoneAdapter extends TypeAdapter<Milestone> {
  @override
  final int typeId = 30;

  @override
  Milestone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Milestone(
      id: fields[0] as String,
      name: fields[1] as String,
      targetDate: fields[2] as DateTime,
      isCompleted: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Milestone obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.targetDate)
      ..writeByte(3)..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MilestoneAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
