import 'package:flutter/foundation.dart';
import '../../core/models/media_item.dart';
import '../../core/models/album.dart';
import '../../core/services/media_service.dart';
import '../../core/database/app_database.dart';

class GalleryProvider with ChangeNotifier {
  final MediaService _mediaService = MediaService();
  final AppDatabase _db = AppDatabase.instance;

  List<MediaItem> _allItems = [];
  List<Album> _albums = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Selection mode for batch operations
  bool _isSelectionMode = false;
  final Set<String> _selectedItemIds = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<MediaItem> get allItems => _allItems.where((i) => !i.isTrash).toList();
  List<MediaItem> get favorites => _allItems.where((i) => !i.isTrash && i.isFavorite).toList();
  List<MediaItem> get trash => _allItems.where((i) => i.isTrash).toList();
  List<Album> get albums => _albums;
  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedItemIds => _selectedItemIds;
  int get selectedCount => _selectedItemIds.length;

  GalleryProvider() {
    loadGallery();
  }

  Future<void> loadGallery() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allItems = await _mediaService.loadMediaItems();
      _albums = await _mediaService.loadAlbums(_allItems);
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  // --- Selection Mode ---
  void enterSelectionMode(String initialItemId) {
    _isSelectionMode = true;
    _selectedItemIds.clear();
    _selectedItemIds.add(initialItemId);
    notifyListeners();
  }

  void exitSelectionMode() {
    _isSelectionMode = false;
    _selectedItemIds.clear();
    notifyListeners();
  }

  void toggleItemSelection(String id) {
    if (_selectedItemIds.contains(id)) {
      _selectedItemIds.remove(id);
      if (_selectedItemIds.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedItemIds.add(id);
    }
    notifyListeners();
  }

  void selectAll() {
    _selectedItemIds.clear();
    _selectedItemIds.addAll(allItems.map((i) => i.id));
    notifyListeners();
  }

  // --- Favorites, Trash & Modifiers ---
  Future<void> toggleFavorite(String id) async {
    final index = _allItems.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = _allItems[index];
    final newFav = !item.isFavorite;
    _allItems[index] = item.copyWith(isFavorite: newFav);
    notifyListeners();

    await _db.setFavorite(id, newFav);
  }

  Future<void> moveToTrash(String id) async {
    final index = _allItems.indexWhere((i) => i.id == id);
    if (index == -1) return;

    _allItems[index] = _allItems[index].copyWith(
      isTrash: true,
      trashDate: DateTime.now(),
    );
    notifyListeners();

    await _db.moveToTrash(id);
    _refreshAlbumsCount();
  }

  Future<void> restoreFromTrash(String id) async {
    final index = _allItems.indexWhere((i) => i.id == id);
    if (index == -1) return;

    _allItems[index] = _allItems[index].copyWith(
      isTrash: false,
      trashDate: null,
    );
    notifyListeners();

    await _db.restoreFromTrash(id);
    _refreshAlbumsCount();
  }

  Future<void> permanentlyDelete(String id) async {
    _allItems.removeWhere((i) => i.id == id);
    notifyListeners();

    await _db.permanentlyDelete(id);
    _refreshAlbumsCount();
  }

  Future<void> batchDeleteSelected() async {
    for (final id in _selectedItemIds) {
      await moveToTrash(id);
    }
    exitSelectionMode();
  }

  Future<void> batchFavoriteSelected() async {
    for (final id in _selectedItemIds) {
      final index = _allItems.indexWhere((i) => i.id == id);
      if (index != -1 && !_allItems[index].isFavorite) {
        await toggleFavorite(id);
      }
    }
    exitSelectionMode();
  }

  Future<void> addTagToItem(String id, String tag) async {
    final index = _allItems.indexWhere((i) => i.id == id);
    if (index == -1) return;

    final item = _allItems[index];
    if (!item.tags.contains(tag)) {
      final newTags = [...item.tags, tag];
      _allItems[index] = item.copyWith(tags: newTags);
      notifyListeners();
      await _db.updateTags(id, newTags);
    }
  }

  Future<void> createCustomAlbum(String name, {List<String>? initialMediaIds}) async {
    final newAlbum = Album(
      id: 'album_custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: AlbumType.userCreated,
      count: initialMediaIds?.length ?? 0,
      coverPhotoUrl: initialMediaIds != null && initialMediaIds.isNotEmpty
          ? _allItems.firstWhere((i) => i.id == initialMediaIds.first).placeholderUrl
          : null,
      lastModified: DateTime.now(),
      isSystem: false,
    );

    _albums.add(newAlbum);
    notifyListeners();

    await _db.insertCustomAlbum(newAlbum);
    if (initialMediaIds != null) {
      for (final mediaId in initialMediaIds) {
        await _db.addMediaToAlbum(newAlbum.id, mediaId);
      }
    }
  }

  void _refreshAlbumsCount() {
    final active = allItems;
    for (int i = 0; i < _albums.length; i++) {
      final a = _albums[i];
      final count = active.where((item) => item.albumId == a.id).length;
      _albums[i] = a.copyWith(count: count);
    }
    notifyListeners();
  }
}
