import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../../../core/widgets/neu_icon_button.dart';
import '../../../../core/widgets/neu_text_field.dart';
import '../../data/note_model.dart';
import '../../providers/note_provider.dart';
import '../widgets/note_card_widget.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  final _searchController = TextEditingController();
  bool _isSearchVisible = false;
  String? _selectedNotebookId;
  ViewLayout _viewLayout = ViewLayout.list;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final textPrimary = isNeon ? AppColors.textPrimaryNeon : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final textSecondary = isNeon ? AppColors.textSecondaryNeon : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    final bgColor = isNeon ? AppColors.backgroundNeon : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    final allNotes = ref.watch(noteProvider);
    final notebooks = ref.watch(notebookProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // Apply search filter
    List<NoteModel> filteredNotes;
    if (searchQuery.isNotEmpty) {
      filteredNotes = ref.watch(searchResultsProvider);
    } else {
      filteredNotes = allNotes.where((n) => !n.isArchived).toList();
    }

    // Apply notebook filter
    if (_selectedNotebookId != null) {
      filteredNotes = filteredNotes
          .where((n) => n.notebookId == _selectedNotebookId)
          .toList();
    }

    // Sort by updated date descending
    filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Split into pinned and unpinned (only when not searching)
    final pinned = searchQuery.isEmpty
        ? filteredNotes.where((n) => n.isPinned).toList()
        : <NoteModel>[];
    final unpinned = searchQuery.isEmpty
        ? filteredNotes.where((n) => !n.isPinned).toList()
        : filteredNotes;

    return Scaffold(
      backgroundColor: bgColor,
      floatingActionButton: _buildFab(isDark),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.lg,
                  AppSizes.md,
                  AppSizes.lg,
                  AppSizes.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: AppSizes.heading1,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ),
                    NeuIconButton(
                      icon: CupertinoIcons.search,
                      onPressed: () {
                        setState(() {
                          _isSearchVisible = !_isSearchVisible;
                          if (!_isSearchVisible) {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          }
                        });
                      },
                      tooltip: 'Search',
                    ),
                    const SizedBox(width: AppSizes.sm),
                    NeuIconButton(
                      icon: _viewLayout == ViewLayout.grid
                          ? CupertinoIcons.list_bullet
                          : CupertinoIcons.square_grid_2x2,
                      onPressed: () {
                        setState(() {
                          _viewLayout = _viewLayout == ViewLayout.grid
                              ? ViewLayout.list
                              : ViewLayout.grid;
                        });
                      },
                      tooltip: _viewLayout == ViewLayout.grid
                          ? 'List view'
                          : 'Grid view',
                    ),
                    const SizedBox(width: AppSizes.sm),
                    NeuIconButton(
                      icon: CupertinoIcons.folder_badge_plus,
                      onPressed: () => _showAddNotebookDialog(context),
                      tooltip: 'Add notebook',
                    ),
                  ],
                ),
              ),
            ),

            // Search bar
            if (_isSearchVisible)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.sm,
                  ),
                  child: NeuTextField(
                    controller: _searchController,
                    hintText: 'Search notes...',
                    prefixIcon: CupertinoIcons.search,
                    suffixIcon: _searchController.text.isNotEmpty
                        ? CupertinoIcons.xmark_circle_fill
                        : null,
                    onSuffixTap: () {
                      _searchController.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                    autofocus: true,
                    onChanged: (value) {
                      ref.read(searchQueryProvider.notifier).state = value;
                    },
                  ),
                ),
              ),

            // Notebook filter chips
            if (notebooks.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.lg),
                    itemCount: notebooks.length + 1, // +1 for "All" chip
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _buildNotebookChip(
                          context,
                          label: 'All',
                          color: AppColors.primary,
                          isSelected: _selectedNotebookId == null,
                          onTap: () =>
                              setState(() => _selectedNotebookId = null),
                        );
                      }
                      final nb = notebooks[index - 1];
                      return _buildNotebookChip(
                        context,
                        label: nb.name,
                        color: Color(nb.colorValue),
                        isSelected: _selectedNotebookId == nb.id,
                        onTap: () => setState(() {
                          _selectedNotebookId =
                              _selectedNotebookId == nb.id ? null : nb.id;
                        }),
                      );
                    },
                  ),
                ),
              ),

            if (notebooks.isNotEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: AppSizes.sm)),

            // Empty state
            if (filteredNotes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(isDark, textSecondary),
              ),

            // Pinned section
            if (pinned.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.sm,
                    AppSizes.lg,
                    AppSizes.xs,
                  ),
                  child: Text(
                    'Pinned',
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              _buildNotesSection(
                context,
                notes: pinned,
                notebooks: notebooks,
                startIndex: 0,
              ),
            ],

            // All Notes section
            if (unpinned.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.md,
                    AppSizes.lg,
                    AppSizes.xs,
                  ),
                  child: Text(
                    searchQuery.isNotEmpty ? 'Results' : 'All Notes',
                    style: TextStyle(
                      fontSize: AppSizes.bodySmall,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              _buildNotesSection(
                context,
                notes: unpinned,
                notebooks: notebooks,
                startIndex: pinned.length,
              ),
            ],

            // Bottom padding for FAB
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(
    BuildContext context, {
    required List<NoteModel> notes,
    required List<NotebookModel> notebooks,
    required int startIndex,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.crossAxisExtent;
          final isWide = maxWidth > AppSizes.compactMax;
          final useGrid = _viewLayout == ViewLayout.grid || isWide;

          if (useGrid) {
            final crossAxisCount = maxWidth > AppSizes.mediumMax
                ? 3
                : maxWidth > AppSizes.compactMax
                    ? 2
                    : 1;

            return SliverMasonryGrid.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: AppSizes.sm,
              crossAxisSpacing: AppSizes.sm,
              childCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                final nb = _notebookForNote(note, notebooks);
                return _buildDismissibleCard(
                  note: note,
                  notebook: nb,
                  index: startIndex + index,
                );
              },
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final note = notes[index];
                final nb = _notebookForNote(note, notebooks);
                return _buildDismissibleCard(
                  note: note,
                  notebook: nb,
                  index: startIndex + index,
                );
              },
              childCount: notes.length,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDismissibleCard({
    required NoteModel note,
    NotebookModel? notebook,
    required int index,
  }) {
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.lg),
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: const Icon(
          CupertinoIcons.archivebox_fill,
          color: AppColors.warning,
        ),
      ),
      confirmDismiss: (_) async {
        ref.read(noteProvider.notifier).archiveNote(note.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Note archived'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref.read(noteProvider.notifier).archiveNote(note.id);
                },
              ),
            ),
          );
        }
        return false; // We handle the removal ourselves
      },
      child: GestureDetector(
        onLongPress: () => _showNoteOptions(context, note),
        child: NoteCardWidget(
          note: note,
          notebook: notebook,
          index: index,
        ),
      ),
    );
  }

  NotebookModel? _notebookForNote(
      NoteModel note, List<NotebookModel> notebooks) {
    if (note.notebookId == null) return null;
    try {
      return notebooks.firstWhere((nb) => nb.id == note.notebookId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildNotebookChip(
    BuildContext context, {
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);

    return Padding(
      padding: const EdgeInsets.only(right: AppSizes.sm),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          decoration: isSelected
              ? NeumorphicDecoration.pressed(
                  isDark: isDark,
                  isNeon: isNeon,
                  borderRadius: AppSizes.radiusFull,
                  color: color.withValues(alpha: isDark ? 0.3 : 0.15),
                )
              : NeumorphicDecoration.raised(
                  isDark: isDark,
                  isNeon: isNeon,
                  borderRadius: AppSizes.radiusFull,
                ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSizes.xs + 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppSizes.bodySmall,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? color
                      : (isNeon
                          ? AppColors.textSecondaryNeon
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFab(bool isDark) {
    return NeuContainer(
      onTap: () => context.push('/notes/new'),
      borderRadius: AppSizes.radiusFull,
      padding: const EdgeInsets.all(AppSizes.md),
      color: AppColors.primary,
      child: const Icon(
        CupertinoIcons.add,
        color: Colors.white,
        size: AppSizes.iconMd,
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: textSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No notes yet',
            style: TextStyle(
              fontSize: AppSizes.heading3,
              fontWeight: FontWeight.w600,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Tap + to create one.',
            style: TextStyle(
              fontSize: AppSizes.body,
              color: textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddNotebookDialog(BuildContext context) {
    final controller = TextEditingController();
    int selectedColor = AppColors.primary.value;

    final notebookColors = [
      AppColors.primary.value,
      AppColors.secondary.value,
      AppColors.warning.value,
      AppColors.danger.value,
      AppColors.success.value,
      AppColors.info.value,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;

          return AlertDialog(
            backgroundColor:
                isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            title: Text(
              'New Notebook',
              style: TextStyle(
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeuTextField(
                  controller: controller,
                  hintText: 'Notebook name',
                  autofocus: true,
                ),
                const SizedBox(height: AppSizes.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: notebookColors.map((c) {
                    final isSelected = selectedColor == c;
                    return GestureDetector(
                      onTap: () =>
                          setDialogState(() => selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(c),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black54,
                                  width: 2.5,
                                )
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
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
                  if (controller.text.trim().isNotEmpty) {
                    ref.read(notebookProvider.notifier).addNotebook(
                          controller.text.trim(),
                          colorValue: selectedColor,
                        );
                    Navigator.pop(ctx);
                  }
                },
                child: const Text(
                  'Create',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showNoteOptions(BuildContext context, NoteModel note) {
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
              leading: Icon(
                note.isPinned
                    ? CupertinoIcons.pin_slash_fill
                    : CupertinoIcons.pin_fill,
                color: AppColors.primary,
              ),
              title: Text(note.isPinned ? 'Unpin' : 'Pin'),
              onTap: () {
                ref.read(noteProvider.notifier).togglePin(note.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                CupertinoIcons.folder,
                color: AppColors.secondary,
              ),
              title: const Text('Move to Notebook'),
              onTap: () {
                Navigator.pop(ctx);
                _showMoveToNotebookDialog(context, note);
              },
            ),
            ListTile(
              leading: const Icon(
                CupertinoIcons.archivebox,
                color: AppColors.warning,
              ),
              title: const Text('Archive'),
              onTap: () {
                ref.read(noteProvider.notifier).archiveNote(note.id);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(
                CupertinoIcons.trash,
                color: AppColors.danger,
              ),
              title: const Text('Delete'),
              onTap: () {
                ref.read(noteProvider.notifier).deleteNote(note.id);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: AppSizes.md),
          ],
        ),
      ),
    );
  }

  void _showMoveToNotebookDialog(BuildContext context, NoteModel note) {
    final notebooks = ref.read(notebookProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        title: Text(
          'Move to Notebook',
          style: TextStyle(
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "None" option
            ListTile(
              title: const Text('No Notebook'),
              leading: const Icon(CupertinoIcons.xmark_circle),
              selected: note.notebookId == null,
              onTap: () {
                ref.read(noteProvider.notifier).updateNote(
                      note.copyWith(notebookId: ''),
                    );
                Navigator.pop(ctx);
              },
            ),
            ...notebooks.map(
              (nb) => ListTile(
                title: Text(nb.name),
                leading: Icon(
                  CupertinoIcons.folder_fill,
                  color: Color(nb.colorValue),
                ),
                selected: note.notebookId == nb.id,
                onTap: () {
                  ref.read(noteProvider.notifier).updateNote(
                        note.copyWith(notebookId: nb.id),
                      );
                  Navigator.pop(ctx);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
