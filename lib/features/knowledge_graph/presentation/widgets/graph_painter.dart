import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/knowledge_graph_provider.dart';

class GraphPainter extends CustomPainter {
  final GraphData graphData;
  final String? selectedNodeId;
  final Offset offset;
  final double scale;

  GraphPainter({
    required this.graphData,
    required this.selectedNodeId,
    this.offset = Offset.zero,
    this.scale = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Build a quick lookup for nodes by id
    final nodeMap = <String, GraphNode>{};
    for (final node in graphData.nodes) {
      nodeMap[node.id] = node;
    }

    // --- Draw edges ---
    for (final edge in graphData.edges) {
      final from = nodeMap[edge.fromId];
      final to = nodeMap[edge.toId];
      if (from == null || to == null) continue;

      final p1 = Offset(from.x, from.y) + center;
      final p2 = Offset(to.x, to.y) + center;

      final edgePaint = Paint()
        ..strokeWidth = edge.isDotted ? 0.8 : 1.5
        ..style = PaintingStyle.stroke;

      if (edge.relationship == 'project') {
        edgePaint.color = AppColors.textTertiaryLight.withValues(alpha: 0.5);
      } else if (edge.relationship == 'linked') {
        edgePaint.color = AppColors.primary.withValues(alpha: 0.4);
      } else {
        edgePaint.color = AppColors.textTertiaryLight.withValues(alpha: 0.2);
      }

      if (edge.isDotted) {
        _drawDottedLine(canvas, p1, p2, edgePaint);
      } else {
        canvas.drawLine(p1, p2, edgePaint);
      }
    }

    // --- Draw nodes ---
    for (final node in graphData.nodes) {
      final pos = Offset(node.x, node.y) + center;
      final isSelected = node.id == selectedNodeId;

      // Glow effect for selected node
      if (isSelected) {
        final glowPaint = Paint()
          ..color = node.color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(pos, node.radius + 8, glowPaint);
      }

      // Node fill
      final fillPaint = Paint()
        ..color = node.color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, node.radius, fillPaint);

      // Node border
      final borderPaint = Paint()
        ..color = isSelected
            ? Colors.white
            : node.color.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.5;
      canvas.drawCircle(pos, node.radius, borderPaint);

      // Label below node (truncated to 10 chars)
      final label = node.label.length > 10
          ? '${node.label.substring(0, 10)}...'
          : node.label;

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : AppColors.textSecondaryDark,
            fontSize: node.type == 'project' ? 11 : 9,
            fontWeight:
                node.type == 'project' ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout(maxWidth: 80);
      textPainter.paint(
        canvas,
        Offset(
          pos.dx - textPainter.width / 2,
          pos.dy + node.radius + 4,
        ),
      );
    }
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 1) return;

    const dashLen = 4.0;
    const gapLen = 4.0;
    final unitX = dx / dist;
    final unitY = dy / dist;

    double drawn = 0;
    bool isDash = true;
    while (drawn < dist) {
      final segLen = isDash ? dashLen : gapLen;
      final end = min(drawn + segLen, dist);
      if (isDash) {
        canvas.drawLine(
          Offset(p1.dx + unitX * drawn, p1.dy + unitY * drawn),
          Offset(p1.dx + unitX * end, p1.dy + unitY * end),
          paint,
        );
      }
      drawn = end;
      isDash = !isDash;
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return oldDelegate.graphData != graphData ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.offset != offset ||
        oldDelegate.scale != scale;
  }
}
