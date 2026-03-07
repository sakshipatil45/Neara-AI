class ReviewModel {
  final int? id;
  final int requestId;
  final int workerId;
  final String customerId;
  final int rating; // 1-5
  final String? comment;
  final DateTime? createdAt;

  const ReviewModel({
    this.id,
    required this.requestId,
    required this.workerId,
    required this.customerId,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: (json['id'] as num?)?.toInt(),
      requestId: (json['request_id'] as num).toInt(),
      workerId: (json['worker_id'] as num).toInt(),
      customerId: json['customer_id'] as String,
      rating: (json['rating'] as num).toInt(),
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'request_id': requestId,
    'worker_id': workerId,
    'customer_id': customerId,
    'rating': rating,
    if (comment != null && comment!.isNotEmpty) 'comment': comment,
  };
}
