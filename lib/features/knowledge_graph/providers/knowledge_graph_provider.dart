import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../notes/providers/note_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../../todo/providers/todo_provider.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class GraphNode {
  final String id;
  final String label;
  final String type; // 'project', 'note', 'task', 'todo'
  final Color color;
  final double radius;
  double x, y; // position (mutable for force simulation)
  double vx, vy; // velocity for force simulation

  GraphNode({
    required this.id,
    required this.label,
    required this.type,
    required this.color,
    required this.radius,
    this.x = 0,
    this.y = 0,
    this.vx = 0,
    this.vy = 0,
  });
}

class GraphEdge {
  final String fromId;
  final String toId;
  final String relationship; // 'project', 'linked', 'tag'
  final bool isDotted;

  GraphEdge({
    required this.fromId,
    required this.toId,
    required this.relationship,
    this.isDotted = false,
  });
}

class GraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;

  GraphData({required this.nodes, required this.edges});
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Builds the full graph from all data providers.
final graphDataProvider = Provider<GraphData>((ref) {
  final projects = ref.watch(projectProvider);
  final notes = ref.watch(noteProvider);
  final tasks = ref.watch(taskProvider);
  final todos = ref.watch(todoProvider);

  final nodes = <GraphNode>[];
  final edges = <GraphEdge>[];

  // Track tag -> list of node ids for tag-based edges
  final tagIndex = <String, List<String>>{};

  void indexTags(String nodeId, List<String> tags) {
    for (final tag in tags) {
      final lower = tag.toLowerCase();
      tagIndex.putIfAbsent(lower, () => []).add(nodeId);
    }
  }

  // --- Projects ---
  for (final p in projects) {
    nodes.add(GraphNode(
      id: p.id,
      label: p.name,
      type: 'project',
      color: Color(p.colorValue),
      radius: 30,
    ));
  }

  // --- Notes ---
  for (final n in notes) {
    nodes.add(GraphNode(
      id: n.id,
      label: n.title,
      type: 'note',
      color: AppColors.primary,
      radius: 20,
    ));
    indexTags(n.id, n.tags);

    // Note -> Project edge
    if (n.projectId != null && n.projectId!.isNotEmpty) {
      edges.add(GraphEdge(
        fromId: n.id,
        toId: n.projectId!,
        relationship: 'project',
      ));
    }

    // Note -> Note edges (linked notes)
    for (final linkedId in n.linkedNoteIds) {
      // Only add one direction to avoid duplicate edges
      if (n.id.compareTo(linkedId) < 0) {
        edges.add(GraphEdge(
          fromId: n.id,
          toId: linkedId,
          relationship: 'linked',
        ));
      }
    }
  }

  // --- Tasks ---
  for (final t in tasks) {
    nodes.add(GraphNode(
      id: t.id,
      label: t.title,
      type: 'task',
      color: AppColors.info,
      radius: 20,
    ));
    indexTags(t.id, t.tags);

    // Task -> Project edge
    if (t.projectId != null && t.projectId!.isNotEmpty) {
      edges.add(GraphEdge(
        fromId: t.id,
        toId: t.projectId!,
        relationship: 'project',
      ));
    }
  }

  // --- Todos ---
  for (final td in todos) {
    nodes.add(GraphNode(
      id: td.id,
      label: td.title,
      type: 'todo',
      color: AppColors.statusNotStarted,
      radius: 15,
    ));
    indexTags(td.id, td.tags);

    // Todo -> Project edge
    if (td.projectId != null && td.projectId!.isNotEmpty) {
      edges.add(GraphEdge(
        fromId: td.id,
        toId: td.projectId!,
        relationship: 'project',
      ));
    }
  }

  // --- Tag-based edges ---
  final addedTagEdges = <String>{};
  for (final entry in tagIndex.entries) {
    final ids = entry.value;
    for (int i = 0; i < ids.length; i++) {
      for (int j = i + 1; j < ids.length; j++) {
        final key = '${ids[i]}_${ids[j]}';
        final keyRev = '${ids[j]}_${ids[i]}';
        if (!addedTagEdges.contains(key) && !addedTagEdges.contains(keyRev)) {
          addedTagEdges.add(key);
          edges.add(GraphEdge(
            fromId: ids[i],
            toId: ids[j],
            relationship: 'tag',
            isDotted: true,
          ));
        }
      }
    }
  }

  // --- Force-directed layout (50 iterations) ---
  _applyForceLayout(nodes, edges);

  return GraphData(nodes: nodes, edges: edges);
});

