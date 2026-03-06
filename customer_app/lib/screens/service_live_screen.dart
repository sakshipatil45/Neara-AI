import 'package:flutter/material.dart';
import 'booking_details_screen.dart';

/// Redirect shim — ServiceLiveScreen is merged into BookingDetailsScreen.
class ServiceLiveScreen extends StatelessWidget {
  final int requestId;
  const ServiceLiveScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailsScreen(requestId: requestId),
          ),
        );
      }
    });
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
