class Worker {
  final int id;
  final String name;
  final String phone;
  final String? profileImage;
  final String category;
  final int experienceYears;
  final double rating;
  final int totalJobs;
  final bool isVerified;
  final bool isOnline;
  final double? latitude;
  final double? longitude;
  final double? serviceRadiusKm;

  const Worker({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
    required this.category,
    required this.experienceYears,
    required this.rating,
    required this.totalJobs,
    required this.isVerified,
    required this.isOnline,
    this.latitude,
    this.longitude,
    this.serviceRadiusKm,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Unknown',
      phone: json['phone'] as String? ?? '',
      profileImage: json['profile_image'] as String?,
      category: json['category'] as String? ?? 'Other',
      experienceYears: (json['experience_years'] as num?)?.toInt() ?? 0,
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      totalJobs: (json['total_jobs'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isOnline: json['is_online'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      serviceRadiusKm: (json['service_radius_km'] as num?)?.toDouble(),
    );
  }
}
