import 'media_item.dart';

class Trip {
  final String id;
  final String title;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final double centerLatitude;
  final double centerLongitude;
  final List<MediaItem> photos;
  final String? coverPhotoUrl;
  final String? coverPhotoPath;

  const Trip({
    required this.id,
    required this.title,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.photos,
    this.coverPhotoUrl,
    this.coverPhotoPath,
  });

  int get photoCount => photos.length;
  MediaItem? get coverPhoto => photos.isNotEmpty ? photos.first : null;
}
