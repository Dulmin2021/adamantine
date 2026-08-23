enum AlbumType {
  camera,
  screenshots,
  downloads,
  whatsApp,
  userCreated,
  other,
}

class Album {
  final String id;
  final String name;
  final AlbumType type;
  final int count;
  final String? coverPhotoPath;
  final String? coverPhotoUrl;
  final DateTime? lastModified;
  final bool isSystem;

  const Album({
    required this.id,
    required this.name,
    required this.type,
    this.count = 0,
    this.coverPhotoPath,
    this.coverPhotoUrl,
    this.lastModified,
    this.isSystem = false,
  });

  Album copyWith({
    String? id,
    String? name,
    AlbumType? type,
    int? count,
    String? coverPhotoPath,
    String? coverPhotoUrl,
    DateTime? lastModified,
    bool? isSystem,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      count: count ?? this.count,
      coverPhotoPath: coverPhotoPath ?? this.coverPhotoPath,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      lastModified: lastModified ?? this.lastModified,
      isSystem: isSystem ?? this.isSystem,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'count': count,
      'coverPhotoPath': coverPhotoPath,
      'coverPhotoUrl': coverPhotoUrl,
      'lastModified': lastModified?.toIso8601String(),
      'isSystem': isSystem ? 1 : 0,
    };
  }

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AlbumType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AlbumType.userCreated,
      ),
      count: map['count'] as int? ?? 0,
      coverPhotoPath: map['coverPhotoPath'] as String?,
      coverPhotoUrl: map['coverPhotoUrl'] as String?,
      lastModified: map['lastModified'] != null
          ? DateTime.parse(map['lastModified'] as String)
          : null,
      isSystem: (map['isSystem'] as int? ?? 0) == 1,
    );
  }
}
