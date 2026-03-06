import 'package:flutter/material.dart';

class BookingRequest {
  final int? id;
  final String customerId;
  final int? workerId;
  final String serviceCategory;
  final String issueSummary;
  final String urgency;
  final double? latitude;
  final double? longitude;
  final String status;
  final DateTime? createdAt;

  // Joined fields
  final String? workerName;
  final String? workerProfileImage;

  const BookingRequest({
    this.id,
    required this.customerId,
    this.workerId,
    required this.serviceCategory,
    required this.issueSummary,
    required this.urgency,
    required this.status,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.workerName,
    this.workerProfileImage,
  });

  Map<String, dynamic> toJson() => {
    'customer_id': customerId,
    if (workerId != null) 'worker_id': workerId,
    'service_category': serviceCategory,
    'issue_summary': issueSummary,
    'urgency': urgency,
    'status': status,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    // Check if worker info is nested (from joins)
    final workerMap = json['workers'] as Map<String, dynamic>?;
    final userMap = workerMap?['users'] as Map<String, dynamic>?;

    return BookingRequest(
      id: (json['id'] as num?)?.toInt(),
      customerId: json['customer_id'] as String,
      workerId: (json['worker_id'] as num?)?.toInt(),
      serviceCategory: json['service_category'] as String,
      issueSummary: json['issue_summary'] as String? ?? '',
      urgency: json['urgency'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'PENDING',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      workerName: userMap?['name'] as String?,
      workerProfileImage: userMap?['profile_image'] as String?,
    );
  }

  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'CREATED':
      case 'MATCHING':
        return const Color(0xFFEA580C);
      case 'PROPOSAL_SENT':
        return const Color(0xFF2563EB);
      case 'NEGOTIATING':
        return const Color(0xFF7C3AED);
      case 'PROPOSAL_ACCEPTED':
      case 'ADVANCE_PAID':
        return const Color(0xFF059669);
      case 'WORKER_COMING':
        return const Color(0xFF0284C7);
      case 'WORKER_ARRIVED':
        return const Color(0xFF0891B2);
      case 'SERVICE_STARTED':
        return const Color(0xFF059669);
      case 'SERVICE_COMPLETED':
      case 'FINAL_PAYMENT_PENDING':
        return const Color(0xFFEA580C);
      case 'SERVICE_CLOSED':
      case 'PAYMENT_DONE':
        return const Color(0xFF6B7280);
      case 'RATED':
        return const Color(0xFF059669);
      case 'CANCELLED':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'CREATED':
        return 'Awaiting Response';
      case 'MATCHING':
        return 'Sent to Worker';
      case 'PROPOSAL_SENT':
        return 'Offer Received';
      case 'NEGOTIATING':
        return 'Negotiating';
      case 'PROPOSAL_ACCEPTED':
        return 'Accepted';
      case 'ADVANCE_PAID':
        return 'Paid (Escrow)';
      case 'WORKER_COMING':
        return 'On the way';
      case 'WORKER_ARRIVED':
        return 'Arrived';
      case 'SERVICE_STARTED':
        return 'In Progress';
      case 'SERVICE_COMPLETED':
        return 'Review Work Done';
      case 'FINAL_PAYMENT_PENDING':
        return 'Pay Balance';
      case 'SERVICE_CLOSED':
        return 'Finalized';
      case 'PAYMENT_DONE':
        return 'Finalized';
      case 'RATED':
        return 'Completed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  bool get needsProposalAction =>
      status.toUpperCase() == 'PROPOSAL_SENT' ||
      status.toUpperCase() == 'NEGOTIATING';
  bool get needsAdvancePayment => status.toUpperCase() == 'PROPOSAL_ACCEPTED';
  bool get isWorkerEnRoute =>
      status.toUpperCase() == 'WORKER_COMING' ||
      status.toUpperCase() == 'WORKER_ARRIVED';
  bool get isServiceActive => status.toUpperCase() == 'SERVICE_STARTED';
  bool get isPhotoReviewPending => status.toUpperCase() == 'SERVICE_COMPLETED';
  bool get needsFinalPayment => status.toUpperCase() == 'FINAL_PAYMENT_PENDING';
  bool get canReview =>
      status.toUpperCase() == 'SERVICE_CLOSED' ||
      status.toUpperCase() == 'PAYMENT_DONE';
  bool get isCompleted =>
      status.toUpperCase() == 'SERVICE_CLOSED' ||
      status.toUpperCase() == 'PAYMENT_DONE' ||
      status.toUpperCase() == 'RATED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';
}
