import 'dart:math';
import '../models/media_item.dart';
import '../models/location_cluster.dart';
import '../models/trip.dart';

class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);
}

class GeoService {
  /// Calculate distance between two lat/lng coordinates using the Haversine formula (in km)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) => degrees * pi / 180.0;
  double _radiansToDegrees(double radians) => radians * 180.0 / pi;

  /// Cluster geotagged media items based on proximity threshold (in km)
  List<LocationCluster> clusterPhotos(List<MediaItem> items, {double clusterRadiusKm = 50.0}) {
    final geotagged = items.where((i) => !i.isTrash && i.hasLocation).toList();
    final List<LocationCluster> clusters = [];
    final List<bool> visited = List.filled(geotagged.length, false);

    for (int i = 0; i < geotagged.length; i++) {
      if (visited[i]) continue;
      visited[i] = true;

      final root = geotagged[i];
      final List<MediaItem> clusterMembers = [root];
      double sumLat = root.exif.latitude!;
      double sumLng = root.exif.longitude!;

      for (int j = i + 1; j < geotagged.length; j++) {
        if (visited[j]) continue;
        final candidate = geotagged[j];
        final dist = calculateDistance(
          root.exif.latitude!,
          root.exif.longitude!,
          candidate.exif.latitude!,
          candidate.exif.longitude!,
        );

        if (dist <= clusterRadiusKm) {
          visited[j] = true;
          clusterMembers.add(candidate);
          sumLat += candidate.exif.latitude!;
          sumLng += candidate.exif.longitude!;
        }
      }

      final centerLat = sumLat / clusterMembers.length;
      final centerLng = sumLng / clusterMembers.length;

      // Extract place name from EXIF location or fall back
      final placeName = clusterMembers.firstWhere(
        (m) => m.exif.locationName != null && m.exif.locationName!.isNotEmpty,
        orElse: () => clusterMembers.first,
      ).exif.locationName ?? 'Location (${centerLat.toStringAsFixed(2)}, ${centerLng.toStringAsFixed(2)})';

      clusters.add(LocationCluster(
        id: 'cluster_${root.id}_${clusterMembers.length}',
        latitude: centerLat,
        longitude: centerLng,
        title: placeName,
        subtitle: '${clusterMembers.length} photos',
        items: clusterMembers,
        startDate: clusterMembers.map((m) => m.createDate).reduce((a, b) => a.isBefore(b) ? a : b),
        endDate: clusterMembers.map((m) => m.createDate).reduce((a, b) => a.isAfter(b) ? a : b),
      ));
    }

    return clusters;
  }

  /// Interpolate great-circle arc points between two coordinates (0.0 <= t <= 1.0)
  GeoPoint interpolateGreatCircle(GeoPoint start, GeoPoint end, double t) {
    final lat1 = _degreesToRadians(start.latitude);
    final lon1 = _degreesToRadians(start.longitude);
    final lat2 = _degreesToRadians(end.latitude);
    final lon2 = _degreesToRadians(end.longitude);

    final d = 2 * asin(sqrt(pow(sin((lat1 - lat2) / 2), 2) +
        cos(lat1) * cos(lat2) * pow(sin((lon1 - lon2) / 2), 2)));

    if (d < 0.0001) return start;

    final a = sin((1 - t) * d) / sin(d);
    final b = sin(t * d) / sin(d);

    final x = a * cos(lat1) * cos(lon1) + b * cos(lat2) * cos(lon2);
    final y = a * cos(lat1) * sin(lon1) + b * cos(lat2) * sin(lon2);
    final z = a * sin(lat1) + b * sin(lat2);

    final lat = atan2(z, sqrt(x * x + y * y));
    final lon = atan2(y, x);

    return GeoPoint(_radiansToDegrees(lat), _radiansToDegrees(lon));
  }

  /// Automatically detect trips from clusters separated by date gaps (> 24 hours)
  List<Trip> detectTrips(List<MediaItem> allItems) {
    final geotagged = allItems.where((i) => !i.isTrash && i.hasLocation).toList();
    if (geotagged.isEmpty) return [];

    // Sort chronologically
    geotagged.sort((a, b) => a.createDate.compareTo(b.createDate));

    final List<Trip> trips = [];
    List<MediaItem> currentTripPhotos = [geotagged.first];

    for (int i = 1; i < geotagged.length; i++) {
      final prev = geotagged[i - 1];
      final curr = geotagged[i];

      final dayGap = curr.createDate.difference(prev.createDate).inDays.abs();
      final dist = calculateDistance(
        prev.exif.latitude!,
        prev.exif.longitude!,
        curr.exif.latitude!,
        curr.exif.longitude!,
      );

      // If more than 3 days apart or moved to a completely different region (> 300km)
      if (dayGap > 3 || dist > 300) {
        if (currentTripPhotos.length >= 2) {
          trips.add(_createTrip(currentTripPhotos));
        }
        currentTripPhotos = [curr];
      } else {
        currentTripPhotos.add(curr);
      }
    }

    if (currentTripPhotos.length >= 2) {
      trips.add(_createTrip(currentTripPhotos));
    }

    return trips;
  }

  Trip _createTrip(List<MediaItem> tripPhotos) {
    final first = tripPhotos.first;
    final last = tripPhotos.last;

    double sumLat = 0;
    double sumLng = 0;
    for (final p in tripPhotos) {
      sumLat += p.exif.latitude!;
      sumLng += p.exif.longitude!;
    }

    final avgLat = sumLat / tripPhotos.length;
    final avgLng = sumLng / tripPhotos.length;

    final place = tripPhotos.firstWhere(
      (m) => m.exif.locationName != null,
      orElse: () => tripPhotos.first,
    ).exif.locationName ?? 'Trip';

    final monthNames = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final tripTitle = '$place, ${monthNames[first.createDate.month]} ${first.createDate.year}';

    return Trip(
      id: 'trip_${first.id}_${tripPhotos.length}',
      title: tripTitle,
      destination: place,
      startDate: first.createDate,
      endDate: last.createDate,
      centerLatitude: avgLat,
      centerLongitude: avgLng,
      photos: tripPhotos,
      coverPhotoUrl: tripPhotos.first.placeholderUrl,
      coverPhotoPath: tripPhotos.first.path,
    );
  }
}
