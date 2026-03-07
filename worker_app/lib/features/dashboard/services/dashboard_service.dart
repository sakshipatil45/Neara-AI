import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class DashboardService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Toggle worker online status
  Future<void> updateWorkerStatus(dynamic userId, bool isOnline) async {
    try {
      await _supabase
          .from('workers')
          .update({'is_online': isOnline})
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to update status: $e');
    }
  }

  // Create a new job record
  Future<void> createJob({
    required dynamic requestId,
    required dynamic workerId,
    required dynamic customerId,
  }) async {
    try {
      print('DEBUG: [createJob] Creating job for request $requestId');

      // Check if job already exists
      final existing = await _supabase
          .from('jobs')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();

      if (existing != null) {
        print('DEBUG: [createJob] Job already exists for request $requestId');
        return;
      }

      await _supabase.from('jobs').insert({
        'request_id': requestId,
        'worker_id': workerId,
        'customer_id': customerId,
        'status': 'PENDING',
      });

      print('DEBUG: [createJob] Job created successfully');
    } catch (e) {
      print('DEBUG: [createJob] ERROR: $e');
      throw Exception('Failed to create job record: $e');
    }
  }

  // Update job status in the jobs table
  Future<void> updateJobStatus(dynamic requestId, String status) async {
    try {
      // Update both table for consistency, but target 'jobs' as primary
      await _supabase
          .from('jobs')
          .update({'status': status})
          .eq('request_id', requestId);

      // Keep service_requests status in sync
      await _supabase
          .from('service_requests')
          .update({'status': status})
          .eq('id', requestId);

      // Proactive earning recording for Advance Payment
      if (status.toUpperCase() == 'ADVANCE_PAYMENT_DONE' ||
          status == 'Advance_payment_done') {
        final payment = await _supabase
            .from('payments')
            .select('advance_amount, service_requests(worker_id)')
            .eq('request_id', requestId)
            .maybeSingle();

        if (payment != null) {
          final amt = (payment['advance_amount'] as num?)?.toDouble() ?? 0.0;
          final workerId = payment['service_requests']?['worker_id'];
          if (amt > 0 && workerId != null) {
            await recordEarning(
              requestId: requestId,
              workerId: workerId,
              amount: amt,
              type: 'ADVANCE',
            );
          }
        }
      }

      print(
        'DEBUG: [updateJobStatus] Status updated to $status for request $requestId',
      );
    } catch (e) {
      print('DEBUG: [updateJobStatus] ERROR: $e');
      throw Exception('Failed to update job status: $e');
    }
  }

  // Update worker current location
  Future<void> updateWorkerLocation(
    dynamic userId,
    double lat,
    double lng,
  ) async {
    try {
      await _supabase
          .from('workers')
          .update({'latitude': lat, 'longitude': lng})
          .eq('user_id', userId);
    } catch (e) {
      print('DEBUG: Location update failed: $e');
    }
  }

  // Get today's earnings and jobs count
  Future<Map<String, dynamic>> getTodayEarnings(dynamic workerId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).toIso8601String();

      print(
        'DEBUG: [getTodayEarnings] Checking payments table for worker $workerId since $startOfDay',
      );

      // Fetch all payments linked to worker's requests (In Progress or Completed)
      final response = await _supabase
          .from('payments')
          .select(
            'advance_amount, balance_amount, service_requests!inner(worker_id)',
          )
          .eq('service_requests.worker_id', workerId)
          .gte('created_at', startOfDay);

      double totalEarnings = 0;
      int jobsToday = response.length;

      for (var payment in response) {
        final adv = (payment['advance_amount'] as num?)?.toDouble() ?? 0.0;
        final bal = (payment['balance_amount'] as num?)?.toDouble() ?? 0.0;
        totalEarnings += (adv + bal);
      }

      print(
        'DEBUG: [getTodayEarnings] SUCCESS: ₹$totalEarnings ($jobsToday jobs)',
      );
      return {'earnings': totalEarnings, 'jobs': jobsToday};
    } catch (e) {
      print('DEBUG: [getTodayEarnings] ERROR: $e');
      return {'earnings': 0.0, 'jobs': 0};
    }
  }

  // Fetch incoming requests using regular query instead of stream to prevent timeouts
  Future<List<Map<String, dynamic>>> getIncomingRequests() async {
    try {
      print('DEBUG: Fetching incoming requests from Supabase...');

      // Debug: Log ANY service requests to see their structure/status
      final anyRes = await _supabase
          .from('service_requests')
          .select('status, id')
          .limit(5);
      print('DEBUG: Raw service_requests sample: $anyRes');

      // Try matching upper/lower case for common initial statuses
      final response = await _supabase
          .from('service_requests')
          .select(
            '*, users!service_requests_customer_id_fkey(name, phone, latitude, longitude)',
          )
          .or(
            'status.eq.MATCHING,status.eq.matching,status.eq.PENDING,status.eq.pending,status.eq.CREATED,status.eq.created',
          )
          .order('created_at', ascending: false)
          .limit(20);

      print(
        'DEBUG: Found ${response.length} matching requests with broad status check',
      );

      List<Map<String, dynamic>> requests = [];
      for (var req in response) {
        final mergedReq = Map<String, dynamic>.from(req);
        if (req['users'] != null) {
          if (req['users']['name'] != null) {
            mergedReq['customer_name'] = req['users']['name'];
          }
          if (req['users']['latitude'] != null) {
            mergedReq['customer_lat'] = req['users']['latitude'];
          }
          if (req['users']['longitude'] != null) {
            mergedReq['customer_lng'] = req['users']['longitude'];
          }
        }
        requests.add(mergedReq);
      }

      return requests;
    } catch (e) {
      print('DEBUG: ERROR in getIncomingRequests: $e');
      return [];
    }
  }

  // Fetch active jobs from the new 'jobs' table
  Future<List<Map<String, dynamic>>> getActiveJobs(dynamic workerId) async {
    try {
      print(
        'DEBUG: [getActiveJobs] Fetching from jobs table for worker $workerId',
      );

      // 1. Fetch active jobs from the 'jobs' table and join with 'service_requests' and 'users'
      final response = await _supabase
          .from('jobs')
          .select(
            '*, service_requests(*), users!jobs_customer_id_fkey(name, phone, latitude, longitude)',
          )
          .eq('worker_id', workerId)
          .not('status', 'eq', 'COMPLETED')
          .not('status', 'eq', 'SERVICE_COMPLETED')
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> activeJobs = [];

      for (var job in response) {
        final requestData = job['service_requests'];
        if (requestData != null) {
          final mergedJob = Map<String, dynamic>.from(requestData);
          mergedJob['status'] = job['status'];
          mergedJob['job_id'] = job['id'];
          mergedJob['before_photo_url'] = job['before_photo_url'];
          mergedJob['after_photo_url'] = job['after_photo_url'];

          if (job['users'] != null) {
            if (job['users']['name'] != null) {
              mergedJob['customer_name'] = job['users']['name'];
            }
            if (job['users']['phone'] != null) {
              mergedJob['customer_phone'] = job['users']['phone'];
            }
            if (job['users']['latitude'] != null) {
              mergedJob['customer_lat'] = job['users']['latitude'];
            }
            if (job['users']['longitude'] != null) {
              mergedJob['customer_lng'] = job['users']['longitude'];
            }
          }

          activeJobs.add(mergedJob);
        }
      }

      print(
        'DEBUG: [getActiveJobs] Found ${activeJobs.length} jobs in jobs table',
      );

      // 2. Legacy/Fallback bridge: Ensure requests that are accepted but don't have a job record appear
      // This is crucial during migration or if the customer app doesn't create the job record yet
      final acceptedProposals = await _supabase
          .from('proposals')
          .select('*, service_requests(*)')
          .eq('worker_id', workerId)
          .or('status.eq.ACCEPTED,status.eq.accepted');

      final Set<dynamic> seenRequestIds = activeJobs
          .map((j) => j['id'])
          .toSet();

      for (var prop in acceptedProposals) {
        final request = prop['service_requests'];
        if (request != null && !seenRequestIds.contains(request['id'])) {
          final requestStatus = request['status']?.toString().toUpperCase();

          if (requestStatus != 'SERVICE_COMPLETED' &&
              requestStatus != 'COMPLETED' &&
              requestStatus != 'CANCELLED') {
            print(
              'DEBUG: [getActiveJobs] PROACTIVE: Creating missing job record for request ${request['id']}',
            );

            // Auto-create missing job record
            try {
              await createJob(
                requestId: request['id'],
                workerId: workerId,
                customerId: request['customer_id'],
              );

              final jobData = Map<String, dynamic>.from(request);
              jobData['status'] = 'ACCEPTED';
              activeJobs.add(jobData);
            } catch (createErr) {
              print('DEBUG: [getActiveJobs] Auto-create failed: $createErr');
            }
          }
        }
      }

      return activeJobs;
    } catch (e, stack) {
      print('DEBUG: [getActiveJobs] ERROR: $e');
      print('DEBUG: Stack trace: $stack');
      return [];
    }
  }

  // Fetch jobs by status from jobs table
  Future<List<Map<String, dynamic>>> getJobsByStatus(
    dynamic workerId,
    List<String> statuses,
  ) async {
    try {
      final response = await _supabase
          .from('jobs')
          .select(
            '*, service_requests(*), users!jobs_customer_id_fkey(name, phone, latitude, longitude)',
          )
          .eq('worker_id', workerId)
          .inFilter('status', statuses)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> res = [];
      for (var job in response) {
        final requestData = job['service_requests'];
        if (requestData != null) {
          final mergedJob = Map<String, dynamic>.from(requestData);
          mergedJob['status'] = job['status'];
          mergedJob['job_id'] = job['id'];
          mergedJob['before_photo_url'] = job['before_photo_url'];
          mergedJob['after_photo_url'] = job['after_photo_url'];

          if (job['users'] != null) {
            if (job['users']['name'] != null) {
              mergedJob['customer_name'] = job['users']['name'];
            }
            if (job['users']['phone'] != null) {
              mergedJob['customer_phone'] = job['users']['phone'];
            }
            if (job['users']['latitude'] != null) {
              mergedJob['customer_lat'] = job['users']['latitude'];
            }
            if (job['users']['longitude'] != null) {
              mergedJob['customer_lng'] = job['users']['longitude'];
            }
          }

          res.add(mergedJob);
        }
      }
      return res;
    } catch (e) {
      print('DEBUG: [getJobsByStatus] Error: $e');
      return [];
    }
  }

  // Get full earnings stats (Total)
  Future<Map<String, dynamic>> getEarningsStats(dynamic workerId) async {
    try {
      print(
        'DEBUG: [getEarningsStats] Fetching from payments table for worker: $workerId',
      );

      final response = await _supabase
          .from('payments')
          .select(
            '*, service_requests!inner(worker_id, service_category, status)',
          )
          .eq('service_requests.worker_id', workerId)
          .order('created_at', ascending: false);

      double total = 0;
      List<Map<String, dynamic>> history = [];

      for (var record in response) {
        try {
          final serviceData =
              record['service_requests'] as Map<String, dynamic>?;
          final advanceAmt =
              (record['advance_amount'] as num?)?.toDouble() ?? 0.0;
          final balanceAmt =
              (record['balance_amount'] as num?)?.toDouble() ?? 0.0;

          total += (advanceAmt + balanceAmt);

          if (advanceAmt > 0) {
            history.add({
              'amount': advanceAmt,
              'service_category': serviceData?['service_category'] ?? 'Service',
              'created_at': record['created_at'],
              'type': 'ADVANCE',
              'status': serviceData?['status'],
              'request_id': record['request_id'],
            });
          }

          if (balanceAmt > 0) {
            history.add({
              'amount': balanceAmt,
              'service_category': serviceData?['service_category'] ?? 'Service',
              'created_at': record['created_at'],
              'type': 'FINAL',
              'status': serviceData?['status'],
              'request_id': record['request_id'],
            });
          }
        } catch (itemErr) {
          print(
            'DEBUG: [getEarningsStats] Error parsing record item: $itemErr',
          );
        }
      }

      print('DEBUG: [getEarningsStats] SUCCESS: Total=₹$total');

      return {'total': total, 'history': history};
    } catch (e, stack) {
      print('DEBUG: [getEarningsStats] ERROR: $e');
      print('DEBUG: [getEarningsStats] STACK: $stack');
      return {'total': 0.0, 'history': []};
    }
  }

  // Record a ledger entry in the earnings table
  Future<void> recordEarning({
    required dynamic requestId,
    required dynamic workerId,
    required double amount,
    required String type, // 'ADVANCE' or 'FINAL'
  }) async {
    try {
      print(
        'DEBUG: [recordEarning] LEDGER: Recording ₹$amount ($type) for request $requestId',
      );

      // Find the payment_id if it exists
      final payment = await _supabase
          .from('payments')
          .select('id')
          .eq('request_id', requestId)
          .maybeSingle();

      if (amount <= 0) return;

      await _supabase.from('earnings').upsert({
        'worker_id': workerId,
        'request_id': requestId,
        'payment_id': payment?['id'],
        'amount': amount,
        'type': type,
      }, onConflict: 'request_id,type');

      print('DEBUG: [recordEarning] Success');
    } catch (e) {
      print('DEBUG: [recordEarning] Error: $e');
    }
  }

  // Record a payment entry in the payments table
  Future<void> recordPayment({
    required dynamic requestId,
    required dynamic workerId,
    required double amount,
    required String type, // 'ADVANCE' or 'FINAL'
  }) async {
    try {
      print(
        'DEBUG: [recordPayment] DB: Updating payments table for request $requestId',
      );

      final column = type == 'ADVANCE' ? 'advance_amount' : 'balance_amount';

      final existing = await _supabase
          .from('payments')
          .select()
          .eq('request_id', requestId)
          .maybeSingle();

      if (existing != null) {
        await _supabase
            .from('payments')
            .update({
              column: amount,
              'payment_status': type == 'FINAL' ? 'PAID' : 'ADVANCE_PAID',
            })
            .eq('request_id', requestId);
      } else {
        await _supabase.from('payments').insert({
          'request_id': requestId,
          column: amount,
          'payment_status': type == 'ADVANCE' ? 'ADVANCE_PAID' : 'PARTIAL_PAID',
        });
      }

      // Also record in the earnings ledger
      await recordEarning(
        requestId: requestId,
        workerId: workerId,
        amount: amount,
        type: type,
      );
    } catch (e) {
      print('DEBUG: [recordPayment] ERROR: $e');
    }
  }

  // Accept a service request - Keep this for legacy or direct matching if needed
  Future<void> acceptRequest(dynamic requestId, dynamic workerId) async {
    try {
      print(
        'DEBUG: Attempting to accept request ID: $requestId for worker: $workerId',
      );

      await _supabase
          .from('service_requests')
          .update({'status': 'PROPOSAL_ACCEPTED', 'worker_id': workerId})
          .eq('id', requestId);

      print('DEBUG: Request $requestId successfully accepted.');
    } catch (e) {
      print('DEBUG: Error in acceptRequest: $e');
      throw Exception('Failed to accept request: $e');
    }
  }

  // Send a proposal for a service request
  Future<void> sendProposal({
    required dynamic requestId,
    required dynamic workerId,
    required double serviceCost,
    required double advancePercent,
    required String? arrivalTime,
    required String? notes,
  }) async {
    try {
      print('DEBUG: Sending proposal for request $requestId');

      // 1. Insert proposal
      await _supabase.from('proposals').insert({
        'request_id': requestId,
        'worker_id': workerId,
        'service_cost': serviceCost,
        'advance_percent': advancePercent,
        'notes': notes,
        'status': 'PENDING',
        'estimated_time': arrivalTime, // Expecting format like '10 minutes'
      });

      // 2. Update service request status
      // We also set the worker_id so the customer knows who sent the (primary) proposal
      // In a multi-proposal system, we'd handle this differently
      await _supabase
          .from('service_requests')
          .update({'status': 'PROPOSAL_SENT', 'worker_id': workerId})
          .eq('id', requestId);

      print('DEBUG: Proposal sent successfully');
    } catch (e) {
      print('DEBUG: Error in sendProposal: $e');
      throw Exception('Failed to send proposal: $e');
    }
  }

  // Update status to 'SERVICE_STARTED'
  Future<void> startJob(dynamic requestId) async {
    try {
      await _supabase
          .from('service_requests')
          .update({'status': 'SERVICE_STARTED'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Failed to start job: $e');
    }
  }

  // Update status to 'SERVICE_COMPLETED' and record payment
  Future<void> completeJob(
    dynamic requestId, {
    double amount = 0,
    dynamic workerId,
  }) async {
    try {
      // 1. Update status
      await updateJobStatus(requestId, 'SERVICE_COMPLETED');

      // 2. Record payment if amount is provided
      if (amount > 0 && workerId != null) {
        await recordPayment(
          requestId: requestId,
          workerId: workerId,
          amount: amount,
          type: 'FINAL',
        );
      }
    } catch (e) {
      throw Exception('Failed to complete job: $e');
    }
  }

  // Check if an advance payment exists for a request
  Future<bool> hasAdvancePayment(dynamic requestId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('request_id', requestId)
          .not('advance_amount', 'is', null)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('DEBUG: [hasAdvancePayment] ERROR: $e');
      return false;
    }
  }

  // Fetch accepted proposal for a request
  Future<Map<String, dynamic>?> getAcceptedProposal(dynamic requestId) async {
    try {
      final response = await _supabase
          .from('proposals')
          .select()
          .eq('request_id', requestId)
          .or('status.eq.ACCEPTED,status.eq.accepted')
          .maybeSingle();
      return response;
    } catch (e) {
      print('DEBUG: Error fetching accepted proposal: $e');
      return null;
    }
  }

  // Fetch all proposals for a worker
  Future<List<Map<String, dynamic>>> getProposals(dynamic workerId) async {
    try {
      print('DEBUG: Fetching all proposals for worker $workerId');

      final response = await _supabase
          .from('proposals')
          .select('*, service_requests(*)')
          .eq('worker_id', workerId)
          .order('created_at', ascending: false);

      print('DEBUG: Found ${response.length} proposals');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('DEBUG: ERROR in getProposals: $e');
      return [];
    }
  }

  // Save job photo URL to the 'jobs' table
  Future<void> saveJobPhotoUrl(
    dynamic requestId,
    String type,
    String url,
  ) async {
    try {
      final column = type == 'before' ? 'before_photo_url' : 'after_photo_url';

      // Update the jobs table
      await _supabase
          .from('jobs')
          .update({column: url})
          .eq('request_id', requestId);

      print(
        'DEBUG: [saveJobPhotoUrl] Successfully saved $type photo URL to jobs table',
      );
    } catch (e) {
      print('DEBUG: [saveJobPhotoUrl] FAILED: $e');
      throw Exception('Failed to save photo URL to jobs table: $e');
    }
  }

  // Upload job documentation photo
  Future<String?> uploadJobPhoto(
    String requestId,
    String type,
    String filePath,
  ) async {
    try {
      print('DEBUG: [uploadJobPhoto] Starting: request $requestId, type $type');
      final file = File(filePath);
      if (!await file.exists()) {
        print('DEBUG: [uploadJobPhoto] ERROR: File not found: $filePath');
        return null;
      }

      final fileExt = filePath.split('.').last;
      final fileName =
          '${type}_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      // Use a flatter path to avoid nested folder permission issues if any
      final path = '$requestId/$fileName';

      print(
        'DEBUG: [uploadJobPhoto] Attempting upload to bucket "job-documentation" at path: $path',
      );

      await _supabase.storage.from('job-documentation').upload(path, file);

      final String publicUrl = _supabase.storage
          .from('job-documentation')
          .getPublicUrl(path);
      print('DEBUG: [uploadJobPhoto] SUCCESS! Public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('DEBUG: [uploadJobPhoto] FAILED: $e');
      if (e.toString().contains('Bucket not found')) {
        print(
          'DEBUG: [uploadJobPhoto] CRITICAL: The bucket "job-documentation" does not exist in Supabase Storage.',
        );
      }
      return null;
    }
  }

  // Fetch reviews given by customers for this worker
  Future<List<Map<String, dynamic>>> getWorkerReviews(dynamic workerId) async {
    try {
      print('DEBUG: [getWorkerReviews] Fetching reviews for worker $workerId');

      final response = await _supabase
          .from('reviews')
          .select('*, users!reviews_customer_id_fkey(name)')
          .eq('worker_id', workerId)
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> reviews = [];
      for (var rev in response) {
        final mergedRev = Map<String, dynamic>.from(rev);
        if (rev['users'] != null && rev['users']['name'] != null) {
          mergedRev['customer_name'] = rev['users']['name'];
        } else {
          mergedRev['customer_name'] = 'Anonymous';
        }
        reviews.add(mergedRev);
      }

      print('DEBUG: [getWorkerReviews] Found ${reviews.length} reviews');
      return reviews;
    } catch (e) {
      print('DEBUG: [getWorkerReviews] ERROR: $e');
      return [];
    }
  }
}

class ServiceRequest {
  final Map<String, dynamic> data;
  ServiceRequest(this.data);
}
