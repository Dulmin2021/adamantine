import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:photo_manager/photo_manager.dart' hide AlbumType;
import '../models/media_item.dart';

class CanvasImageLoader {
  static final Map<String, ui.Image> _cache = {};
  static final Set<String> _loading = {};

  static ui.Image? getCachedImage(String key) => _cache[key];

  /// Loads and decodes a lightweight thumbnail ui.Image for direct Canvas rendering
  static Future<ui.Image?> loadThumbnail(MediaItem item, {int targetSize = 140}) async {
    final key = item.id;
    if (_cache.containsKey(key)) return _cache[key];
    if (_loading.contains(key)) return null;

    _loading.add(key);

    try {
      Uint8List? bytes;

      if (item.assetEntity != null) {
        bytes = await item.assetEntity!.thumbnailDataWithSize(
          ThumbnailSize.square(targetSize),
          format: ThumbnailFormat.jpeg,
          quality: 80,
        );
      } else if (item.path != null && File(item.path!).existsSync()) {
        bytes = await File(item.path!).readAsBytes();
      }

      if (bytes != null && bytes.isNotEmpty) {
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: targetSize,
          targetHeight: targetSize,
        );
        final frame = await codec.getNextFrame();
        _cache[key] = frame.image;
        return frame.image;
      }
    } catch (_) {
      // Ignore decoding errors on individual corrupted files
    } finally {
      _loading.remove(key);
    }

    return null;
  }
}
