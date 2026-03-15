import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/neu_container.dart';
import '../../data/note_model.dart';

class NoteCardWidget extends StatelessWidget {
  final NoteModel note;
  final NotebookModel? notebook;
  final int index;

  const NoteCardWidget({
    super.key,
    required this.note,
    this.notebook,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textTertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    return NeuContainer(
      onTap: () => context.push('/notes/${note.id}'),
      padding: const EdgeInsets.all(AppSizes.md),
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            note.title.isNotEmpty ? note.title : 'Untitled',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppSizes.heading4,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),

          // Body preview
          if (note.body.isNotEmpty) ...[
            const SizedBox(height: AppSizes.xs),
            Text(
              note.body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppSizes.bodySmall,
                color: textSecondary,
                height: 1.4,
              ),
            ),
          ],

          const SizedBox(height: AppSizes.sm),

          // Bottom row: notebook badge, voice indicator, date, pin
          Row(
            children: [
              // Notebook color dot + name
              if (notebook != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color(notebook!.colorValue),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  notebook!.name,
                  style: TextStyle(
                    fontSize: AppSizes.caption,
                    fontWeight: FontWeight.w500,
                    color: Color(notebook!.colorValue),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
              ],

              // Voice note indicator
              if (note.voiceNotePath != null &&
                  note.voiceNotePath!.isNotEmpty) ...[
                Icon(
                  CupertinoIcons.mic_fill,
                  size: AppSizes.iconSm - 4,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: AppSizes.xs),
              ],

              // Updated date
              Expanded(
                child: Text(
                  note.updatedAt.friendlyDate,
                  style: TextStyle(
                    fontSize: AppSizes.caption,
                    color: textTertiary,
                  ),
                ),
              ),

              // Pin icon
              if (note.isPinned)
                Icon(
                  CupertinoIcons.pin_fill,
                  size: AppSizes.iconSm - 4,
                  color: AppColors.primary,
                ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: (index * 50).ms,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
          delay: (index * 50).ms,
          curve: Curves.easeOut,
        );
  }
}
