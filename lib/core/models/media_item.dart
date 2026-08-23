import 'dart:typed_data';

class ExifData {
  final double? latitude;
  final double? longitude;
  final String? locationName;
  final String? cameraMake;
  final String? cameraModel;
  final String? lens;
  final String? focalLength;
  final String? aperture;
  final String? iso;
  final String? shutterSpeed;
  final int? width;
  final int? height;
  final int? fileSize;

  const ExifData({
    this.latitude,
    this.longitude,
    this.locationName,
    this.cameraMake,
    this.cameraModel,
    this.lens,
    this.focalLength,
    this.aperture,
    this.iso,
    this.shutterSpeed,
    this.width,
    this.height,
    this.fileSize,
  });

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'cameraMake': cameraMake,
      'cameraModel': cameraModel,
      'lens': lens,
      'focalLength': focalLength,
      'aperture': aperture,
      'iso': iso,
      'shutterSpeed': shutterSpeed,
      'width': width,
      'height': height,
      'fileSize': fileSize,
    };
  }

  factory ExifData.fromMap(Map<String, dynamic> map) {
    return ExifData(
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      locationName: map['locationName'] as String?,
      cameraMake: map['cameraMake'] as String?,
      cameraModel: map['cameraModel'] as String?,
      lens: map['lens'] as String?,
      focalLength: map['focalLength'] as String?,
      aperture: map['aperture'] as String?,
      iso: map['iso'] as String?,
      shutterSpeed: map['shutterSpeed'] as String?,
      width: map['width'] as int?,
      height: map['height'] as int?,
      fileSize: map['fileSize'] as int?,
    );
  }
}

class MediaItem {
  final String id;
  final String title;
  final String? path;
  final String? uri;
  final DateTime createDate;
  final DateTime modifiedDate;
  final int duration; // for video in seconds, 0 for photos
  final bool isVideo;
  final bool isFavorite;
  final bool isTrash;
  final DateTime? trashDate;
  final List<String> tags;
  final List<String> people;
  final String albumId;
  final String albumName;
  final ExifData exif;
  final Uint8List? thumbnailData; // In-memory cache or mock image bytes
  final String? placeholderUrl; // Sample image URL for mock display

  MediaItem({
    required this.id,
    required this.title,
    this.path,
    this.uri,
    required this.createDate,
    required this.modifiedDate,
    this.duration = 0,
    this.isVideo = false,
    this.isFavorite = false,
    this.isTrash = false,
    this.trashDate,
    this.tags = const [],
    this.people = const [],
    required this.albumId,
    required this.albumName,
    this.exif = const ExifData(),
    this.thumbnailData,
    this.placeholderUrl,
  });

  bool get hasLocation => exif.hasLocation;

  int get daysUntilPermanentDelete {
    if (!isTrash || trashDate == null) return 30;
    final diff = 30 - DateTime.now().difference(trashDate!).inDays;
    return diff < 0 ? 0 : diff;
  }

  MediaItem copyWith({
    String? id,
    String? title,
    String? path,
    String? uri,
    DateTime? createDate,
    DateTime? modifiedDate,
    int? duration,
    bool? isVideo,
    bool? isFavorite,
    bool? isTrash,
    DateTime? trashDate,
    List<String>? tags,
    List<String>? people,
    String? albumId,
    String? albumName,
    ExifData? exif,
    Uint8List? thumbnailData,
    String? placeholderUrl,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      uri: uri ?? this.uri,
      createDate: createDate ?? this.createDate,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      duration: duration ?? this.duration,
      isVideo: isVideo ?? this.isVideo,
      isFavorite: isFavorite ?? this.isFavorite,
      isTrash: isTrash ?? this.isTrash,
      trashDate: trashDate ?? this.trashDate,
      tags: tags ?? this.tags,
      people: people ?? this.people,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      exif: exif ?? this.exif,
      thumbnailData: thumbnailData ?? this.thumbnailData,
      placeholderUrl: placeholderUrl ?? this.placeholderUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'path': path,
      'uri': uri,
      'createDate': createDate.toIso8601String(),
      'modifiedDate': modifiedDate.toIso8601String(),
      'duration': duration,
      'isVideo': isVideo ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'isTrash': isTrash ? 1 : 0,
      'trashDate': trashDate?.toIso8601String(),
      'tags': tags.join(','),
      'people': people.join(','),
      'albumId': albumId,
      'albumName': albumName,
      'placeholderUrl': placeholderUrl,
      ...exif.toMap(),
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map, {Uint8List? thumbnailData}) {
    return MediaItem(
      id: map['id'] as String,
      title: map['title'] as String,
      path: map['path'] as String?,
      uri: map['uri'] as String?,
      createDate: DateTime.parse(map['createDate'] as String),
      modifiedDate: DateTime.parse(map['modifiedDate'] as String),
      duration: map['duration'] as int? ?? 0,
      isVideo: (map['isVideo'] as int? ?? 0) == 1,
      isFavorite: (map['isFavorite'] as int? ?? 0) == 1,
      isTrash: (map['isTrash'] as int? ?? 0) == 1,
      trashDate: map['trashDate'] != null ? DateTime.parse(map['trashDate'] as String) : null,
      tags: (map['tags'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      people: (map['people'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      albumId: map['albumId'] as String? ?? 'default',
      albumName: map['albumName'] as String? ?? 'All Photos',
      placeholderUrl: map['placeholderUrl'] as String?,
      exif: ExifData.fromMap(map),
      thumbnailData: thumbnailData,
    );
  }
}
