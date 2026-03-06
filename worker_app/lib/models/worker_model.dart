class WorkerModel {
  final int? id;
  final String userId;
  final String category;
  final int? experienceYears;
  final double? rating;
  final int? totalJobs;
  final bool isVerified;
  final bool isOnline;
  final double? latitude;
  final double? longitude;
  final double? serviceRadiusKm;
  final DateTime? createdAt;

  WorkerModel({
    this.id,
    required this.userId,
    required this.category,
    this.experienceYears,
    this.rating,
    this.totalJobs,
    this.isVerified = false,
    this.isOnline = false,
    this.latitude,
    this.longitude,
    this.serviceRadiusKm,
    this.createdAt,
  });

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'],
      userId: json['user_id'],
      category: json['category'],
      experienceYears: json['experience_years'],
      rating: json['rating']?.toDouble(),
      totalJobs: json['total_jobs'],
      isVerified: json['is_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      serviceRadiusKm: json['service_radius_km']?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'category': category,
      'experience_years': experienceYears,
      'rating': rating,
      'total_jobs': totalJobs,
      'is_verified': isVerified,
      'is_online': isOnline,
      'latitude': latitude,
      'longitude': longitude,
      'service_radius_km': serviceRadiusKm,
    };
  }
}
