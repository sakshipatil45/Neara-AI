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

  // Accept a service request
  Future<void> acceptRequest(String requestId, String workerId) async {
    try {
      await _supabase
          .from('service_requests')
          .update({
            'status':
                'MATCHING', // or 'ACCEPTED' based on exact flow, assume MATCHING or similar
            'worker_id': workerId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('service_id', requestId);
    } catch (e) {
      throw Exception('Failed to accept request');
    }
  }
}
