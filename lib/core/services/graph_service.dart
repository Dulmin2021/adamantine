import 'dart:math';
import 'package:flutter/material.dart';
import '../models/media_item.dart';
import '../models/album.dart';
import '../models/graph_node.dart';
import '../theme/app_colors.dart';

enum GraphFilter {
  byTag,
  byLocation,
  byDate,
  byPerson,
}

class GraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final Map<String, GraphNode> nodeMap;

  GraphData({
    required this.nodes,
    required this.edges,
    required this.nodeMap,
  });
}

class GraphService {
  GraphData buildGraph({
    required List<MediaItem> allItems,
    required List<Album> allAlbums,
    Set<GraphFilter> activeFilters = const {GraphFilter.byTag},
    String? expandedHubId,
    String? focusedNodeId,
    Map<String, GraphNode>? previousNodeMap,
    bool fromScratch = false,
    int maxNodes = 250,
  }) {
    final List<GraphNode> nodes = [];
    final List<GraphEdge> edges = [];
    final Map<String, GraphNode> nodeMap = {};

    final activeItems = allItems.where((i) => !i.isTrash).toList();

    // 1. Create Hub Nodes for Albums
    for (int i = 0; i < allAlbums.length; i++) {
      final album = allAlbums[i];
      final albumPhotos = activeItems.where((item) => item.albumId == album.id).toList();
      final isExpanded = expandedHubId == album.id;

      // Position hubs: preserve existing position if available, or arrange in circle
      final prevHub = previousNodeMap?['hub_${album.id}'];
      final angle = (i / max(1, allAlbums.length)) * 2 * pi;
      final dist = 220.0 + (i % 2) * 50.0;

      double initialX, initialY, initialVx, initialVy;

      if (fromScratch) {
        // Clustered seed point at the center with high expansion velocity
        initialX = cos(angle) * (4.0 + i * 2.0);
        initialY = sin(angle) * (4.0 + i * 2.0);
        initialVx = cos(angle) * 180.0;
        initialVy = sin(angle) * 180.0;
      } else {
        initialX = prevHub?.x ?? (cos(angle) * dist);
        initialY = prevHub?.y ?? (sin(angle) * dist);
        initialVx = prevHub?.vx ?? 0.0;
        initialVy = prevHub?.vy ?? 0.0;
      }

      final hubMediaItem = album.coverItem ?? (albumPhotos.isNotEmpty ? albumPhotos.first : null);

      final hubNode = GraphNode(
        id: 'hub_${album.id}',
        label: album.name,
        category: NodeCategory.hub,
        albumId: album.id,
        mediaItem: hubMediaItem,
        photoCount: albumPhotos.length,
        radius: 28.0 + min(16.0, albumPhotos.length * 1.5),
        mass: 3.0 + min(3.0, albumPhotos.length * 0.2),
        color: AppColors.primary,
        x: initialX,
        y: initialY,
        vx: initialVx,
        vy: initialVy,
        isExpanded: isExpanded,
        image: prevHub?.image,
      );

      nodes.add(hubNode);
      nodeMap[hubNode.id] = hubNode;

      // 2. Create Satellite Leaf Nodes for Photos
      final shouldShowSatellites = expandedHubId == null || expandedHubId == album.id;
      final satelliteLimit = isExpanded ? albumPhotos.length : min(albumPhotos.length, 8);

      if (shouldShowSatellites) {
        for (int p = 0; p < satelliteLimit; p++) {
          if (nodes.length >= maxNodes) break;
          final photo = albumPhotos[p];
          final satAngle = (p / max(1, satelliteLimit)) * 2 * pi + (p * 0.15);

          final prevLeaf = previousNodeMap?['photo_${photo.id}'];
          double satX, satY, satVx, satVy;

          if (fromScratch) {
            satX = initialX + cos(satAngle) * 6.0;
            satY = initialY + sin(satAngle) * 6.0;
            satVx = cos(satAngle) * 240.0;
            satVy = sin(satAngle) * 240.0;
          } else if (prevLeaf != null) {
            satX = prevLeaf.x;
            satY = prevLeaf.y;
            satVx = prevLeaf.vx;
            satVy = prevLeaf.vy;
          } else {
            // Smooth blooming burst outward from the parent hub
            final satDist = isExpanded ? 24.0 : 16.0;
            satX = hubNode.x + cos(satAngle) * satDist;
            satY = hubNode.y + sin(satAngle) * satDist;
            satVx = cos(satAngle) * (isExpanded ? 180.0 : 40.0);
            satVy = sin(satAngle) * (isExpanded ? 180.0 : 40.0);
          }

          final leafNode = GraphNode(
            id: 'photo_${photo.id}',
            label: photo.title,
            category: NodeCategory.photo,
            albumId: album.id,
            mediaItem: photo,
            photoCount: 1,
            radius: isExpanded ? 11.0 : 7.0,
            mass: 0.8,
            color: isExpanded ? AppColors.primaryLight : AppColors.graphLeaf,
            x: satX,
            y: satY,
            vx: satVx,
            vy: satVy,
            image: prevLeaf?.image,
          );

          nodes.add(leafNode);
          nodeMap[leafNode.id] = leafNode;

          // Membership edge (from photo to parent hub)
          edges.add(GraphEdge(
            id: 'edge_${hubNode.id}_${leafNode.id}',
            sourceId: hubNode.id,
            targetId: leafNode.id,
            type: EdgeType.albumMembership,
            length: isExpanded ? 115.0 : 50.0,
            strength: isExpanded ? 0.12 : 0.25,
            color: AppColors.glassBorder,
            opacity: isExpanded ? 0.8 : 0.4,
          ));
        }
      }
    }

    // 3. Auto-cluster small/distant albums if node count > maxNodes
    if (nodes.length > maxNodes) {
      final excess = nodes.length - maxNodes;
      nodes.removeRange(nodes.length - excess, nodes.length);
      final otherHub = GraphNode(
        id: 'hub_other_clustered',
        label: 'Other Photos (${excess + 1})',
        category: NodeCategory.other,
        radius: 28.0,
        color: AppColors.textSecondary,
        x: 300,
        y: 300,
      );
      nodes.add(otherHub);
      nodeMap[otherHub.id] = otherHub;
    }

    // 4. Derive Cross-Links based on Active Filters
    if (activeFilters.contains(GraphFilter.byTag)) {
      _deriveTagCrossLinks(nodes, edges);
    }
    if (activeFilters.contains(GraphFilter.byLocation)) {
      _deriveLocationCrossLinks(nodes, edges);
    }
    if (activeFilters.contains(GraphFilter.byDate)) {
      _deriveDateCrossLinks(nodes, edges);
    }
    if (activeFilters.contains(GraphFilter.byPerson)) {
      _derivePersonCrossLinks(nodes, edges);
    }

    // 5. Apply Focus Mode Dimming & Hub Expansion Scaling
    if (focusedNodeId != null && nodeMap.containsKey(focusedNodeId)) {
      final focused = nodeMap[focusedNodeId]!;
      focused.isFocused = true;

      final Set<String> neighborIds = {focused.id};
      for (final e in edges) {
        if (e.sourceId == focused.id) neighborIds.add(e.targetId);
        if (e.targetId == focused.id) neighborIds.add(e.sourceId);
      }

      for (final node in nodes) {
        if (!neighborIds.contains(node.id)) {
          node.isDimmed = true;
          node.opacity = 0.15;
        } else {
          node.isDimmed = false;
          node.opacity = 1.0;
        }
      }
    } else if (expandedHubId != null) {
      // Bloom state: non-expanded hubs are faded & shrunk
      for (final node in nodes) {
        if (node.category == NodeCategory.hub && node.albumId != expandedHubId) {
          node.opacity = 0.25;
          node.radius = 16.0;
        } else {
          node.opacity = 1.0;
        }
      }
    }

    return GraphData(nodes: nodes, edges: edges, nodeMap: nodeMap);
  }

