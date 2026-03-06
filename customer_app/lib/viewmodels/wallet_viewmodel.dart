import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../services/auth_service.dart';
import '../services/worker_repository.dart';
import 'workers_viewmodel.dart';

// ─── State ───────────────────────────────────────────────────────────────────

class WalletState {
  final List<PaymentHistoryEntry> history;
  final bool isLoading;
  final String? error;

  const WalletState({
    this.history = const [],
    this.isLoading = false,
    this.error,
  });

  double get totalSpent => history.fold(0.0, (sum, e) => sum + e.totalPaid);

  WalletState copyWith({
    List<PaymentHistoryEntry>? history,
    bool? isLoading,
    String? error,
  }) => WalletState(
    history: history ?? this.history,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class WalletViewModel extends Notifier<WalletState> {
  @override
  WalletState build() {
    Future.microtask(loadHistory);
    return const WalletState(isLoading: true);
  }

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userId =
          await AuthService().getLoggedUserId() ??
          'fc91af88-9664-4953-a342-01f50a9ea2c6';
      final history = await _repo.fetchPaymentHistory(userId);
      state = state.copyWith(history: history, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load payment history: ${e.toString()}',
      );
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final walletViewModelProvider = NotifierProvider<WalletViewModel, WalletState>(
  WalletViewModel.new,
);
