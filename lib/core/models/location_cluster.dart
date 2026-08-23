import 'media_item.dart';

class LocationCluster {
  final String id;
  final double latitude;
  final double longitude;
  final String title;
  final String? subtitle;
  final List<MediaItem> items;
  final DateTime? startDate;
  final DateTime? endDate;

  const LocationCluster({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.title,
    this.subtitle,
    required this.items,
    this.startDate,
    this.endDate,
  });

  int get count => items.length;
  MediaItem? get coverPhoto => items.isNotEmpty ? items.first : null;
}
