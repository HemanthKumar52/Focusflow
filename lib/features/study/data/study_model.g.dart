// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_model.dart';

class StudyPlanModelAdapter extends TypeAdapter<StudyPlanModel> {
  @override
  final int typeId = 4;

  @override
  StudyPlanModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyPlanModel(
      id: fields[0] as String,
      name: fields[1] as String,
      weeklyTopics: (fields[2] as List).cast<WeeklyTopicBucket>(),
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      sessionsPerWeek: fields[5] as int,
      sessionDurationMinutes: fields[6] as int,
      createdAt: fields[7] as DateTime,
      isDeleted: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StudyPlanModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.weeklyTopics)
      ..writeByte(3)..write(obj.startDate)
      ..writeByte(4)..write(obj.endDate)
      ..writeByte(5)..write(obj.sessionsPerWeek)
      ..writeByte(6)..write(obj.sessionDurationMinutes)
      ..writeByte(7)..write(obj.createdAt)
      ..writeByte(8)..write(obj.isDeleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyPlanModelAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class WeeklyTopicBucketAdapter extends TypeAdapter<WeeklyTopicBucket> {
  @override
  final int typeId = 40;

  @override
  WeeklyTopicBucket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WeeklyTopicBucket(
      weekNumber: fields[0] as int,
      topics: (fields[1] as List).cast<StudyTopic>(),
    );
  }

  @override
  void write(BinaryWriter writer, WeeklyTopicBucket obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)..write(obj.weekNumber)
      ..writeByte(1)..write(obj.topics);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyTopicBucketAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class StudyTopicAdapter extends TypeAdapter<StudyTopic> {
  @override
  final int typeId = 41;

  @override
  StudyTopic read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudyTopic(
      id: fields[0] as String,
      name: fields[1] as String,
      statusIndex: fields[2] as int,
      resourceUrls: (fields[3] as List).cast<String>(),
      lastStudied: fields[4] as DateTime?,
      nextReviewDate: fields[5] as DateTime?,
      reviewCount: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, StudyTopic obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.name)
      ..writeByte(2)..write(obj.statusIndex)
      ..writeByte(3)..write(obj.resourceUrls)
      ..writeByte(4)..write(obj.lastStudied)
      ..writeByte(5)..write(obj.nextReviewDate)
      ..writeByte(6)..write(obj.reviewCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudyTopicAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}

class StudySessionAdapter extends TypeAdapter<StudySession> {
  @override
  final int typeId = 42;

  @override
  StudySession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudySession(
      id: fields[0] as String,
      planId: fields[1] as String,
      topicId: fields[2] as String?,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime?,
      durationMinutes: fields[5] as int,
      isCompleted: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StudySession obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)..write(obj.id)
      ..writeByte(1)..write(obj.planId)
      ..writeByte(2)..write(obj.topicId)
      ..writeByte(3)..write(obj.startTime)
      ..writeByte(4)..write(obj.endTime)
      ..writeByte(5)..write(obj.durationMinutes)
      ..writeByte(6)..write(obj.isCompleted);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySessionAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