  void _deriveTagCrossLinks(List<GraphNode> nodes, List<GraphEdge> edges) {
    final photoNodes = nodes.where((n) => n.mediaItem != null).toList();
    for (int i = 0; i < min(photoNodes.length, 60); i++) {
      for (int j = i + 1; j < min(photoNodes.length, 60); j++) {
        final a = photoNodes[i];
        final b = photoNodes[j];
        if (a.albumId == b.albumId) continue; // skip same album

        final commonTags = a.mediaItem!.tags.toSet().intersection(b.mediaItem!.tags.toSet());
        if (commonTags.isNotEmpty) {
          edges.add(GraphEdge(
            id: 'tag_${a.id}_${b.id}',
            sourceId: a.id,
            targetId: b.id,
            type: EdgeType.sharedTag,
            length: 160.0,
            strength: 0.04,
            color: const Color(0x7734D399),
            opacity: 0.7,
            label: commonTags.first,
          ));
        }
      }
    }
  }

  void _deriveLocationCrossLinks(List<GraphNode> nodes, List<GraphEdge> edges) {
    final photoNodes = nodes.where((n) => n.mediaItem?.hasLocation ?? false).toList();
    for (int i = 0; i < min(photoNodes.length, 50); i++) {
      for (int j = i + 1; j < min(photoNodes.length, 50); j++) {
        final a = photoNodes[i];
        final b = photoNodes[j];
        if (a.albumId == b.albumId) continue;

        final latDiff = (a.mediaItem!.exif.latitude! - b.mediaItem!.exif.latitude!).abs();
        final lngDiff = (a.mediaItem!.exif.longitude! - b.mediaItem!.exif.longitude!).abs();

        if (latDiff < 0.5 && lngDiff < 0.5) {
          edges.add(GraphEdge(
            id: 'loc_${a.id}_${b.id}',
            sourceId: a.id,
            targetId: b.id,
            type: EdgeType.sharedLocation,
            length: 180.0,
            strength: 0.03,
            color: const Color(0x77F43F5E),
            opacity: 0.65,
            label: a.mediaItem!.exif.locationName,
          ));
        }
      }
    }
  }

