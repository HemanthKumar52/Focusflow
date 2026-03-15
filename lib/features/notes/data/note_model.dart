import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 1)
class NoteModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String body; // markdown content

  @HiveField(3)
  String? notebookId;

  @HiveField(4)
  bool isPinned;

  @HiveField(5)
  bool isArchived;

  @HiveField(6)
  List<String> linkedNoteIds;

  @HiveField(7)
  List<String> tags;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime updatedAt;

  @HiveField(10)
  bool isDeleted;

  @HiveField(11)
  String? projectId;

  @HiveField(12)
  String? voiceNotePath;

  NoteModel({
    required this.id,
    required this.title,
    this.body = '',
    this.notebookId,
    this.isPinned = false,
    this.isArchived = false,
    this.linkedNoteIds = const [],
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.projectId,
    this.voiceNotePath,
  });

  NoteModel copyWith({
    String? title,
    String? body,
    String? notebookId,
    bool? isPinned,
    bool? isArchived,
    List<String>? linkedNoteIds,
    List<String>? tags,
    DateTime? updatedAt,
    bool? isDeleted,
    String? projectId,
    String? voiceNotePath,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      notebookId: notebookId ?? this.notebookId,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      projectId: projectId ?? this.projectId,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
    );
  }
}

@HiveType(typeId: 11)
class NotebookModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  DateTime createdAt;

  NotebookModel({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.createdAt,
  });
}
