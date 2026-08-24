import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/graph_node.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/gallery_provider.dart';
import '../../state/graph_provider.dart';
import 'painters/graph_painter.dart';
import 'widgets/graph_filter_bar.dart';
import 'widgets/node_preview_card.dart';
import 'widgets/graph_settings_sheet.dart';
import '../detail/photo_viewer_view.dart';

class GraphView extends StatefulWidget {
  const GraphView({super.key});

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _elapsedSeconds = 0.0;

  @override
  void initState() {
    super.initState();
    final gallery = context.read<GalleryProvider>();
    final graph = context.read<GraphProvider>();

    // Initial graph build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      graph.rebuildGraph(allItems: gallery.allItems, allAlbums: gallery.albums);
    });

    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;
      _elapsedSeconds = elapsed.inMicroseconds / 1000000.0;

      if (dt > 0 && dt < 0.1) {
        graph.stepSimulation(dt, _elapsedSeconds);
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details, BuildContext context, GraphProvider graph, GalleryProvider gallery, Size size) {
    // Transform tap coordinates to graph canvas space
    final localPos = details.localPosition;
    final centerX = size.width / 2 + graph.panOffset.dx;
    final centerY = size.height / 2 + graph.panOffset.dy;

    final graphX = (localPos.dx - centerX) / graph.scale;
    final graphY = (localPos.dy - centerY) / graph.scale;

    // Find tapped node
    GraphNode? tappedNode;
    double minDistance = double.infinity;

    for (final node in graph.nodes) {
      final dx = node.x - graphX;
      final dy = node.y - graphY;
      final dist = sqrt(dx * dx + dy * dy);

      if (dist <= node.radius * 1.5 && dist < minDistance) {
        minDistance = dist;
        tappedNode = node;
      }
    }

    if (tappedNode != null) {
      graph.onNodeTapped(tappedNode, allItems: gallery.allItems, allAlbums: gallery.albums);
    } else {
      // Tap on empty space closes preview
      graph.closePreview();
    }
  }

  void _showPhysicsSettings(BuildContext context, GraphProvider graph) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GraphSettingsSheet(graphProvider: graph),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gallery = context.watch<GalleryProvider>();
    final graph = context.watch<GraphProvider>();

    if (graph.nodes.isEmpty && gallery.allItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && graph.nodes.isEmpty) {
          graph.rebuildGraph(allItems: gallery.allItems, allAlbums: gallery.albums);
        }
      });
    }

    if (gallery.isLoading && graph.nodes.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryLight),
              SizedBox(height: 16),
              Text(
                'Building Knowledge Graph...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // Graph Canvas with Gestures
            GestureDetector(
              onTapUp: (details) => _handleTapUp(details, context, graph, gallery, size),
              onDoubleTap: () {
                setState(() {
                  graph.panOffset = Offset.zero;
                  graph.scale = 1.0;
                });
              },
              onScaleUpdate: (details) {
                setState(() {
                  graph.scale = (graph.scale * details.scale).clamp(0.4, 2.5);
                  graph.panOffset += details.focalPointDelta;
                });
              },
              child: Container(
                color: AppColors.background,
                width: double.infinity,
                height: double.infinity,
                child: CustomPaint(
                  painter: GraphPainter(
                    nodes: graph.nodes,
                    edges: graph.edges,
                    nodeMap: graph.graphData?.nodeMap ?? {},
                    scale: graph.scale,
                    panOffset: graph.panOffset,
                    expandedHubId: graph.expandedHubId,
                    focusedNodeId: graph.focusedNodeId,
                  ),
                ),
              ),
            ),

            // Top Floating Filter Chips
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: GraphFilterBar(
                activeFilters: graph.activeFilters,
                onToggleFilter: (filter) => graph.toggleFilter(
                  filter,
                  allItems: gallery.allItems,
                  allAlbums: gallery.albums,
                ),
              ),
            ),

            // Collapse Hub Bloom Button (Top Left when expanded)
            if (graph.expandedHubId != null)
              Positioned(
                top: 70,
                left: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'collapse_hub',
                  onPressed: () => graph.collapseExpandedHub(allItems: gallery.allItems, allAlbums: gallery.albums),
                  backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryLight, size: 18),
                  label: const Text('Back to Overview', style: TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),

            // Physics Settings Gear FAB (Bottom Right)
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'graph_physics_fab',
                onPressed: () => _showPhysicsSettings(context, graph),
                backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
                child: const Icon(Icons.tune_rounded, color: AppColors.primaryLight, size: 20),
              ),
            ),

            // Reset View / Center FAB (Bottom Left)
            Positioned(
              bottom: 24,
              left: 16,
              child: FloatingActionButton.small(
                heroTag: 'graph_center_fab',
                onPressed: () {
                  setState(() {
                    graph.panOffset = Offset.zero;
                    graph.scale = 1.0;
                  });
                },
                backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
                child: const Icon(Icons.center_focus_strong_rounded, color: AppColors.textSecondary, size: 20),
              ),
            ),

            // Photo Node Preview Card Popup
            if (graph.selectedPreviewNode != null && graph.selectedPreviewNode!.mediaItem != null)
              Positioned(
                bottom: 80,
                left: 24,
                right: 24,
                child: Center(
                  child: NodePreviewCard(
                    node: graph.selectedPreviewNode!,
                    onClose: () => graph.closePreview(),
                    onOpen: () {
                      final item = graph.selectedPreviewNode!.mediaItem!;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PhotoViewerView(
                            initialPhotoId: item.id,
                            photoList: gallery.allItems,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
