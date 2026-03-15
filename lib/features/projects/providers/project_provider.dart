import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/enums.dart';
import '../../../core/services/database_service.dart';
import '../../tasks/providers/task_provider.dart';
import '../data/project_model.dart';

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class ProjectNotifier extends StateNotifier<List<ProjectModel>> {
  ProjectNotifier() : super([]) {
    _loadProjects();
  }

  void _loadProjects() {
    final box = DatabaseService.projects;
    state = box.values.where((p) => !p.isDeleted).toList();
  }

  Future<void> addProject(
    String name, {
    int color = 0xFF5B3FE8,
    String? description,
  }) async {
    final project = ProjectModel(
      id: const Uuid().v4(),
      name: name,
      description: description,
      colorValue: color,
      createdAt: DateTime.now(),
    );
    await DatabaseService.projects.put(project.id, project);
    state = [...state, project];
  }

  Future<void> updateProject(ProjectModel updated) async {
    await DatabaseService.projects.put(updated.id, updated);
    state = [
      for (final p in state)
        if (p.id == updated.id) updated else p,
    ];
  }

  Future<void> deleteProject(String id) async {
    final existing = DatabaseService.projects.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(isDeleted: true);
    await DatabaseService.projects.put(id, updated);
    state = state.where((p) => p.id != id).toList();
  }

  Future<void> archiveProject(String id) async {
    final existing = DatabaseService.projects.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(archivedAt: DateTime.now());
    await DatabaseService.projects.put(id, updated);
    state = [
      for (final p in state)
        if (p.id == id) updated else p,
    ];
  }

  Future<void> addMilestone(String projectId, String name, DateTime targetDate) async {
    final existing = DatabaseService.projects.get(projectId);
    if (existing == null) return;
    final milestone = Milestone(
      id: const Uuid().v4(),
      name: name,
      targetDate: targetDate,
    );
    final updated = existing.copyWith(
      milestones: [...existing.milestones, milestone],
    );
    await DatabaseService.projects.put(projectId, updated);
    state = [
      for (final p in state)
        if (p.id == projectId) updated else p,
    ];
  }

  /// Auto-compute project health from task due dates.
  Future<void> computeHealth(String projectId, List<dynamic> projectTasks) async {
    final existing = DatabaseService.projects.get(projectId);
    if (existing == null) return;

    final now = DateTime.now();
    final overdueTasks = projectTasks.where((t) =>
        t.dueDate != null && t.dueDate!.isBefore(now) && !t.isCompleted);
    final totalWithDue = projectTasks.where((t) => t.dueDate != null);

    int healthIndex;
    if (totalWithDue.isEmpty) {
      healthIndex = ProjectHealth.onTrack.index;
    } else {
      final overdueRatio = overdueTasks.length / totalWithDue.length;
      if (overdueRatio > 0.3) {
        healthIndex = ProjectHealth.overdue.index;
      } else if (overdueRatio > 0.0) {
        healthIndex = ProjectHealth.atRisk.index;
      } else {
        healthIndex = ProjectHealth.onTrack.index;
      }
    }

    final updated = existing.copyWith(healthIndex: healthIndex);
    await DatabaseService.projects.put(projectId, updated);
    state = [
      for (final p in state)
        if (p.id == projectId) updated else p,
    ];
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final projectProvider =
    StateNotifierProvider<ProjectNotifier, List<ProjectModel>>((ref) {
  return ProjectNotifier();
});

final activeProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final projects = ref.watch(projectProvider);
  return projects.where((p) => !p.isArchived).toList();
});

final archivedProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final projects = ref.watch(projectProvider);
  return projects.where((p) => p.isArchived).toList();
});

final projectProgressProvider =
    Provider.family<double, String>((ref, projectId) {
  final tasks = ref.watch(tasksByProjectProvider(projectId));
  if (tasks.isEmpty) return 0.0;
  final completed = tasks.where((t) => t.isCompleted).length;
  return completed / tasks.length;
});
