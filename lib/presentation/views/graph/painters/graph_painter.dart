import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
    // 0. Batch draw subtle radial dot grid background (Stitch .grid-bg) in 1 GPU call
    const double gridSize = 24.0;
    final int xCount = (size.width / gridSize).ceil() + 1;
    final int yCount = (size.height / gridSize).ceil() + 1;
    final Float32List points = Float32List(xCount * yCount * 2);
    int pIdx = 0;
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        if (pIdx + 1 < points.length) {
          points[pIdx++] = x;
          points[pIdx++] = y;
        }
      }
    }
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawRawPoints(ui.PointMode.points, points, gridPaint);

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
        ..color = (edge.type == EdgeType.albumMembership ? AppColors.primary : AppColors.graphCrossLink).withValues(alpha: edgeOpacity * 0.7)
        ..strokeWidth = edge.type == EdgeType.albumMembership ? 1.5 : 1.0
        ..style = PaintingStyle.stroke;

      if (edge.type == EdgeType.sharedTag || edge.type == EdgeType.sharedLocation) {
        // Draw subtle dashed / dotted glow line for cross-links
        _drawDashedLine(canvas, Offset(source.x, source.y), Offset(target.x, target.y), paint);
      } else {
        canvas.drawLine(Offset(source.x, source.y), Offset(target.x, target.y), paint);
      }
    }

    // 2. Draw Nodes (Stitch Hubs & Satellites)
    for (final node in nodes) {
      final pos = Offset(node.x, node.y);
      final isExpanded = expandedHubId == node.albumId;
      final nodeOpacity = node.opacity;

      if (node.category == NodeCategory.hub) {
        // Outer Emerald Neon Glow (Stitch box-shadow: 0 0 24px rgba(0, 92, 51, 0.8))
        final outerGlow = Paint()
          ..color = AppColors.primaryGlow.withValues(alpha: 0.7 * nodeOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
        canvas.drawCircle(pos, node.radius + 8, outerGlow);

        // Dark obsidian surface fill
        final baseFill = Paint()
          ..color = AppColors.background.withValues(alpha: nodeOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, node.radius, baseFill);

        // Inner emerald tint fill
        final innerGlow = Paint()
          ..color = AppColors.primaryDark.withValues(alpha: 0.35 * nodeOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, node.radius * 0.85, innerGlow);

        // 2px solid emerald ring border
        final strokePaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.95 * nodeOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
        canvas.drawCircle(pos, node.radius, strokePaint);
      } else {
        // Satellite Node (Stitch .node-satellite with 1px emerald border)
        final satGlow = Paint()
          ..color = AppColors.primaryDark.withValues(alpha: 0.3 * nodeOpacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(pos, node.radius + 2, satGlow);

        final satFill = Paint()
          ..color = (isExpanded ? AppColors.primaryContainer : AppColors.surfaceContainerHigh).withValues(alpha: nodeOpacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, node.radius, satFill);

        final satStroke = Paint()
          ..color = (isExpanded ? AppColors.primary : AppColors.primary.withValues(alpha: 0.6)).withValues(alpha: 0.8 * nodeOpacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(pos, node.radius, satStroke);
      }

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
