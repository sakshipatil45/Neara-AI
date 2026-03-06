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

// Incoming requests – live via Supabase Realtime
class IncomingRequestsNotifier
    extends Notifier<AsyncValue<List<Map<String, dynamic>>>> {
  RealtimeChannel? _channel;

  @override
  AsyncValue<List<Map<String, dynamic>>> build() {
    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });
    _fetchAndSubscribe();
    return const AsyncValue.loading();
  }

  Future<void> _fetchAndSubscribe() async {
    final service = ref.read(dashboardServiceProvider);
    try {
      final data = await service.getIncomingRequests();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }

    // Subscribe to new service_requests inserts
    _channel = Supabase.instance.client
        .channel('incoming_service_requests_ch')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'service_requests',
          callback: (payload) {
            final newReq = Map<String, dynamic>.from(payload.newRecord);
            final current = state.valueOrNull ?? [];
            state = AsyncValue.data([newReq, ...current]);
            ref.read(newRequestAlertProvider.notifier).trigger(newReq);
          },
        )
        .subscribe();
  }

  /// Re-fetch without recreating the channel subscription.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final service = ref.read(dashboardServiceProvider);
    try {
      final data = await service.getIncomingRequests();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final incomingRequestsProvider =
    NotifierProvider<
      IncomingRequestsNotifier,
      AsyncValue<List<Map<String, dynamic>>>
    >(IncomingRequestsNotifier.new);

// ─── New-Request Alert ────────────────────────────────────────────────────────
// Holds the latest incoming request that just arrived via realtime.
// Consumers call ref.listen(...) and show a SnackBar / banner, then dismiss().
class NewRequestAlertNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;

  void trigger(Map<String, dynamic> request) => state = request;
  void dismiss() => state = null;
}

final newRequestAlertProvider =
    NotifierProvider<NewRequestAlertNotifier, Map<String, dynamic>?>(
      NewRequestAlertNotifier.new,
    );

// Active jobs
final activeJobsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final worker = await ref.watch(currentWorkerProvider.future);
  if (worker == null) return [];

  final service = ref.watch(dashboardServiceProvider);
  return service.getActiveJobs(worker.id);
});

// Full Earnings Stats Provider
final earningsStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final worker = await ref.watch(currentWorkerProvider.future);
  if (worker == null)
    return {'today': 0.0, 'week': 0.0, 'total': 0.0, 'history': []};

  final service = ref.watch(dashboardServiceProvider);
  return await service.getEarningsStats(worker.id);
});
