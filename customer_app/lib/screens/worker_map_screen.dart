import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;

import '../models/worker_model.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Full-screen map that shows:
/// • A blue pin for the worker's location
/// • A green dot for the user's current location (if available)
/// • A dashed polyline connecting the two
/// • A distance badge in the top overlay
class WorkerMapScreen extends StatefulWidget {
  final Worker worker;

  const WorkerMapScreen({super.key, required this.worker});

  @override
  State<WorkerMapScreen> createState() => _WorkerMapScreenState();
}

class _WorkerMapScreenState extends State<WorkerMapScreen> {
  Position? _userPos;
  bool _loading = true;
  List<LatLng> _routePoints = [];
  bool _routeLoading = false;
  final MapController _mapCtrl = MapController();

  LatLng get _workerLatLng =>
      LatLng(widget.worker.latitude!, widget.worker.longitude!);

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final pos = await LocationService.instance.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPos = pos;
        _loading = false;
      });
      if (pos != null) _fetchRoute(pos);
    }
  }

  /// Fetches a road-snapped route from OSRM (free, no API key).
  Future<void> _fetchRoute(Position userPos) async {
    setState(() => _routeLoading = true);
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${userPos.longitude},${userPos.latitude};'
        '${widget.worker.longitude},${widget.worker.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final coords = (routes[0]['geometry']['coordinates'] as List<dynamic>)
              .map(
                (c) =>
                    LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
              )
              .toList();
          if (mounted) setState(() => _routePoints = coords);
        }
      }
    } catch (_) {
      // Route unavailable — straight line shown as fallback
    } finally {
      if (mounted) setState(() => _routeLoading = false);
    }
  }

  /// Pan the map so both pins are visible with padding.
  void _fitBounds() {
    if (_userPos == null) return;
    final bounds = LatLngBounds.fromPoints([
      _workerLatLng,
      LatLng(_userPos!.latitude, _userPos!.longitude),
    ]);
    _mapCtrl.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm = LocationService.instance.distanceTo(
      widget.worker.latitude,
      widget.worker.longitude,
    );

    final userLatLng = _userPos != null
        ? LatLng(_userPos!.latitude, _userPos!.longitude)
        : null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.worker.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              widget.worker.category,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          if (!_loading && userLatLng != null)
            IconButton(
              tooltip: 'Fit both pins',
              icon: const Icon(
                Icons.fit_screen_rounded,
                color: AppTheme.textSecondary,
              ),
              onPressed: _fitBounds,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapCtrl,
                  options: MapOptions(
                    initialCenter: _workerLatLng,
                    initialZoom: 14.0,
                    onMapReady: () {
                      if (userLatLng != null) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) => _fitBounds(),
                        );
                      }
                    },
                  ),
                  children: [
                    // OpenStreetMap tile layer (no API key needed)
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.neara.customer_app',
                    ),

                    // Polyline user → worker (road-snapped via OSRM, straight fallback)
                    if (userLatLng != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePoints.isNotEmpty
                                ? _routePoints
                                : [userLatLng, _workerLatLng],
                            strokeWidth: 4.0,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.85),
                          ),
                        ],
                      ),

                    // User pin (green dot)
                    if (userLatLng != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: userLatLng,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2.5,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),

                    // Worker pin (blue)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _workerLatLng,
                          width: 42,
                          height: 52,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    widget.worker.name.isNotEmpty
                                        ? widget.worker.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: const Size(10, 8),
                                painter: _PinTailPainter(AppTheme.primaryBlue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Distance badge (bottom-centre overlay)
                if (distanceKm != null)
                  Positioned(
                    bottom: 24,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSecondary,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppTheme.borderDefault),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.near_me_rounded,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              LocationService.formatDistance(distanceKm),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Legend (top-right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundSecondary.withValues(
                        alpha: 0.95,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderDefault),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LegendItem(
                          color: AppTheme.primaryBlue,
                          label: widget.worker.name,
                        ),
                        if (userLatLng != null) ...[
                          const SizedBox(height: 6),
                          const _LegendItem(
                            color: AppTheme.successGreen,
                            label: 'You',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ──────────────── Helpers ────────────────

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Draws a small downward-pointing triangle to form a map pin tail.
class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}
