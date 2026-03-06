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

    final response = await Supabase.instance.client
        .from('workers')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) {
      return WorkerModel.fromJson(response);
    }
    return null;
  } catch (e) {
    return null;
  }
});

// Earnings Provider
final dashboardStatsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return {'earnings': 0.0, 'jobs': 0};

  final service = ref.watch(dashboardServiceProvider);
  return await service.getTodayEarnings(user.id);
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
  final user = await ref.watch(currentUserProvider.future);
  final service = ref.watch(dashboardServiceProvider);
  return service.getActiveJobs(user?.id ?? '');
});
