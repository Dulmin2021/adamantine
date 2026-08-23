import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/models/graph_node.dart';
import '../../core/models/media_item.dart';
import '../../core/models/album.dart';
import '../../core/services/graph_service.dart';

class GraphProvider with ChangeNotifier {
  final GraphService _graphService = GraphService();

  GraphData? _graphData;
  final Set<GraphFilter> _activeFilters = {GraphFilter.byTag};
  
  String? _expandedHubId;
  String? _focusedNodeId;
  GraphNode? _selectedPreviewNode;

  // Physics Simulation Controls
  double _linkDistance = 85.0;
  double _repulsionForce = 1400.0;
  double _centerGravity = 0.04;
  double _driftSpeed = 0.5;
  bool _isIdleDriftEnabled = true;

  // Canvas Viewport transformation
  double scale = 1.0;
  Offset panOffset = Offset.zero;

  // Getters
  GraphData? get graphData => _graphData;
  List<GraphNode> get nodes => _graphData?.nodes ?? [];
  List<GraphEdge> get edges => _graphData?.edges ?? [];
  Set<GraphFilter> get activeFilters => _activeFilters;
  String? get expandedHubId => _expandedHubId;
  String? get focusedNodeId => _focusedNodeId;
  GraphNode? get selectedPreviewNode => _selectedPreviewNode;

  double get linkDistance => _linkDistance;
  double get repulsionForce => _repulsionForce;
  double get centerGravity => _centerGravity;
  double get driftSpeed => _driftSpeed;
  bool get isIdleDriftEnabled => _isIdleDriftEnabled;

  void rebuildGraph({
    required List<MediaItem> allItems,
    required List<Album> allAlbums,
  }) {
    _graphData = _graphService.buildGraph(
      allItems: allItems,
      allAlbums: allAlbums,
      activeFilters: _activeFilters,
      expandedHubId: _expandedHubId,
      focusedNodeId: _focusedNodeId,
    );
    notifyListeners();
  }

  void toggleFilter(GraphFilter filter, {required List<MediaItem> allItems, required List<Album> allAlbums}) {
    if (_activeFilters.contains(filter)) {
      _activeFilters.remove(filter);
    } else {
      _activeFilters.add(filter);
    }
    rebuildGraph(allItems: allItems, allAlbums: allAlbums);
  }

  void onNodeTapped(GraphNode node, {required List<MediaItem> allItems, required List<Album> allAlbums}) {
    if (node.category == NodeCategory.hub) {
      if (_expandedHubId == node.albumId) {
        // Collapse
        _expandedHubId = null;
        _selectedPreviewNode = null;
      } else {
        // Expand (bloom out satellites)
        _expandedHubId = node.albumId;
        _selectedPreviewNode = null;
      }
      rebuildGraph(allItems: allItems, allAlbums: allAlbums);
    } else if (node.category == NodeCategory.photo) {
      _selectedPreviewNode = node;
      notifyListeners();
    }
  }

  void toggleFocusMode(String? nodeId, {required List<MediaItem> allItems, required List<Album> allAlbums}) {
    if (_focusedNodeId == nodeId) {
      _focusedNodeId = null;
    } else {
      _focusedNodeId = nodeId;
    }
    rebuildGraph(allItems: allItems, allAlbums: allAlbums);
  }

  void closePreview() {
    _selectedPreviewNode = null;
    notifyListeners();
  }

  void collapseExpandedHub({required List<MediaItem> allItems, required List<Album> allAlbums}) {
    _expandedHubId = null;
    _selectedPreviewNode = null;
    rebuildGraph(allItems: allItems, allAlbums: allAlbums);
  }

  // Live Physics Controls
  void setPhysics({
    double? linkDistance,
    double? repulsionForce,
    double? centerGravity,
    double? driftSpeed,
    bool? idleDrift,
  }) {
    if (linkDistance != null) _linkDistance = linkDistance;
    if (repulsionForce != null) _repulsionForce = repulsionForce;
    if (centerGravity != null) _centerGravity = centerGravity;
    if (driftSpeed != null) _driftSpeed = driftSpeed;
    if (idleDrift != null) _isIdleDriftEnabled = idleDrift;
    notifyListeners();
  }

  /// Run one step of the force simulation (called each frame from Ticker)
  void stepSimulation(double dt, double timeSeconds) {
    if (_graphData == null || _graphData!.nodes.isEmpty) return;

    final nodes = _graphData!.nodes;
    final edges = _graphData!.edges;
    final nodeMap = _graphData!.nodeMap;

    // 1. Reset forces & apply central gravity + idle drift
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      node.fx = -node.x * _centerGravity;
      node.fy = -node.y * _centerGravity;

      if (_isIdleDriftEnabled) {
        // Subtle harmonic breathing motion like Obsidian
        final driftAngle = timeSeconds * 0.8 + (i * 0.4);
        node.fx += sin(driftAngle) * 8.0 * _driftSpeed;
        node.fy += cos(driftAngle) * 8.0 * _driftSpeed;
      }
    }

    // 2. Coulomb Repulsion between all node pairs
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final a = nodes[i];
        final b = nodes[j];

        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final distSq = dx * dx + dy * dy + 100.0;
        final dist = sqrt(distSq);

        if (dist > 500) continue; // Cull distant repulsion

        final force = _repulsionForce / distSq;
        final fx = (dx / dist) * force;
        final fy = (dy / dist) * force;

        a.fx -= fx;
        a.fy -= fy;
        b.fx += fx;
        b.fy += fy;
      }
    }

    // 3. Hooke's Law Spring Forces along edges
    for (final edge in edges) {
      final source = nodeMap[edge.sourceId];
      final target = nodeMap[edge.targetId];
      if (source == null || target == null) continue;

      final dx = target.x - source.x;
      final dy = target.y - source.y;
      final dist = sqrt(dx * dx + dy * dy) + 0.001;

      final displacement = dist - edge.length;
      final force = displacement * edge.strength;

      final fx = (dx / dist) * force;
      final fy = (dy / dist) * force;

      source.fx += fx;
      source.fy += fy;
      target.fx -= fx;
      target.fy -= fy;
    }

    // 4. Update velocity and position with damping
    const double damping = 0.85;
    for (final node in nodes) {
      node.vx = (node.vx + (node.fx / node.mass) * dt) * damping;
      node.vy = (node.vy + (node.fy / node.mass) * dt) * damping;

      // Limit max velocity
      final speed = sqrt(node.vx * node.vx + node.vy * node.vy);
      if (speed > 120) {
        node.vx = (node.vx / speed) * 120;
        node.vy = (node.vy / speed) * 120;
      }

      node.x += node.vx * dt;
      node.y += node.vy * dt;
    }

    notifyListeners();
  }
}
