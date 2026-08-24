import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/models/media_item.dart';
import '../../core/models/location_cluster.dart';
import '../../core/models/trip.dart';
import '../../core/services/geo_service.dart';
import '../../core/services/canvas_image_loader.dart';

class EarthProvider with ChangeNotifier {
  final GeoService _geoService = GeoService();

  // 3D Globe camera state
  double _yaw = 0.0;     // longitude rotation in radians
  double _pitch = 0.2;   // latitude tilt in radians
  double _zoom = 1.0;    // zoom scale (0.6 to 3.5)

  // Inertia & Auto-rotation
  double _velocityYaw = 0.0;
  double _velocityPitch = 0.0;
  bool _isAutoRotate = true;
  bool _isUserInteracting = false;

  // Render & Fallback
  bool _useFlatMap = false;

  // Geo Data
  List<LocationCluster> _clusters = [];
  List<Trip> _trips = [];
  LocationCluster? _selectedCluster;
  Trip? _selectedTrip;
  final Map<String, ui.Image> _clusterThumbnails = {};

  // Search & Navigation
  String _searchQuery = '';

  // Getters
  double get yaw => _yaw;
  double get pitch => _pitch;
  double get zoom => _zoom;
  bool get isAutoRotate => _isAutoRotate;
  bool get useFlatMap => _useFlatMap;
  List<LocationCluster> get clusters => _clusters;
  List<Trip> get trips => _trips;
  LocationCluster? get selectedCluster => _selectedCluster;
  Trip? get selectedTrip => _selectedTrip;
  String get searchQuery => _searchQuery;
  Map<String, ui.Image> get clusterThumbnails => _clusterThumbnails;

  void refreshGeoData(List<MediaItem> allItems) {
    _clusters = _geoService.clusterPhotos(allItems, clusterRadiusKm: 60.0 / _zoom);
    _trips = _geoService.detectTrips(allItems);

    // Pre-decode cluster thumbnail images for realistic globe photo pins
    for (final cluster in _clusters) {
      if (cluster.coverPhoto != null && !_clusterThumbnails.containsKey(cluster.id)) {
        CanvasImageLoader.loadThumbnail(cluster.coverPhoto!, targetSize: 120).then((img) {
          if (img != null) {
            _clusterThumbnails[cluster.id] = img;
            notifyListeners();
          }
        });
      }
    }
    notifyListeners();
  }

  void toggleAutoRotate() {
    _isAutoRotate = !_isAutoRotate;
    notifyListeners();
  }

  void toggleRenderMode() {
    _useFlatMap = !_useFlatMap;
    notifyListeners();
  }

  void setRenderMode(bool useFlat) {
    _useFlatMap = useFlat;
    notifyListeners();
  }

  // --- Gesture Interactions (Scale & Pan) ---
  void onScaleStart() {
    _isUserInteracting = true;
    _velocityYaw = 0.0;
    _velocityPitch = 0.0;
  }

  void onScaleUpdate(ScaleUpdateDetails details) {
    const double sensitivity = 0.006;
    if (details.focalPointDelta != Offset.zero) {
      _yaw += details.focalPointDelta.dx * sensitivity;
      _pitch -= details.focalPointDelta.dy * sensitivity;
      _pitch = _pitch.clamp(-pi / 2.2, pi / 2.2);

      _velocityYaw = details.focalPointDelta.dx * sensitivity;
      _velocityPitch = -details.focalPointDelta.dy * sensitivity;
    }

    if (details.scale != 1.0) {
      _zoom = (_zoom * details.scale).clamp(0.6, 3.5);
    }
    notifyListeners();
  }

  void onScaleEnd() {
    _isUserInteracting = false;
  }

  void setZoom(double newZoom) {
    _zoom = newZoom.clamp(0.6, 3.5);
    notifyListeners();
  }

  // --- Animation Tick for Inertia and Auto-rotation ---
  void tick(double dt) {
    if (_useFlatMap) return;

    if (!_isUserInteracting) {
      if (_isAutoRotate && _velocityYaw.abs() < 0.001) {
        _yaw += 0.15 * dt; // slow smooth auto-rotation
      } else {
        // Inertia decay
        _yaw += _velocityYaw;
        _pitch += _velocityPitch;
        _pitch = _pitch.clamp(-pi / 2.2, pi / 2.2);

        _velocityYaw *= 0.92;
        _velocityPitch *= 0.92;
      }
      notifyListeners();
    }
  }

  // --- Cluster & Trip Selection ---
  void selectCluster(LocationCluster cluster) {
    _selectedCluster = cluster;
    _selectedTrip = null;
    notifyListeners();
  }

  void closeClusterSheet() {
    _selectedCluster = null;
    notifyListeners();
  }

  void selectTrip(Trip trip) {
    _selectedTrip = trip;
    _selectedCluster = null;
    flyToLocation(trip.centerLatitude, trip.centerLongitude);
    notifyListeners();
  }

  void closeTripCard() {
    _selectedTrip = null;
    notifyListeners();
  }

  // --- Fly-To Coordinates ---
  void flyToLocation(double lat, double lng) {
    // Target yaw & pitch corresponding to lat/lng
    final targetPitch = lat * pi / 180.0;
    final targetYaw = -lng * pi / 180.0 - pi / 2.0;

    _pitch = targetPitch.clamp(-pi / 2.2, pi / 2.2);
    _yaw = targetYaw;
    _zoom = max(_zoom, 1.6);
    _velocityYaw = 0;
    _velocityPitch = 0;
    notifyListeners();
  }

  void flyToNearestCluster() {
    if (_clusters.isNotEmpty) {
      final cluster = _clusters.first;
      selectCluster(cluster);
      flyToLocation(cluster.latitude, cluster.longitude);
    }
  }

  void searchPlace(String query) {
    _searchQuery = query;
    if (query.isEmpty) return;

    final lower = query.toLowerCase();
    // Search in clusters
    for (final cluster in _clusters) {
      if (cluster.title.toLowerCase().contains(lower)) {
        selectCluster(cluster);
        flyToLocation(cluster.latitude, cluster.longitude);
        return;
      }
    }

    // Search in trips
    for (final trip in _trips) {
      if (trip.destination.toLowerCase().contains(lower) || trip.title.toLowerCase().contains(lower)) {
        selectTrip(trip);
        return;
      }
    }
  }
}
