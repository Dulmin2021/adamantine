import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/models/graph_node.dart';
import '../../../../core/theme/app_colors.dart';

class GraphPainter extends CustomPainter {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, GraphNode> nodeMap;
  final double scale;
  final Offset panOffset;
  final String? expandedHubId;
  final String? focusedNodeId;

  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.nodeMap,
    required this.scale,
    required this.panOffset,
    this.expandedHubId,
    this.focusedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Center the origin and apply pan & zoom transformations
    canvas.save();
    canvas.translate(size.width / 2 + panOffset.dx, size.height / 2 + panOffset.dy);
    canvas.scale(scale);

    // 1. Draw Edges / Lines with glowing effects
    for (final edge in edges) {
      final source = nodeMap[edge.sourceId];
      final target = nodeMap[edge.targetId];
      if (source == null || target == null) continue;

      final isSourceFocused = focusedNodeId == null || edge.sourceId == focusedNodeId || edge.targetId == focusedNodeId;
      final edgeOpacity = isSourceFocused ? edge.opacity : 0.08;

      final paint = Paint()
        ..color = edge.color.withValues(alpha: edgeOpacity)
        ..strokeWidth = edge.type == EdgeType.albumMembership ? 1.5 : 1.0
        ..style = PaintingStyle.stroke;

      if (edge.type == EdgeType.sharedTag || edge.type == EdgeType.sharedLocation) {
        // Draw subtle dashed / dotted glow line for cross-links
        _drawDashedLine(canvas, Offset(source.x, source.y), Offset(target.x, target.y), paint);
      } else {
        canvas.drawLine(Offset(source.x, source.y), Offset(target.x, target.y), paint);
      }
    }

    // 2. Draw Nodes (Hubs & Satellites)
    for (final node in nodes) {
      final pos = Offset(node.x, node.y);
      final isExpanded = expandedHubId == node.albumId;
      final nodeOpacity = node.opacity;

      // Glow halo for Hub nodes or expanded nodes
      if (node.category == NodeCategory.hub || isExpanded || node.isFocused) {
        final glowPaint = Paint()
          ..color = (isExpanded ? AppColors.primaryLight : node.color).withValues(alpha: 0.25 * nodeOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawCircle(pos, node.radius * 1.5, glowPaint);
      }

      // Main Node Body Circle
      final bodyPaint = Paint()
        ..color = (isExpanded ? AppColors.primaryLight : node.color).withValues(alpha: nodeOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, node.radius, bodyPaint);

      // Node Border Stroke
      final strokePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6 * nodeOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = node.category == NodeCategory.hub ? 2.0 : 1.0;
      canvas.drawCircle(pos, node.radius, strokePaint);

      // Node Text Labels
      if (node.category == NodeCategory.hub || (isExpanded && node.category == NodeCategory.photo)) {
        final textSpan = TextSpan(
          text: node.category == NodeCategory.hub ? '${node.label} (${node.photoCount})' : node.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9 * nodeOpacity),
            fontSize: node.category == NodeCategory.hub ? 12.0 : 9.0,
            fontWeight: node.category == NodeCategory.hub ? FontWeight.bold : FontWeight.w500,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '...',
        );
        textPainter.layout(maxWidth: 120);
        textPainter.paint(
          canvas,
          Offset(pos.dx - textPainter.width / 2, pos.dy + node.radius + 4),
        );
      }
    }

    canvas.restore();
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double count = (sqrt(dx * dx + dy * dy) / (dashWidth + dashSpace)).floorToDouble();

    if (count <= 0) return;

    for (int i = 0; i < count; i++) {
      final double startFraction = i / count;
      final double endFraction = (i + 0.6) / count;

      canvas.drawLine(
        Offset(p1.dx + dx * startFraction, p1.dy + dy * startFraction),
        Offset(p1.dx + dx * endFraction, p1.dy + dy * endFraction),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) => true;
}