/// Filter: which node types are visible. Defaults to all.
final graphFilterProvider = StateProvider<Set<String>>((ref) {
  return {'project', 'note', 'task', 'todo'};
});

/// Filtered graph combining data + filter.
final filteredGraphProvider = Provider<GraphData>((ref) {
  final data = ref.watch(graphDataProvider);
  final filter = ref.watch(graphFilterProvider);

  final visibleNodes =
      data.nodes.where((n) => filter.contains(n.type)).toList();
  final visibleIds = visibleNodes.map((n) => n.id).toSet();

  final visibleEdges = data.edges
      .where((e) => visibleIds.contains(e.fromId) && visibleIds.contains(e.toId))
      .toList();

  return GraphData(nodes: visibleNodes, edges: visibleEdges);
});

/// Currently selected node ID.
final selectedNodeProvider = StateProvider<String?>((ref) => null);

// ---------------------------------------------------------------------------
// Force-directed layout
// ---------------------------------------------------------------------------

void _applyForceLayout(List<GraphNode> nodes, List<GraphEdge> edges) {
  if (nodes.isEmpty) return;

  final rng = Random(42);
  final nodeMap = <String, GraphNode>{};
  for (final n in nodes) {
    nodeMap[n.id] = n;
  }

  // Separate projects from others
  final projectNodes = nodes.where((n) => n.type == 'project').toList();
  final otherNodes = nodes.where((n) => n.type != 'project').toList();

  // Place projects in a circle at center
  if (projectNodes.isNotEmpty) {
    final angleStep = 2 * pi / projectNodes.length;
    final projectRadius = 80.0 + projectNodes.length * 20.0;
    for (int i = 0; i < projectNodes.length; i++) {
      projectNodes[i].x = cos(angleStep * i) * projectRadius;
      projectNodes[i].y = sin(angleStep * i) * projectRadius;
    }
  }

  // Place other nodes near their project or randomly on periphery
  for (final n in otherNodes) {
    // Find if connected to a project
    String? projectId;
    for (final e in edges) {
      if (e.relationship == 'project') {
        if (e.fromId == n.id) {
          projectId = e.toId;
          break;
        }
        if (e.toId == n.id) {
          projectId = e.fromId;
          break;
        }
      }
    }

    if (projectId != null && nodeMap.containsKey(projectId)) {
      final pNode = nodeMap[projectId]!;
      n.x = pNode.x + (rng.nextDouble() - 0.5) * 120;
      n.y = pNode.y + (rng.nextDouble() - 0.5) * 120;
    } else {
      // Periphery
      final angle = rng.nextDouble() * 2 * pi;
      final dist = 200.0 + rng.nextDouble() * 100;
      n.x = cos(angle) * dist;
      n.y = sin(angle) * dist;
    }
  }

  // Force simulation: 50 iterations
  const iterations = 50;
  const repulsion = 5000.0;
  const attraction = 0.005;
  const damping = 0.85;
  const minDist = 20.0;

  for (int iter = 0; iter < iterations; iter++) {
    // Repulsion between all pairs
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final a = nodes[i];
        final b = nodes[j];
        double dx = b.x - a.x;
        double dy = b.y - a.y;
        double dist = sqrt(dx * dx + dy * dy);
        if (dist < minDist) dist = minDist;

        final force = repulsion / (dist * dist);
        final fx = (dx / dist) * force;
        final fy = (dy / dist) * force;

        a.vx -= fx;
        a.vy -= fy;
        b.vx += fx;
        b.vy += fy;
      }
    }

    // Attraction along edges
    for (final e in edges) {
      final a = nodeMap[e.fromId];
      final b = nodeMap[e.toId];
      if (a == null || b == null) continue;

      double dx = b.x - a.x;
      double dy = b.y - a.y;
      double dist = sqrt(dx * dx + dy * dy);
      if (dist < 1) dist = 1;

      // Weaker attraction for tag edges
      final k = e.isDotted ? attraction * 0.3 : attraction;
      final fx = dx * k;
      final fy = dy * k;

      a.vx += fx;
      a.vy += fy;
      b.vx -= fx;
      b.vy -= fy;
    }

    // Update positions with damping
    for (final n in nodes) {
      n.vx *= damping;
      n.vy *= damping;
      n.x += n.vx;
      n.y += n.vy;
    }
  }

  // Reset velocities
  for (final n in nodes) {
    n.vx = 0;
    n.vy = 0;
  }
}
