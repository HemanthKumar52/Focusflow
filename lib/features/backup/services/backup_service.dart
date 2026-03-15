import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/database_service.dart';
import '../../habits/data/habit_model.dart';
import '../../notes/data/note_model.dart';
import '../../projects/data/project_model.dart';
import '../../study/data/study_model.dart';
import '../../tasks/data/task_model.dart';
import '../../todo/data/todo_model.dart';
import '../../voice_notes/data/voice_note_model.dart';
import '../../sync/services/encryption_service.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class BackupFile {
  final String path;
  final DateTime createdAt;
  final int sizeBytes;
  final bool isEncrypted;

  const BackupFile({
    required this.path,
    required this.createdAt,
    required this.sizeBytes,
    this.isEncrypted = false,
  });

  String get fileName => path.split(Platform.pathSeparator).last;

  String get sizeLabel {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ---------------------------------------------------------------------------
// Backup Service
// ---------------------------------------------------------------------------

class BackupService {
  static const String _autoBackupKey = 'autoBackupEnabled';
  static const String _autoBackupFrequencyKey = 'autoBackupFrequency';
  static const String _backupExtension = '.focusflow';
  static const String _encryptedExtension = '.focusflow.enc';

  /// Exports all Hive box data as a JSON-serialisable map.
  Map<String, dynamic> exportAllData() {
    final data = <String, dynamic>{};

    data['todos'] = _boxToJsonMap(DatabaseService.todos);
    data['notes'] = _boxToJsonMap(DatabaseService.notes);
    data['notebooks'] = _boxToJsonMap(DatabaseService.notebooks);
    data['tasks'] = _boxToJsonMap(DatabaseService.tasks);
    data['projects'] = _boxToJsonMap(DatabaseService.projects);
    data['studyPlans'] = _boxToJsonMap(DatabaseService.studyPlans);
    data['studySessions'] = _boxToJsonMap(DatabaseService.studySessions);
    data['voiceNotes'] = _boxToJsonMap(DatabaseService.voiceNotes);
    data['habits'] = _boxToJsonMap(DatabaseService.habits);
    data['habitEntries'] = _boxToJsonMap(DatabaseService.habitEntries);
    data['exportedAt'] = DateTime.now().toIso8601String();
    data['version'] = 1;

    return data;
  }

  /// Clears all Hive boxes and imports data from [data].
  Future<void> importAllData(Map<String, dynamic> data) async {
    // Clear existing data
    await DatabaseService.todos.clear();
    await DatabaseService.notes.clear();
    await DatabaseService.notebooks.clear();
    await DatabaseService.tasks.clear();
    await DatabaseService.projects.clear();
    await DatabaseService.studyPlans.clear();
    await DatabaseService.studySessions.clear();
    await DatabaseService.voiceNotes.clear();
    await DatabaseService.habits.clear();
    await DatabaseService.habitEntries.clear();

    // Import each box's data using typed deserialisation
    final todos = data['todos'] as Map<String, dynamic>?;
    if (todos != null) {
      for (final e in todos.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.todos.put(e.key, _todoFromJson(m));
      }
    }

    final notes = data['notes'] as Map<String, dynamic>?;
    if (notes != null) {
      for (final e in notes.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.notes.put(e.key, _noteFromJson(m));
      }
    }

    final notebooks = data['notebooks'] as Map<String, dynamic>?;
    if (notebooks != null) {
      for (final e in notebooks.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.notebooks.put(e.key, _notebookFromJson(m));
      }
    }

    final tasks = data['tasks'] as Map<String, dynamic>?;
    if (tasks != null) {
      for (final e in tasks.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.tasks.put(e.key, _taskFromJson(m));
      }
    }

    final projects = data['projects'] as Map<String, dynamic>?;
    if (projects != null) {
      for (final e in projects.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.projects.put(e.key, _projectFromJson(m));
      }
    }

    final studyPlans = data['studyPlans'] as Map<String, dynamic>?;
    if (studyPlans != null) {
      for (final e in studyPlans.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.studyPlans.put(e.key, _studyPlanFromJson(m));
      }
    }

    final studySessions = data['studySessions'] as Map<String, dynamic>?;
    if (studySessions != null) {
      for (final e in studySessions.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.studySessions.put(e.key, _studySessionFromJson(m));
      }
    }

    final voiceNotes = data['voiceNotes'] as Map<String, dynamic>?;
    if (voiceNotes != null) {
      for (final e in voiceNotes.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.voiceNotes.put(e.key, _voiceNoteFromJson(m));
      }
    }

    final habits = data['habits'] as Map<String, dynamic>?;
    if (habits != null) {
      for (final e in habits.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.habits.put(e.key, _habitFromJson(m));
      }
    }

    final habitEntries = data['habitEntries'] as Map<String, dynamic>?;
    if (habitEntries != null) {
      for (final e in habitEntries.entries) {
        final m = e.value as Map<String, dynamic>;
        await DatabaseService.habitEntries.put(e.key, _habitEntryFromJson(m));
      }
    }
  }

  /// Creates an unencrypted backup file in the documents directory.
  Future<BackupFile> createBackup() async {
    final dir = await _backupDir();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'focusflow_$timestamp$_backupExtension';
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');

    final data = exportAllData();
    final jsonString = jsonEncode(data);
    await file.writeAsString(jsonString);

    return BackupFile(
      path: file.path,
      createdAt: DateTime.now(),
      sizeBytes: await file.length(),
    );
  }

  /// Creates an encrypted backup file protected by [passphrase].
  Future<BackupFile> createEncryptedBackup(String passphrase) async {
    final dir = await _backupDir();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'focusflow_$timestamp$_encryptedExtension';
    final file = File('${dir.path}${Platform.pathSeparator}$fileName');

    final data = exportAllData();
    final encrypted = EncryptionService.encryptBackup(data, passphrase);
    await file.writeAsString(encrypted);

    return BackupFile(
      path: file.path,
      createdAt: DateTime.now(),
      sizeBytes: await file.length(),
      isEncrypted: true,
    );
  }

  /// Restores data from an encrypted backup file.
  Future<void> restoreEncryptedBackup(
    String filePath,
    String passphrase,
  ) async {
    final file = File(filePath);
    final encrypted = await file.readAsString();
    final data = EncryptionService.decryptBackup(encrypted, passphrase);
    await importAllData(data);
  }

  /// Restores data from an unencrypted backup file.
  Future<void> restoreBackup(String filePath) async {
    final file = File(filePath);
    final jsonString = await file.readAsString();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    await importAllData(data);
  }

  /// Lists available backup files in the documents directory.
  Future<List<BackupFile>> getBackupFiles() async {
    final dir = await _backupDir();
    if (!dir.existsSync()) return [];

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.path.endsWith(_backupExtension) ||
            f.path.endsWith(_encryptedExtension))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    return files.map((f) {
      final stat = f.statSync();
      return BackupFile(
        path: f.path,
        createdAt: stat.modified,
        sizeBytes: stat.size,
        isEncrypted: f.path.endsWith(_encryptedExtension),
      );
    }).toList();
  }

  /// Deletes a backup file.
  Future<void> deleteBackup(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Sets up or disables periodic auto-backup (stub using SharedPreferences).
  Future<void> scheduleAutoBackup({
    required bool enabled,
    String frequency = 'weekly',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);
    await prefs.setString(_autoBackupFrequencyKey, frequency);

    // TODO: integrate workmanager or background_fetch for actual periodic
    //       backup execution.
  }

  /// Returns whether auto-backup is enabled.
  Future<bool> isAutoBackupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_autoBackupKey) ?? false;
  }

  /// Returns the auto-backup frequency ('daily' or 'weekly').
  Future<String> getAutoBackupFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_autoBackupFrequencyKey) ?? 'weekly';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<Directory> _backupDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory(
        '${docsDir.path}${Platform.pathSeparator}FocusFlow_Backups');
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }
    return backupDir;
  }

  Map<String, dynamic> _boxToJsonMap(Box box) {
    final map = <String, dynamic>{};
    for (final key in box.keys) {
      map[key.toString()] = _objectToJson(box.get(key));
    }
    return map;
  }

  // ---------------------------------------------------------------------------
  // Serialisation: HiveObject -> JSON-safe Map
  // ---------------------------------------------------------------------------

  dynamic _objectToJson(dynamic obj) {
    if (obj == null) return null;
    if (obj is String || obj is int || obj is double || obj is bool) return obj;
    if (obj is DateTime) return obj.toIso8601String();
    if (obj is List) return obj.map(_objectToJson).toList();
    if (obj is Map) {
      return obj.map((k, v) => MapEntry(k.toString(), _objectToJson(v)));
    }

    // ----- Model-specific -----
    if (obj is TodoModel) return _todoToJson(obj);
    if (obj is SubTask) return _subTaskToJson(obj);
    if (obj is NoteModel) return _noteToJson(obj);
    if (obj is NotebookModel) return _notebookToJson(obj);
    if (obj is TaskModel) return _taskToJson(obj);
    if (obj is ChecklistItem) return _checklistItemToJson(obj);
    if (obj is TimeLogEntry) return _timeLogEntryToJson(obj);
    if (obj is ActivityLogEntry) return _activityLogEntryToJson(obj);
    if (obj is ProjectModel) return _projectToJson(obj);
    if (obj is Milestone) return _milestoneToJson(obj);
    if (obj is StudyPlanModel) return _studyPlanToJson(obj);
    if (obj is WeeklyTopicBucket) return _weeklyTopicBucketToJson(obj);
    if (obj is StudyTopic) return _studyTopicToJson(obj);
    if (obj is StudySession) return _studySessionToJson(obj);
    if (obj is VoiceNoteModel) return _voiceNoteToJson(obj);
    if (obj is HabitModel) return _habitToJson(obj);
    if (obj is HabitEntry) return _habitEntryToJson(obj);

    // Fallback — toString so jsonEncode never throws
    return obj.toString();
  }

  // -- TodoModel --
  Map<String, dynamic> _todoToJson(TodoModel o) => {
        'id': o.id,
        'title': o.title,
        'notes': o.notes,
        'createdAt': o.createdAt.toIso8601String(),
        'dueDate': o.dueDate?.toIso8601String(),
        'priorityIndex': o.priorityIndex,
        'statusIndex': o.statusIndex,
        'repeatRuleIndex': o.repeatRuleIndex,
        'tags': o.tags,
        'subTasks': o.subTasks.map(_subTaskToJson).toList(),
        'projectId': o.projectId,
        'completedAt': o.completedAt?.toIso8601String(),
        'reminderAt': o.reminderAt?.toIso8601String(),
        'isDeleted': o.isDeleted,
      };

  Map<String, dynamic> _subTaskToJson(SubTask o) => {
        'id': o.id,
        'title': o.title,
        'isCompleted': o.isCompleted,
      };

  TodoModel _todoFromJson(Map<String, dynamic> m) => TodoModel(
        id: m['id'] as String,
        title: m['title'] as String,
        notes: m['notes'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate'] as String) : null,
        priorityIndex: m['priorityIndex'] as int? ?? 2,
        statusIndex: m['statusIndex'] as int? ?? 0,
        repeatRuleIndex: m['repeatRuleIndex'] as int? ?? 0,
        tags: (m['tags'] as List?)?.cast<String>() ?? [],
        subTasks: (m['subTasks'] as List?)
                ?.map((e) => _subTaskFromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        projectId: m['projectId'] as String?,
        completedAt: m['completedAt'] != null ? DateTime.parse(m['completedAt'] as String) : null,
        reminderAt: m['reminderAt'] != null ? DateTime.parse(m['reminderAt'] as String) : null,
        isDeleted: m['isDeleted'] as bool? ?? false,
      );

  SubTask _subTaskFromJson(Map<String, dynamic> m) => SubTask(
        id: m['id'] as String,
        title: m['title'] as String,
        isCompleted: m['isCompleted'] as bool? ?? false,
      );

  // -- NoteModel --
  Map<String, dynamic> _noteToJson(NoteModel o) => {
        'id': o.id,
        'title': o.title,
        'body': o.body,
        'notebookId': o.notebookId,
        'isPinned': o.isPinned,
        'isArchived': o.isArchived,
        'linkedNoteIds': o.linkedNoteIds,
        'tags': o.tags,
        'createdAt': o.createdAt.toIso8601String(),
        'updatedAt': o.updatedAt.toIso8601String(),
        'isDeleted': o.isDeleted,
        'projectId': o.projectId,
        'voiceNotePath': o.voiceNotePath,
      };

  NoteModel _noteFromJson(Map<String, dynamic> m) => NoteModel(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String? ?? '',
        notebookId: m['notebookId'] as String?,
        isPinned: m['isPinned'] as bool? ?? false,
        isArchived: m['isArchived'] as bool? ?? false,
        linkedNoteIds: (m['linkedNoteIds'] as List?)?.cast<String>() ?? [],
        tags: (m['tags'] as List?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
        isDeleted: m['isDeleted'] as bool? ?? false,
        projectId: m['projectId'] as String?,
        voiceNotePath: m['voiceNotePath'] as String?,
      );

  // -- NotebookModel --
  Map<String, dynamic> _notebookToJson(NotebookModel o) => {
        'id': o.id,
        'name': o.name,
        'colorValue': o.colorValue,
        'createdAt': o.createdAt.toIso8601String(),
      };

  NotebookModel _notebookFromJson(Map<String, dynamic> m) => NotebookModel(
        id: m['id'] as String,
        name: m['name'] as String,
        colorValue: m['colorValue'] as int,
        createdAt: DateTime.parse(m['createdAt'] as String),
      );

  // -- TaskModel --
  Map<String, dynamic> _taskToJson(TaskModel o) => {
        'id': o.id,
        'title': o.title,
        'description': o.description,
        'statusIndex': o.statusIndex,
        'priorityIndex': o.priorityIndex,
        'effortIndex': o.effortIndex,
        'projectId': o.projectId,
        'checklist': o.checklist.map(_checklistItemToJson).toList(),
        'attachmentUrls': o.attachmentUrls,
        'timeLog': o.timeLog.map(_timeLogEntryToJson).toList(),
        'activityLog': o.activityLog.map(_activityLogEntryToJson).toList(),
        'dueDate': o.dueDate?.toIso8601String(),
        'reminderAt': o.reminderAt?.toIso8601String(),
        'blockedByTaskId': o.blockedByTaskId,
        'createdAt': o.createdAt.toIso8601String(),
        'completedAt': o.completedAt?.toIso8601String(),
        'isDeleted': o.isDeleted,
        'tags': o.tags,
        'kanbanOrder': o.kanbanOrder,
      };

  Map<String, dynamic> _checklistItemToJson(ChecklistItem o) => {
        'id': o.id,
        'title': o.title,
        'isCompleted': o.isCompleted,
      };

  Map<String, dynamic> _timeLogEntryToJson(TimeLogEntry o) => {
        'startTime': o.startTime.toIso8601String(),
        'endTime': o.endTime.toIso8601String(),
        'note': o.note,
      };

  Map<String, dynamic> _activityLogEntryToJson(ActivityLogEntry o) => {
        'timestamp': o.timestamp.toIso8601String(),
        'message': o.message,
      };

  TaskModel _taskFromJson(Map<String, dynamic> m) => TaskModel(
        id: m['id'] as String,
        title: m['title'] as String,
        description: m['description'] as String?,
        statusIndex: m['statusIndex'] as int? ?? 0,
        priorityIndex: m['priorityIndex'] as int? ?? 2,
        effortIndex: m['effortIndex'] as int? ?? 2,
        projectId: m['projectId'] as String?,
        checklist: (m['checklist'] as List?)
                ?.map((e) => _checklistItemFromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        attachmentUrls: (m['attachmentUrls'] as List?)?.cast<String>() ?? [],
        timeLog: (m['timeLog'] as List?)
                ?.map((e) => _timeLogEntryFromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        activityLog: (m['activityLog'] as List?)
                ?.map((e) => _activityLogEntryFromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate'] as String) : null,
        reminderAt: m['reminderAt'] != null ? DateTime.parse(m['reminderAt'] as String) : null,
        blockedByTaskId: m['blockedByTaskId'] as String?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        completedAt: m['completedAt'] != null ? DateTime.parse(m['completedAt'] as String) : null,
        isDeleted: m['isDeleted'] as bool? ?? false,
        tags: (m['tags'] as List?)?.cast<String>() ?? [],
        kanbanOrder: m['kanbanOrder'] as int? ?? 0,
      );

  ChecklistItem _checklistItemFromJson(Map<String, dynamic> m) => ChecklistItem(
        id: m['id'] as String,
        title: m['title'] as String,
        isCompleted: m['isCompleted'] as bool? ?? false,
      );

  TimeLogEntry _timeLogEntryFromJson(Map<String, dynamic> m) => TimeLogEntry(
        startTime: DateTime.parse(m['startTime'] as String),
        endTime: DateTime.parse(m['endTime'] as String),
        note: m['note'] as String?,
      );

  ActivityLogEntry _activityLogEntryFromJson(Map<String, dynamic> m) => ActivityLogEntry(
        timestamp: DateTime.parse(m['timestamp'] as String),
        message: m['message'] as String,
      );

  // -- ProjectModel --
  Map<String, dynamic> _projectToJson(ProjectModel o) => {
        'id': o.id,
        'name': o.name,
        'description': o.description,
        'colorValue': o.colorValue,
        'milestones': o.milestones.map(_milestoneToJson).toList(),
        'healthIndex': o.healthIndex,
        'createdAt': o.createdAt.toIso8601String(),
        'archivedAt': o.archivedAt?.toIso8601String(),
        'isDeleted': o.isDeleted,
        'linkedNoteIds': o.linkedNoteIds,
        'dueDate': o.dueDate?.toIso8601String(),
      };

  Map<String, dynamic> _milestoneToJson(Milestone o) => {
        'id': o.id,
        'name': o.name,
        'targetDate': o.targetDate.toIso8601String(),
        'isCompleted': o.isCompleted,
      };

  ProjectModel _projectFromJson(Map<String, dynamic> m) => ProjectModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        colorValue: m['colorValue'] as int? ?? 0xFF5B3FE8,
        milestones: (m['milestones'] as List?)
                ?.map((e) => _milestoneFromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        healthIndex: m['healthIndex'] as int? ?? 0,
        createdAt: DateTime.parse(m['createdAt'] as String),
        archivedAt: m['archivedAt'] != null ? DateTime.parse(m['archivedAt'] as String) : null,
        isDeleted: m['isDeleted'] as bool? ?? false,
        linkedNoteIds: (m['linkedNoteIds'] as List?)?.cast<String>() ?? [],
        dueDate: m['dueDate'] != null ? DateTime.parse(m['dueDate'] as String) : null,
      );

  Milestone _milestoneFromJson(Map<String, dynamic> m) => Milestone(
        id: m['id'] as String,
        name: m['name'] as String,
        targetDate: DateTime.parse(m['targetDate'] as String),
        isCompleted: m['isCompleted'] as bool? ?? false,
      );

  // -- StudyPlanModel --
  Map<String, dynamic> _studyPlanToJson(StudyPlanModel o) => {
        'id': o.id,
        'name': o.name,
        'weeklyTopics': o.weeklyTopics.map(_weeklyTopicBucketToJson).toList(),
        'startDate': o.startDate.toIso8601String(),
        'endDate': o.endDate.toIso8601String(),
        'sessionsPerWeek': o.sessionsPerWeek,
        'sessionDurationMinutes': o.sessionDurationMinutes,
        'createdAt': o.createdAt.toIso8601String(),
        'isDeleted': o.isDeleted,
      };

  Map<String, dynamic> _weeklyTopicBucketToJson(WeeklyTopicBucket o) => {
        'weekNumber': o.weekNumber,
        'topics': o.topics.map(_studyTopicToJson).toList(),
      };

  Map<String, dynamic> _studyTopicToJson(StudyTopic o) => {
        'id': o.id,
        'name': o.name,
        'statusIndex': o.statusIndex,
        'resourceUrls': o.resourceUrls,
        'lastStudied': o.lastStudied?.toIso8601String(),
        'nextReviewDate': o.nextReviewDate?.toIso8601String(),
        'reviewCount': o.reviewCount,
      };

  Map<String, dynamic> _studySessionToJson(StudySession o) => {
        'id': o.id,
        'planId': o.planId,
        'topicId': o.topicId,
        'startTime': o.startTime.toIso8601String(),
        'endTime': o.endTime?.toIso8601String(),
        'durationMinutes': o.durationMinutes,
        'isCompleted': o.isCompleted,
      };

  StudyPlanModel _studyPlanFromJson(Map<String, dynamic> m) => StudyPlanModel(
        id: m['id'] as String,
        name: m['name'] as String,
        weeklyTopics: (m['weeklyTopics'] as List?)
                ?.map((e) => _weeklyTopicBucketFromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        startDate: DateTime.parse(m['startDate'] as String),
        endDate: DateTime.parse(m['endDate'] as String),
        sessionsPerWeek: m['sessionsPerWeek'] as int? ?? 5,
        sessionDurationMinutes: m['sessionDurationMinutes'] as int? ?? 25,
        createdAt: DateTime.parse(m['createdAt'] as String),
        isDeleted: m['isDeleted'] as bool? ?? false,
      );

  WeeklyTopicBucket _weeklyTopicBucketFromJson(Map<String, dynamic> m) => WeeklyTopicBucket(
        weekNumber: m['weekNumber'] as int,
        topics: (m['topics'] as List?)
                ?.map((e) => _studyTopicFromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  StudyTopic _studyTopicFromJson(Map<String, dynamic> m) => StudyTopic(
        id: m['id'] as String,
        name: m['name'] as String,
        statusIndex: m['statusIndex'] as int? ?? 0,
        resourceUrls: (m['resourceUrls'] as List?)?.cast<String>() ?? [],
        lastStudied: m['lastStudied'] != null ? DateTime.parse(m['lastStudied'] as String) : null,
        nextReviewDate: m['nextReviewDate'] != null ? DateTime.parse(m['nextReviewDate'] as String) : null,
        reviewCount: m['reviewCount'] as int? ?? 0,
      );

  StudySession _studySessionFromJson(Map<String, dynamic> m) => StudySession(
        id: m['id'] as String,
        planId: m['planId'] as String,
        topicId: m['topicId'] as String?,
        startTime: DateTime.parse(m['startTime'] as String),
        endTime: m['endTime'] != null ? DateTime.parse(m['endTime'] as String) : null,
        durationMinutes: m['durationMinutes'] as int? ?? 25,
        isCompleted: m['isCompleted'] as bool? ?? false,
      );

  // -- VoiceNoteModel --
  Map<String, dynamic> _voiceNoteToJson(VoiceNoteModel o) => {
        'id': o.id,
        'title': o.title,
        'filePath': o.filePath,
        'durationSeconds': o.durationSeconds,
        'createdAt': o.createdAt.toIso8601String(),
        'linkedEntityId': o.linkedEntityId,
        'linkedEntityType': o.linkedEntityType,
        'tags': o.tags,
        'isDeleted': o.isDeleted,
        'transcription': o.transcription,
      };

  VoiceNoteModel _voiceNoteFromJson(Map<String, dynamic> m) => VoiceNoteModel(
        id: m['id'] as String,
        title: m['title'] as String,
        filePath: m['filePath'] as String,
        durationSeconds: m['durationSeconds'] as int? ?? 0,
        createdAt: DateTime.parse(m['createdAt'] as String),
        linkedEntityId: m['linkedEntityId'] as String?,
        linkedEntityType: m['linkedEntityType'] as String?,
        tags: (m['tags'] as List?)?.cast<String>() ?? [],
        isDeleted: m['isDeleted'] as bool? ?? false,
        transcription: m['transcription'] as String?,
      );

  // -- HabitModel --
  Map<String, dynamic> _habitToJson(HabitModel o) => {
        'id': o.id,
        'name': o.name,
        'description': o.description,
        'iconCodePoint': o.iconCodePoint,
        'colorValue': o.colorValue,
        'frequency': o.frequency,
        'targetPerDay': o.targetPerDay,
        'reminderHour': o.reminderHour,
        'reminderMinute': o.reminderMinute,
        'createdAt': o.createdAt.toIso8601String(),
        'isArchived': o.isArchived,
        'isDeleted': o.isDeleted,
      };

  HabitModel _habitFromJson(Map<String, dynamic> m) => HabitModel(
        id: m['id'] as String,
        name: m['name'] as String,
        description: m['description'] as String?,
        iconCodePoint: m['iconCodePoint'] as int,
        colorValue: m['colorValue'] as int,
        frequency: m['frequency'] as int? ?? 0,
        targetPerDay: m['targetPerDay'] as int? ?? 1,
        reminderHour: m['reminderHour'] as int?,
        reminderMinute: m['reminderMinute'] as int?,
        createdAt: DateTime.parse(m['createdAt'] as String),
        isArchived: m['isArchived'] as bool? ?? false,
        isDeleted: m['isDeleted'] as bool? ?? false,
      );

  // -- HabitEntry --
  Map<String, dynamic> _habitEntryToJson(HabitEntry o) => {
        'id': o.id,
        'habitId': o.habitId,
        'date': o.date.toIso8601String(),
        'completionCount': o.completionCount,
        'note': o.note,
      };

  HabitEntry _habitEntryFromJson(Map<String, dynamic> m) => HabitEntry(
        id: m['id'] as String,
        habitId: m['habitId'] as String,
        date: DateTime.parse(m['date'] as String),
        completionCount: m['completionCount'] as int? ?? 1,
        note: m['note'] as String?,
      );
}
