import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/providers/dashboard_provider.dart';

final workerProposalsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final worker = await ref.watch(currentWorkerProvider.future);
  if (worker == null) return [];

  final service = ref.watch(dashboardServiceProvider);
  return await service.getProposals(worker.id);
});
