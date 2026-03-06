import 'package:geolocator/geolocator.dart';

/// Fetches the device's current GPS location and returns a Google Maps link.
class LocationService {
  /// Returns a Google Maps link: https://maps.google.com/?q=LAT,LONG
  ///
  /// Handles permission checks and location service availability.
  /// Falls back to a default link if location is unavailable.
  static Future<String> getLiveLocationLink() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _fallbackLink;
      }

      // Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return _fallbackLink;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return _fallbackLink;
      }

      // Fetch current position with a timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    } catch (_) {
      return _fallbackLink;
    }
  }

  // Fallback: Pune, India coordinates
  static const String _fallbackLink =
      'https://maps.google.com/?q=18.516726,73.856255';
}
