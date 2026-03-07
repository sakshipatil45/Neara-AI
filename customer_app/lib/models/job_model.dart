class JobRecord {
  final int id;
  final int requestId;
  final int? workerId;
  final String? customerId;
  final String status; // PENDING, ACTIVE, COMPLETED
  final String? beforePhotoUrl;
  final String? afterPhotoUrl;
  final DateTime? createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  const JobRecord({
    required this.id,
    required this.requestId,
    this.workerId,
    this.customerId,
    required this.status,
    this.beforePhotoUrl,
    this.afterPhotoUrl,
    this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  factory JobRecord.fromJson(Map<String, dynamic> json) {
    return JobRecord(
      id: (json['id'] as num).toInt(),
      requestId: (json['request_id'] as num).toInt(),
      workerId: (json['worker_id'] as num?)?.toInt(),
      customerId: json['customer_id'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      beforePhotoUrl: json['before_photo_url'] as String?,
      afterPhotoUrl: json['after_photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }
}
