import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_model.dart';

export '../data/settings_model.dart' show AppThemeMode;

class ThemeModeNotifier extends StateNotifier<AppThemeMode> {
  ThemeModeNotifier() : super(AppSettings.appThemeMode);

  void setThemeMode(AppThemeMode mode) {
    AppSettings.appThemeMode = mode;
    state = mode;
  }

  void toggleTheme() {
    final next = state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    setThemeMode(next);
  }
}

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AppThemeMode>(
  (ref) => ThemeModeNotifier(),
);

final isNeonProvider = Provider<bool>((ref) {
  return ref.watch(themeModeProvider) == AppThemeMode.neon;
});

final pomodoroMinutesProvider = StateProvider<int>(
  (ref) => AppSettings.pomodoroMinutes,
);

final breakMinutesProvider = StateProvider<int>(
  (ref) => AppSettings.breakMinutes,
);

final autoReminderProvider = StateProvider<bool>(
  (ref) => AppSettings.autoReminder,
);

final autoQuietHoursProvider = StateProvider<bool>(
  (ref) => AppSettings.autoQuietHours,
);
