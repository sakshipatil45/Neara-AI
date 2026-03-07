import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/worker_model.dart';
import '../models/booking_model.dart';
import '../models/proposal_model.dart';
import '../models/payment_model.dart';
import '../models/negotiation_model.dart';
import '../models/review_model.dart';
import '../models/job_model.dart';

class WorkerRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // ── Fetch all workers with joined user info ──
  Future<List<Worker>> fetchWorkers({String? category}) async {
    var query = _client
        .from('workers')
        .select(
          'id, category, experience_years, rating, total_jobs, is_verified, is_online, latitude, longitude, service_radius_km, users!workers_user_id_fkey(name, phone, profile_image)',
        );

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }

    final data = await query.order('rating', ascending: false);

    return (data as List<dynamic>).map((row) {
      final user = row['users'] as Map<String, dynamic>? ?? {};
      return Worker.fromJson({
        ...row as Map<String, dynamic>,
        'name': user['name'],
        'phone': user['phone'],
        'profile_image': user['profile_image'],
      });
    }).toList();
  }

  // ── Send a booking request (saved in service_requests table) ──
  Future<BookingRequest> sendBookingRequest(BookingRequest request) async {
    final response = await _client
        .from('service_requests')
        .insert(request.toJson())
        .select()
        .single();

    return BookingRequest.fromJson(response as Map<String, dynamic>);
  }

  // ── Fetch bookings for a specific customer with worker info ──
  Future<List<BookingRequest>> fetchMyBookings(String customerId) async {
    final data = await _client
        .from('service_requests')
        .select('*, workers(rating, users(name, profile_image))')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => BookingRequest.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ── Fetch a single booking by ID ──
  Future<BookingRequest> fetchBookingDetails(int requestId) async {
    final data = await _client
        .from('service_requests')
        .select('*, workers(rating, users(name, profile_image))')
        .eq('id', requestId)
        .single();

    return BookingRequest.fromJson(data as Map<String, dynamic>);
  }

  // ── Fetch proposals for a request ──
  Future<List<Proposal>> fetchProposals(int requestId) async {
    try {
      final data = await _client
          .from('proposals')
          .select(
            '*, workers(rating, category, users(name, phone, profile_image))',
          )
          .eq('request_id', requestId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((row) => Proposal.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Fallback: fetch without join if the join fails (e.g. RLS on workers)
      final data = await _client
          .from('proposals')
          .select(
            '*, workers(rating, category, users(name, phone, profile_image))',
          )
          .eq('request_id', requestId)
          .order('created_at', ascending: false);

      return (data as List<dynamic>)
          .map((row) => Proposal.fromJson(row as Map<String, dynamic>))
          .toList();
    }
  }

  // ── Accept/Reject a proposal ──
  Future<void> respondToProposal(
    int proposalId,
    int requestId,
    String status,
  ) async {
    // 1. Update proposal status
    await _client
        .from('proposals')
        .update({'status': status})
        .eq('id', proposalId);

    // 2. If accepted, update service request status
    if (status == 'ACCEPTED') {
      await _client
          .from('service_requests')
          .update({'status': 'PROPOSAL_ACCEPTED'})
          .eq('id', requestId);

      // Defer: Reject all other proposals for this request?
      // PRD doesn't explicitly state, but typically desirable.
    }
  }

  // ── Accept a proposal and update request status ──
  Future<void> acceptProposal(int proposalId, int requestId) async {
    // 1. Update proposal status
    await _client
        .from('proposals')
        .update({'status': 'ACCEPTED'})
        .eq('id', proposalId);

    // 2. Update service request status
    await _client
        .from('service_requests')
        .update({'status': 'PROPOSAL_ACCEPTED'})
        .eq('id', requestId);
  }

  // ── Confirm advance payment ──
  Future<void> confirmAdvancePayment(int requestId) async {
    await _client
        .from('service_requests')
        .update({'status': 'ADVANCE_PAID'})
        .eq('id', requestId);
  }

  // ── Final payment release ──
  Future<void> releaseFinalPayment(int requestId) async {
    await _client
        .from('service_requests')
        .update({'status': 'COMPLETED'})
        .eq('id', requestId);
  }

  // ── Update booking status ──
  Future<void> updateBookingStatus(int requestId, String status) async {
    await _client
        .from('service_requests')
        .update({'status': status})
        .eq('id', requestId);
  }

  // ── Send a counter-offer (negotiation) ──
  Future<Negotiation> sendCounterOffer({
    required int proposalId,
    required int requestId,
    required double counterAmount,
    required String message,
  }) async {
    final negotiation = Negotiation(
      proposalId: proposalId,
      requestId: requestId,
      senderRole: 'customer',
      counterAmount: counterAmount,
      message: message,
      status: 'PENDING',
    );

    final response = await _client
        .from('negotiations')
        .insert(negotiation.toJson())
        .select()
        .single();

    // Mark proposal as NEGOTIATING
    await _client
        .from('proposals')
        .update({'status': 'NEGOTIATING'})
        .eq('id', proposalId);

    // Mark service request as NEGOTIATING
    await _client
        .from('service_requests')
        .update({'status': 'NEGOTIATING'})
        .eq('id', requestId);

    return Negotiation.fromJson(response as Map<String, dynamic>);
  }

  // ── Fetch negotiation history for a proposal ──
  Future<List<Negotiation>> fetchNegotiations(int proposalId) async {
    final data = await _client
        .from('negotiations')
        .select()
        .eq('proposal_id', proposalId)
        .order('created_at', ascending: true);

    return (data as List<dynamic>)
        .map((row) => Negotiation.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ── Create escrow payment record (advance payment) ──
  Future<EscrowPayment> createAdvancePayment({
    required int requestId,
    required double advanceAmount,
    required double balanceAmount,
    int? workerId,
    String? customerId,
  }) async {
    final txnId = 'TXN_ADV_${DateTime.now().millisecondsSinceEpoch}';
    final response = await _client
        .from('payments')
        .insert({
          'request_id': requestId,
          'advance_amount': advanceAmount,
          'balance_amount': balanceAmount,
          'escrow_status': 'HELD',
          'payment_status': 'ADVANCE_PAID',
          'transaction_id': txnId,
        })
        .select()
        .single();

    // Create a jobs record in PENDING state
    try {
      await _client.from('jobs').insert({
        'request_id': requestId,
        if (workerId != null) 'worker_id': workerId,
        if (customerId != null) 'customer_id': customerId,
        'status': 'PENDING',
      });
    } catch (_) {
      // Non-fatal: jobs record creation failure should not block payment
    }

    // Update service request status to WORKER_COMING
    await _client
        .from('service_requests')
        .update({'status': 'WORKER_COMING'})
        .eq('id', requestId);

    return EscrowPayment.fromJson(response as Map<String, dynamic>);
  }

  // ── Fetch escrow payment for a request ──
  Future<EscrowPayment?> fetchPayment(int requestId) async {
    final data = await _client
        .from('payments')
        .select()
        .eq('request_id', requestId)
        .maybeSingle();

    if (data == null) return null;
    return EscrowPayment.fromJson(data as Map<String, dynamic>);
  }

  // ── Fetch all payment history for a customer (for wallet screen) ──
  Future<List<PaymentHistoryEntry>> fetchPaymentHistory(
    String customerId,
  ) async {
    final data = await _client
        .from('service_requests')
        .select('id, service_category, issue_summary, payments(*)')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);

    final entries = <PaymentHistoryEntry>[];
    for (final row in data as List<dynamic>) {
      final paymentsList = row['payments'] as List<dynamic>?;
      if (paymentsList != null && paymentsList.isNotEmpty) {
        for (final p in paymentsList) {
          entries.add(
            PaymentHistoryEntry.fromJson({
              ...(p as Map<String, dynamic>),
              'service_category': row['service_category'],
              'issue_summary': row['issue_summary'],
            }),
          );
        }
      }
    }
    entries.sort(
      (a, b) =>
          (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
    );
    return entries;
  }

  // ── Pay full amount when no advance record exists (direct settlement) ──
  Future<EscrowPayment> payFullAmountOnCompletion({
    required int requestId,
    required double totalAmount,
  }) async {
    final txnId = 'TXN_FULL_${DateTime.now().millisecondsSinceEpoch}';
    final response = await _client
        .from('payments')
        .insert({
          'request_id': requestId,
          'advance_amount': 0,
          'balance_amount': totalAmount,
          'escrow_status': 'RELEASED',
          'payment_status': 'PAID',
          'transaction_id': txnId,
        })
        .select()
        .single();

    await _client
        .from('service_requests')
        .update({'status': 'SERVICE_CLOSED'})
        .eq('id', requestId);

    return EscrowPayment.fromJson(response as Map<String, dynamic>);
  }

  // ── Pay final balance (release escrow) ──
  Future<EscrowPayment> payFinalBalance(int paymentId, int requestId) async {
    final response = await _client
        .from('payments')
        .update({'escrow_status': 'RELEASED'})
        .eq('id', paymentId)
        .select()
        .single();

    // Close the service request
    await _client
        .from('service_requests')
        .update({'status': 'SERVICE_CLOSED'})
        .eq('id', requestId);

    return EscrowPayment.fromJson(response as Map<String, dynamic>);
  }

  // ── Confirm service completion (customer side) ──
  Future<void> confirmServiceCompletion(int requestId) async {
    await _client
        .from('service_requests')
        .update({'status': 'FINAL_PAYMENT_PENDING'})
        .eq('id', requestId);
  }

  // ── Fetch jobs record for a service request ──
  Future<JobRecord?> fetchJobForRequest(int requestId) async {
    final data = await _client
        .from('jobs')
        .select()
        .eq('request_id', requestId)
        .maybeSingle();
    if (data == null) return null;
    return JobRecord.fromJson(data as Map<String, dynamic>);
  }

  // ── Submit review for a worker ──
  Future<ReviewModel> submitReview({
    required int requestId,
    required int workerId,
    required String customerId,
    required int rating,
    String? comment,
  }) async {
    final review = ReviewModel(
      requestId: requestId,
      workerId: workerId,
      customerId: customerId,
      rating: rating,
      comment: comment,
    );

    final response = await _client
        .from('reviews')
        .insert(review.toJson())
        .select()
        .single();

    // Update service request to RATED
    await _client
        .from('service_requests')
        .update({'status': 'RATED'})
        .eq('id', requestId);

    // Update worker's rating average (stored proc or manual average)
    final existingReviews = await _client
        .from('reviews')
        .select('rating')
        .eq('worker_id', workerId);

    final ratings = (existingReviews as List<dynamic>)
        .map((r) => (r['rating'] as num).toDouble())
        .toList();
    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;

    await _client
        .from('workers')
        .update({
          'rating': double.parse(avgRating.toStringAsFixed(1)),
          'total_jobs': ratings.length,
        })
        .eq('id', workerId);

    return ReviewModel.fromJson(response as Map<String, dynamic>);
  }

  // ── Fetch ALL actionable proposals for a customer across all their requests ──
  // Returns proposals in states that still need customer action:
  //   • PENDING / NEGOTIATING / COUNTERED  → respond / pay advance
  //   • ACCEPTED  → pay advance if not yet paid (request still PROPOSAL_ACCEPTED)
  // Also returns proposals where final payment is needed (ADVANCE_PAID requests).
  Future<List<ProposalWithBooking>> fetchCustomerProposals(
    String customerId,
  ) async {
    // 1. Fetch all service requests for this customer that are action-pending
    final srData = await _client
        .from('service_requests')
        .select(
          'id, service_category, issue_summary, urgency, status, created_at',
        )
        .eq('customer_id', customerId)
        .inFilter('status', [
          'PENDING',
          'PROPOSAL_SENT',
          'NEGOTIATING',
          'PROPOSAL_ACCEPTED',
          'ADVANCE_PAID',
          'FINAL_PAYMENT_PENDING',
          'SERVICE_COMPLETED',
        ])
        .order('created_at', ascending: false);

    final requests = (srData as List<dynamic>)
        .map((r) => r as Map<String, dynamic>)
        .toList();

    if (requests.isEmpty) return [];

    final requestIds = requests.map((r) => r['id']).toList();

    // 2. Fetch proposals for those requests
    List<Map<String, dynamic>> proposalRows;
    try {
      final pData = await _client
          .from('proposals')
          .select(
            '*, workers(rating, category, users(name, phone, profile_image))',
          )
          .inFilter('request_id', requestIds)
          .order('created_at', ascending: false);
      proposalRows = (pData as List<dynamic>)
          .map((r) => r as Map<String, dynamic>)
          .toList();
    } catch (_) {
      final pData = await _client
          .from('proposals')
          .select()
          .inFilter('request_id', requestIds)
          .order('created_at', ascending: false);
      proposalRows = (pData as List<dynamic>)
          .map((r) => r as Map<String, dynamic>)
          .toList();
    }

    // Build a lookup map: requestId → booking info
    final requestMap = {for (final r in requests) r['id']: r};

    return proposalRows.map((row) {
      final requestId = row['request_id'] as int;
      final booking = requestMap[requestId] ?? {};
      return ProposalWithBooking(
        proposal: Proposal.fromJson(row),
        requestId: requestId,
        serviceCategory: booking['service_category'] as String? ?? '',
        issueSummary: booking['issue_summary'] as String? ?? '',
        bookingStatus: booking['status'] as String? ?? 'PENDING',
      );
    }).toList();
  }
}

/// Thin container pairing a Proposal with its parent booking info.
class ProposalWithBooking {
  final Proposal proposal;
  final int requestId;
  final String serviceCategory;
  final String issueSummary;
  final String bookingStatus;

  const ProposalWithBooking({
    required this.proposal,
    required this.requestId,
    required this.serviceCategory,
    required this.issueSummary,
    required this.bookingStatus,
  });
}
