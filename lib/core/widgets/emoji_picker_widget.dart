import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// A simple built-in emoji picker shown as a bottom sheet.
/// No external packages required.
class EmojiPicker {
  EmojiPicker._();

  /// Show the emoji picker as a modal bottom sheet.
  /// Returns the selected emoji string, or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    ValueChanged<String>? onSelected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (ctx) => _EmojiPickerSheet(
        onSelected: (emoji) {
          onSelected?.call(emoji);
          Navigator.of(ctx).pop(emoji);
        },
      ),
    );
  }
}

class _EmojiPickerSheet extends StatefulWidget {
  final ValueChanged<String> onSelected;

  const _EmojiPickerSheet({required this.onSelected});

  @override
  State<_EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<_EmojiPickerSheet> {
  int _categoryIndex = 0;

  static const _categories = [
    _EmojiCategory('Smileys', [
      '\u{1F600}', '\u{1F603}', '\u{1F604}', '\u{1F601}', '\u{1F606}',
      '\u{1F605}', '\u{1F923}', '\u{1F602}', '\u{1F642}', '\u{1F60A}',
      '\u{1F607}', '\u{1F970}', '\u{1F60D}', '\u{1F929}', '\u{1F618}',
      '\u{1F60B}', '\u{1F61B}', '\u{1F914}', '\u{1F917}', '\u{1F92B}',
      '\u{1FAE1}', '\u{1F610}', '\u{1F611}', '\u{1F636}', '\u{1F644}',
      '\u{1F60F}', '\u{1F62E}', '\u{1F632}', '\u{1F97A}', '\u{1F622}',
      '\u{1F62D}', '\u{1F624}', '\u{1F621}', '\u{1F92F}', '\u{1F973}',
      '\u{1F920}',
    ]),
    _EmojiCategory('Work', [
      '\u{2705}', '\u{274C}', '\u{2B50}', '\u{1F525}', '\u{1F4AF}',
      '\u{1F4CC}', '\u{1F4CE}', '\u{1F4DD}', '\u{1F4C5}', '\u{1F3AF}',
      '\u{1F4A1}', '\u{1F514}', '\u{1F3C6}', '\u{1F389}', '\u{2728}',
      '\u{1F4AA}', '\u{1F9E0}', '\u{1F4CA}', '\u{1F4C8}', '\u{1F680}',
      '\u{1F4BC}', '\u{1F4CB}', '\u{1F5C2}',
    ]),
    _EmojiCategory('Symbols', [
      '\u{2764}\u{FE0F}', '\u{1F9E1}', '\u{1F49B}', '\u{1F49A}',
      '\u{1F499}', '\u{1F49C}', '\u{1F5A4}', '\u{1F90D}',
      '\u{2757}', '\u{2753}', '\u{2714}\u{FE0F}', '\u{2795}', '\u{2796}',
      '\u{2B06}\u{FE0F}', '\u{2B07}\u{FE0F}', '\u{25B6}\u{FE0F}',
      '\u{23F8}\u{FE0F}', '\u{1F534}', '\u{1F7E2}', '\u{1F535}', '\u{1F7E1}',
    ]),
    _EmojiCategory('Nature', [
      '\u{1F31E}', '\u{1F319}', '\u{1F31F}', '\u{26A1}', '\u{1F308}',
      '\u{2744}\u{FE0F}', '\u{1F33B}', '\u{1F331}', '\u{1F340}',
      '\u{1F338}', '\u{1F333}', '\u{1F30A}',
    ]),
    _EmojiCategory('Food', [
      '\u{2615}', '\u{1F355}', '\u{1F354}', '\u{1F382}', '\u{1F370}',
      '\u{1F34E}', '\u{1F34A}', '\u{1F353}', '\u{1F347}', '\u{1F349}',
    ]),
    _EmojiCategory('Activities', [
      '\u{26BD}', '\u{1F3C0}', '\u{1F3B5}', '\u{1F3A8}', '\u{1F3AE}',
      '\u{1F3AC}', '\u{1F4F7}', '\u{1F3B6}', '\u{1F3A4}', '\u{1F3B2}',
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final category = _categories[_categoryIndex];

    return SizedBox(
      height: 340,
      child: Column(
        children: [
          // Drag handle
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
          const SizedBox(height: AppSizes.sm),

          // Title
          Text(
            'Emoji',
            style: TextStyle(
              fontSize: AppSizes.bodySmall,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // Category tabs
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final isSelected = _categoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSizes.xs),
                  child: GestureDetector(
                    onTap: () => setState(() => _categoryIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm + 2,
                        vertical: AppSizes.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      child: Center(
                        child: Text(
                          _categories[index].name,
                          style: TextStyle(
                            fontSize: AppSizes.caption,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: isSelected
                                ? AppColors.primary
                                : textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppSizes.sm),

          // Emoji grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.xs,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: category.emojis.length,
              itemBuilder: (context, index) {
                final emoji = category.emojis[index];
                return GestureDetector(
                  onTap: () => widget.onSelected(emoji),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmojiCategory {
  final String name;
  final List<String> emojis;

  const _EmojiCategory(this.name, this.emojis);
}
