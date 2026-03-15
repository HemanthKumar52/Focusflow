// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_model.dart';

class HabitModelAdapter extends TypeAdapter<HabitModel> {
  @override
  final int typeId = 6;

  @override
  HabitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String?,
      iconCodePoint: fields[3] as int,
      colorValue: fields[4] as int,
      frequency: fields[5] as int,
      targetPerDay: fields[6] as int,
      reminderHour: fields[7] as int?,
      reminderMinute: fields[8] as int?,
      createdAt: fields[9] as DateTime,
      isArchived: fields[10] as bool,
      isDeleted: fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, HabitModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.description)
      ..writeByte(3)..write(obj.iconCodePoint)
      ..writeByte(4)..write(obj.colorValue)
      ..writeByte(5)..write(obj.frequency)
      ..writeByte(6)..write(obj.targetPerDay)
      ..writeByte(7)..write(obj.reminderHour)
      ..writeByte(8)..write(obj.reminderMinute)
      ..writeByte(9)..write(obj.createdAt)
      ..writeByte(10)..write(obj.isArchived)
      ..writeByte(11)..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class HabitEntryAdapter extends TypeAdapter<HabitEntry> {
  @override
  final int typeId = 60;

  @override
  HabitEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitEntry(
      id: fields[0] as String,
      habitId: fields[1] as String,
      date: fields[2] as DateTime,
      completionCount: fields[3] as int,
      note: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, HabitEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.habitId)
      ..writeByte(2)..write(obj.date)
      ..writeByte(3)..write(obj.completionCount)
      ..writeByte(4)..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitEntryAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
