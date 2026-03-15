import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/audio_recorder_service.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../../core/widgets/neu_bottom_sheet.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../data/voice_note_model.dart';
import '../../providers/voice_note_provider.dart';

class VoiceNotesScreen extends ConsumerStatefulWidget {
  const VoiceNotesScreen({super.key});

  @override
  ConsumerState<VoiceNotesScreen> createState() => _VoiceNotesScreenState();
}

class _VoiceNotesScreenState extends ConsumerState<VoiceNotesScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingId;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = false;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _durationSub;

  @override
  void initState() {
    super.initState();
    _positionSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _currentPosition = pos);
    });
    _stateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.completed) {
            _playingId = null;
            _currentPosition = Duration.zero;
          }
        });
      }
    });
    _durationSub = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _totalDuration = dur);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _durationSub?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playVoiceNote(VoiceNoteModel note) async {
    if (_playingId == note.id && _isPlaying) {
      await _audioPlayer.pause();
      return;
    }

    if (_playingId == note.id && !_isPlaying) {
      await _audioPlayer.resume();
      return;
    }

    // Play a new note.
    setState(() {
      _playingId = note.id;
      _currentPosition = Duration.zero;
    });

    try {
      await _audioPlayer.play(DeviceFileSource(note.filePath));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not play: $e')),
        );
      }
    }
  }

  void _showRecordingSheet() {
    NeuBottomSheet.show(
      context: context,
      title: 'Record Voice Note',
      child: _RecordingSheet(
        onSaved: (title, filePath, duration, linkedType) {
          ref.read(voiceNoteProvider.notifier).addVoiceNote(
                title,
                filePath,
                duration,
                linkedEntityType: linkedType,
              );
        },
      ),
    );
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

    final voiceNotes = ref.watch(voiceNoteProvider);
    final sortedNotes = [...voiceNotes]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: GestureDetector(
        onTap: _showRecordingSheet,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.danger,
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.mic_fill,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.sm),
              child: Row(
                children: [
                  Text(
                    'Voice Notes',
                    style: TextStyle(
                      fontSize: AppSizes.heading1,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  NeuBadge(
                    label: '${sortedNotes.length}',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),

            Expanded(
              child: sortedNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.mic_off,
                            size: 64,
                            color: textSecondary.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: AppSizes.md),
                          Text(
                            'No voice notes yet',
                            style: TextStyle(
                              fontSize: AppSizes.heading4,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            'Tap the mic button to start recording',
                            style: TextStyle(
                              fontSize: AppSizes.body,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.lg),
                      itemCount: sortedNotes.length,
                      itemBuilder: (context, index) {
                        final note = sortedNotes[index];
                        final isCurrentlyPlaying = _playingId == note.id;

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSizes.sm),
                          child: NeuContainer(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Play button
                                    GestureDetector(
                                      onTap: () => _playVoiceNote(note),
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                        ),
                                        child: Icon(
                                          isCurrentlyPlaying && _isPlaying
                                              ? CupertinoIcons.pause_fill
                                              : CupertinoIcons.play_fill,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.sm),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            note.title,
                                            style: TextStyle(
                                              fontSize: AppSizes.body,
                                              fontWeight: FontWeight.w600,
                                              color: textPrimary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat('MMM d, h:mm a')
                                                .format(note.createdAt),
                                            style: TextStyle(
                                              fontSize: AppSizes.caption,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Flexible(
                                      flex: 0,
                                      child: NeuBadge(
                                        label: note.formattedDuration,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    if (note.linkedEntityType != null) ...[
                                      const SizedBox(width: AppSizes.xs),
                                      Flexible(
                                        flex: 0,
                                        child: NeuBadge(
                                          label: note.linkedEntityType!,
                                          color: AppColors.info,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Inline player (seek bar) when this note is active.
                                if (isCurrentlyPlaying) ...[
                                  const SizedBox(height: AppSizes.sm),
                                  Row(
                                    children: [
                                      Text(
                                        _formatDuration(_currentPosition),
                                        style: TextStyle(
                                          fontSize: AppSizes.caption,
                                          color: textSecondary,
                                        ),
                                      ),
                                      Expanded(
                                        child: Slider(
                                          value: _currentPosition
                                              .inMilliseconds
                                              .toDouble()
                                              .clamp(
                                                0,
                                                _totalDuration
                                                    .inMilliseconds
                                                    .toDouble()
                                                    .clamp(1, double.infinity),
                                              ),
                                          min: 0,
                                          max: _totalDuration
                                              .inMilliseconds
                                              .toDouble()
                                              .clamp(1, double.infinity),
                                          activeColor: AppColors.primary,
                                          inactiveColor: AppColors.primary
                                              .withValues(alpha: 0.2),
                                          onChanged: (value) {
                                            _audioPlayer.seek(Duration(
                                                milliseconds: value.round()));
                                          },
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(_totalDuration),
                                        style: TextStyle(
                                          fontSize: AppSizes.caption,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ---------------------------------------------------------------------------
// Recording Bottom Sheet
// ---------------------------------------------------------------------------

class _RecordingSheet extends StatefulWidget {
  final void Function(
    String title,
    String filePath,
    int durationSeconds,
    String? linkedType,
  ) onSaved;

  const _RecordingSheet({required this.onSaved});

  @override
  State<_RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends State<_RecordingSheet>
    with SingleTickerProviderStateMixin {
  final AudioRecorderService _recorder = AudioRecorderService();
  final _titleController = TextEditingController();
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0;
  Timer? _durationTimer;
  String? _filePath;
  String? _linkedEntityType;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const _entityTypes = ['todo', 'note', 'task'];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _titleController.dispose();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required. '
                'Please grant permission in Settings.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      // Show an info message when real recording is not available
      if (!_recorder.isRealRecordingAvailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recording in preview mode — a placeholder file will be saved. '
              'Full recording will be available in a future update.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      _filePath = await _recorder.generateFilePath();
      await _recorder.start(_filePath!);

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _recordingDuration = 0;
      });

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isRecording && !_isPaused) {
          setState(() => _recordingDuration++);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not start recording. Please check microphone '
              'permissions in your device Settings.\n$e',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _stopAndSave() async {
    _durationTimer?.cancel();

    try {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);

      if (path == null || _filePath == null) return;

      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Voice Note ${DateFormat('MMM d, h:mm a').format(DateTime.now())}';

      widget.onSaved(
        title,
        _filePath!,
        _recordingDuration,
        _linkedEntityType,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final minutes = _recordingDuration ~/ 60;
    final seconds = _recordingDuration % 60;
    final durationStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: AppSizes.lg,
        right: AppSizes.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSizes.md),

          // Animated pulsing circles (waveform placeholder).
          SizedBox(
            height: 80,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final scale = _isRecording && !_isPaused
                        ? _pulseAnimation.value * (0.6 + i * 0.1)
                        : 0.6;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Container(
                        width: 12,
                        height: 12 + (scale * 30),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? AppColors.danger.withValues(alpha: 0.6 + i * 0.08)
                              : textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),

          // Duration counter
          Text(
            durationStr,
            style: TextStyle(
              fontSize: AppSizes.heading1,
              fontWeight: FontWeight.w300,
              color: _isRecording ? AppColors.danger : textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSizes.lg),

          // Control buttons
          if (!_isRecording)
            NeuButton(
              label: 'Start Recording',
              icon: CupertinoIcons.mic_fill,
              onPressed: _startRecording,
              variant: NeuButtonVariant.primary,
              isFullWidth: true,
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                NeuButton(
                  label: _isPaused ? 'Resume' : 'Pause',
                  icon: _isPaused
                      ? CupertinoIcons.play_fill
                      : CupertinoIcons.pause_fill,
                  variant: NeuButtonVariant.outline,
                  onPressed:
                      _isPaused ? _resumeRecording : _pauseRecording,
                ),
                NeuButton(
                  label: 'Stop & Save',
                  icon: CupertinoIcons.stop_fill,
                  onPressed: _stopAndSave,
                ),
              ],
            ),

          const SizedBox(height: AppSizes.lg),

          // Title field
          NeuTextField(
            controller: _titleController,
            labelText: 'Title',
            hintText: 'Give your note a name...',
            prefixIcon: CupertinoIcons.textformat,
          ),
          const SizedBox(height: AppSizes.md),

          // Link to entity selector
          Row(
            children: [
              Text(
                'Link to:',
                style: TextStyle(
                  fontSize: AppSizes.bodySmall,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: NeuContainer(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm, vertical: AppSizes.xs),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _linkedEntityType,
                      isExpanded: true,
                      hint: Text(
                        'None',
                        style: TextStyle(
                          fontSize: AppSizes.body,
                          color: textSecondary,
                        ),
                      ),
                      dropdownColor: isDark
                          ? AppColors.surfaceDark
                          : AppColors.surfaceLight,
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            'None',
                            style: TextStyle(
                              fontSize: AppSizes.body,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        ..._entityTypes.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type[0].toUpperCase() + type.substring(1),
                                style: TextStyle(
                                  fontSize: AppSizes.body,
                                  color: textPrimary,
                                ),
                              ),
                            )),
                      ],
                      onChanged: (value) =>
                          setState(() => _linkedEntityType = value),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
        ],
      ),
    );
  }
}
