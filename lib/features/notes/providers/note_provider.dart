import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database_service.dart';
import '../data/note_model.dart';

// ---------------------------------------------------------------------------
// Note Notifier
// ---------------------------------------------------------------------------

class NoteNotifier extends StateNotifier<List<NoteModel>> {
  NoteNotifier() : super([]) {
    _loadNotes();
  }

  void _loadNotes() {
    final box = DatabaseService.notes;
    state = box.values.where((n) => !n.isDeleted).toList();
  }

  Future<void> addNote(String title) async {
    final now = DateTime.now();
    final note = NoteModel(
      id: const Uuid().v4(),
      title: title,
      createdAt: now,
      updatedAt: now,
    );
    await DatabaseService.notes.put(note.id, note);
    state = [...state, note];
  }

  Future<void> updateNote(NoteModel updated) async {
    final note = updated.copyWith(updatedAt: DateTime.now());
    await DatabaseService.notes.put(note.id, note);
    state = [
      for (final n in state)
        if (n.id == note.id) note else n,
    ];
  }

  Future<void> deleteNote(String id) async {
    final existing = DatabaseService.notes.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(isDeleted: true);
    await DatabaseService.notes.put(id, updated);
    state = state.where((n) => n.id != id).toList();
  }

  Future<void> togglePin(String id) async {
    final existing = DatabaseService.notes.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      isPinned: !existing.isPinned,
      updatedAt: DateTime.now(),
    );
    await DatabaseService.notes.put(id, updated);
    state = [
      for (final n in state)
        if (n.id == id) updated else n,
    ];
  }

  Future<void> archiveNote(String id) async {
    final existing = DatabaseService.notes.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(
      isArchived: !existing.isArchived,
      updatedAt: DateTime.now(),
    );
    await DatabaseService.notes.put(id, updated);
    state = [
      for (final n in state)
        if (n.id == id) updated else n,
    ];
  }

  List<NoteModel> searchNotes(String query) {
    if (query.isEmpty) return state;
    final lower = query.toLowerCase();
    return state.where((n) {
      return n.title.toLowerCase().contains(lower) ||
          n.body.toLowerCase().contains(lower) ||
          n.tags.any((tag) => tag.toLowerCase().contains(lower));
    }).toList();
  }
}

// ---------------------------------------------------------------------------
// Notebook Notifier
// ---------------------------------------------------------------------------

class NotebookNotifier extends StateNotifier<List<NotebookModel>> {
  NotebookNotifier() : super([]) {
    _loadNotebooks();
  }

  void _loadNotebooks() {
    final box = DatabaseService.notebooks;
    state = box.values.toList();
  }

  Future<void> addNotebook(String name, {int colorValue = 0xFF5B3FE8}) async {
    final notebook = NotebookModel(
      id: const Uuid().v4(),
      name: name,
      colorValue: colorValue,
      createdAt: DateTime.now(),
    );
    await DatabaseService.notebooks.put(notebook.id, notebook);
    state = [...state, notebook];
  }

  Future<void> updateNotebook(NotebookModel updated) async {
    await DatabaseService.notebooks.put(updated.id, updated);
    state = [
      for (final nb in state)
        if (nb.id == updated.id) updated else nb,
    ];
  }

  Future<void> deleteNotebook(String id) async {
    await DatabaseService.notebooks.delete(id);
    state = state.where((nb) => nb.id != id).toList();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final noteProvider =
    StateNotifierProvider<NoteNotifier, List<NoteModel>>((ref) {
  return NoteNotifier();
});

final pinnedNotesProvider = Provider<List<NoteModel>>((ref) {
  final notes = ref.watch(noteProvider);
  return notes.where((n) => n.isPinned && !n.isArchived).toList();
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = Provider<List<NoteModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  final notifier = ref.read(noteProvider.notifier);
  return notifier.searchNotes(query);
});

final notebookProvider =
    StateNotifierProvider<NotebookNotifier, List<NotebookModel>>((ref) {
  return NotebookNotifier();
});
