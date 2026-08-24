import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart' hide AlbumType;
import '../models/media_item.dart';
import '../models/album.dart';
import '../database/app_database.dart';

class MediaService {
  final AppDatabase _db = AppDatabase.instance;

  Future<bool> requestPermissions() async {
    try {
      if (kIsWeb || !Platform.isAndroid) return true;
      final PermissionState ps = await PhotoManager.requestPermissionExtend();
      return ps.isAuth || ps.hasAccess;
    } catch (e) {
      debugPrint("Permission request fallback: $e");
      return true;
    }
  }

  Future<List<MediaItem>> loadMediaItems({bool forceMock = false}) async {
    final List<MediaItem> items = [];

    if (!forceMock && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final permitted = await requestPermissions();
        if (permitted) {
          final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
            type: RequestType.image,
            onlyAll: false,
          );

          final metadataOverrides = await _db.getAllMetadata();
          final metaMap = {for (var m in metadataOverrides) m['id'] as String: m};

          for (final pathEntity in paths) {
            final int assetCount = await pathEntity.assetCountAsync;
            if (assetCount == 0) continue;

            final List<AssetEntity> assets = await pathEntity.getAssetListRange(
              start: 0,
              end: min(assetCount, 300),
            );

            for (final asset in assets) {
              final latLng = await asset.latlngAsync();
              final meta = metaMap[asset.id];

              final isFavorite = meta != null && (meta['isFavorite'] == 1);
              final isTrash = meta != null && (meta['isTrash'] == 1);
              final trashDate = meta != null && meta['trashDate'] != null
                  ? DateTime.tryParse(meta['trashDate'] as String)
                  : null;

              final tagsStr = meta?['tags'] as String?;
              final tags = tagsStr?.split(',').where((s) => s.isNotEmpty).toList() ?? [];

              items.add(MediaItem(
                id: asset.id,
                title: asset.title ?? 'IMG_${asset.id.substring(0, min(6, asset.id.length))}.jpg',
                createDate: asset.createDateTime,
                modifiedDate: asset.modifiedDateTime,
                duration: asset.duration,
                isVideo: asset.type == AssetType.video,
                isFavorite: isFavorite,
                isTrash: isTrash,
                trashDate: trashDate,
                tags: tags,
                albumId: pathEntity.id,
                albumName: pathEntity.name,
                assetEntity: asset,
                exif: ExifData(
                  latitude: (latLng != null && latLng.latitude != 0.0) ? latLng.latitude : null,
                  longitude: (latLng != null && latLng.longitude != 0.0) ? latLng.longitude : null,
                  width: asset.width,
                  height: asset.height,
                ),
              ));
            }
          }
        }
      } catch (e) {
        debugPrint("Error loading system media: $e. Falling back to rich mock data.");
      }
    }

    // If no device media was loaded (e.g. running on desktop, emulator, or empty gallery), provide rich mock dataset
    if (items.isEmpty) {
      items.addAll(_generateRichMockMedia());
    }

    // Merge SQLite user-created tags and favorites overrides
    try {
      final allMeta = await _db.getAllMetadata();
      final metaLookup = {for (var m in allMeta) m['id'] as String: m};

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        if (metaLookup.containsKey(item.id)) {
          final m = metaLookup[item.id]!;
          items[i] = item.copyWith(
            isFavorite: m['isFavorite'] == 1,
            isTrash: m['isTrash'] == 1,
            trashDate: m['trashDate'] != null ? DateTime.tryParse(m['trashDate']) : null,
            tags: (m['tags'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? item.tags,
          );
        }
      }
    } catch (_) {}

    return items;
  }

  Future<List<Album>> loadAlbums(List<MediaItem> allItems) async {
    final Map<String, List<MediaItem>> albumMap = {};
    for (final item in allItems) {
      if (item.isTrash) continue;
      albumMap.putIfAbsent(item.albumId, () => []).add(item);
    }

    final List<Album> albums = [];

    albumMap.forEach((albumId, items) {
      final name = items.first.albumName;
      AlbumType type = AlbumType.userCreated;
      final lower = name.toLowerCase();

      if (lower.contains('camera')) {
        type = AlbumType.camera;
      } else if (lower.contains('screenshot')) {
        type = AlbumType.screenshots;
      } else if (lower.contains('download')) {
        type = AlbumType.downloads;
      } else if (lower.contains('whatsapp')) {
        type = AlbumType.whatsApp;
      }

      final firstItem = items.isNotEmpty ? items.first : null;

      albums.add(Album(
        id: albumId,
        name: name,
        type: type,
        count: items.length,
        coverItem: firstItem,
        coverPhotoPath: firstItem?.path,
        coverPhotoUrl: firstItem?.placeholderUrl,
        lastModified: firstItem?.createDate,
        isSystem: type != AlbumType.userCreated,
      ));
    });

    // Load custom SQLite user-created albums
    try {
      final custom = await _db.getCustomAlbums();
      for (final ca in custom) {
        if (!albums.any((a) => a.id == ca.id)) {
          final mediaIds = await _db.getAlbumMediaIds(ca.id);
          final albumPhotos = allItems.where((i) => mediaIds.contains(i.id)).toList();
          albums.add(ca.copyWith(
            count: albumPhotos.length,
            coverPhotoUrl: albumPhotos.isNotEmpty ? albumPhotos.first.placeholderUrl : ca.coverPhotoUrl,
          ));
        }
      }
    } catch (_) {}

    return albums;
  }

  List<MediaItem> _generateRichMockMedia() {
    final List<MediaItem> mockList = [];
    final now = DateTime.now();

    final locations = [
      {'name': 'Kandy, Sri Lanka', 'lat': 7.2906, 'lng': 80.6337, 'tags': ['Travel', 'Temple', 'Nature', 'Asia'], 'album': 'Camera'},
      {'name': 'Tokyo, Japan', 'lat': 35.6762, 'lng': 139.6503, 'tags': ['Travel', 'City', 'Night', 'Neon'], 'album': 'Camera'},
      {'name': 'Paris, France', 'lat': 48.8566, 'lng': 2.3522, 'tags': ['Travel', 'Architecture', 'Europe', 'Art'], 'album': 'Camera'},
      {'name': 'New York, USA', 'lat': 40.7128, 'lng': -74.0060, 'tags': ['City', 'Architecture', 'Street', 'USA'], 'album': 'Downloads'},
      {'name': 'Rome, Italy', 'lat': 41.9028, 'lng': 12.4964, 'tags': ['History', 'Architecture', 'Europe', 'Travel'], 'album': 'Camera'},
      {'name': 'San Francisco, USA', 'lat': 37.7749, 'lng': -122.4194, 'tags': ['City', 'Coast', 'USA'], 'album': 'Screenshots'},
      {'name': 'London, UK', 'lat': 51.5074, 'lng': -0.1278, 'tags': ['City', 'Europe', 'Museum'], 'album': 'Camera'},
      {'name': 'Kyoto, Japan', 'lat': 35.0116, 'lng': 135.7681, 'tags': ['Travel', 'Gardens', 'Asia', 'Nature'], 'album': 'Camera'},
      {'name': 'Sydney, Australia', 'lat': -33.8688, 'lng': 151.2093, 'tags': ['Ocean', 'Harbor', 'Travel'], 'album': 'WhatsApp'},
      {'name': 'Reykjavik, Iceland', 'lat': 64.1466, 'lng': -21.9426, 'tags': ['Aurora', 'Ice', 'Nature', 'Travel'], 'album': 'Camera'},
    ];

    final cameras = [
      {'make': 'Sony', 'model': 'Alpha 7 IV', 'lens': 'FE 24-70mm F2.8 GM II', 'aperture': 'f/2.8', 'iso': '200', 'shutter': '1/500s', 'focal': '35mm'},
      {'make': 'Fujifilm', 'model': 'X-T5', 'lens': 'XF 16-55mm F2.8 R LM WR', 'aperture': 'f/4.0', 'iso': '160', 'shutter': '1/250s', 'focal': '23mm'},
      {'make': 'Google', 'model': 'Pixel 9 Pro', 'lens': 'Main 50MP Wide', 'aperture': 'f/1.68', 'iso': '64', 'shutter': '1/1200s', 'focal': '24mm'},
      {'make': 'Apple', 'model': 'iPhone 16 Pro', 'lens': '48MP Fusion Camera', 'aperture': 'f/1.78', 'iso': '80', 'shutter': '1/800s', 'focal': '24mm'},
    ];

    // Placeholder image URLs with rich photography
    final imageUrls = [
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1477959858617-67f30bc75b82?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1534447677768-be436bb09401?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1488646953014-85cb44e25828?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1518495973542-4542c06a5843?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1433086966358-54859d0ed716?auto=format&fit=crop&w=800&q=80',
    ];

    int idCounter = 100;

    for (int locIdx = 0; locIdx < locations.length; locIdx++) {
      final loc = locations[locIdx];
      final photoCount = 3 + (locIdx % 4);

      for (int i = 0; i < photoCount; i++) {
        idCounter++;
        final daysAgo = locIdx * 5 + i * 2;
        final date = now.subtract(Duration(days: daysAgo, hours: (i * 3) % 24, minutes: (i * 17) % 60));
        final cam = cameras[(idCounter) % cameras.length];
        final imgUrl = imageUrls[(idCounter) % imageUrls.length];

        final isFav = (idCounter % 5 == 0);
        final isTrash = (idCounter == 103); // one sample trash item

        final jitterLat = (loc['lat'] as double) + ((i - 1) * 0.008);
        final jitterLng = (loc['lng'] as double) + ((i - 1) * 0.008);

        final albumName = loc['album'] as String;
        final albumId = 'album_${albumName.toLowerCase()}';

        mockList.add(MediaItem(
          id: 'photo_$idCounter',
          title: 'IMG_${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_$idCounter.jpg',
          createDate: date,
          modifiedDate: date,
          isFavorite: isFav,
          isTrash: isTrash,
          trashDate: isTrash ? now.subtract(const Duration(days: 3)) : null,
          tags: List<String>.from(loc['tags'] as List),
          people: i % 2 == 0 ? ['Alice', 'Elena'] : ['David'],
          albumId: albumId,
          albumName: albumName,
          placeholderUrl: imgUrl,
          exif: ExifData(
            latitude: jitterLat,
            longitude: jitterLng,
            locationName: loc['name'] as String,
            cameraMake: cam['make'],
            cameraModel: cam['model'],
            lens: cam['lens'],
            aperture: cam['aperture'],
            iso: cam['iso'],
            shutterSpeed: cam['shutter'],
            focalLength: cam['focal'],
            width: 4000,
            height: 3000,
            fileSize: 4800000 + (idCounter * 12345) % 1500000,
          ),
        ));
      }
    }

    return mockList;
  }
}
