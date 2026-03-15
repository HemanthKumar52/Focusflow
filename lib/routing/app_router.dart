import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/presentation/screens/app_shell.dart';
import '../features/home/presentation/screens/today_screen.dart';
import '../features/todo/presentation/screens/todo_list_screen.dart';
import '../features/todo/presentation/screens/todo_detail_screen.dart';
import '../features/notes/presentation/screens/notes_list_screen.dart';
import '../features/notes/presentation/screens/note_editor_screen.dart';
import '../features/tasks/presentation/screens/task_board_screen.dart';
import '../features/tasks/presentation/screens/task_detail_screen.dart';
import '../features/projects/presentation/screens/project_list_screen.dart';
import '../features/projects/presentation/screens/project_detail_screen.dart';
import '../features/study/presentation/screens/study_dashboard_screen.dart';
import '../features/study/presentation/screens/study_plan_editor_screen.dart';
import '../features/study/presentation/screens/session_timer_screen.dart';
import '../features/voice_notes/presentation/screens/voice_notes_screen.dart';
import '../features/habits/presentation/screens/habits_screen.dart';
import '../features/habits/presentation/screens/habit_detail_screen.dart';
import '../features/calendar/presentation/screens/calendar_screen.dart';
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/knowledge_graph/presentation/screens/knowledge_graph_screen.dart';
import '../features/sync/presentation/screens/sync_screen.dart';
import '../features/backup/presentation/screens/backup_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/today', builder: (_, _) => const TodayScreen()),
        GoRoute(
          path: '/todos',
          builder: (_, _) => const TodoListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  TodoDetailScreen(todoId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/notes',
          builder: (_, _) => const NotesListScreen(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, _) => const NoteEditorScreen(),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  NoteEditorScreen(noteId: state.pathParameters['id']),
            ),
          ],
        ),
        GoRoute(
          path: '/tasks',
          builder: (_, _) => const TaskBoardScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  TaskDetailScreen(taskId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/projects',
          builder: (_, _) => const ProjectListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => ProjectDetailScreen(
                  projectId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/study',
          builder: (_, _) => const StudyDashboardScreen(),
          routes: [
            GoRoute(
              path: 'plan/new',
              builder: (_, _) => const StudyPlanEditorScreen(),
            ),
            GoRoute(
              path: 'plan/:id',
              builder: (_, state) => StudyPlanEditorScreen(
                  planId: state.pathParameters['id']),
            ),
            GoRoute(
              path: 'timer',
              builder: (_, _) => const SessionTimerScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/habits',
          builder: (_, _) => const HabitsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  HabitDetailScreen(habitId: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(path: '/calendar', builder: (_, _) => const CalendarScreen()),
        GoRoute(path: '/analytics', builder: (_, _) => const AnalyticsScreen()),
        GoRoute(path: '/graph', builder: (_, _) => const KnowledgeGraphScreen()),
        GoRoute(path: '/sync', builder: (_, _) => const SyncScreen()),
        GoRoute(path: '/backup', builder: (_, _) => const BackupScreen()),
        GoRoute(path: '/voice', builder: (_, _) => const VoiceNotesScreen()),
        GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      ],
    ),
  ],
);
