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
  StreamSubscription<List<Map<String, dynamic>>>? _requestsStream;

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

    // Subscribe to service_requests status changes so the booking list
    // updates in real-time whenever a booking's status changes
    // (e.g. PENDING → PROPOSAL_SENT, WORKER_COMING → SERVICE_STARTED).
    const customerId = 'fc91af88-9664-4953-a342-01f50a9ea2c6';
    _requestsStream = Supabase.instance.client
        .from('service_requests')
        .stream(primaryKey: ['id'])
        .eq('customer_id', customerId)
        .listen((_) => loadBookings());

    ref.onDispose(() {
      _requestsStream?.cancel();
      _requestsStream = null;
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

// ─────────────── Proposals Hub (all actionable proposals) ───────────────

class ProposalItem {
  final Proposal proposal;
  final int requestId;
  final String serviceCategory;
  final String issueSummary;
  final String bookingStatus;

  const ProposalItem({
    required this.proposal,
    required this.requestId,
    required this.serviceCategory,
    required this.issueSummary,
    required this.bookingStatus,
  });

  // needs customer response (accept/negotiate/reject)
  bool get needsResponse => proposal.isPending || proposal.isNegotiating;

  // accepted but advance not yet paid
  bool get needsAdvancePay =>
      proposal.isAccepted && (bookingStatus == 'PROPOSAL_ACCEPTED');

  // advance paid, service completed, final balance due
  bool get needsFinalPay =>
      bookingStatus == 'FINAL_PAYMENT_PENDING' ||
      bookingStatus == 'SERVICE_COMPLETED';
}

class ProposalsHubState {
  final List<ProposalItem> items;
  final bool isLoading;
  final String? error;

  const ProposalsHubState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  ProposalsHubState copyWith({
    List<ProposalItem>? items,
    bool? isLoading,
    String? error,
  }) => ProposalsHubState(
    items: items ?? this.items,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  int get pendingCount => items
      .where((i) => i.needsResponse || i.needsAdvancePay || i.needsFinalPay)
      .length;
}

class ProposalsHubNotifier extends Notifier<ProposalsHubState> {
  RealtimeChannel? _channel;

  @override
  ProposalsHubState build() {
    Future.microtask(load);

    _channel = Supabase.instance.client
        .channel('proposals_hub_ch')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'proposals',
          callback: (_) => load(),
        )
        .subscribe();

    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    return const ProposalsHubState();
  }

  WorkerRepository get _repo => ref.read(workerRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      const customerId = 'fc91af88-9664-4953-a342-01f50a9ea2c6';
      final raw = await _repo.fetchCustomerProposals(customerId);
      final items = raw
          .map(
            (r) => ProposalItem(
              proposal: r.proposal,
              requestId: r.requestId,
              serviceCategory: r.serviceCategory,
              issueSummary: r.issueSummary,
              bookingStatus: r.bookingStatus,
            ),
          )
          .toList();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load proposals: ${e.toString()}',
      );
    }
  }

  Future<void> respondToProposal(
    int proposalId,
    int requestId,
    String status,
  ) async {
    try {
      await _repo.respondToProposal(proposalId, requestId, status);
      await load();
      // Also refresh the bookings list so status chip updates
      ref.read(myBookingsViewModelProvider.notifier).loadBookings();
    } catch (e) {
      state = state.copyWith(error: 'Action failed: ${e.toString()}');
    }
  }
}

final proposalsHubProvider =
    NotifierProvider<ProposalsHubNotifier, ProposalsHubState>(
      ProposalsHubNotifier.new,
    );
