import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/worker_model.dart';
import '../models/booking_model.dart';
import '../services/worker_repository.dart';

// ── Repository provider ──
final workerRepositoryProvider = Provider<WorkerRepository>(
  (_) => WorkerRepository(),
);

// ─────────────── Workers State & Notifier ───────────────
class WorkersState {
  final List<Worker> workers;
  final bool isLoading;
  final String? error;
  final String selectedCategory;

  const WorkersState({
    this.workers = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'All',
  });

  WorkersState copyWith({
    List<Worker>? workers,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) => WorkersState(
    workers: workers ?? this.workers,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    selectedCategory: selectedCategory ?? this.selectedCategory,
  );
}

class WorkersViewModel extends Notifier<WorkersState> {
  @override
  WorkersState build() {
    // Auto-load workers when provider is first created
    Future.microtask(() => loadWorkers());
    return const WorkersState();
  }

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  Future<void> loadWorkers({String? category}) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedCategory: category ?? state.selectedCategory,
    );
    try {
      final workers = await _repo.fetchWorkers(
        category: category ?? state.selectedCategory,
      );
      state = state.copyWith(workers: workers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load workers. Check your connection.',
      );
    }
  }

  void filterByCategory(String category) {
    loadWorkers(category: category);
  }
}

final workersViewModelProvider =
    NotifierProvider<WorkersViewModel, WorkersState>(WorkersViewModel.new);

// ─────────────── Booking State & Notifier ───────────────
enum BookingStatus { idle, loading, success, error }

class BookingState {
  final BookingStatus status;
  final BookingRequest? lastBooking;
  final String? error;

  const BookingState({
    this.status = BookingStatus.idle,
    this.lastBooking,
    this.error,
  });

  BookingState copyWith({
    BookingStatus? status,
    BookingRequest? lastBooking,
    String? error,
  }) => BookingState(
    status: status ?? this.status,
    lastBooking: lastBooking ?? this.lastBooking,
    error: error,
  );
}

class BookingViewModel extends Notifier<BookingState> {
  @override
  BookingState build() => const BookingState();

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  Future<bool> sendBooking({
    required int workerId,
    required String serviceCategory,
    required String issueSummary,
    required String urgency,
    String? customerId,
  }) async {
    state = state.copyWith(status: BookingStatus.loading, error: null);
    try {
      // 1. Try to get current user id from Supabase Auth
      // 2. If null, use the valid dummy UUID for demo purposes
      final finalCustomerId =
          customerId ??
          Supabase.instance.client.auth.currentUser?.id ??
          'fc91af88-9664-4953-a342-01f50a9ea2c6';

      final booking = await _repo.sendBookingRequest(
        BookingRequest(
          customerId: finalCustomerId,
          workerId: workerId,
          serviceCategory: serviceCategory,
          issueSummary: issueSummary,
          urgency: urgency,
          status: 'CREATED',
        ),
      );
      state = state.copyWith(
        status: BookingStatus.success,
        lastBooking: booking,
      );
      return true;
    } catch (e) {
      print('❌ Booking Error: $e');
      state = state.copyWith(
        status: BookingStatus.error,
        error: 'Booking failed: ${e.toString()}',
      );
      return false;
    }
  }

  void reset() => state = const BookingState();
}

final bookingViewModelProvider =
    NotifierProvider<BookingViewModel, BookingState>(BookingViewModel.new);
