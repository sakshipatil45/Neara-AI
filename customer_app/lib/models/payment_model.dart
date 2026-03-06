class EscrowPayment {
  final int? id;
  final int requestId;
  final String customerId;
  final int workerId;
  final double advanceAmount;
  final double balanceAmount;
  final double totalAmount;
  final String escrowStatus; // HELD | PARTIALLY_RELEASED | RELEASED | REFUNDED
  final String paymentMethod; // UPI | CARD | WALLET | MOCK
  final String? advanceTransactionId;
  final String? balanceTransactionId;
  final DateTime? advancePaidAt;
  final DateTime? balancePaidAt;
  final DateTime? createdAt;

  const EscrowPayment({
    this.id,
    required this.requestId,
    required this.customerId,
    required this.workerId,
    required this.advanceAmount,
    required this.balanceAmount,
    required this.totalAmount,
    required this.escrowStatus,
    required this.paymentMethod,
    this.advanceTransactionId,
    this.balanceTransactionId,
    this.advancePaidAt,
    this.balancePaidAt,
    this.createdAt,
  });

  factory EscrowPayment.fromJson(Map<String, dynamic> json) {
    return EscrowPayment(
      id: (json['id'] as num?)?.toInt(),
      requestId: (json['request_id'] as num).toInt(),
      customerId: json['customer_id'] as String,
      workerId: (json['worker_id'] as num).toInt(),
      advanceAmount:
          double.tryParse(json['advance_amount']?.toString() ?? '0') ?? 0.0,
      balanceAmount:
          double.tryParse(json['balance_amount']?.toString() ?? '0') ?? 0.0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      escrowStatus: json['escrow_status'] as String? ?? 'HELD',
      paymentMethod: json['payment_method'] as String? ?? 'MOCK',
      advanceTransactionId: json['advance_transaction_id'] as String?,
      balanceTransactionId: json['balance_transaction_id'] as String?,
      advancePaidAt: json['advance_paid_at'] != null
          ? DateTime.tryParse(json['advance_paid_at'])
          : null,
      balancePaidAt: json['balance_paid_at'] != null
          ? DateTime.tryParse(json['balance_paid_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'customer_id': customerId,
    'worker_id': workerId,
    'advance_amount': advanceAmount,
    'balance_amount': balanceAmount,
    'total_amount': totalAmount,
    'escrow_status': escrowStatus,
    'payment_method': paymentMethod,
    if (advanceTransactionId != null)
      'advance_transaction_id': advanceTransactionId,
    if (balanceTransactionId != null)
      'balance_transaction_id': balanceTransactionId,
    if (advancePaidAt != null)
      'advance_paid_at': advancePaidAt!.toIso8601String(),
    if (balancePaidAt != null)
      'balance_paid_at': balancePaidAt!.toIso8601String(),
  };

  bool get isAdvancePaid => advancePaidAt != null;
  bool get isFullyPaid => balancePaidAt != null;
}
