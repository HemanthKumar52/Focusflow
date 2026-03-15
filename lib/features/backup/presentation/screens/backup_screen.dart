import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/neu_badge.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_card.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../services/backup_service.dart';

// ---------------------------------------------------------------------------
// Providers scoped to this feature
// ---------------------------------------------------------------------------

final backupServiceProvider = Provider<BackupService>((ref) => BackupService());

final backupFilesProvider =
    FutureProvider.autoDispose<List<BackupFile>>((ref) async {
  final service = ref.read(backupServiceProvider);
  return service.getBackupFiles();
});

final autoBackupEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.read(backupServiceProvider).isAutoBackupEnabled();
});

final autoBackupFrequencyProvider = FutureProvider<String>((ref) async {
  return ref.read(backupServiceProvider).getAutoBackupFrequency();
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isCreating = false;
  bool _autoBackup = false;
  String _frequency = 'weekly';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final service = ref.read(backupServiceProvider);
    final enabled = await service.isAutoBackupEnabled();
    final freq = await service.getAutoBackupFrequency();
    if (mounted) {
      setState(() {
        _autoBackup = enabled;
        _frequency = freq;
      });
    }
  }

  // -----------------------------------------------------------------------
  // Actions
  // -----------------------------------------------------------------------

  Future<void> _createBackup() async {
    setState(() => _isCreating = true);
    final service = ref.read(backupServiceProvider);
    await service.createBackup();
    ref.invalidate(backupFilesProvider);
    if (mounted) setState(() => _isCreating = false);
  }

  Future<void> _createEncryptedBackup() async {
    final passphrase = await _askPassphrase('Encrypt Backup');
    if (passphrase == null || passphrase.isEmpty) return;

    setState(() => _isCreating = true);
    final service = ref.read(backupServiceProvider);
    await service.createEncryptedBackup(passphrase);
    ref.invalidate(backupFilesProvider);
    if (mounted) setState(() => _isCreating = false);
  }

  Future<void> _restoreBackup(BackupFile backup) async {
    final confirmed = await _confirmRestore();
    if (!confirmed) return;

    final service = ref.read(backupServiceProvider);

    if (backup.isEncrypted) {
      final passphrase = await _askPassphrase('Decrypt Backup');
      if (passphrase == null || passphrase.isEmpty) return;
      await service.restoreEncryptedBackup(backup.path, passphrase);
    } else {
      await service.restoreBackup(backup.path);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup restored successfully.')),
      );
    }
  }

  Future<void> _deleteBackup(BackupFile backup) async {
    final service = ref.read(backupServiceProvider);
    await service.deleteBackup(backup.path);
    ref.invalidate(backupFilesProvider);
  }

  Future<void> _toggleAutoBackup(bool value) async {
    setState(() => _autoBackup = value);
    final service = ref.read(backupServiceProvider);
    await service.scheduleAutoBackup(enabled: value, frequency: _frequency);
  }

  Future<void> _changeFrequency(String freq) async {
    setState(() => _frequency = freq);
    final service = ref.read(backupServiceProvider);
    await service.scheduleAutoBackup(enabled: _autoBackup, frequency: freq);
  }

  // -----------------------------------------------------------------------
  // Dialogs
  // -----------------------------------------------------------------------

  Future<String?> _askPassphrase(String title) async {
    final controller = TextEditingController();
    return showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: AppSizes.sm),
          child: CupertinoTextField(
            controller: controller,
            placeholder: 'Enter passphrase',
            obscureText: true,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmRestore() async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Restore Backup?'),
        content: const Text(
          'This will overwrite all current data with the backup. '
          'This action cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final backupFiles = ref.watch(backupFilesProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // -- App Bar --
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.sm),
              child: Row(
                children: [
                  NeuIconButton(
                    icon: CupertinoIcons.back,
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      'Backup & Restore',
                      style: TextStyle(
                        fontSize: AppSizes.heading2,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -- Content --
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                children: [
                  // ===== Create Backup =====
                  NeuCard(
                    title: 'Create Backup',
                    child: Column(
                      children: [
                        NeuButton(
                          label: 'Create Backup',
                          icon: CupertinoIcons.cloud_upload,
                          isFullWidth: true,
                          isLoading: _isCreating,
                          onPressed: _createBackup,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        NeuButton(
                          label: 'Create Encrypted Backup',
                          icon: CupertinoIcons.lock_shield,
                          variant: NeuButtonVariant.secondary,
                          isFullWidth: true,
                          isLoading: _isCreating,
                          onPressed: _createEncryptedBackup,
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Auto-backup toggle
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.clock,
                              size: AppSizes.iconMd,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                'Auto-backup',
                                style: TextStyle(
                                  fontSize: AppSizes.body,
                                  fontWeight: FontWeight.w500,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                            CupertinoSwitch(
                              value: _autoBackup,
                              activeTrackColor: AppColors.primary,
                              onChanged: _toggleAutoBackup,
                            ),
                          ],
                        ),
                        if (_autoBackup) ...[
                          const SizedBox(height: AppSizes.sm),
                          Row(
                            children: [
                              const SizedBox(width: AppSizes.iconMd + AppSizes.sm),
                              Text(
                                'Frequency:',
                                style: TextStyle(
                                  fontSize: AppSizes.bodySmall,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              GestureDetector(
                                onTap: () => _changeFrequency('daily'),
                                child: NeuBadge(
                                  label: 'Daily',
                                  color: _frequency == 'daily'
                                      ? AppColors.primary
                                      : AppColors.textTertiaryLight,
                                ),
                              ),
                              const SizedBox(width: AppSizes.sm),
                              GestureDetector(
                                onTap: () => _changeFrequency('weekly'),
                                child: NeuBadge(
                                  label: 'Weekly',
                                  color: _frequency == 'weekly'
                                      ? AppColors.primary
                                      : AppColors.textTertiaryLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // ===== Available Backups =====
                  NeuCard(
                    title: 'Available Backups',
                    child: backupFiles.when(
                      data: (files) {
                        if (files.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSizes.lg),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    CupertinoIcons.tray,
                                    size: 36,
                                    color:
                                        textSecondary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: AppSizes.sm),
                                  Text(
                                    'No backups yet. Create one above.',
                                    style: TextStyle(
                                      fontSize: AppSizes.body,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: files
                              .map((f) => _BackupFileTile(
                                    backup: f,
                                    onRestore: () => _restoreBackup(f),
                                    onDelete: () => _deleteBackup(f),
                                  ))
                              .toList(),
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(AppSizes.lg),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.all(AppSizes.md),
                        child: Text(
                          'Failed to load backups: $e',
                          style: TextStyle(
                            fontSize: AppSizes.body,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // ===== Restore section =====
                  NeuCard(
                    title: 'Restore',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: AppSizes.iconSm,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                'Restoring a backup will overwrite all current data. '
                                'Consider creating a backup first.',
                                style: TextStyle(
                                  fontSize: AppSizes.bodySmall,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.md),
                        NeuButton(
                          label: 'Restore from File',
                          icon: CupertinoIcons.cloud_download,
                          variant: NeuButtonVariant.outline,
                          isFullWidth: true,
                          onPressed: () {
                            // TODO: integrate file_picker to select a
                            //       .focusflow file from the file system.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'File picker integration coming soon.',
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private Widgets
// ---------------------------------------------------------------------------

class _BackupFileTile extends StatelessWidget {
  final BackupFile backup;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _BackupFileTile({
    required this.backup,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final fmt = DateFormat('MMM d, yyyy  h:mm a');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm),
      child: NeuContainer(
        padding: const EdgeInsets.all(AppSizes.sm),
        child: Row(
          children: [
            Icon(
              backup.isEncrypted
                  ? CupertinoIcons.lock_fill
                  : CupertinoIcons.doc,
              size: AppSizes.iconMd,
              color: backup.isEncrypted
                  ? AppColors.warning
                  : AppColors.primary,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backup.fileName,
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        fmt.format(backup.createdAt),
                        style: TextStyle(
                          fontSize: AppSizes.caption,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      NeuBadge(
                        label: backup.sizeLabel,
                        color: AppColors.info,
                        fontSize: AppSizes.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            NeuIconButton(
              icon: CupertinoIcons.arrow_counterclockwise,
              tooltip: 'Restore',
              onPressed: onRestore,
              iconColor: AppColors.primary,
            ),
            const SizedBox(width: AppSizes.xs),
            NeuIconButton(
              icon: CupertinoIcons.trash,
              tooltip: 'Delete',
              onPressed: onDelete,
              iconColor: AppColors.danger,
            ),
          ],
        ),
      ),
    );
  }
}
