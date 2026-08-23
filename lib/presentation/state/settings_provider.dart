import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  int _gridColumns = 3;
  ThemeMode _themeMode = ThemeMode.dark;
  String _globeQuality = 'High';
  bool _stripExifLocationOnExport = false;
  final Set<String> _hiddenAlbums = {};

  int get gridColumns => _gridColumns;
  ThemeMode get themeMode => _themeMode;
  String get globeQuality => _globeQuality;
  bool get stripExifLocationOnExport => _stripExifLocationOnExport;
  Set<String> get hiddenAlbums => _hiddenAlbums;

  void setGridColumns(int cols) {
    if (cols >= 2 && cols <= 5) {
      _gridColumns = cols;
      notifyListeners();
    }
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setGlobeQuality(String quality) {
    _globeQuality = quality;
    notifyListeners();
  }

  void toggleStripExif(bool value) {
    _stripExifLocationOnExport = value;
    notifyListeners();
  }

  void toggleAlbumHidden(String albumId) {
    if (_hiddenAlbums.contains(albumId)) {
      _hiddenAlbums.remove(albumId);
    } else {
      _hiddenAlbums.add(albumId);
    }
    notifyListeners();
  }
}
