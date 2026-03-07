import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../main.dart'; // To access scaffoldMessengerKey

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

class NotificationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _serviceRequestsChannel;

  NotificationService();

  void startListening(String workerId) {
    if (_serviceRequestsChannel != null) return;

    print(
      'DEBUG: [NotificationService] Starting realtime listeners for worker $workerId',
    );

    _serviceRequestsChannel = _supabase
        .channel('public:service_requests_notifications_$workerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_requests',
          callback: (payload) {
            _handleServiceRequestChange(payload, workerId);
          },
        )
        .subscribe();
  }

  void _handleServiceRequestChange(
    PostgresChangePayload payload,
    String workerId,
  ) {
    final eventType = payload.eventType;
    final newRecord = payload.newRecord;

    if (eventType == PostgresChangeEvent.insert) {
      final status = newRecord['status']?.toString().toUpperCase();
      // Only notify if it's a new pending request (broadcast to all)
      if (status == 'PENDING' || status == 'CREATED') {
        _showNotification(
          title: 'New Service Request',
          message: 'A new user request was just posted nearby.',
          icon: Icons.notifications_active_rounded,
          color: Colors.blue,
        );
      }
    } else if (eventType == PostgresChangeEvent.update) {
      final status = newRecord['status']?.toString().toUpperCase();
      final recordWorkerId = newRecord['worker_id']?.toString();

      // Only notify if this request is assigned to this exact worker
      if (recordWorkerId == workerId) {
        if (status == 'PROPOSAL_ACCEPTED') {
          _showNotification(
            title: 'Proposal Accepted!',
            message:
                'The customer accepted your proposal. Please proceed to payment.',
            icon: Icons.check_circle_rounded,
            color: Colors.green,
          );
        } else if (status == 'WORKER_COMING' || status == 'ADVANCE_PAID') {
          _showNotification(
            title: 'Advance Payment Received',
            message:
                'The customer paid the advance. Please head to the location.',
            icon: Icons.payments_rounded,
            color: Colors.teal,
          );
        }
      }
    }
  }

  void _showNotification({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    if (scaffoldMessengerKey.currentState == null) return;

    scaffoldMessengerKey.currentState!.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 20),
        padding: const EdgeInsets.all(16),
        backgroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void dispose() {
    print('DEBUG: [NotificationService] Disposing realtime listeners');
    _serviceRequestsChannel?.unsubscribe();
    _serviceRequestsChannel = null;
  }
}
