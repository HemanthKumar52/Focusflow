import 'package:hive_flutter/hive_flutter.dart';
import '../../features/todo/data/todo_model.dart';
import '../../features/notes/data/note_model.dart';
import '../../features/tasks/data/task_model.dart';
import '../../features/projects/data/project_model.dart';
import '../../features/study/data/study_model.dart';
import '../../features/voice_notes/data/voice_note_model.dart';
import '../../features/habits/data/habit_model.dart';
import '../../features/sync/data/sync_models.dart';

class DatabaseService {
  static const String todosBox = 'todos';
  static const String notesBox = 'notes';
  static const String notebooksBox = 'notebooks';
  static const String tasksBox = 'tasks';
  static const String projectsBox = 'projects';
  static const String studyPlansBox = 'studyPlans';
  static const String studySessionsBox = 'studySessions';
  static const String voiceNotesBox = 'voiceNotes';
  static const String habitsBox = 'habits';
  static const String habitEntriesBox = 'habitEntries';
  static const String devicesBox = 'devices';
  static const String syncLogsBox = 'syncLogs';
  static const String settingsBox = 'settings';

  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(TodoModelAdapter());
    Hive.registerAdapter(SubTaskAdapter());
    Hive.registerAdapter(NoteModelAdapter());
    Hive.registerAdapter(NotebookModelAdapter());
    Hive.registerAdapter(TaskModelAdapter());
    Hive.registerAdapter(ChecklistItemAdapter());
    Hive.registerAdapter(TimeLogEntryAdapter());
    Hive.registerAdapter(ActivityLogEntryAdapter());
    Hive.registerAdapter(ProjectModelAdapter());
    Hive.registerAdapter(MilestoneAdapter());
    Hive.registerAdapter(StudyPlanModelAdapter());
    Hive.registerAdapter(WeeklyTopicBucketAdapter());
    Hive.registerAdapter(StudyTopicAdapter());
    Hive.registerAdapter(StudySessionAdapter());
    Hive.registerAdapter(VoiceNoteModelAdapter());
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(HabitEntryAdapter());
    Hive.registerAdapter(DeviceInfoAdapter());
    Hive.registerAdapter(SyncLogAdapter());

    // Open boxes
    await Hive.openBox<TodoModel>(todosBox);
    await Hive.openBox<NoteModel>(notesBox);
    await Hive.openBox<NotebookModel>(notebooksBox);
    await Hive.openBox<TaskModel>(tasksBox);
    await Hive.openBox<ProjectModel>(projectsBox);
    await Hive.openBox<StudyPlanModel>(studyPlansBox);
    await Hive.openBox<StudySession>(studySessionsBox);
    await Hive.openBox<VoiceNoteModel>(voiceNotesBox);
    await Hive.openBox<HabitModel>(habitsBox);
    await Hive.openBox<HabitEntry>(habitEntriesBox);
    await Hive.openBox<DeviceInfo>(devicesBox);
    await Hive.openBox<SyncLog>(syncLogsBox);
    await Hive.openBox(settingsBox);
  }

  static Box<TodoModel> get todos => Hive.box<TodoModel>(todosBox);
  static Box<NoteModel> get notes => Hive.box<NoteModel>(notesBox);
  static Box<NotebookModel> get notebooks => Hive.box<NotebookModel>(notebooksBox);
  static Box<TaskModel> get tasks => Hive.box<TaskModel>(tasksBox);
  static Box<ProjectModel> get projects => Hive.box<ProjectModel>(projectsBox);
  static Box<StudyPlanModel> get studyPlans => Hive.box<StudyPlanModel>(studyPlansBox);
  static Box<StudySession> get studySessions => Hive.box<StudySession>(studySessionsBox);
  static Box<VoiceNoteModel> get voiceNotes => Hive.box<VoiceNoteModel>(voiceNotesBox);
  static Box<HabitModel> get habits => Hive.box<HabitModel>(habitsBox);
  static Box<HabitEntry> get habitEntries => Hive.box<HabitEntry>(habitEntriesBox);
  static Box<DeviceInfo> get devices => Hive.box<DeviceInfo>(devicesBox);
  static Box<SyncLog> get syncLogs => Hive.box<SyncLog>(syncLogsBox);
  static Box get settings => Hive.box(settingsBox);
}
