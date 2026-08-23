import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/location_cluster.dart';
import '../../../../core/theme/app_colors.dart';
import '../../state/gallery_provider.dart';
import '../../state/earth_provider.dart';
import 'painters/globe_painter.dart';
import 'widgets/cluster_bottom_sheet.dart';
import 'widgets/trips_carousel.dart';
import 'widgets/earth_search_bar.dart';
import 'satellite_map_view.dart';

class EarthView extends StatefulWidget {
  const EarthView({super.key});

  @override
  State<EarthView> createState() => _EarthViewState();
}

class _EarthViewState extends State<EarthView> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    final gallery = context.read<GalleryProvider>();
    final earth = context.read<EarthProvider>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      earth.refreshGeoData(gallery.allItems);
    });

    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _lastElapsed).inMicroseconds / 1000000.0;
      _lastElapsed = elapsed;

      if (dt > 0 && dt < 0.1) {
        earth.tick(dt);
      }
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleTapUp(TapUpDetails details, BuildContext context, EarthProvider earth, Size size) {
    final localPos = details.localPosition;
    final center = Offset(size.width / 2, size.height / 2);
    final globeRadius = min(size.width, size.height) * 0.38 * earth.zoom;

    // Check hit test against visible clusters
    LocationCluster? hitCluster;
    double minDistance = double.infinity;

    for (final cluster in earth.clusters) {
      final lat = cluster.latitude * pi / 180.0;
      final lon = cluster.longitude * pi / 180.0;

      // 3D Cartesian coordinates
      double x = globeRadius * cos(lat) * sin(lon);
      double y = -globeRadius * sin(lat);
      double z = globeRadius * cos(lat) * cos(lon);

      // Rotate yaw
      final x1 = x * cos(earth.yaw) + z * sin(earth.yaw);
      final z1 = -x * sin(earth.yaw) + z * cos(earth.yaw);

      // Rotate pitch
      final y2 = y * cos(earth.pitch) - z1 * sin(earth.pitch);
      final z2 = y * sin(earth.pitch) + z1 * cos(earth.pitch);

      // Depth test: ignore back hemisphere
      if (z2 <= 0) continue;

      final screenPos = Offset(center.dx + x1, center.dy + y2);
      final dist = (screenPos - localPos).distance;

      if (dist <= 26.0 && dist < minDistance) {
        minDistance = dist;
        hitCluster = cluster;
      }
    }

    if (hitCluster != null) {
      earth.selectCluster(hitCluster);
    } else {
      earth.closeClusterSheet();
    }
  }

  @override
  Widget build(BuildContext context) {
    final earth = context.watch<EarthProvider>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // 3D Globe Render or Flat Map Fallback
            if (earth.useFlatMap)
              SatelliteMapView(
                clusters: earth.clusters,
                onClusterSelected: (c) => earth.selectCluster(c),
              )
            else
              GestureDetector(
                onTapUp: (details) => _handleTapUp(details, context, earth, size),
                onScaleStart: (_) => earth.onScaleStart(),
                onScaleUpdate: (details) => earth.onScaleUpdate(details),
                onScaleEnd: (_) => earth.onScaleEnd(),
                child: Container(
                  color: AppColors.background,
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(
                    painter: GlobePainter(
                      yaw: earth.yaw,
                      pitch: earth.pitch,
                      zoom: earth.zoom,
                      clusters: earth.clusters,
                      selectedClusterId: earth.selectedCluster?.id,
                    ),
                  ),
                ),
              ),

            // Top Search & Fly-to Bar
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: EarthSearchBar(
                onSearch: (q) => earth.searchPlace(q),
                onClear: () {},
              ),
            ),

            // Flat Map / 3D Globe Toggle Button (Top Right)
            Positioned(
              top: 72,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'earth_mode_toggle',
                onPressed: () => earth.toggleRenderMode(),
                backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
                child: Icon(
                  earth.useFlatMap ? Icons.public_rounded : Icons.map_outlined,
                  color: AppColors.primaryLight,
                  size: 20,
                ),
              ),
            ),

            // Auto-Rotate Toggle (Top Right below mode toggle)
            if (!earth.useFlatMap)
              Positioned(
                top: 124,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'earth_autorotate_toggle',
                  onPressed: () => earth.toggleAutoRotate(),
                  backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.9),
                  child: Icon(
                    earth.isAutoRotate ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                    color: earth.isAutoRotate ? AppColors.primaryLight : AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),

            // Fly to Nearest Photos FAB (Bottom Right)
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'earth_fly_nearest_fab',
                onPressed: () => earth.flyToNearestCluster(),
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.my_location_rounded, color: Colors.white),
              ),
            ),

            // Bottom Trips Carousel (Docked above bottom nav)
            if (earth.selectedCluster == null && earth.trips.isNotEmpty)
              Positioned(
                bottom: 20,
                left: 0,
                right: 80,
                child: TripsCarousel(
                  trips: earth.trips,
                  onTripSelected: (t) => earth.selectTrip(t),
                ),
              ),

            // Cluster Bottom Sheet (When pin or cluster tapped)
            if (earth.selectedCluster != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClusterBottomSheet(
                  cluster: earth.selectedCluster!,
                  onClose: () => earth.closeClusterSheet(),
                ),
              ),
          ],
        );
      },
    );
  }
}
