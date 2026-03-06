class ServiceIntentModel {
  final String serviceCategory;
  final String urgency;
  final String summary;

  ServiceIntentModel({
    required this.serviceCategory,
    required this.urgency,
    required this.summary,
  });

  factory ServiceIntentModel.fromJson(Map<String, dynamic> json) {
    return ServiceIntentModel(
      serviceCategory: json['service_category'] ?? '',
      urgency: json['urgency'] ?? 'low',
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service_category': serviceCategory,
      'urgency': urgency,
      'summary': summary,
    };
  }
}
