import 'package:hive_flutter/hive_flutter.dart';

enum AppThemeMode { system, light, dark, neon }

class AppSettings {
  static const _themeKey = 'themeMode';
  static const _dailyDigestTimeKey = 'dailyDigestTime';
  static const _quietHoursStartKey = 'quietHoursStart';
  static const _quietHoursEndKey = 'quietHoursEnd';
  static const _pomodoroMinutesKey = 'pomodoroMinutes';
  static const _breakMinutesKey = 'breakMinutes';
  static const _autoReminderKey = 'autoReminder';

  static Box get _box => Hive.box('settings');

  static AppThemeMode get appThemeMode {
    final index = _box.get(_themeKey, defaultValue: 0) as int;
    if (index < 0 || index >= AppThemeMode.values.length) {
      return AppThemeMode.system;
    }
    return AppThemeMode.values[index];
  }
  static set appThemeMode(AppThemeMode mode) => _box.put(_themeKey, mode.index);

  static int get dailyDigestHour => _box.get(_dailyDigestTimeKey, defaultValue: 8) as int;
  static set dailyDigestHour(int hour) => _box.put(_dailyDigestTimeKey, hour);

  static int get quietHoursStart => _box.get(_quietHoursStartKey, defaultValue: 22) as int;
  static set quietHoursStart(int hour) => _box.put(_quietHoursStartKey, hour);

  static int get quietHoursEnd => _box.get(_quietHoursEndKey, defaultValue: 7) as int;
  static set quietHoursEnd(int hour) => _box.put(_quietHoursEndKey, hour);

  static int get pomodoroMinutes => _box.get(_pomodoroMinutesKey, defaultValue: 25) as int;
  static set pomodoroMinutes(int min) => _box.put(_pomodoroMinutesKey, min);

  static int get breakMinutes => _box.get(_breakMinutesKey, defaultValue: 5) as int;
  static set breakMinutes(int min) => _box.put(_breakMinutesKey, min);

  static bool get autoReminder => _box.get(_autoReminderKey, defaultValue: true) as bool;
  static set autoReminder(bool val) => _box.put(_autoReminderKey, val);

  static bool get autoQuietHours => _box.get('autoQuietHours', defaultValue: true) as bool;
  static set autoQuietHours(bool val) => _box.put('autoQuietHours', val);
}
