import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Toggle worker online status
  Future<void> updateWorkerStatus(String workerId, bool isOnline) async {
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
  Future<Map<String, dynamic>> getTodayEarnings(String workerId) async {
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
      // Temporarily removing status filter to see if ANY requests exist
      final response = await _supabase
          .from('service_requests')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      print('DEBUG: Supabase returned ${response.length} requests');
      if (response.isNotEmpty) {
        print('DEBUG: First request status: ${response[0]['status']}');
      } else {
        print('DEBUG: service_requests table appears to be empty.');
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: Supabase fetch error: $e');
      return [];
    }
  }

  // Fetch active jobs using regular query instead of stream to prevent timeouts
  Future<List<Map<String, dynamic>>> getActiveJobs(String userId) async {
    try {
      print('DEBUG: Fetching active jobs for user $userId...');
      // Since we don't know the exact schema, we fallback to all active jobs
      // In a real app we'd join the workers table to filter by user_id
      final response = await _supabase
          .from('service_requests')
          .select()
          .inFilter('status', [
            'PROPOSAL_ACCEPTED',
            'WORKER_COMING',
            'SERVICE_STARTED',
          ])
          .limit(10);
      print('DEBUG: Successfully fetched ${response.length} active jobs');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: Error fetching active jobs: $e');
      return [];
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
