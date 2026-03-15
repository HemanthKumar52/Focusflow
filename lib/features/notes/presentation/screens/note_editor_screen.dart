import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../../../core/widgets/emoji_picker_widget.dart';
import '../../data/note_model.dart';
import '../../providers/note_provider.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _tagController;

  NoteModel? _note;
  bool _isNew = true;
  bool _isDirty = false;
  Timer? _autoSaveTimer;
  String? _selectedNotebookId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _bodyController = TextEditingController();
    _tagController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNote();
    });
  }

  void _loadNote() {
    if (widget.noteId != null) {
      final notes = ref.read(noteProvider);
      try {
        _note = notes.firstWhere((n) => n.id == widget.noteId);
        _isNew = false;
        _titleController.text = _note!.title;
        _bodyController.text = _note!.body;
        _selectedNotebookId = _note!.notebookId;
        setState(() {});
      } catch (_) {
        // Note not found, treat as new
      }
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _saveIfDirty();
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    _isDirty = true;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text;

    // Don't save completely empty notes
    if (title.isEmpty && body.isEmpty) return;

    if (_isNew) {
      await ref.read(noteProvider.notifier).addNote(
            title.isEmpty ? 'Untitled' : title,
          );
      // Get the newly created note and update it with body and notebook
      final notes = ref.read(noteProvider);
      if (notes.isNotEmpty) {
        final created = notes.last;
        _note = created;
        _isNew = false;
        await ref.read(noteProvider.notifier).updateNote(
              created.copyWith(
                title: title.isEmpty ? 'Untitled' : title,
                body: body,
                notebookId: _selectedNotebookId,
                tags: _note?.tags ?? [],
              ),
            );
      }
    } else if (_note != null) {
      await ref.read(noteProvider.notifier).updateNote(
            _note!.copyWith(
              title: title.isEmpty ? 'Untitled' : title,
              body: body,
              notebookId: _selectedNotebookId,
              tags: _note!.tags,
            ),
          );
      // Refresh the local note reference
      final notes = ref.read(noteProvider);
      try {
        _note = notes.firstWhere((n) => n.id == _note!.id);
      } catch (_) {}
    }

    _isDirty = false;
  }

  void _saveIfDirty() {
    if (_isDirty) {
      _save();
    }
  }

  int get _wordCount {
    final text = _bodyController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).length;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final textPrimary = isNeon ? AppColors.textPrimaryNeon : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final textSecondary = isNeon ? AppColors.textSecondaryNeon : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final textTertiary = isNeon ? AppColors.textTertiaryNeon : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);
    final bgColor = isNeon ? AppColors.backgroundNeon : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    final notebooks = ref.watch(notebookProvider);

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveIfDirty();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Column(
            children: [
              // Top bar
              _buildTopBar(context, isDark, textPrimary, textSecondary),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title field
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => _onContentChanged(),
                        style: TextStyle(
                          fontSize: AppSizes.heading2,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Note title',
                          hintStyle: TextStyle(
                            fontSize: AppSizes.heading2,
                            fontWeight: FontWeight.w700,
                            color: textTertiary.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      // Timestamps
                      if (_note != null) ...[
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          'Created ${_note!.createdAt.friendlyDateTime}  ·  Updated ${_note!.updatedAt.friendlyDateTime}',
                          style: TextStyle(
                            fontSize: AppSizes.caption,
                            color: textTertiary,
                          ),
                        ),
                      ],

                      // Notebook selector
                      const SizedBox(height: AppSizes.sm),
                      _buildNotebookSelector(
                          context, isDark, notebooks, textSecondary),

                      // Tags
                      const SizedBox(height: AppSizes.sm),
                      _buildTagsEditor(isDark, textPrimary, textSecondary,
                          textTertiary),

                      const SizedBox(height: AppSizes.md),

                      // Body editor
                      TextField(
                        controller: _bodyController,
                        onChanged: (_) => _onContentChanged(),
                        style: TextStyle(
                          fontSize: AppSizes.body,
                          color: textPrimary,
                          height: 1.6,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Start writing... (Markdown supported)',
                          hintStyle: TextStyle(
                            color: textTertiary.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        maxLines: null,
                        minLines: 20,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom toolbar
              _buildBottomToolbar(isDark, textSecondary, textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark, Color textPrimary,
      Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.sm,
        AppSizes.sm,
        AppSizes.sm,
        AppSizes.xs,
      ),
      child: Row(
        children: [
          NeuIconButton(
            icon: CupertinoIcons.back,
            onPressed: () {
              _saveIfDirty();
              context.pop();
            },
            tooltip: 'Back',
          ),
          const Spacer(),
          if (_note != null)
            NeuIconButton(
              icon: _note!.isPinned
                  ? CupertinoIcons.pin_fill
                  : CupertinoIcons.pin,
              iconColor: _note!.isPinned ? AppColors.primary : null,
              onPressed: () {
                ref.read(noteProvider.notifier).togglePin(_note!.id);
                setState(() {
                  _note = _note!.copyWith(isPinned: !_note!.isPinned);
                });
              },
              tooltip: _note!.isPinned ? 'Unpin' : 'Pin',
            ),
          const SizedBox(width: AppSizes.xs),
          NeuIconButton(
            icon: CupertinoIcons.mic,
            onPressed: () {
              // Link to voice recording — navigate to voice notes
              context.push('/voice');
            },
            tooltip: 'Voice note',
          ),
          const SizedBox(width: AppSizes.xs),
          NeuIconButton(
            icon: CupertinoIcons.ellipsis,
            onPressed: () => _showMoreOptions(context),
            tooltip: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildNotebookSelector(BuildContext context, bool isDark,
      List<NotebookModel> notebooks, Color textSecondary) {
    if (notebooks.isEmpty) return const SizedBox.shrink();

    final selected = _selectedNotebookId != null
        ? notebooks
            .cast<NotebookModel?>()
            .firstWhere((nb) => nb!.id == _selectedNotebookId,
                orElse: () => null)
        : null;

    return GestureDetector(
      onTap: () => _showNotebookPicker(context, notebooks),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm + 2,
          vertical: AppSizes.xs + 2,
        ),
        decoration: NeumorphicDecoration.raised(
          isDark: isDark,
          isNeon: AppColors.isNeonTheme(context),
          borderRadius: AppSizes.radiusFull,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.folder,
              size: AppSizes.iconSm,
              color: selected != null
                  ? Color(selected.colorValue)
                  : textSecondary,
            ),
            const SizedBox(width: AppSizes.xs),
            Text(
              selected?.name ?? 'No Notebook',
              style: TextStyle(
                fontSize: AppSizes.bodySmall,
                fontWeight: FontWeight.w500,
                color: selected != null
                    ? Color(selected.colorValue)
                    : textSecondary,
              ),
            ),
            const SizedBox(width: AppSizes.xs),
            Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showNotebookPicker(
      BuildContext context, List<NotebookModel> notebooks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            ListTile(
              leading: const Icon(CupertinoIcons.xmark_circle),
              title: const Text('No Notebook'),
              selected: _selectedNotebookId == null,
              onTap: () {
                setState(() => _selectedNotebookId = null);
                _onContentChanged();
                Navigator.pop(ctx);
              },
            ),
            ...notebooks.map(
              (nb) => ListTile(
                leading: Icon(
                  CupertinoIcons.folder_fill,
                  color: Color(nb.colorValue),
                ),
                title: Text(nb.name),
                selected: _selectedNotebookId == nb.id,
                onTap: () {
                  setState(() => _selectedNotebookId = nb.id);
                  _onContentChanged();
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsEditor(
      bool isDark, Color textPrimary, Color textSecondary, Color textTertiary) {
    final tags = _note?.tags ?? [];
    final isNeon = AppColors.isNeonTheme(context);

    return Wrap(
      spacing: AppSizes.xs,
      runSpacing: AppSizes.xs,
      children: [
        ...tags.map(
          (tag) => Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.xs,
            ),
            decoration: NeumorphicDecoration.raised(
              isDark: isDark,
              isNeon: isNeon,
              borderRadius: AppSizes.radiusFull,
              color: (isNeon ? AppColors.primaryNeon : AppColors.primary).withValues(alpha: isDark ? 0.2 : 0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '#$tag',
                  style: TextStyle(
                    fontSize: AppSizes.caption,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                GestureDetector(
                  onTap: () {
                    final updated =
                        List<String>.from(_note?.tags ?? [])..remove(tag);
                    _note = _note?.copyWith(tags: updated);
                    _onContentChanged();
                    setState(() {});
                  },
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 14,
                    color: AppColors.primary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Add tag button
        GestureDetector(
          onTap: () => _showAddTagDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: AppSizes.xs,
            ),
            decoration: NeumorphicDecoration.raised(
              isDark: isDark,
              isNeon: isNeon,
              borderRadius: AppSizes.radiusFull,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.tag,
                  size: 12,
                  color: textTertiary,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  'Add tag',
                  style: TextStyle(
                    fontSize: AppSizes.caption,
                    color: textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddTagDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _tagController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(
          'Add Tag',
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        content: NeuTextField(
          controller: _tagController,
          hintText: 'Tag name',
          autofocus: true,
          onSubmitted: (value) {
            _addTag(value);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              _addTag(_tagController.text);
              Navigator.pop(ctx);
            },
            child: const Text(
              'Add',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();
    if (trimmed.isEmpty) return;
    final currentTags = List<String>.from(_note?.tags ?? []);
    if (!currentTags.contains(trimmed)) {
      currentTags.add(trimmed);
      if (_note != null) {
        _note = _note!.copyWith(tags: currentTags);
      }
      _onContentChanged();
      setState(() {});
    }
  }

  Widget _buildBottomToolbar(
      bool isDark, Color textSecondary, Color textTertiary) {
    return Container(
      decoration: NeumorphicDecoration.raised(
        isDark: isDark,
        isNeon: AppColors.isNeonTheme(context),
        borderRadius: 0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          // Formatting buttons (for future rich editing)
          _buildToolbarButton(CupertinoIcons.bold, 'Bold', isDark),
          _buildToolbarButton(CupertinoIcons.italic, 'Italic', isDark),
          _buildToolbarButton(
              CupertinoIcons.textformat_size, 'Heading', isDark),
          _buildToolbarButton(
              CupertinoIcons.chevron_left_slash_chevron_right, 'Code', isDark),
          _buildToolbarButton(
              CupertinoIcons.checkmark_square, 'Checklist', isDark),
          _buildToolbarButton(CupertinoIcons.link, 'Link', isDark),
          _buildToolbarButton(Icons.emoji_emotions_outlined, 'Emoji', isDark),

          const Spacer(),

          // Word count
          Text(
            '$_wordCount words',
            style: TextStyle(
              fontSize: AppSizes.caption,
              color: textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, String tooltip, bool isDark) {
    final color =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          // Placeholder for future markdown insertion
          _insertMarkdown(tooltip);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xs,
          ),
          child: Icon(icon, size: AppSizes.iconSm, color: color),
        ),
      ),
    );
  }

  void _insertEmoji(TextEditingController controller, String emoji) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    _onContentChanged();
  }

  void _insertMarkdown(String type) {
    if (type == 'Emoji') {
      EmojiPicker.show(context, onSelected: (emoji) {
        _insertEmoji(_bodyController, emoji);
      });
      return;
    }

    final text = _bodyController.text;
    final selection = _bodyController.selection;
    final start = selection.baseOffset;
    final end = selection.extentOffset;

    if (start < 0) return;

    String prefix;
    String suffix;

    switch (type) {
      case 'Bold':
        prefix = '**';
        suffix = '**';
        break;
      case 'Italic':
        prefix = '_';
        suffix = '_';
        break;
      case 'Heading':
        prefix = '## ';
        suffix = '';
        break;
      case 'Code':
        prefix = '`';
        suffix = '`';
        break;
      case 'Checklist':
        prefix = '- [ ] ';
        suffix = '';
        break;
      case 'Link':
        prefix = '[';
        suffix = '](url)';
        break;
      default:
        return;
    }

    final selectedText = start != end ? text.substring(start, end) : '';
    final newText = text.replaceRange(
      start,
      end,
      '$prefix$selectedText$suffix',
    );
    _bodyController.text = newText;
    _bodyController.selection = TextSelection.collapsed(
      offset: start + prefix.length + selectedText.length,
    );
    _onContentChanged();
  }

  void _showMoreOptions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            ListTile(
              leading: const Icon(
                CupertinoIcons.share,
                color: AppColors.primary,
              ),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(ctx);
                // Share functionality placeholder
              },
            ),
            ListTile(
              leading: const Icon(
                CupertinoIcons.arrow_up_doc,
                color: AppColors.secondary,
              ),
              title: const Text('Export as Markdown'),
              onTap: () {
                Navigator.pop(ctx);
                // Export functionality placeholder
              },
            ),
            if (_note != null)
              ListTile(
                leading: const Icon(
                  CupertinoIcons.trash,
                  color: AppColors.danger,
                ),
                title: const Text('Delete'),
                onTap: () {
                  ref.read(noteProvider.notifier).deleteNote(_note!.id);
                  Navigator.pop(ctx);
                  context.pop();
                },
              ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }
}
