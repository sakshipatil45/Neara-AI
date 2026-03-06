import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/worker_model.dart';
import '../models/booking_model.dart';
import '../models/proposal_model.dart';

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
        .select(
          '*, workers!service_requests_worker_id_fkey(*, users!workers_user_id_fkey(name, profile_image))',
        )
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
        .select(
          '*, workers!service_requests_worker_id_fkey(*, users!workers_user_id_fkey(name, profile_image))',
        )
        .eq('id', requestId)
        .single();

    return BookingRequest.fromJson(data as Map<String, dynamic>);
  }

  // ── Fetch proposals for a request ──
  Future<List<Proposal>> fetchProposals(int requestId) async {
    final data = await _client
        .from('proposals')
        .select(
          '*, workers!proposals_worker_id_fkey(*, users!workers_user_id_fkey(name, profile_image))',
        )
        .eq('request_id', requestId)
        .order('created_at', ascending: false);

    return (data as List<dynamic>)
        .map((row) => Proposal.fromJson(row as Map<String, dynamic>))
        .toList();
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
}
