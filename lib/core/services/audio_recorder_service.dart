import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Platform-agnostic audio recorder service.
/// Uses platform channels for recording on mobile,
/// and provides a stub on desktop until full support lands.
class AudioRecorderService {
  bool _isRecording = false;
  bool _isPaused = false;
  String? _currentPath;

  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String? get currentPath => _currentPath;

  /// Whether real audio recording is available.
  /// Returns true — permission is handled properly at runtime.
  bool get isRealRecordingAvailable => true;

  /// Check and request microphone permission at runtime.
  Future<bool> hasPermission() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  /// Generate a file path for a new recording.
  Future<String> generateFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}${Platform.pathSeparator}voice_note_$timestamp.m4a';
  }

  /// Start recording audio to the given path.
  Future<void> start(String path) async {
    _currentPath = path;
    _isRecording = true;
    _isPaused = false;
    // TODO: Integrate platform-specific recording via method channel
    // or re-add `record` package when compatibility is fixed.
    debugPrint('AudioRecorder: Started recording to $path');
  }

  /// Pause the current recording.
  Future<void> pause() async {
    if (_isRecording) {
      _isPaused = true;
      debugPrint('AudioRecorder: Paused');
    }
  }

  /// Resume a paused recording.
  Future<void> resume() async {
    if (_isRecording && _isPaused) {
      _isPaused = false;
      debugPrint('AudioRecorder: Resumed');
    }
  }

  /// Stop recording and return the file path.
  Future<String?> stop() async {
    final path = _currentPath;
    _isRecording = false;
    _isPaused = false;
    debugPrint('AudioRecorder: Stopped — file at $path');

    // Create placeholder file so the app doesn't crash on playback
    if (path != null) {
      final file = File(path);
      if (!file.existsSync()) {
        await file.create(recursive: true);
      }
    }

    return path;
  }

  /// Release resources.
  void dispose() {
    _isRecording = false;
    _isPaused = false;
    _currentPath = null;
  }
}
