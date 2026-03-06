import 'worker_model.dart'; // Ensure it's here

enum ServiceCategory {
  mechanic,
  plumber,
  electrician,
  maid,
  roadsideAssistance,
  gasService,
  other,
}

enum EmergencyUrgency { low, medium, high, critical }

class EmergencyInterpretation {
  final String issueSummary;
  final EmergencyUrgency urgency;
  final String locationHint;
  final ServiceCategory serviceCategory;
  final String reason;
  final double confidence;
  final List<String> riskFactors;
  final bool needsClarification;

  EmergencyInterpretation({
    required this.issueSummary,
    required this.urgency,
    required this.locationHint,
    required this.serviceCategory,
    required this.reason,
    required this.confidence,
    this.riskFactors = const [],
    this.needsClarification = false,
  });
}

class SearchFilters {
  final ServiceCategory? serviceCategory;
  final List<ServiceCategory> categories;
  final double radiusKm;
  final double minRating;
  final bool verifiedOnly;
  final String genderPreference;
  final bool womenSafetyMode;
  final bool liveTracking;
  final bool riskMonitoring;
  final bool shareWithPrioritized;

  const SearchFilters({
    this.serviceCategory,
    this.categories = const [],
    this.radiusKm = 50,
    this.minRating = 3.5,
    this.verifiedOnly = false,
    this.genderPreference = 'any',
    this.womenSafetyMode = false,
    this.liveTracking = false,
    this.riskMonitoring = false,
    this.shareWithPrioritized = false,
  });

  SearchFilters copyWith({
    ServiceCategory? serviceCategory,
    List<ServiceCategory>? categories,
    double? radiusKm,
    double? minRating,
    bool? verifiedOnly,
    String? genderPreference,
    bool? womenSafetyMode,
    bool? liveTracking,
    bool? riskMonitoring,
    bool? shareWithPrioritized,
  }) {
    return SearchFilters(
      serviceCategory: serviceCategory ?? this.serviceCategory,
      categories: categories ?? this.categories,
      radiusKm: radiusKm ?? this.radiusKm,
      minRating: minRating ?? this.minRating,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      genderPreference: genderPreference ?? this.genderPreference,
      womenSafetyMode: womenSafetyMode ?? this.womenSafetyMode,
      liveTracking: liveTracking ?? this.liveTracking,
      riskMonitoring: riskMonitoring ?? this.riskMonitoring,
      shareWithPrioritized: shareWithPrioritized ?? this.shareWithPrioritized,
    );
  }
}

class MultilingualResponse {
  final String detectedLanguage;
  final String selectedLanguage;
  final String normalizedRequest;
  final String serviceType;
  final String responseText;
  final double confidence;
  final bool needsClarification;

  MultilingualResponse({
    required this.detectedLanguage,
    required this.selectedLanguage,
    required this.normalizedRequest,
    required this.serviceType,
    required this.responseText,
    required this.confidence,
    required this.needsClarification,
  });

  factory MultilingualResponse.fromJson(Map<String, dynamic> json) {
    return MultilingualResponse(
      detectedLanguage: json['detected_language'] as String? ?? 'en',
      selectedLanguage: json['selected_language'] as String? ?? 'en',
      normalizedRequest: json['normalized_request'] as String? ?? '',
      serviceType: json['service_type'] as String? ?? 'other',
      responseText: json['response_text'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      needsClarification: json['needs_clarification'] as bool? ?? false,
    );
  }
}

class VoiceCommandInterpretation {
  final String detectedLanguage;
  final String serviceType;
  final String normalizedIntent;
  final String urgencyLevel;
  final double confidence;

  VoiceCommandInterpretation({
    required this.detectedLanguage,
    required this.serviceType,
    required this.normalizedIntent,
    required this.urgencyLevel,
    required this.confidence,
  });

  factory VoiceCommandInterpretation.fromJson(Map<String, dynamic> json) {
    return VoiceCommandInterpretation(
      detectedLanguage: json['detected_language'] as String? ?? 'en',
      serviceType: json['service_type'] as String? ?? 'other',
      normalizedIntent: json['normalized_intent'] as String? ?? '',
      urgencyLevel: json['urgency_level'] as String? ?? 'LOW',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WorkerRanking {
  final String workerId;
  final double score;
  final String reason;
  final String recommendationLevel;
  final bool highlightMarker;
  final String? badgeLabel;
  final Worker? worker;

  WorkerRanking({
    required this.workerId,
    required this.score,
    required this.reason,
    this.recommendationLevel = 'STANDARD',
    this.highlightMarker = false,
    this.badgeLabel,
    this.worker,
  });

  WorkerRanking copyWith({
    String? workerId,
    double? score,
    String? reason,
    String? recommendationLevel,
    bool? highlightMarker,
    String? badgeLabel,
    Worker? worker,
  }) {
    return WorkerRanking(
      workerId: workerId ?? this.workerId,
      score: score ?? this.score,
      reason: reason ?? this.reason,
      recommendationLevel: recommendationLevel ?? this.recommendationLevel,
      highlightMarker: highlightMarker ?? this.highlightMarker,
      badgeLabel: badgeLabel ?? this.badgeLabel,
      worker: worker ?? this.worker,
    );
  }
}
