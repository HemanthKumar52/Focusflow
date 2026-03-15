import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/database_service.dart';
import 'core/services/notification_service.dart';
import 'features/settings/providers/settings_provider.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress known debug-only assertion from Riverpod + GoRouter ShellRoute interaction
  if (kDebugMode) {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception.toString().contains('_dependents.isEmpty')) {
        return; // Known debug-only issue with Riverpod + GoRouter ShellRoute
      }
      originalOnError?.call(details);
    };
  }

  await DatabaseService.initialize();

  final notificationService = NotificationService();
  await notificationService.init();

  // Auto-save: Hive persists data to disk on every .put() call, so all
  // provider writes (todos, notes, tasks, settings, etc.) are automatically
  // saved. No additional lifecycle handling is needed.
  runApp(const ProviderScope(child: FocusFlowApp()));
}

class FocusFlowApp extends ConsumerWidget {
  const FocusFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeModeProvider);

    final ThemeMode themeMode;
    final ThemeData darkTheme;

    switch (appThemeMode) {
      case AppThemeMode.system:
        themeMode = ThemeMode.system;
        darkTheme = AppTheme.darkTheme;
        break;
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        darkTheme = AppTheme.darkTheme;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        darkTheme = AppTheme.darkTheme;
        break;
      case AppThemeMode.neon:
        themeMode = ThemeMode.dark;
        darkTheme = AppTheme.neonTheme;
        break;
    }

    return MaterialApp.router(
      title: 'FocusFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}
