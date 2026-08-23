import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/models/location_cluster.dart';
import '../../../../core/theme/app_colors.dart';

class GlobePainter extends CustomPainter {
  final double yaw;     // Longitude rotation in radians
  final double pitch;   // Latitude tilt in radians
  final double zoom;    // Scale multiplier
  final List<LocationCluster> clusters;
  final String? selectedClusterId;

  // Pre-calculated starfield points
  static final List<Offset> _stars = List.generate(80, (i) {
    final random = Random(i * 997);
    return Offset(random.nextDouble(), random.nextDouble());
  });

  GlobePainter({
    required this.yaw,
    required this.pitch,
    required this.zoom,
    required this.clusters,
    this.selectedClusterId,
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
          AppColors.primary.withValues(alpha: 0.35),
          AppColors.primary.withValues(alpha: 0.1),
          Colors.transparent,
        ],
        stops: const [0.75, 0.9, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: globeRadius * 1.35));
    canvas.drawCircle(center, globeRadius * 1.35, atmospherePaint);

    // 3. Draw Globe Sphere Body (Dark oceans with subtle gradient)
    final sphereBodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          const Color(0xFF1E1E28),
          const Color(0xFF13131A),
          const Color(0xFF09090C),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: globeRadius));
    canvas.drawCircle(center, globeRadius, sphereBodyPaint);

    // 4. Draw Spherical Grid Lines (Parallels & Meridians)
    _drawGridLines(canvas, center, globeRadius);

    // 5. Draw Continents / Landmass representations
    _drawStylizedLandmasses(canvas, center, globeRadius);

    // 6. Draw Globe Limb / Border Ring
    final limbPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(center, globeRadius, limbPaint);

    // 7. Project Geotagged Clusters & Pins (with 3D Depth Testing)
    _drawClusters(canvas, center, globeRadius);
  }

  void _drawStarfield(Canvas canvas, Size size) {
    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (int i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final alpha = 0.2 + 0.5 * (sin(i + yaw) * 0.5 + 0.5);
      starPaint.color = Colors.white.withValues(alpha: alpha);
      final radius = (i % 3 == 0) ? 1.5 : 1.0;
      canvas.drawCircle(Offset(s.dx * size.width, s.dy * size.height), radius, starPaint);
    }
  }

  void _drawGridLines(Canvas canvas, Offset center, double radius) {
    final gridPaint = Paint()
      ..color = AppColors.glassBorder.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Latitude parallels (-60, -30, 0, 30, 60 degrees)
    for (int latDeg = -60; latDeg <= 60; latDeg += 30) {
      final path = Path();
      bool first = true;

      for (int lonDeg = -180; lonDeg <= 180; lonDeg += 10) {
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

  void _drawStylizedLandmasses(Canvas canvas, Offset center, double radius) {
    final landPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Stylized continent sample nodes
    final landCenters = [
      {'lat': 45.0, 'lon': 15.0, 'rad': 25.0},   // Europe
      {'lat': 35.0, 'lon': 100.0, 'rad': 35.0},  // Asia
      {'lat': 0.0, 'lon': 20.0, 'rad': 30.0},    // Africa
      {'lat': 40.0, 'lon': -100.0, 'rad': 30.0}, // North America
      {'lat': -15.0, 'lon': -60.0, 'rad': 28.0}, // South America
      {'lat': -25.0, 'lon': 135.0, 'rad': 22.0}, // Australia
      {'lat': 7.0, 'lon': 81.0, 'rad': 8.0},     // Sri Lanka
      {'lat': 36.0, 'lon': 138.0, 'rad': 12.0},  // Japan
    ];

    for (final land in landCenters) {
      final lat = land['lat'] as double;
      final lon = land['lon'] as double;
      final landR = land['rad'] as double;

      final pt3d = _project3D(lat, lon, radius);
      if (pt3d.z > 0) {
        final projectedRadius = (landR / 90.0) * radius * (pt3d.z / radius);
        canvas.drawCircle(
          Offset(center.dx + pt3d.x, center.dy + pt3d.y),
          max(4.0, projectedRadius),
          landPaint,
        );
      }
    }
  }

  void _drawClusters(Canvas canvas, Offset center, double radius) {
    for (final cluster in clusters) {
      final pt3d = _project3D(cluster.latitude, cluster.longitude, radius);

      // Depth test: cull pins on the back hemisphere (z <= 0)
      if (pt3d.z <= 0) continue;

      final screenPos = Offset(center.dx + pt3d.x, center.dy + pt3d.y);
      final isSelected = selectedClusterId == cluster.id;
      final isMultiple = cluster.count > 1;

      // Glow halo
      final glowPaint = Paint()
        ..color = (isSelected ? AppColors.earthPin : AppColors.earthCluster).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(screenPos, isMultiple ? 18.0 : 12.0, glowPaint);

      if (isMultiple) {
        // Numbered Cluster Badge (e.g. "24")
        final badgePaint = Paint()
          ..color = isSelected ? AppColors.earthPin : AppColors.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(screenPos, 14.0, badgePaint);

        final strokePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(screenPos, 14.0, strokePaint);

        // Count Text
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${cluster.count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(screenPos.dx - textPainter.width / 2, screenPos.dy - textPainter.height / 2),
        );
      } else {
        // Single Pin Marker
        final pinPaint = Paint()
          ..color = isSelected ? AppColors.earthPin : AppColors.primaryLight
          ..style = PaintingStyle.fill;
        canvas.drawCircle(screenPos, 8.0, pinPaint);

        final pinBorder = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(screenPos, 8.0, pinBorder);
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
