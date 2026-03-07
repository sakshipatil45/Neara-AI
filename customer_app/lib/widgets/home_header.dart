import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String? _locationLabel;
  bool _loadingLocation = true;
  StreamSubscription<String>? _refineSub;

  @override
  void initState() {
    super.initState();
    // Subscribe to GPS refinements so the label updates if IP gave a rough
    // city name and GPS later produces a precise neighbourhood string.
    _refineSub = LocationService.instance.onLabelRefined.listen((refined) {
      if (mounted) setState(() => _locationLabel = refined);
    });
    // Delay until the first frame so the permission dialog has a host Activity
    // to attach to on Android.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchLocation());
  }

  @override
  void dispose() {
    _refineSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    if (!mounted) return;
    setState(() => _loadingLocation = true);
    final label = await LocationService.instance.getLocationLabel();
    if (mounted) {
      setState(() {
        _locationLabel = label;
        _loadingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: 'Your Location' label + address
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Location',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 15,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 3),
                  if (_loadingLocation)
                    Text(
                      'Locating…',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textTertiary,
                      ),
                    )
                  else if (_locationLabel != null)
                    Flexible(
                      child: Text(
                        _locationLabel!,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () async {
                        if (LocationService.instance.permissionDeniedForever) {
                          await Geolocator.openAppSettings();
                        }
                        _fetchLocation();
                      },
                      child: Text(
                        LocationService.instance.permissionDeniedForever
                            ? 'Enable location ›'
                            : 'Tap to allow location',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Right: notification bell only
        SizedBox(
          width: 44,
          height: 44,
          child: Material(
            color: AppTheme.backgroundTertiary,
            shape: const CircleBorder(
              side: BorderSide(color: AppTheme.borderDefault),
            ),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pushNamed(context, '/notifications'),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
