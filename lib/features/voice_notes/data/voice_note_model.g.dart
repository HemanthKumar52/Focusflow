// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_note_model.dart';

class VoiceNoteModelAdapter extends TypeAdapter<VoiceNoteModel> {
  @override
  final int typeId = 5;

  @override
  VoiceNoteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoiceNoteModel(
      id: fields[0] as String,
      title: fields[1] as String,
      filePath: fields[2] as String,
      durationSeconds: fields[3] as int,
      createdAt: fields[4] as DateTime,
      linkedEntityId: fields[5] as String?,
      linkedEntityType: fields[6] as String?,
      tags: (fields[7] as List).cast<String>(),
      isDeleted: fields[8] as bool,
      transcription: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VoiceNoteModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.title)
      ..writeByte(2)..write(obj.filePath)
      ..writeByte(3)..write(obj.durationSeconds)
      ..writeByte(4)..write(obj.createdAt)
      ..writeByte(5)..write(obj.linkedEntityId)
      ..writeByte(6)..write(obj.linkedEntityType)
      ..writeByte(7)..write(obj.tags)
      ..writeByte(8)..write(obj.isDeleted)
      ..writeByte(9)..write(obj.transcription);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceNoteModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