  void _deriveDateCrossLinks(List<GraphNode> nodes, List<GraphEdge> edges) {
    final photoNodes = nodes.where((n) => n.mediaItem != null).toList();
    for (int i = 0; i < min(photoNodes.length, 45); i++) {
      for (int j = i + 1; j < min(photoNodes.length, 45); j++) {
        final a = photoNodes[i];
        final b = photoNodes[j];
        if (a.albumId == b.albumId) continue;

        final diffDays = a.mediaItem!.createDate.difference(b.mediaItem!.createDate).inDays.abs();
        if (diffDays <= 2) {
          edges.add(GraphEdge(
            id: 'date_${a.id}_${b.id}',
            sourceId: a.id,
            targetId: b.id,
            type: EdgeType.sharedDate,
            length: 190.0,
            strength: 0.02,
            color: const Color(0x77F59E0B),
            opacity: 0.6,
          ));
        }
      }
    }
  }

  void _derivePersonCrossLinks(List<GraphNode> nodes, List<GraphEdge> edges) {
    final photoNodes = nodes.where((n) => n.mediaItem?.people.isNotEmpty ?? false).toList();
    for (int i = 0; i < min(photoNodes.length, 40); i++) {
      for (int j = i + 1; j < min(photoNodes.length, 40); j++) {
        final a = photoNodes[i];
        final b = photoNodes[j];
        if (a.albumId == b.albumId) continue;

        final commonPeople = a.mediaItem!.people.toSet().intersection(b.mediaItem!.people.toSet());
        if (commonPeople.isNotEmpty) {
          edges.add(GraphEdge(
            id: 'person_${a.id}_${b.id}',
            sourceId: a.id,
            targetId: b.id,
            type: EdgeType.sharedPerson,
            length: 150.0,
            strength: 0.05,
            color: const Color(0x77C084FC),
            opacity: 0.75,
            label: commonPeople.first,
          ));
        }
      }
    }
  }
}
