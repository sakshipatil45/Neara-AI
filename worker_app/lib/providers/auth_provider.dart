import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/worker_auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<WorkerAuthService>((ref) {
  return WorkerAuthService();
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getCurrentUserData();
});

final isProfileCompleteProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return false;
  final authService = ref.watch(authServiceProvider);
  return await authService.checkProfileExists(user.id);
});
