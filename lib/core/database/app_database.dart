import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/album.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('adamantine_gallery.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Media metadata override / local persistence table
    await db.execute('''
      CREATE TABLE media_metadata (
        id TEXT PRIMARY KEY,
        title TEXT,
        isFavorite INTEGER DEFAULT 0,
        isTrash INTEGER DEFAULT 0,
        trashDate TEXT,
        tags TEXT,
        people TEXT,
        albumId TEXT,
        customLocation TEXT
      )
    ''');

    // Custom Albums table
    await db.execute('''
      CREATE TABLE custom_albums (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        coverPhotoPath TEXT,
        coverPhotoUrl TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Album to Media mappings
    await db.execute('''
      CREATE TABLE album_media_map (
        albumId TEXT,
        mediaId TEXT,
        PRIMARY KEY (albumId, mediaId)
      )
    ''');

    // Derived graph relations cache
    await db.execute('''
      CREATE TABLE derived_edges (
        id TEXT PRIMARY KEY,
        sourceId TEXT NOT NULL,
        targetId TEXT NOT NULL,
        type TEXT NOT NULL,
        weight REAL DEFAULT 1.0
      )
    ''');
  }

  // --- Favorites & Trash Operations ---
  Future<void> setFavorite(String id, bool isFavorite) async {
    final db = await instance.database;
    await db.rawInsert('''
      INSERT INTO media_metadata (id, isFavorite)
      VALUES (?, ?)
      ON CONFLICT(id) DO UPDATE SET isFavorite = excluded.isFavorite
    ''', [id, isFavorite ? 1 : 0]);
  }

  Future<void> moveToTrash(String id) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT INTO media_metadata (id, isTrash, trashDate)
      VALUES (?, 1, ?)
      ON CONFLICT(id) DO UPDATE SET isTrash = 1, trashDate = excluded.trashDate
    ''', [id, now]);
  }

  Future<void> restoreFromTrash(String id) async {
    final db = await instance.database;
    await db.rawInsert('''
      INSERT INTO media_metadata (id, isTrash, trashDate)
      VALUES (?, 0, NULL)
      ON CONFLICT(id) DO UPDATE SET isTrash = 0, trashDate = NULL
    ''', [id]);
  }

  Future<void> permanentlyDelete(String id) async {
    final db = await instance.database;
    await db.delete('media_metadata', where: 'id = ?', whereArgs: [id]);
    await db.delete('album_media_map', where: 'mediaId = ?', whereArgs: [id]);
  }

  Future<void> updateTags(String id, List<String> tags) async {
    final db = await instance.database;
    final tagsStr = tags.join(',');
    await db.rawInsert('''
      INSERT INTO media_metadata (id, tags)
      VALUES (?, ?)
      ON CONFLICT(id) DO UPDATE SET tags = excluded.tags
    ''', [id, tagsStr]);
  }

  Future<Map<String, dynamic>?> getMetadata(String id) async {
    final db = await instance.database;
    final results = await db.query(
      'media_metadata',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getAllMetadata() async {
    final db = await instance.database;
    return await db.query('media_metadata');
  }

  // --- Custom Album Operations ---
  Future<void> insertCustomAlbum(Album album) async {
    final db = await instance.database;
    await db.insert(
      'custom_albums',
      {
        'id': album.id,
        'name': album.name,
        'type': album.type.name,
        'coverPhotoPath': album.coverPhotoPath,
        'coverPhotoUrl': album.coverPhotoUrl,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Album>> getCustomAlbums() async {
    final db = await instance.database;
    final maps = await db.query('custom_albums');
    return maps.map((m) => Album.fromMap(m)).toList();
  }

  Future<void> addMediaToAlbum(String albumId, String mediaId) async {
    final db = await instance.database;
    await db.insert(
      'album_media_map',
      {'albumId': albumId, 'mediaId': mediaId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<String>> getAlbumMediaIds(String albumId) async {
    final db = await instance.database;
    final maps = await db.query(
      'album_media_map',
      columns: ['mediaId'],
      where: 'albumId = ?',
      whereArgs: [albumId],
    );
    return maps.map((m) => m['mediaId'] as String).toList();
  }
}
