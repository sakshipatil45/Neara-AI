import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking_model.dart';
import '../models/proposal_model.dart';
import '../services/worker_repository.dart';
import 'workers_viewmodel.dart';

// ─────────────── My Bookings List Notifier ───────────────
class MyBookingsState {
  final List<BookingRequest> bookings;
  final bool isLoading;
  final String? error;

  const MyBookingsState({
    this.bookings = const [],
    this.isLoading = false,
    this.error,
  });

  MyBookingsState copyWith({
    List<BookingRequest>? bookings,
    bool? isLoading,
    String? error,
  }) => MyBookingsState(
    bookings: bookings ?? this.bookings,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class MyBookingsViewModel extends Notifier<MyBookingsState> {
  RealtimeChannel? _proposalChannel;

  @override
  MyBookingsState build() {
    // Initial fetch
    Future.microtask(() => loadBookings());

    // Subscribe to new proposals so the list updates automatically when a
    // worker sends a proposal on any of the customer's requests.
    _proposalChannel = Supabase.instance.client
        .channel('my_bookings_proposals_ch')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'proposals',
          callback: (_) {
            loadBookings();
            ref.read(newProposalAlertProvider.notifier).trigger();
          },
        )
        .subscribe();

    ref.onDispose(() {
      _proposalChannel?.unsubscribe();
      _proposalChannel = null;
    });

    return const MyBookingsState();
  }

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  Future<void> loadBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Use the demo UUID for now, same as in workers_viewmodel
      const customerId = 'fc91af88-9664-4953-a342-01f50a9ea2c6';
      final bookings = await _repo.fetchMyBookings(customerId);
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load bookings: ${e.toString()}',
      );
    }
  }
}

final myBookingsViewModelProvider =
    NotifierProvider<MyBookingsViewModel, MyBookingsState>(
      MyBookingsViewModel.new,
    );

// ─────────────── Booking Details Notifier (with Real-time) ───────────────
class BookingDetailsState {
  final BookingRequest? booking;
  final List<Proposal> proposals;
  final bool isLoading;
  final String? error;

  const BookingDetailsState({
    this.booking,
    this.proposals = const [],
    this.isLoading = false,
    this.error,
  });

  BookingDetailsState copyWith({
    BookingRequest? booking,
    List<Proposal>? proposals,
    bool? isLoading,
    String? error,
  }) => BookingDetailsState(
    booking: booking ?? this.booking,
    proposals: proposals ?? this.proposals,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class BookingDetailsViewModel extends Notifier<BookingDetailsState> {
  final int requestId;
  BookingDetailsViewModel(this.requestId);

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  BookingDetailsState build() {
    // Initial fetch
    Future.microtask(() => loadDetails(requestId));

    // Setup real-time subscription for this specific request ID
    setupRealtime(requestId);

    // Cancel subscription when provider is disposed
    ref.onDispose(() {
      _subscription?.cancel();
    });

    return const BookingDetailsState();
  }

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  Future<void> loadDetails(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final booking = await _repo.fetchBookingDetails(id);
      final proposals = await _repo.fetchProposals(id);
      state = state.copyWith(
        booking: booking,
        proposals: proposals,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load details: ${e.toString()}',
      );
    }
  }

  void setupRealtime(int id) {
    _subscription = Supabase.instance.client
        .from('service_requests')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .listen((data) {
          if (data.isNotEmpty) {
            // When status changes, reload everything to get joined data too
            loadDetails(id);

            // Also refresh the main list if needed
            ref.read(myBookingsViewModelProvider.notifier).loadBookings();
          }
        });
  }

  Future<void> respondToProposal(int proposalId, String status) async {
    if (state.booking == null) return;
    try {
      await _repo.respondToProposal(proposalId, state.booking!.id!, status);
      // Real-time or manual reload will handle UI update
      if (state.booking != null) {
        loadDetails(state.booking!.id!);
      }
    } catch (e) {
      state = state.copyWith(error: 'Action failed: ${e.toString()}');
    }
  }
}

final bookingDetailsViewModelProvider =
    NotifierProvider.family<BookingDetailsViewModel, BookingDetailsState, int>(
      (requestId) => BookingDetailsViewModel(requestId),
    );

// ─────────────── New-Proposal Alert (customer) ───────────────
// Holds a simple counter; increments each time a proposal arrives via realtime.
// Consumers use ref.listen to show a SnackBar notification.
class NewProposalAlertNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void trigger() => state = state + 1;
}

final newProposalAlertProvider =
    NotifierProvider<NewProposalAlertNotifier, int>(
      NewProposalAlertNotifier.new,
    );
