import 'package:flutter/material.dart';

class BookingRequest {
  final int? id;
  final String customerId;
  final int workerId;
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
    required this.workerId,
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
        'worker_id': workerId,
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
        workerId: (json['worker_id'] as num).toInt(),
        serviceCategory: json['service_category'] as String,
        issueSummary: json['issue_summary'] as String? ?? '',
        urgency: json['urgency'] as String? ?? 'medium',
        status: json['status'] as String? ?? 'CREATED',
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
        return const Color(0xFFEA580C); // Warning Orange
      case 'MATCHING':
      case 'PROPOSAL_SENT':
        return const Color(0xFF2563EB); // Primary Blue
      case 'PROPOSAL_ACCEPTED':
      case 'ADVANCE_PAID':
      case 'WORKER_COMING':
      case 'SERVICE_STARTED':
        return const Color(0xFF059669); // Success Green
      case 'SERVICE_COMPLETED':
      case 'PAYMENT_DONE':
        return const Color(0xFF6B7280); // Gray
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  String get statusText {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'Pending';
      case 'CREATED': return 'Finding Worker';
      case 'MATCHING': return 'Matching';
      case 'PROPOSAL_SENT': return 'Offer Received';
      case 'PROPOSAL_ACCEPTED': return 'Accepted';
      case 'ADVANCE_PAID': return 'Paid (Escrow)';
      case 'WORKER_COMING': return 'On the way';
      case 'SERVICE_STARTED': return 'In Progress';
      case 'SERVICE_COMPLETED': return 'Completed';
      case 'PAYMENT_DONE': return 'Finalized';
      default: return status;
    }
  }
}
