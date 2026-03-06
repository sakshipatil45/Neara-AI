import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/auth_provider.dart';
import '../services/dashboard_service.dart';
import '../../../models/worker_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService();
});

// Worker profile stream provider - using basic query to avoid realtime timeout
final currentWorkerProvider = FutureProvider<WorkerModel?>((ref) async {
  try {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) {
      return null;
    }

    print('DEBUG: Fetching worker profile for user ID: ${user.id}');
    final response = await Supabase.instance.client
        .from('workers')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) {
      print('DEBUG: Worker profile found: ${response['id']}');
      return WorkerModel.fromJson(response);
    }
    print('DEBUG: NO WORKER PROFILE FOUND for user ID: ${user.id}');
    return null;
  } catch (e) {
    print('DEBUG: Error fetching worker profile: $e');
    return null;
  }
});

// Health Stats Provider
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final worker = await ref.watch(currentWorkerProvider.future);
  if (worker == null) return {'earnings': 0.0, 'jobs': 0};

  final service = ref.watch(dashboardServiceProvider);
  return await service.getTodayEarnings(worker.id);
});

// Incoming requests
final incomingRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(dashboardServiceProvider);
  return service.getIncomingRequests();
});

// Active jobs
final activeJobsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final worker = await ref.watch(currentWorkerProvider.future);
  if (worker == null) return [];

  final service = ref.watch(dashboardServiceProvider);
  return service.getJobsByStatus(worker.id, [
    'PROPOSAL_ACCEPTED',
    'WORKER_COMING',
    'SERVICE_STARTED',
  ]);
});

// Full Earnings Stats Provider
final earningsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final worker = await ref.watch(currentWorkerProvider.future);
  if (worker == null)
    return {'today': 0.0, 'week': 0.0, 'total': 0.0, 'history': []};

  final service = ref.watch(dashboardServiceProvider);
  return await service.getEarningsStats(worker.id);
});
