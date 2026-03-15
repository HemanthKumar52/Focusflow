import 'package:hive/hive.dart';

part 'voice_note_model.g.dart';

@HiveType(typeId: 5)
class VoiceNoteModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String filePath;

  @HiveField(3)
  int durationSeconds;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? linkedEntityId; // todo, note, task, etc.

  @HiveField(6)
  String? linkedEntityType; // 'todo', 'note', 'task'

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  bool isDeleted;

  @HiveField(9)
  String? transcription; // optional voice-to-text

  VoiceNoteModel({
    required this.id,
    required this.title,
    required this.filePath,
    this.durationSeconds = 0,
    required this.createdAt,
    this.linkedEntityId,
    this.linkedEntityType,
    this.tags = const [],
    this.isDeleted = false,
    this.transcription,
  });

  String get formattedDuration {
    final min = durationSeconds ~/ 60;
    final sec = durationSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  VoiceNoteModel copyWith({
    String? title,
    String? filePath,
    int? durationSeconds,
    String? linkedEntityId,
    String? linkedEntityType,
    List<String>? tags,
    bool? isDeleted,
    String? transcription,
  }) {
    return VoiceNoteModel(
      id: id,
      title: title ?? this.title,
      filePath: filePath ?? this.filePath,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      createdAt: createdAt,
      linkedEntityId: linkedEntityId ?? this.linkedEntityId,
      linkedEntityType: linkedEntityType ?? this.linkedEntityType,
      tags: tags ?? this.tags,
      isDeleted: isDeleted ?? this.isDeleted,
      transcription: transcription ?? this.transcription,
    );
  }
}
