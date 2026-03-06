import 'package:geolocator/geolocator.dart';

/// Thin wrapper around [Geolocator] that caches the last known position.
/// Call [getCurrentPosition] once per session; subsequent calls return the
/// cached value unless [forceRefresh] is true.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _cached;

  /// Returns the user's current GPS position, or null if permission is denied
  /// or location services are off.  Never throws — failures return null.
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached;

    try {
      // Check if location services are enabled.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // Check / request permission.
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      _cached = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return _cached;
    } catch (_) {
      return null;
    }
  }

  /// Distance in kilometres between the user's cached position and [lat]/[lng].
  /// Returns null if the user's location is unknown.
  double? distanceTo(double? lat, double? lng) {
    if (_cached == null || lat == null || lng == null) return null;
    final metres = Geolocator.distanceBetween(
      _cached!.latitude,
      _cached!.longitude,
      lat,
      lng,
    );
    return metres / 1000.0;
  }

  /// Formats a distance value for display, e.g. "2.4 km" or "850 m".
  static String formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m away';
    }
    return '${km.toStringAsFixed(1)} km away';
  }
}
