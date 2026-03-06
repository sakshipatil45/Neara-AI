class Proposal {
  final int id;
  final int requestId;
  final int workerId;
  final double inspectionFee;
  final double serviceCost;
  final double advancePercent;
  final String? estimatedTime;
  final String? notes;
  final String status;
  final DateTime createdAt;

  // Joined fields
  final String? workerName;
  final String? workerRating;

  const Proposal({
    required this.id,
    required this.requestId,
    required this.workerId,
    required this.inspectionFee,
    required this.serviceCost,
    required this.advancePercent,
    this.estimatedTime,
    this.notes,
    required this.status,
    required this.createdAt,
    this.workerName,
    this.workerRating,
  });

  factory Proposal.fromJson(Map<String, dynamic> json) {
    final workerMap = json['workers'] as Map<String, dynamic>?;
    final userMap = workerMap?['users'] as Map<String, dynamic>?;

    return Proposal(
      id: (json['id'] as num).toInt(),
      requestId: (json['request_id'] as num).toInt(),
      workerId: (json['worker_id'] as num).toInt(),
      inspectionFee: double.tryParse(json['inspection_fee']?.toString() ?? '0') ?? 0.0,
      serviceCost: double.tryParse(json['service_cost']?.toString() ?? '0') ?? 0.0,
      advancePercent: double.tryParse(json['advance_percent']?.toString() ?? '0') ?? 0.0,
      estimatedTime: json['estimated_time']?.toString(),
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(json['created_at']),
      workerName: userMap?['name'] as String?,
      workerRating: workerMap?['rating']?.toString(),
    );
  }

  double get totalEstimate => inspectionFee + serviceCost;
  double get advanceAmount => (totalEstimate * advancePercent) / 100;
}
