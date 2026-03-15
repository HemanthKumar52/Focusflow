import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_card.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../data/settings_model.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final bgColor = isNeon ? AppColors.backgroundNeon : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);
    final textPrimary = isNeon ? AppColors.textPrimaryNeon : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final textSecondary = isNeon ? AppColors.textSecondaryNeon : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    final appThemeMode = ref.watch(themeModeProvider);
    final pomodoroMinutes = ref.watch(pomodoroMinutesProvider);
    final breakMinutes = ref.watch(breakMinutesProvider);
    final autoReminder = ref.watch(autoReminderProvider);
    final autoQuietHours = ref.watch(autoQuietHoursProvider);
    final userName = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: AppSizes.heading1,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ),

            // -- Profile --
            NeuCard(
              title: 'Profile',
              child: Column(
                children: [
                  _SettingsRow(
                    label: 'Name',
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          userName ?? 'Not set',
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            color: userName != null
                                ? textPrimary
                                : textSecondary,
                          ),
                        ),
                        const SizedBox(width: AppSizes.xs),
                        GestureDetector(
                          onTap: () => _showEditNameDialog(context, ref, userName),
                          child: Icon(
                            CupertinoIcons.pencil,
                            size: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  NeuButton(
                    label: 'Clear Name',
                    icon: CupertinoIcons.person_crop_circle_badge_minus,
                    variant: NeuButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: () {
                      ref.read(userNameProvider.notifier).clearName();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Name cleared. Onboarding will show on next launch.'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // -- Appearance --
            NeuCard(
              title: 'Appearance',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _ThemeSpinner(
                    selectedMode: appThemeMode,
                    isDark: isDark,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onChanged: (mode) {
                      ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // -- Notifications --
            NeuCard(
              title: 'Notifications',
              child: Column(
                children: [
                  _SettingsToggleRow(
                    label: 'Auto-reminder',
                    value: autoReminder,
                    textPrimary: textPrimary,
                    onChanged: (val) {
                      ref.read(autoReminderProvider.notifier).state = val;
                      AppSettings.autoReminder = val;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Daily digest time.
                  _SettingsRow(
                    label: 'Daily Digest',
                    trailing: GestureDetector(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime:
                              TimeOfDay(hour: AppSettings.dailyDigestHour, minute: 0),
                        );
                        if (time != null) {
                          AppSettings.dailyDigestHour = time.hour;
                        }
                      },
                      child: NeuContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm + 4, vertical: AppSizes.xs + 2),
                        child: Text(
                          '${AppSettings.dailyDigestHour.toString().padLeft(2, '0')}:00',
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Auto quiet hours toggle.
                  _SettingsToggleRow(
                    label: 'Auto-detect Quiet Hours',
                    value: autoQuietHours,
                    textPrimary: textPrimary,
                    onChanged: (val) {
                      ref.read(autoQuietHoursProvider.notifier).state = val;
                      AppSettings.autoQuietHours = val;
                      if (val) {
                        // Apply auto-detected defaults: 10 PM - 7 AM.
                        AppSettings.quietHoursStart = 22;
                        AppSettings.quietHoursEnd = 7;
                      }
                    },
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Quiet hours.
                  if (autoQuietHours)
                    _SettingsRow(
                      label: 'Quiet Hours',
                      trailing: Text(
                        '10:00 PM - 7:00 AM (auto-detected)',
                        style: TextStyle(
                          fontSize: AppSizes.bodySmall,
                          color: textSecondary,
                        ),
                      ),
                      textPrimary: textPrimary,
                    )
                  else
                    _SettingsRow(
                      label: 'Quiet Hours',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: AppSettings.quietHoursStart, minute: 0),
                              );
                              if (time != null) {
                                AppSettings.quietHoursStart = time.hour;
                              }
                            },
                            child: NeuContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.sm, vertical: AppSizes.xs + 2),
                              child: Text(
                                '${AppSettings.quietHoursStart.toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                  fontSize: AppSizes.bodySmall,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSizes.xs),
                            child: Text(
                              '-',
                              style: TextStyle(color: textSecondary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay(
                                    hour: AppSettings.quietHoursEnd, minute: 0),
                              );
                              if (time != null) {
                                AppSettings.quietHoursEnd = time.hour;
                              }
                            },
                            child: NeuContainer(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.sm, vertical: AppSizes.xs + 2),
                              child: Text(
                                '${AppSettings.quietHoursEnd.toString().padLeft(2, '0')}:00',
                                style: TextStyle(
                                  fontSize: AppSizes.bodySmall,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textPrimary: textPrimary,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // -- Study --
            NeuCard(
              title: 'Study',
              child: Column(
                children: [
                  _SettingsSliderRow(
                    label: 'Pomodoro Duration',
                    value: pomodoroMinutes,
                    min: 5,
                    max: 90,
                    suffix: 'min',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onChanged: (val) {
                      ref.read(pomodoroMinutesProvider.notifier).state = val;
                      AppSettings.pomodoroMinutes = val;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                  _SettingsSliderRow(
                    label: 'Break Duration',
                    value: breakMinutes,
                    min: 1,
                    max: 30,
                    suffix: 'min',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    onChanged: (val) {
                      ref.read(breakMinutesProvider.notifier).state = val;
                      AppSettings.breakMinutes = val;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // -- Data --
            NeuCard(
              title: 'Data',
              child: Column(
                children: [
                  NeuButton(
                    label: 'Export JSON',
                    icon: CupertinoIcons.share,
                    variant: NeuButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: () => _exportData(context),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  NeuButton(
                    label: 'Import JSON',
                    icon: CupertinoIcons.tray_arrow_down,
                    variant: NeuButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: () => _importData(context),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  NeuButton(
                    label: 'Clear All Data',
                    icon: CupertinoIcons.trash,
                    variant: NeuButtonVariant.outline,
                    isFullWidth: true,
                    onPressed: () => _clearData(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // -- About --
            NeuCard(
              title: 'About',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SettingsRow(
                    label: 'Version',
                    trailing: Text(
                      '1.0.0',
                      style: TextStyle(
                        fontSize: AppSizes.body,
                        color: textSecondary,
                      ),
                    ),
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  _SettingsRow(
                    label: 'Build',
                    trailing: Text(
                      'HK',
                      style: TextStyle(
                        fontSize: AppSizes.body,
                        color: textSecondary,
                      ),
                    ),
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _SettingsRow(
                    label: 'Built by',
                    trailing: Text(
                      'HK',
                      style: TextStyle(
                        fontSize: AppSizes.body,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    textPrimary: textPrimary,
                  ),
                  const SizedBox(height: AppSizes.md),
                  Center(
                    child: Text(
                      'FocusFlow - Your productivity companion',
                      style: TextStyle(
                        fontSize: AppSizes.caption,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Center(
                    child: Text(
                      '\u00a9 HK 2026. All rights reserved.',
                      style: TextStyle(
                        fontSize: AppSizes.caption,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.xxl + AppSizes.xl),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(
      BuildContext context, WidgetRef ref, String? currentName) {
    final controller = TextEditingController(text: currentName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isNotEmpty) {
              ref.read(userNameProvider.notifier).setName(name);
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(userNameProvider.notifier).setName(name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/focusflow_export_$timestamp.json');

      // Collect all box data as Maps.
      final export = <String, dynamic>{};
      for (final boxName in [
        'todos',
        'notes',
        'notebooks',
        'tasks',
        'projects',
        'studyPlans',
        'studySessions',
        'voiceNotes',
        'settings',
      ]) {
        try {
          final box = Hive.box(boxName);
          export[boxName] = box.toMap().map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
        } catch (_) {
          // Box might not be open or might be typed - skip gracefully.
        }
      }

      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(export));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Exported to ${file.path}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    // Placeholder: In a production app you'd use file_picker.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Import requires file_picker integration')),
      );
    }
  }

  Future<void> _clearData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your todos, notes, tasks, '
          'projects, study plans, voice notes, and settings. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final boxName in [
        'todos',
        'notes',
        'notebooks',
        'tasks',
        'projects',
        'studyPlans',
        'studySessions',
        'voiceNotes',
        'settings',
      ]) {
        try {
          final box = Hive.box(boxName);
          await box.clear();
        } catch (_) {
          // Typed boxes need to be accessed differently.
          try {
            await Hive.box<dynamic>(boxName).clear();
          } catch (_) {}
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All data cleared')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Theme spinner (CupertinoPicker)
// ---------------------------------------------------------------------------

class _ThemeSpinner extends StatefulWidget {
  final AppThemeMode selectedMode;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<AppThemeMode> onChanged;

  const _ThemeSpinner({
    required this.selectedMode,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.onChanged,
  });

  @override
  State<_ThemeSpinner> createState() => _ThemeSpinnerState();
}

class _ThemeSpinnerState extends State<_ThemeSpinner> {
  late FixedExtentScrollController _scrollController;

  static const _modes = AppThemeMode.values;

  static const _labels = ['System', 'Light', 'Dark', 'Neon'];

  static const _icons = [
    CupertinoIcons.device_phone_portrait,
    CupertinoIcons.sun_max_fill,
    CupertinoIcons.moon_fill,
    CupertinoIcons.bolt_fill,
  ];

  static const _colors = [
    AppColors.primary,           // System
    Color(0xFFF5A623),           // Light - amber/yellow
    Color(0xFF5B3FE8),           // Dark - indigo
    Color(0xFF00D4FF),           // Neon - ice blue
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(
      initialItem: widget.selectedMode.index,
    );
  }

  @override
  void didUpdateWidget(covariant _ThemeSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMode != widget.selectedMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateToItem(
            widget.selectedMode.index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      isPressed: true, // inset / recessed look
      height: 120,
      padding: EdgeInsets.zero,
      child: CupertinoPicker(
        scrollController: _scrollController,
        itemExtent: 40,
        diameterRatio: 1.2,
        squeeze: 1.0,
        selectionOverlay: Container(
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        onSelectedItemChanged: (index) {
          widget.onChanged(AppThemeMode.values[index]);
        },
        children: List.generate(_modes.length, (i) {
          final isSelected = widget.selectedMode == _modes[i];
          return Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _icons[i],
                  size: 18,
                  color: isSelected ? _colors[i] : widget.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: AppSizes.body,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? _colors[i] : widget.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper rows
// ---------------------------------------------------------------------------

class _SettingsRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final Color textPrimary;

  const _SettingsRow({
    required this.label,
    required this.trailing,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.body,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        trailing,
      ],
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final Color textPrimary;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: AppSizes.body,
              color: textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SettingsSliderRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final Color textPrimary;
  final Color textSecondary;
  final ValueChanged<int> onChanged;

  const _SettingsSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.textPrimary,
    required this.textSecondary,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.body,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Text(
              '$value $suffix',
              style: TextStyle(
                fontSize: AppSizes.body,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.primary.withValues(alpha: 0.2),
          onChanged: (v) => onChanged(v.round()),
        ),
      ],
    );
  }
}
