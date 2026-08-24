import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/models/location_cluster.dart';
import '../../../../core/theme/app_colors.dart';

class GlobePainter extends CustomPainter {
  final double yaw;     // Longitude rotation in radians
  final double pitch;   // Latitude tilt in radians
  final double zoom;    // Scale multiplier
  final List<LocationCluster> clusters;
  final String? selectedClusterId;
  final Map<String, ui.Image>? clusterThumbnails;

  // Pre-calculated starfield points
  static final List<Offset> _stars = List.generate(100, (i) {
    final random = Random(i * 997);
    return Offset(random.nextDouble(), random.nextDouble());
  });

  GlobePainter({
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.clusters,
    this.selectedClusterId,
    this.clusterThumbnails,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final globeRadius = min(size.width, size.height) * 0.38 * zoom;

    // 1. Draw Starfield Background
    _drawStarfield(canvas, size);

    // 2. Draw Atmospheric Outer Glow Halo
    final atmospherePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.primary.withValues(alpha: 0.4),
          AppColors.primaryDark.withValues(alpha: 0.15),
          Colors.transparent,
        ],
        stops: const [0.75, 0.92, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: globeRadius * 1.35));
    canvas.drawCircle(center, globeRadius * 1.35, atmospherePaint);

    // 3. Draw Globe Sphere Body (Deep oceanic sphere with realistic radial shading)
    final sphereBodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        colors: [
          const Color(0xFF19222E),
          const Color(0xFF10161F),
          const Color(0xFF090D12),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: globeRadius));
    canvas.drawCircle(center, globeRadius, sphereBodyPaint);

    // 4. Draw Spherical Grid Lines (Parallels & Meridians)
    _drawGridLines(canvas, center, globeRadius);

    // 5. Draw Realistic Continent Landmasses
    _drawRealisticContinents(canvas, center, globeRadius);

    // 6. Draw Globe Limb / Border Ring
    final limbPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, globeRadius, limbPaint);

    // 7. Project Floating Geotagged Photo Thumbnail Pins
    _drawClusters(canvas, center, globeRadius);
  }

  void _drawStarfield(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (int i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final alpha = 0.15 + 0.45 * (sin(i * 3.0 + yaw) * 0.5 + 0.5);
      starPaint.color = Colors.white.withValues(alpha: alpha);
      final radius = (i % 3 == 0) ? 1.5 : 1.0;
      canvas.drawCircle(Offset(s.dx * size.width, s.dy * size.height), radius, starPaint);
    }
  }

  void _drawGridLines(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Latitude parallels (-60, -30, 0, 30, 60 degrees)
    for (int latDeg = -60; latDeg <= 60; latDeg += 30) {
      final path = Path();
      bool first = true;

      for (int lonDeg = -180; lonDeg <= 180; lonDeg += 8) {
        final pt3d = _project3D(latDeg.toDouble(), lonDeg.toDouble(), radius);
        if (pt3d.z > 0) {
          final pt2d = Offset(center.dx + pt3d.x, center.dy + pt3d.y);
          if (first) {
            path.moveTo(pt2d.dx, pt2d.dy);
            first = false;
          } else {
            path.lineTo(pt2d.dx, pt2d.dy);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Longitude meridians (every 30 degrees)
    for (int lonDeg = -180; lonDeg < 180; lonDeg += 30) {
      final path = Path();
      bool first = true;

      for (int latDeg = -85; latDeg <= 85; latDeg += 5) {
        final pt3d = _project3D(latDeg.toDouble(), lonDeg.toDouble(), radius);
        if (pt3d.z > 0) {
          final pt2d = Offset(center.dx + pt3d.x, center.dy + pt3d.y);
          if (first) {
            path.moveTo(pt2d.dx, pt2d.dy);
            first = false;
          } else {
            path.lineTo(pt2d.dx, pt2d.dy);
          }
        } else {
          first = true;
        }
      }
      canvas.drawPath(path, gridPaint);
    }
  }

  void _drawRealisticContinents(Canvas canvas, Offset center, double radius) {
    final landFillPaint = Paint()
      ..color = const Color(0xFF142E20)
      ..style = PaintingStyle.fill;

    final shorelinePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Detailed world continent and regional polygon outlines [lat, lon]
    const List<List<List<double>>> continents = [
      // Africa
      [[37.0, 10.0], [32.0, 32.0], [12.0, 44.0], [0.0, 42.0], [-10.0, 40.0], [-25.0, 33.0], [-34.0, 26.0], [-34.0, 18.0], [-20.0, 12.0], [-5.0, 10.0], [5.0, 0.0], [5.0, -10.0], [15.0, -17.0], [28.0, -13.0], [35.0, -5.0], [37.0, 10.0]],
      // Europe
      [[71.0, 28.0], [68.0, 40.0], [60.0, 50.0], [45.0, 40.0], [40.0, 28.0], [36.0, 22.0], [36.0, -5.0], [43.0, -9.0], [48.0, -4.0], [54.0, 8.0], [60.0, 5.0], [65.0, 12.0], [71.0, 28.0]],
      // Asia & Middle East
      [[75.0, 100.0], [72.0, 140.0], [65.0, 175.0], [58.0, 160.0], [42.0, 132.0], [35.0, 120.0], [22.0, 114.0], [8.0, 104.0], [1.0, 104.0], [15.0, 95.0], [22.0, 88.0], [8.0, 77.0], [24.0, 68.0], [25.0, 56.0], [12.0, 44.0], [28.0, 34.0], [38.0, 36.0], [42.0, 50.0], [55.0, 60.0], [75.0, 100.0]],
      // North America
      [[72.0, -155.0], [70.0, -125.0], [60.0, -85.0], [50.0, -55.0], [44.0, -64.0], [30.0, -80.0], [25.0, -80.0], [18.0, -88.0], [8.0, -80.0], [15.0, -95.0], [22.0, -105.0], [32.0, -117.0], [48.0, -125.0], [60.0, -145.0], [65.0, -168.0], [72.0, -155.0]],
      // South America
      [[12.0, -72.0], [6.0, -52.0], [-5.0, -35.0], [-22.0, -40.0], [-35.0, -55.0], [-54.0, -68.0], [-45.0, -75.0], [-18.0, -70.0], [-5.0, -80.0], [10.0, -75.0], [12.0, -72.0]],
      // Australia
      [[-12.0, 132.0], [-15.0, 145.0], [-25.0, 153.0], [-38.0, 148.0], [-38.0, 140.0], [-32.0, 115.0], [-22.0, 114.0], [-15.0, 125.0], [-12.0, 132.0]],
      // Greenland
      [[82.0, -30.0], [75.0, -20.0], [60.0, -45.0], [70.0, -55.0], [80.0, -60.0], [82.0, -30.0]],
      // British Isles
      [[58.0, -5.0], [52.0, 1.5], [50.0, -5.0], [55.0, -8.0], [58.0, -5.0]],
      // Japan
      [[44.0, 144.0], [38.0, 141.0], [33.0, 132.0], [36.0, 136.0], [43.0, 142.0], [44.0, 144.0]],
      // Sri Lanka
      [[9.8, 80.2], [6.0, 80.5], [6.0, 81.5], [9.0, 81.5], [9.8, 80.2]],
      // Madagascar
      [[-12.0, 49.0], [-25.0, 47.0], [-25.0, 44.0], [-15.0, 46.0], [-12.0, 49.0]],
    ];

    for (final poly in continents) {
      final path = Path();
      bool first = true;
      bool visible = false;

      for (final pt in poly) {
        final pt3d = _project3D(pt[0], pt[1], radius);
        if (pt3d.z > -radius * 0.15) {
          visible = true;
          final pt2d = Offset(center.dx + pt3d.x, center.dy + pt3d.y);
          if (first) {
            path.moveTo(pt2d.dx, pt2d.dy);
            first = false;
          } else {
            path.lineTo(pt2d.dx, pt2d.dy);
          }
        }
      }

      if (visible && !first) {
        path.close();
        canvas.drawPath(path, landFillPaint);
        canvas.drawPath(path, shorelinePaint);
      }
    }
  }

  void _drawClusters(Canvas canvas, Offset center, double radius) {
    for (final cluster in clusters) {
      final pt3d = _project3D(cluster.latitude, cluster.longitude, radius);

      // Depth test: cull pins on the back hemisphere (z <= 0)
      if (pt3d.z <= 0) continue;

      final anchorPos = Offset(center.dx + pt3d.x, center.dy + pt3d.y);
      final isSelected = selectedClusterId == cluster.id;
      final thumbnailImage = clusterThumbnails?[cluster.id];

      const double cardSize = 38.0;
      final pinCenter = Offset(anchorPos.dx, anchorPos.dy - 28.0);

      // 1. Globe Anchor Dot on Surface
      final anchorPaint = Paint()
        ..color = isSelected ? AppColors.earthPin : AppColors.primary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(anchorPos, 4.0, anchorPaint);

      final anchorRing = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(anchorPos, 4.0, anchorRing);

      // 2. Vertical Pin Stalk Line
      final stalkPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..strokeWidth = 1.5;
      canvas.drawLine(anchorPos, Offset(pinCenter.dx, pinCenter.dy + cardSize / 2), stalkPaint);

      // 3. Drop Shadow for Floating Photo Card
      final cardRect = Rect.fromCenter(center: pinCenter, width: cardSize, height: cardSize);
      final rrect = RRect.fromRectAndRadius(cardRect, const Radius.circular(8));

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadowPaint);

      // 4. Render Photo Thumbnail Card
      if (thumbnailImage != null) {
        canvas.save();
        canvas.clipRRect(rrect);
        canvas.drawImageRect(
          thumbnailImage,
          Rect.fromLTWH(0, 0, thumbnailImage.width.toDouble(), thumbnailImage.height.toDouble()),
          cardRect,
          Paint()..filterQuality = FilterQuality.medium,
        );
        canvas.restore();
      } else {
        // Fallback charcoal container with photo icon placeholder
        final bgPaint = Paint()
          ..color = AppColors.surfaceContainerHigh
          ..style = PaintingStyle.fill;
        canvas.drawRRect(rrect, bgPaint);

        canvas.drawCircle(
          pinCenter,
          8.0,
          Paint()..color = AppColors.primaryDark.withValues(alpha: 0.5),
        );
      }

      // 5. Card Border Ring
      final borderPaint = Paint()
        ..color = isSelected ? AppColors.earthPin : Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRRect(rrect, borderPaint);

      // 6. Photo Count Badge Pill (top right)
      if (cluster.count > 1) {
        final badgeOffset = Offset(pinCenter.dx + cardSize / 2 - 2, pinCenter.dy - cardSize / 2 + 2);
        final badgePaint = Paint()
          ..color = isSelected ? AppColors.earthPin : AppColors.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(badgeOffset, 9.0, badgePaint);

        final badgeBorder = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawCircle(badgeOffset, 9.0, badgeBorder);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '${cluster.count}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(badgeOffset.dx - textPainter.width / 2, badgeOffset.dy - textPainter.height / 2),
        );
      }
    }
  }

  /// 3D Spherical transformation matrix (Lat/Lng -> 3D Sphere -> Yaw/Pitch Rotation)
  _Point3D _project3D(double latDeg, double lonDeg, double radius) {
    final lat = latDeg * pi / 180.0;
    final lon = lonDeg * pi / 180.0;

    // 1. Spherical to 3D Cartesian coordinates
    double x = radius * cos(lat) * sin(lon);
    double y = -radius * sin(lat);
    double z = radius * cos(lat) * cos(lon);

    // 2. Rotate around Y-axis (Yaw)
    final x1 = x * cos(yaw) + z * sin(yaw);
    final z1 = -x * sin(yaw) + z * cos(yaw);

    // 3. Rotate around X-axis (Pitch)
    final y2 = y * cos(pitch) - z1 * sin(pitch);
    final z2 = y * sin(pitch) + z1 * cos(pitch);

    return _Point3D(x1, y2, z2);
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) => true;
}

class _Point3D {
  final double x;
  final double y;
  final double z;
  const _Point3D(this.x, this.y, this.z);
}

