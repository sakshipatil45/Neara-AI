import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Thin wrapper around [Geolocator] that caches the last known position.
/// Call [getCurrentPosition] once per session; subsequent calls return the
/// cached value unless [forceRefresh] is true.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _cached;
  String? _locationLabel;
  bool _deniedForever = false;

  /// Whether location permission was permanently denied.
  /// If true, the app must open system settings to let the user grant it.
  bool get permissionDeniedForever => _deniedForever;

  /// Returns a human-readable location label (e.g. "Koramangala, Bengaluru").
  /// First tries IP-based geolocation (fast, no permissions needed), then
  /// refines with GPS + Nominatim reverse geocoding if available.
  Future<String?> getLocationLabel({bool forceRefresh = false}) async {
    if (_locationLabel != null && !forceRefresh) return _locationLabel;

    // Step 1: IP-based location — fast, no permissions, works on emulators.
    final ipLabel = await _ipBasedLocation();
    if (ipLabel != null) {
      dev.log('LocationService: IP label = $ipLabel', name: 'Location');
      _locationLabel = ipLabel;
      // Kick off GPS refinement in the background — updates cache for next call.
      _refineWithGps();
      return _locationLabel;
    }

    // Step 2: GPS fallback if IP lookup failed.
    return _refineWithGps();
  }

  /// Quick city-level location from the device's public IP — no permissions.
  Future<String?> _ipBasedLocation() async {
    try {
      final response = await http
          .get(
            Uri.parse('https://ipapi.co/json/'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final city = data['city'] as String?;
        final region = data['region'] as String?;
        if (city != null && city.isNotEmpty) {
          return region != null && region.isNotEmpty ? '$city, $region' : city;
        }
      }
    } catch (e) {
      dev.log('LocationService: IP lookup error: $e', name: 'Location');
    }
    return null;
  }

  /// Tries to get GPS position and reverse-geocode it, updating [_locationLabel].
  Future<String?> _refineWithGps() async {
    final position = await getCurrentPosition();
    if (position == null) return _locationLabel;

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&zoom=16',
      );
      final response = await http
          .get(uri, headers: const {'Accept-Language': 'en'})
          .timeout(const Duration(seconds: 10));
      dev.log(
        'LocationService: geocode status ${response.statusCode}',
        name: 'Location',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final suburb =
              address['suburb'] as String? ??
              address['neighbourhood'] as String? ??
              address['quarter'] as String? ??
              address['city_district'] as String?;
          final city =
              address['city'] as String? ??
              address['town'] as String? ??
              address['village'] as String?;
          if (suburb != null && city != null) {
            _locationLabel = '$suburb, $city';
          } else if (city != null) {
            _locationLabel = city;
          } else if (suburb != null) {
            _locationLabel = suburb;
          }
        }
      }
    } catch (e) {
      dev.log('LocationService: geocode error: $e', name: 'Location');
    }
    return _locationLabel;
  }

  /// Returns the user's current GPS position, or null if permission is denied
  /// or location services are off.  Never throws — failures return null.
  Future<Position?> getCurrentPosition({bool forceRefresh = false}) async {
    if (_cached != null && !forceRefresh) return _cached;

    try {
      // Check if location services are enabled.
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        dev.log(
          'LocationService: location services disabled',
          name: 'Location',
        );
        return null;
      }

      // Check / request permission.
      var permission = await Geolocator.checkPermission();
      dev.log(
        'LocationService: initial permission = $permission',
        name: 'Location',
      );
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        dev.log(
          'LocationService: after request = $permission',
          name: 'Location',
        );
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) {
        _deniedForever = true;
        dev.log('LocationService: denied forever', name: 'Location');
        return null;
      }
      _deniedForever = false;

      // Fast path: use last known position if available.
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        dev.log(
          'LocationService: using last known ${last.latitude}, ${last.longitude}',
          name: 'Location',
        );
        _cached = last;
        return _cached;
      }

      // Slow path: request a fresh fix with a timeout.
      dev.log('LocationService: requesting fresh position…', name: 'Location');
      _cached = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // network-based, much faster
          timeLimit: Duration(seconds: 15),
        ),
      );
      dev.log(
        'LocationService: got ${_cached!.latitude}, ${_cached!.longitude}',
        name: 'Location',
      );
      return _cached;
    } catch (e) {
      dev.log(
        'LocationService: getCurrentPosition error: $e',
        name: 'Location',
      );
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
