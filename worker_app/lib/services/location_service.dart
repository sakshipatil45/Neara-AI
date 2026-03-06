import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/providers/dashboard_provider.dart';
import '../providers/auth_provider.dart';

final locationServiceProvider = Provider((ref) => LocationService(ref));

class LocationService {
  final Ref _ref;
  Timer? _timer;

  LocationService(this._ref);

  Future<void> startTracking() async {
    _timer?.cancel();

    // Check permissions
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Start periodic updates (every 30 seconds as per requirement #3)
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      await _updateLocation();
    });

    // Initial update
    await _updateLocation();
  }

  void stopTracking() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _updateLocation() async {
    try {
      final userId = await _ref.read(authServiceProvider).getLoggedUserId();
      if (userId == null) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final dashboardService = _ref.read(dashboardServiceProvider);
      await dashboardService.updateWorkerLocation(
        userId,
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      print('DEBUG: Location update failed: $e');
    }
  }
}
