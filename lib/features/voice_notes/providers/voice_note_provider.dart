import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/database_service.dart';
import '../data/voice_note_model.dart';

// ---------------------------------------------------------------------------
// Voice Note Notifier
// ---------------------------------------------------------------------------

class VoiceNoteNotifier extends StateNotifier<List<VoiceNoteModel>> {
  VoiceNoteNotifier() : super([]) {
    _loadVoiceNotes();
  }

  void _loadVoiceNotes() {
    final box = DatabaseService.voiceNotes;
    state = box.values.where((v) => !v.isDeleted).toList();
  }

  Future<void> addVoiceNote(
    String title,
    String filePath,
    int durationSeconds, {
    String? linkedEntityId,
    String? linkedEntityType,
  }) async {
    final voiceNote = VoiceNoteModel(
      id: const Uuid().v4(),
      title: title,
      filePath: filePath,
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
      linkedEntityId: linkedEntityId,
      linkedEntityType: linkedEntityType,
    );
    await DatabaseService.voiceNotes.put(voiceNote.id, voiceNote);
    state = [...state, voiceNote];
  }

  Future<void> updateVoiceNote(VoiceNoteModel updated) async {
    await DatabaseService.voiceNotes.put(updated.id, updated);
    state = [
      for (final v in state)
        if (v.id == updated.id) updated else v,
    ];
  }

  Future<void> deleteVoiceNote(String id) async {
    final existing = DatabaseService.voiceNotes.get(id);
    if (existing == null) return;
    final updated = existing.copyWith(isDeleted: true);
    await DatabaseService.voiceNotes.put(id, updated);
    state = state.where((v) => v.id != id).toList();
  }
}

// ---------------------------------------------------------------------------
// Recording State Notifier
// ---------------------------------------------------------------------------

class RecordingState {
  final bool isRecording;
  final int recordingDuration;
  final String? currentFilePath;

  const RecordingState({
    this.isRecording = false,
    this.recordingDuration = 0,
    this.currentFilePath,
  });

  RecordingState copyWith({
    bool? isRecording,
    int? recordingDuration,
    String? currentFilePath,
  }) {
    return RecordingState(
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      currentFilePath: currentFilePath ?? this.currentFilePath,
    );
  }
}

class RecordingStateNotifier extends StateNotifier<RecordingState> {
  RecordingStateNotifier() : super(const RecordingState());

  void startRecording(String filePath) {
    state = RecordingState(
      isRecording: true,
      recordingDuration: 0,
      currentFilePath: filePath,
    );
  }

  void tick() {
    if (!state.isRecording) return;
    state = state.copyWith(recordingDuration: state.recordingDuration + 1);
  }

  void stopRecording() {
    state = state.copyWith(isRecording: false);
  }

  void reset() {
    state = const RecordingState();
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final voiceNoteProvider =
    StateNotifierProvider<VoiceNoteNotifier, List<VoiceNoteModel>>((ref) {
  return VoiceNoteNotifier();
});

final recordingStateProvider =
    StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
  return RecordingStateNotifier();
});

final voiceNotesByEntityProvider =
    Provider.family<List<VoiceNoteModel>, String>((ref, entityId) {
  final voiceNotes = ref.watch(voiceNoteProvider);
  return voiceNotes.where((v) => v.linkedEntityId == entityId).toList();
});
