import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_progress_ring.dart';
import '../../data/study_model.dart';
import '../../providers/study_provider.dart';
import '../../../settings/providers/settings_provider.dart';

class SessionTimerScreen extends ConsumerStatefulWidget {
  const SessionTimerScreen({super.key});

  @override
  ConsumerState<SessionTimerScreen> createState() => _SessionTimerScreenState();
}

class _SessionTimerScreenState extends ConsumerState<SessionTimerScreen> {
  Timer? _ticker;
  bool _isBreakMode = false;
  int _completedSessions = 0;
  int _targetSessions = 5;
  String _currentTopicName = 'Study Session';
  String? _currentTopicId;
  String? _activePlanId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSession());
  }

  void _initSession() {
    final plans = ref.read(studyPlanProvider);
    if (plans.isNotEmpty) {
      final now = DateTime.now();
      final activePlan = plans.firstWhere(
        (p) => p.endDate.isAfter(now),
        orElse: () => plans.first,
      );
      _activePlanId = activePlan.id;
      _targetSessions = activePlan.sessionsPerWeek;

      // Find the first topic due for review.
      final todayEnd = DateTime(now.year, now.month, now.day)
          .add(const Duration(days: 1));
      for (final bucket in activePlan.weeklyTopics) {
        for (final topic in bucket.topics) {
          final status = StudyTopicStatus.values[topic.statusIndex];
          if (status != StudyTopicStatus.mastered) {
            if (topic.nextReviewDate == null ||
                topic.nextReviewDate!.isBefore(todayEnd) ||
                topic.lastStudied == null) {
              setState(() {
                _currentTopicName = topic.name;
                _currentTopicId = topic.id;
              });
              return;
            }
          }
        }
      }
    }
  }

  void _startTimer() {
    final timerNotifier = ref.read(activeTimerProvider.notifier);
    final pomodoroMinutes = ref.read(pomodoroMinutesProvider);
    final breakMinutes = ref.read(breakMinutesProvider);

    final duration = _isBreakMode ? breakMinutes : pomodoroMinutes;
    timerNotifier.start(
      durationMinutes: duration,
      sessionId: const Uuid().v4(),
    );

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      final state = ref.read(activeTimerProvider);
      if (state.isRunning && !state.isPaused) {
        ref.read(activeTimerProvider.notifier).tick();

        // Check if timer completed.
        if (ref.read(activeTimerProvider).secondsRemaining <= 0) {
          _onTimerComplete();
        }
      }
    });
  }

  void _pauseTimer() {
    ref.read(activeTimerProvider.notifier).pause();
  }

  void _resumeTimer() {
    ref.read(activeTimerProvider.notifier).resume();
  }

  void _resetTimer() {
    _ticker?.cancel();
    ref.read(activeTimerProvider.notifier).reset();
    setState(() => _isBreakMode = false);
  }

  void _skipBreak() {
    _ticker?.cancel();
    ref.read(activeTimerProvider.notifier).reset();
    setState(() => _isBreakMode = false);
  }

  void _onTimerComplete() {
    _ticker?.cancel();

    if (!_isBreakMode) {
      // Study session completed — haptic feedback.
      HapticFeedback.mediumImpact();
      setState(() => _completedSessions++);

      // Log the session.
      final session = StudySession(
        id: const Uuid().v4(),
        planId: _activePlanId ?? '',
        topicId: _currentTopicId,
        startTime: DateTime.now().subtract(
          Duration(minutes: ref.read(pomodoroMinutesProvider)),
        ),
        endTime: DateTime.now(),
        durationMinutes: ref.read(pomodoroMinutesProvider),
        isCompleted: true,
      );
      ref.read(studySessionProvider.notifier).addSession(session);

      // Mark topic as studied if we have one.
      if (_activePlanId != null && _currentTopicId != null) {
        ref.read(studyPlanProvider.notifier).updateTopicStatus(
              _activePlanId!,
              _currentTopicId!,
              StudyTopicStatus.studied,
            );
      }

      // Show celebration.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(CupertinoIcons.checkmark_seal_fill,
                    color: Colors.white),
                const SizedBox(width: 8),
                Text('Session $_completedSessions complete!'),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Switch to break mode.
      setState(() => _isBreakMode = true);
      ref.read(activeTimerProvider.notifier).reset();
    } else {
      // Break completed, back to study mode.
      setState(() => _isBreakMode = false);
      ref.read(activeTimerProvider.notifier).reset();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final timerState = ref.watch(activeTimerProvider);
    final pomodoroMinutes = ref.watch(pomodoroMinutesProvider);
    final breakMinutes = ref.watch(breakMinutesProvider);

    final totalSeconds = _isBreakMode
        ? breakMinutes * 60
        : pomodoroMinutes * 60;
    final progress = totalSeconds > 0
        ? 1.0 - (timerState.secondsRemaining / totalSeconds)
        : 0.0;

    final minutes = timerState.secondsRemaining ~/ 60;
    final seconds = timerState.secondsRemaining % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    final progressColor =
        _isBreakMode ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.sm, AppSizes.sm, AppSizes.lg, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(CupertinoIcons.back, color: textPrimary),
                    onPressed: () {
                      _ticker?.cancel();
                      context.pop();
                    },
                  ),
                  Expanded(
                    child: Text(
                      _isBreakMode ? 'Break Time' : 'Study Session',
                      style: TextStyle(
                        fontSize: AppSizes.heading3,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  // Inline settings: change duration.
                  PopupMenuButton<int>(
                    icon: Icon(CupertinoIcons.settings,
                        color: textSecondary, size: 22),
                    onSelected: (value) {
                      ref.read(pomodoroMinutesProvider.notifier).state = value;
                      if (!timerState.isRunning) {
                        ref.read(activeTimerProvider.notifier).reset();
                      }
                    },
                    itemBuilder: (context) => [
                      for (final min in [15, 25, 30, 45, 60])
                        PopupMenuItem(
                          value: min,
                          child: Text('$min minutes'),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 1),

            // Timer circle
            NeuProgressRing(
              progress: progress.clamp(0.0, 1.0),
              size: 240,
              strokeWidth: 12,
              progressColor: progressColor,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: textPrimary,
                      letterSpacing: 2,
                    ),
                  ),
                  if (_isBreakMode)
                    Text(
                      'Break',
                      style: TextStyle(
                        fontSize: AppSizes.body,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: AppSizes.lg),

            // Topic name
            Text(
              _currentTopicName,
              style: TextStyle(
                fontSize: AppSizes.heading4,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSizes.sm),

            // Session counter
            NeuContainer(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: AppSizes.sm),
              child: Text(
                'Session $_completedSessions of $_targetSessions',
                style: TextStyle(
                  fontSize: AppSizes.body,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ),

            const Spacer(flex: 1),

            // Control buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reset button
                  NeuButton(
                    label: 'Reset',
                    icon: CupertinoIcons.arrow_counterclockwise,
                    variant: NeuButtonVariant.outline,
                    onPressed: _resetTimer,
                  ),

                  // Start / Pause / Resume button
                  if (!timerState.isRunning)
                    NeuButton(
                      label: 'Start',
                      icon: CupertinoIcons.play_fill,
                      onPressed: _startTimer,
                      size: NeuButtonSize.large,
                    )
                  else if (timerState.isPaused)
                    NeuButton(
                      label: 'Resume',
                      icon: CupertinoIcons.play_fill,
                      onPressed: _resumeTimer,
                      size: NeuButtonSize.large,
                    )
                  else
                    NeuButton(
                      label: 'Pause',
                      icon: CupertinoIcons.pause_fill,
                      onPressed: _pauseTimer,
                      size: NeuButtonSize.large,
                    ),

                  // Skip break button (only during break)
                  if (_isBreakMode)
                    NeuButton(
                      label: 'Skip',
                      icon: CupertinoIcons.forward_fill,
                      variant: NeuButtonVariant.ghost,
                      onPressed: _skipBreak,
                    )
                  else
                    // Placeholder to keep layout balanced.
                    const SizedBox(width: 80),
                ],
              ),
            ),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
