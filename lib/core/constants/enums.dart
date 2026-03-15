import 'package:flutter/material.dart';
import 'app_colors.dart';

enum TaskPriority {
  urgent('Urgent', AppColors.priorityUrgent),
  high('High', AppColors.priorityHigh),
  normal('Normal', AppColors.priorityNormal),
  low('Low', AppColors.priorityLow);

  final String label;
  final Color color;
  const TaskPriority(this.label, this.color);
}

enum TaskStatus {
  notStarted('Not Started', AppColors.statusNotStarted),
  inProgress('In Progress', AppColors.statusInProgress),
  pending('Pending', AppColors.statusPending),
  completed('Completed', AppColors.statusCompleted),
  archived('Archived', AppColors.statusArchived);

  final String label;
  final Color color;
  const TaskStatus(this.label, this.color);
}

enum RepeatRule {
  none('None'),
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  weekdays('Weekdays'),
  custom('Custom');

  final String label;
  const RepeatRule(this.label);
}

enum EffortSize {
  xs('XS', 1),
  s('S', 2),
  m('M', 3),
  l('L', 5),
  xl('XL', 8);

  final String label;
  final int points;
  const EffortSize(this.label, this.points);
}

enum ProjectHealth {
  onTrack('On Track', AppColors.success),
  atRisk('At Risk', AppColors.warning),
  overdue('Overdue', AppColors.danger);

  final String label;
  final Color color;
  const ProjectHealth(this.label, this.color);
}

enum StudyTopicStatus {
  notStarted('Not Started'),
  studied('Studied'),
  revisionNeeded('Revision Needed'),
  mastered('Mastered');

  final String label;
  const StudyTopicStatus(this.label);
}

enum ReminderType {
  manualFixed,
  autoSmart,
  patternBased,
  overdueEscalation,
  dailyDigest,
  studySessionPrompt,
  milestoneAlert,
}

enum ViewLayout {
  list,
  grid,
  kanban,
}

enum HabitFrequency {
  daily('Daily'),
  weekdays('Weekdays'),
  weekends('Weekends'),
  weekly('Weekly'),
  custom('Custom');

  final String label;
  const HabitFrequency(this.label);
}
