class EscrowPayment {
  final int? id;
  final int requestId;
  final double advanceAmount;
  final double balanceAmount;
  final String? paymentStatus; // ADVANCE_PAID | PAID
  final String? escrowStatus; // HELD | RELEASED
  final String? transactionId;
  final DateTime? createdAt;

  double get totalAmount => advanceAmount + balanceAmount;
  bool get isAdvancePaid =>
      paymentStatus == 'ADVANCE_PAID' || advanceAmount > 0;
  bool get isFullyPaid => escrowStatus == 'RELEASED';

  const EscrowPayment({
    this.id,
    required this.requestId,
    required this.advanceAmount,
    required this.balanceAmount,
    this.paymentStatus,
    this.escrowStatus,
    this.transactionId,
    this.createdAt,
  });

  factory EscrowPayment.fromJson(Map<String, dynamic> json) {
    return EscrowPayment(
      id: (json['id'] as num?)?.toInt(),
      requestId: (json['request_id'] as num).toInt(),
      advanceAmount:
          double.tryParse(json['advance_amount']?.toString() ?? '0') ?? 0.0,
      balanceAmount:
          double.tryParse(json['balance_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status'] as String?,
      escrowStatus: json['escrow_status'] as String?,
      transactionId: json['transaction_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'advance_amount': advanceAmount,
    'balance_amount': balanceAmount,
    if (paymentStatus != null) 'payment_status': paymentStatus,
    if (escrowStatus != null) 'escrow_status': escrowStatus,
    if (transactionId != null) 'transaction_id': transactionId,
  };
}

// ── Payment history entry (payment joined with service_request context) ──
class PaymentHistoryEntry {
  final int? id;
  final int requestId;
  final String serviceCategory;
  final String issueSummary;
  final double advanceAmount;
  final double balanceAmount;
  final String? paymentStatus;
  final String? escrowStatus;
  final String? transactionId;
  final DateTime? createdAt;

  double get totalPaid => advanceAmount + balanceAmount;

  const PaymentHistoryEntry({
    this.id,
    required this.requestId,
    required this.serviceCategory,
    required this.issueSummary,
    required this.advanceAmount,
    required this.balanceAmount,
    this.paymentStatus,
    this.escrowStatus,
    this.transactionId,
    this.createdAt,
  });

  factory PaymentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryEntry(
      id: (json['id'] as num?)?.toInt(),
      requestId: (json['request_id'] as num).toInt(),
      serviceCategory: json['service_category'] as String? ?? 'Service',
      issueSummary: json['issue_summary'] as String? ?? '',
      advanceAmount:
          double.tryParse(json['advance_amount']?.toString() ?? '0') ?? 0.0,
      balanceAmount:
          double.tryParse(json['balance_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: json['payment_status'] as String?,
      escrowStatus: json['escrow_status'] as String?,
      transactionId: json['transaction_id'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
