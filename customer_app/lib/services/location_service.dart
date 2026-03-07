import 'dart:async';
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

  static const String _fallbackLabel = 'DKTE, Ichalkaranji, Kolhapur';

  /// Returns a human-readable location label (e.g. "Koramangala, Bengaluru").
  /// Uses GPS → Nominatim reverse geocoding, falling back to a hardcoded
  /// location when GPS is unavailable or permission is denied.
  Future<String?> getLocationLabel({bool forceRefresh = false}) async {
    if (_locationLabel != null && !forceRefresh) return _locationLabel;

    // GPS → Nominatim (accurate neighbourhood-level label).
    final gpsLabel = await _refineWithGps();
    if (gpsLabel != null) return gpsLabel;

    // Hardcoded fallback so the header always shows something.
    dev.log('LocationService: using fallback label', name: 'Location');
    _locationLabel = _fallbackLabel;
    _labelController.add(_locationLabel!);
    return _locationLabel;
  }

  // Stream that emits the label whenever the background GPS refinement
  // produces a better result than the initial IP lookup.
  final _labelController = _BroadcastController<String>();
  Stream<String> get onLabelRefined => _labelController.stream;

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
          .timeout(const Duration(seconds: 5));
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
          // Notify the header to update if it previously showed IP / fallback.
          if (_locationLabel != null) _labelController.add(_locationLabel!);
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

// Minimal broadcast stream controller without requiring dart:async StreamController.
class _BroadcastController<T> {
  final _listeners = <void Function(T)>[];

  void add(T value) {
    for (final l in _listeners) {
      l(value);
    }
  }

  Stream<T> get stream => _BroadcastStream<T>(this);
}

class _BroadcastStream<T> extends Stream<T> {
  final _BroadcastController<T> _controller;
  _BroadcastStream(this._controller);

  @override
  StreamSubscription<T> listen(
    void Function(T)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _BroadcastSubscription<T>(_controller, onData ?? (_) {});
  }
}

class _BroadcastSubscription<T> implements StreamSubscription<T> {
  final _BroadcastController<T> _controller;
  void Function(T) _onData;
  bool _paused = false;
  bool _cancelled = false;

  _BroadcastSubscription(this._controller, this._onData) {
    _controller._listeners.add(_dispatch);
  }

  void _dispatch(T value) {
    if (!_cancelled && !_paused) _onData(value);
  }

  @override
  Future<void> cancel() async {
    _cancelled = true;
    _controller._listeners.remove(_dispatch);
  }

  @override
  void onData(void Function(T)? handleData) => _onData = handleData ?? (_) {};
  @override
  void onError(Function? handleError) {}
  @override
  void onDone(void Function()? handleDone) {}
  @override
  void pause([Future<void>? resumeSignal]) {
    _paused = true;
    resumeSignal?.then((_) => _paused = false);
  }

  @override
  void resume() => _paused = false;
  @override
  bool get isPaused => _paused;
  @override
  Future<E> asFuture<E>([E? futureValue]) => Future.value(futureValue as E);
}
