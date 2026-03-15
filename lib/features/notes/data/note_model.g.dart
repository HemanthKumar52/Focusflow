// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_model.dart';

class NoteModelAdapter extends TypeAdapter<NoteModel> {
  @override
  final int typeId = 1;

  @override
  NoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteModel(
      id: fields[0] as String,
      title: fields[1] as String,
      body: fields[2] as String,
      notebookId: fields[3] as String?,
      isPinned: fields[4] as bool,
      isArchived: fields[5] as bool,
      linkedNoteIds: (fields[6] as List).cast<String>(),
      tags: (fields[7] as List).cast<String>(),
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      isDeleted: fields[10] as bool,
      projectId: fields[11] as String?,
      voiceNotePath: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, NoteModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.body)
      ..writeByte(3)..write(obj.notebookId)
      ..writeByte(4)..write(obj.isPinned)
      ..writeByte(5)..write(obj.isArchived)
      ..writeByte(6)..write(obj.linkedNoteIds)
      ..writeByte(7)..write(obj.tags)
      ..writeByte(8)..write(obj.createdAt)
      ..writeByte(9)..write(obj.updatedAt)
      ..writeByte(10)..write(obj.isDeleted)
      ..writeByte(11)..write(obj.projectId)
      ..writeByte(12)..write(obj.voiceNotePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class NotebookModelAdapter extends TypeAdapter<NotebookModel> {
  @override
  final int typeId = 11;

  @override
  NotebookModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotebookModel(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int,
      createdAt: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, NotebookModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.colorValue)
      ..writeByte(3)..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotebookModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
