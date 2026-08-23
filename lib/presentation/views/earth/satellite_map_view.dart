import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/models/location_cluster.dart';
import '../../../../core/theme/app_colors.dart';

class SatelliteMapView extends StatelessWidget {
  final List<LocationCluster> clusters;
  final Function(LocationCluster) onClusterSelected;

  const SatelliteMapView({
    super.key,
    required this.clusters,
    required this.onClusterSelected,
  });

  @override
  Widget build(BuildContext context) {
    final initialCenter = clusters.isNotEmpty
        ? LatLng(clusters.first.latitude, clusters.first.longitude)
        : const LatLng(20.0, 0.0);

    return FlutterMap(
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 2.5,
        minZoom: 1.5,
        maxZoom: 18.0,
      ),
      children: [
        // Dark Carto / OpenStreetMap Tile Layer
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.adamantine.adamantine',
        ),

        // Clustered Photo Markers Layer
        MarkerLayer(
          markers: clusters.map((cluster) {
            return Marker(
              point: LatLng(cluster.latitude, cluster.longitude),
              width: cluster.count > 1 ? 40 : 30,
              height: cluster.count > 1 ? 40 : 30,
              child: GestureDetector(
                onTap: () => onClusterSelected(cluster),
                child: Container(
                  decoration: BoxDecoration(
                    color: cluster.count > 1 ? AppColors.primary : AppColors.earthPin,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: (cluster.count > 1 ? AppColors.primary : AppColors.earthPin).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: cluster.count > 1
                        ? Text(
                            '${cluster.count}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          )
                        : const Icon(Icons.photo, color: Colors.white, size: 14),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
