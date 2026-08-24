import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'media_item.dart';

enum NodeCategory {
  hub,      // Album hub node
  photo,    // Satellite photo node
  other,    // Clustered distant/overflow node
}

enum EdgeType {
  albumMembership,
  sharedTag,
  sharedLocation,
  sharedDate,
  sharedPerson,
}

class Vector2D {
  double x;
  double y;

  Vector2D(this.x, this.y);

  Vector2D operator +(Vector2D other) => Vector2D(x + other.x, y + other.y);
  Vector2D operator -(Vector2D other) => Vector2D(x - other.x, y - other.y);
  Vector2D operator *(double scalar) => Vector2D(x * scalar, y * scalar);
  Vector2D operator /(double scalar) => Vector2D(x / scalar, y / scalar);

  double get lengthSquared => x * x + y * y;
  double get length => x * x + y * y > 0 ? (x * x + y * y) : 0.0;

  void normalize() {
    final len = lengthSquared;
    if (len > 0.00001) {
      final l = 1.0 / (len > 0 ? 1.0 : 1.0); // simple normalize helper
      x *= l;
      y *= l;
    }
  }

  Vector2D clone() => Vector2D(x, y);
}

class GraphNode {
  final String id;
  final String label;
  final NodeCategory category;
  final String? albumId;
  final MediaItem? mediaItem;
  final int photoCount;
  
  double x;
  double y;
  double vx;
  double vy;
  double fx;
  double fy;
  double radius;
  double mass;
  Color color;
  double opacity;
  bool isExpanded;
  bool isFocused;
  bool isDimmed;
  bool isPinned;
  ui.Image? image; // Decoded thumbnail for canvas rendering

  GraphNode({
    required this.id,
    required this.label,
    required this.category,
    this.albumId,
    this.mediaItem,
    this.photoCount = 0,
    this.x = 0,
    this.y = 0,
    this.vx = 0,
    this.vy = 0,
    this.fx = 0,
    this.fy = 0,
    this.radius = 16.0,
    this.mass = 1.0,
    this.color = const Color(0xFF8AD7A3),
    this.opacity = 1.0,
    this.isExpanded = false,
    this.isFocused = false,
    this.isDimmed = false,
    this.isPinned = false,
    this.image,
  });

  Offset get offset => Offset(x, y);

  GraphNode copyWith({
    String? id,
    String? label,
    NodeCategory? category,
    String? albumId,
    MediaItem? mediaItem,
    int? photoCount,
    double? x,
    double? y,
    double? vx,
    double? vy,
    double? radius,
    double? mass,
    Color? color,
    double? opacity,
    bool? isExpanded,
    bool? isFocused,
    bool? isDimmed,
  }) {
    return GraphNode(
      id: id ?? this.id,
      label: label ?? this.label,
      category: category ?? this.category,
      albumId: albumId ?? this.albumId,
      mediaItem: mediaItem ?? this.mediaItem,
      photoCount: photoCount ?? this.photoCount,
      x: x ?? this.x,
      y: y ?? this.y,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      radius: radius ?? this.radius,
      mass: mass ?? this.mass,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      isExpanded: isExpanded ?? this.isExpanded,
      isFocused: isFocused ?? this.isFocused,
      isDimmed: isDimmed ?? this.isDimmed,
    );
  }
}

class GraphEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final EdgeType type;
  final double length;
  final double strength;
  final Color color;
  final double opacity;
  final String? label;

  const GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.type,
    this.length = 80.0,
    this.strength = 0.1,
    this.color = const Color(0x558B5CF6),
    this.opacity = 0.6,
    this.label,
  });
}
