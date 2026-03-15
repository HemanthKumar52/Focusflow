import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/theme/neumorphic_theme.dart';
import '../../providers/knowledge_graph_provider.dart';
import '../widgets/graph_painter.dart';

class KnowledgeGraphScreen extends ConsumerStatefulWidget {
  const KnowledgeGraphScreen({super.key});

  @override
  ConsumerState<KnowledgeGraphScreen> createState() =>
      _KnowledgeGraphScreenState();
}

class _KnowledgeGraphScreenState extends ConsumerState<KnowledgeGraphScreen> {
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNeon = AppColors.isNeonTheme(context);
    final graphData = ref.watch(filteredGraphProvider);
    final selectedId = ref.watch(selectedNodeProvider);
    final filter = ref.watch(graphFilterProvider);

    final bgColor = isNeon ? AppColors.backgroundNeon : (isDark ? AppColors.backgroundDark : AppColors.backgroundLight);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      decoration: NeumorphicDecoration.raised(isDark: isDark, isNeon: isNeon),
                      padding: const EdgeInsets.all(AppSizes.sm),
                      child: Icon(
                        CupertinoIcons.back,
                        size: AppSizes.iconMd,
                        color: isNeon
                            ? AppColors.textPrimaryNeon
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Text(
                    'Knowledge Graph',
                    style: TextStyle(
                      fontSize: AppSizes.heading3,
                      fontWeight: FontWeight.w700,
                      color: isNeon
                          ? AppColors.textPrimaryNeon
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    ),
                  ),
                  const Spacer(),
                  // Node count badge
                  Container(
                    decoration: NeumorphicDecoration.raised(isDark: isDark, isNeon: isNeon),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.sm,
                      vertical: AppSizes.xs,
                    ),
                    child: Text(
                      '${graphData.nodes.length} nodes',
                      style: TextStyle(
                        fontSize: AppSizes.bodySmall,
                        color: isNeon
                            ? AppColors.textSecondaryNeon
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- Filter bar ---
            _FilterBar(isDark: isDark, filter: filter),

            // --- Graph area ---
            Expanded(
              child: graphData.nodes.isEmpty
                  ? _EmptyState(isDark: isDark)
                  : GestureDetector(
                      onTapDown: (details) {
                        _handleTap(details.localPosition, graphData);
                      },
                      onDoubleTapDown: (details) {
                        _handleDoubleTap(details.localPosition, graphData);
                      },
                      onDoubleTap: () {}, // required for onDoubleTapDown
                      child: InteractiveViewer(
                        transformationController: _transformController,
                        boundaryMargin: const EdgeInsets.all(400),
                        minScale: 0.3,
                        maxScale: 3.0,
                        child: SizedBox.expand(
                          child: CustomPaint(
                            painter: GraphPainter(
                              graphData: graphData,
                              selectedNodeId: selectedId,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),

            // --- Selected node info card ---
            if (selectedId != null)
              _NodeInfoCard(
                isDark: isDark,
                graphData: graphData,
                selectedId: selectedId,
              ),

            // --- Legend ---
            _Legend(isDark: isDark),
          ],
        ),
      ),
    );
  }

  void _handleTap(Offset localPos, GraphData graphData) {
    final node = _hitTestNode(localPos, graphData);
    ref.read(selectedNodeProvider.notifier).state = node?.id;
  }

  void _handleDoubleTap(Offset localPos, GraphData graphData) {
    final node = _hitTestNode(localPos, graphData);
    if (node == null) return;

    // Navigate to the item's detail screen
    switch (node.type) {
      case 'note':
        context.push('/notes/${node.id}');
        break;
      case 'task':
        context.push('/tasks/${node.id}');
        break;
      case 'todo':
        context.push('/todos/${node.id}');
        break;
      case 'project':
        context.push('/projects/${node.id}');
        break;
    }
  }

  GraphNode? _hitTestNode(Offset localPos, GraphData graphData) {
    // Get the current canvas size from context
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return null;

    final size = renderBox.size;

    // Account for the InteractiveViewer transform
    final matrix = _transformController.value;
    final invertedMatrix = Matrix4.inverted(matrix);

    // Transform the tap position back to the canvas coordinate space
    final transformedPos = MatrixUtils.transformPoint(invertedMatrix, localPos);

    // The center offset used by the painter
    // Approximate: graph area starts below header+filter (~110px from top)
    final center = Offset(size.width / 2, size.height / 2);

    for (final node in graphData.nodes.reversed) {
      final nodePos = Offset(node.x, node.y) + center;
      final dist = (transformedPos - nodePos).distance;
      if (dist <= node.radius + 8) {
        return node;
      }
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Filter bar widget
// ---------------------------------------------------------------------------

class _FilterBar extends ConsumerWidget {
  final bool isDark;
  final Set<String> filter;

  const _FilterBar({required this.isDark, required this.filter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNeon = AppColors.isNeonTheme(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.xs,
      ),
      child: Container(
        decoration: NeumorphicDecoration.raised(isDark: isDark, isNeon: isNeon),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _filterChip(ref, 'project', 'Projects', AppColors.primary),
            _filterChip(ref, 'note', 'Notes', AppColors.primary),
            _filterChip(ref, 'task', 'Tasks', AppColors.info),
            _filterChip(ref, 'todo', 'Todos', AppColors.statusNotStarted),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    WidgetRef ref,
    String type,
    String label,
    Color activeColor,
  ) {
    final isActive = filter.contains(type);
    return GestureDetector(
      onTap: () {
        final current = ref.read(graphFilterProvider);
        final updated = Set<String>.from(current);
        if (updated.contains(type)) {
          updated.remove(type);
        } else {
          updated.add(type);
        }
        ref.read(graphFilterProvider.notifier).state = updated;
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          border: Border.all(
            color: isActive ? activeColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive
                  ? CupertinoIcons.checkmark_square_fill
                  : CupertinoIcons.square,
              size: 16,
              color: isActive
                  ? activeColor
                  : (isDark
                      ? AppColors.textTertiaryDark
                      : AppColors.textTertiaryLight),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: AppSizes.bodySmall,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? activeColor
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Node info card
// ---------------------------------------------------------------------------

class _NodeInfoCard extends StatelessWidget {
  final bool isDark;
  final GraphData graphData;
  final String selectedId;

  const _NodeInfoCard({
    required this.isDark,
    required this.graphData,
    required this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final node = graphData.nodes
        .cast<GraphNode?>()
        .firstWhere((n) => n?.id == selectedId, orElse: () => null);

    if (node == null) return const SizedBox.shrink();

    // Count connections
    final connections = graphData.edges
        .where((e) => e.fromId == selectedId || e.toId == selectedId)
        .length;

    final typeLabel = node.type[0].toUpperCase() + node.type.substring(1);
    final typeIcon = _iconForType(node.type);

    final isNeon = AppColors.isNeonTheme(context);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      decoration: NeumorphicDecoration.raised(isDark: isDark, isNeon: isNeon),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Row(
        children: [
          // Colored dot
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: node.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: node.color, size: 18),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  node.label,
                  style: TextStyle(
                    fontSize: AppSizes.body,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$typeLabel  ·  $connections connections',
                  style: TextStyle(
                    fontSize: AppSizes.bodySmall,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            size: AppSizes.iconSm,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'project':
        return CupertinoIcons.folder_fill;
      case 'note':
        return CupertinoIcons.doc_text_fill;
      case 'task':
        return CupertinoIcons.bolt_fill;
      case 'todo':
        return CupertinoIcons.checkmark_circle_fill;
      default:
        return CupertinoIcons.circle_fill;
    }
  }
}

// ---------------------------------------------------------------------------
// Legend
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  final bool isDark;

  const _Legend({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.md,
        right: AppSizes.md,
        bottom: AppSizes.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem('Project', AppColors.primary, 10),
          const SizedBox(width: AppSizes.md),
          _legendItem('Note', AppColors.primary, 7),
          const SizedBox(width: AppSizes.md),
          _legendItem('Task', AppColors.info, 7),
          const SizedBox(width: AppSizes.md),
          _legendItem('Todo', AppColors.statusNotStarted, 5),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, double dotSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize * 2,
          height: dotSize * 2,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppSizes.caption,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final bool isDark;

  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.graph_circle,
            size: 64,
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textTertiaryLight,
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'No items to display',
            style: TextStyle(
              fontSize: AppSizes.body,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            'Create notes, tasks, or projects to see\nyour knowledge graph come alive.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppSizes.bodySmall,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
