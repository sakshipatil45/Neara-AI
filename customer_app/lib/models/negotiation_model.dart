class Negotiation {
  final int? id;
  final int proposalId;
  final int requestId;
  final String senderRole; // 'customer' | 'worker'
  final double? counterAmount;
  final String message;
  final String status; // PENDING | ACCEPTED | REJECTED | SUPERSEDED
  final DateTime? createdAt;

  const Negotiation({
    this.id,
    required this.proposalId,
    required this.requestId,
    required this.senderRole,
    this.counterAmount,
    required this.message,
    required this.status,
    this.createdAt,
  });

  factory Negotiation.fromJson(Map<String, dynamic> json) {
    return Negotiation(
      id: (json['id'] as num?)?.toInt(),
      proposalId: (json['proposal_id'] as num).toInt(),
      requestId: (json['request_id'] as num).toInt(),
      senderRole: json['sender_role'] as String? ?? 'customer',
      counterAmount: double.tryParse(json['counter_amount']?.toString() ?? ''),
      message: json['message'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'proposal_id': proposalId,
    'request_id': requestId,
    'sender_role': senderRole,
    if (counterAmount != null) 'counter_amount': counterAmount,
    'message': message,
    'status': status,
  };
}
