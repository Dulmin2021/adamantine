import 'package:flutter_test/flutter_test.dart';
import 'package:adamantine/core/models/media_item.dart';
import 'package:adamantine/core/models/album.dart';
import 'package:adamantine/core/models/graph_node.dart';
import 'package:adamantine/core/services/graph_service.dart';
import 'package:adamantine/core/services/geo_service.dart';

void main() {
  group('Adamantine Model & Services Unit Tests', () {
    test('MediaItem serialization & EXIF parsing', () {
      final item = MediaItem(
        id: 'test_1',
        title: 'IMG_2026.jpg',
        createDate: DateTime(2026, 8, 20, 14, 30),
        modifiedDate: DateTime(2026, 8, 20, 14, 30),
        isFavorite: true,
        isTrash: false,
        tags: ['Travel', 'Temple'],
        people: ['Alice'],
        albumId: 'album_camera',
        albumName: 'Camera',
        exif: const ExifData(
          latitude: 7.2906,
          longitude: 80.6337,
          locationName: 'Kandy, Sri Lanka',
          cameraMake: 'Sony',
          cameraModel: 'A7 IV',
        ),
      );

      final map = item.toMap();
      final restored = MediaItem.fromMap(map);

      expect(restored.id, 'test_1');
      expect(restored.isFavorite, true);
      expect(restored.tags, contains('Travel'));
      expect(restored.people, contains('Alice'));
      expect(restored.exif.latitude, 7.2906);
      expect(restored.exif.locationName, 'Kandy, Sri Lanka');
    });

    test('GraphService builds Obsidian-style nodes and cross-links', () {
      final graphService = GraphService();

      final photos = [
        MediaItem(
          id: 'p1',
          title: 'p1.jpg',
          createDate: DateTime(2026, 8, 1),
          modifiedDate: DateTime(2026, 8, 1),
          albumId: 'a1',
          albumName: 'Tokyo Trip',
          tags: ['Neon', 'Japan'],
          exif: const ExifData(latitude: 35.6762, longitude: 139.6503, locationName: 'Tokyo'),
        ),
        MediaItem(
          id: 'p2',
          title: 'p2.jpg',
          createDate: DateTime(2026, 8, 2),
          modifiedDate: DateTime(2026, 8, 2),
          albumId: 'a2',
          albumName: 'Kyoto Trip',
          tags: ['Japan', 'Temple'],
          exif: const ExifData(latitude: 35.0116, longitude: 135.7681, locationName: 'Kyoto'),
        ),
      ];

      final albums = [
        const Album(id: 'a1', name: 'Tokyo Trip', type: AlbumType.camera, count: 1),
        const Album(id: 'a2', name: 'Kyoto Trip', type: AlbumType.camera, count: 1),
      ];

      final graphData = graphService.buildGraph(
        allItems: photos,
        allAlbums: albums,
        activeFilters: {GraphFilter.byTag},
      );

      expect(graphData.nodes.isNotEmpty, true);
      // Verify hubs were created
      final hubNodes = graphData.nodes.where((n) => n.id.startsWith('hub_')).toList();
      expect(hubNodes.length, 2);

      // Verify tag cross-link between photos sharing 'Japan' tag
      final tagEdges = graphData.edges.where((e) => e.type == EdgeType.sharedTag).toList();
      expect(tagEdges.isNotEmpty, true);
    });

    test('GeoService clusters nearby photos and detects trips', () {
      final geoService = GeoService();

      final photos = [
        MediaItem(
          id: 'p1',
          title: 'p1.jpg',
          createDate: DateTime(2026, 3, 10, 10, 0),
          modifiedDate: DateTime(2026, 3, 10, 10, 0),
          albumId: 'a1',
          albumName: 'Camera',
          exif: const ExifData(latitude: 7.2906, longitude: 80.6337, locationName: 'Kandy'),
        ),
        MediaItem(
          id: 'p2',
          title: 'p2.jpg',
          createDate: DateTime(2026, 3, 11, 15, 0),
          modifiedDate: DateTime(2026, 3, 11, 15, 0),
          albumId: 'a1',
          albumName: 'Camera',
          exif: const ExifData(latitude: 7.2910, longitude: 80.6340, locationName: 'Kandy'),
        ),
      ];

      final clusters = geoService.clusterPhotos(photos, clusterRadiusKm: 50.0);
      expect(clusters.length, 1);
      expect(clusters.first.count, 2);

      final trips = geoService.detectTrips(photos);
      expect(trips.length, 1);
      expect(trips.first.destination, 'Kandy');
    });
  });
}
