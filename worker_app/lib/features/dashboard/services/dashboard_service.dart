import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Toggle worker online status
  Future<void> updateWorkerStatus(dynamic workerId, bool isOnline) async {
    try {
      await _supabase
          .from('workers')
          .update({'is_online': isOnline})
          .eq('user_id', workerId);
    } catch (e) {
      throw Exception('Failed to update status');
    }
  }

  // Get today's earnings and jobs count
  Future<Map<String, dynamic>> getTodayEarnings(dynamic workerId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();

      final response = await _supabase
          .from('payments')
          .select('balance_amount')
          .eq('worker_id', workerId)
          .gte('created_at', startOfDay);

      double totalEarnings = 0;
      int jobsToday = response.length;

      for (var payment in response) {
        totalEarnings += (payment['balance_amount'] as num?)?.toDouble() ?? 0.0;
      }

      return {'earnings': totalEarnings, 'jobs': jobsToday};
    } catch (e) {
      // Graceful fallback for missing payments table or worker_id column
      return {'earnings': 0.0, 'jobs': 0};
    }
  }

  // Fetch incoming requests using regular query instead of stream to prevent timeouts
  Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    try {
      print('DEBUG: Fetching incoming requests from Supabase...');

      // Debug: Log ANY service requests to see their structure/status
      final anyRes = await _supabase
          .from('service_requests')
          .select('status, id')
          .limit(5);
      print('DEBUG: Raw service_requests sample: $anyRes');

      // Try matching both upper and lower case
      final response = await _supabase
          .from('service_requests')
          .select()
          .or('status.eq.MATCHING,status.eq.matching')
          .order('created_at', ascending: false)
          .limit(20);

      print('DEBUG: Found ${response.length} matching requests');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: ERROR in getIncomingRequests: $e');
      return [];
    }
  }

  // Fetch jobs by status (Pending, Active, Completed)
  Future<List<Map<String, dynamic>>> getJobsByStatus(
    dynamic workerId,
    List<String> statuses,
  ) async {
    try {
      print(
        'DEBUG: Fetching jobs for worker $workerId with statuses $statuses',
      );

      final response = await _supabase
          .from('service_requests')
          .select()
          .eq('worker_id', workerId)
          .inFilter('status', statuses)
          .order('created_at', ascending: false);

      print('DEBUG: Found ${response.length} matching jobs');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: ERROR in getJobsByStatus: $e');
      return [];
    }
  }

  // Get full earnings stats (Today, Week, All Time)
  Future<Map<String, dynamic>> getEarningsStats(dynamic workerId) async {
    try {
      final now = DateTime.now();
      final startOfToday = DateTime(
        now.year,
        now.month,
        now.day,
      ).toUtc().toIso8601String();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeekStr = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      ).toUtc().toIso8601String();

      // Fetch all completed jobs for this worker
      final response = await _supabase
          .from('service_requests')
          .select('estimated_payment, created_at')
          .eq('worker_id', workerId)
          .eq('status', 'SERVICE_COMPLETED');

      double today = 0;
      double week = 0;
      double total = 0;

      for (var job in response) {
        final paymentStr = job['estimated_payment']?.toString() ?? '₹0';
        final price =
            double.tryParse(paymentStr.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0.0;
        final createdAt = DateTime.parse(job['created_at']);

        total += price;
        if (createdAt.isAfter(DateTime.parse(startOfToday))) {
          today += price;
        }
        if (createdAt.isAfter(DateTime.parse(startOfWeekStr))) {
          week += price;
        }
      }

      return {
        'today': today,
        'week': week,
        'total': total,
        'history': List<Map<String, dynamic>>.from(response),
      };
    } catch (e) {
      print('DEBUG: Error fetching earnings stats: $e');
      return {'today': 0, 'week': 0, 'total': 0, 'history': []};
    }
  }

  // Accept a service request - Keep this for legacy or direct matching if needed
  Future<void> acceptRequest(dynamic requestId, dynamic workerId) async {
    try {
      print(
        'DEBUG: Attempting to accept request ID: $requestId for worker: $workerId',
      );

      await _supabase
          .from('service_requests')
          .update({'status': 'PROPOSAL_ACCEPTED', 'worker_id': workerId})
          .eq('id', requestId);

      print('DEBUG: Request $requestId successfully accepted.');
    } catch (e) {
      print('DEBUG: Error in acceptRequest: $e');
      throw Exception('Failed to accept request: $e');
    }
  }

  // Send a proposal for a service request
  Future<void> sendProposal({
    required dynamic requestId,
    required dynamic workerId,
    required double serviceCost,
    required double advancePercent,
    required String? arrivalTime,
    required String? notes,
  }) async {
    try {
      print('DEBUG: Sending proposal for request $requestId');

      // 1. Insert proposal
      await _supabase.from('proposals').insert({
        'request_id': requestId,
        'worker_id': workerId,
        'service_cost': serviceCost,
        'advance_percent': advancePercent,
        'notes': notes,
        'status': 'PENDING',
        'estimated_time': arrivalTime, // Expecting format like '10 minutes'
      });

      // 2. Update service request status
      // We also set the worker_id so the customer knows who sent the (primary) proposal
      // In a multi-proposal system, we'd handle this differently
      await _supabase
          .from('service_requests')
          .update({'status': 'PROPOSAL_SENT', 'worker_id': workerId})
          .eq('id', requestId);

      print('DEBUG: Proposal sent successfully');
    } catch (e) {
      print('DEBUG: Error in sendProposal: $e');
      throw Exception('Failed to send proposal: $e');
    }
  }

  // Update status to 'in_progress'
  Future<void> startJob(dynamic requestId) async {
    try {
      await _supabase
          .from('service_requests')
          .update({'status': 'SERVICE_STARTED'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to start job: $e');
    }
  }

  // Update status to 'completed'
  Future<void> completeJob(dynamic requestId) async {
    try {
      await _supabase
          .from('service_requests')
          .update({'status': 'SERVICE_COMPLETED'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to complete job: $e');
    }
  }
}
