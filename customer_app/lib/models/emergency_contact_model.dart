class EmergencyContactModel {
  final String id;
  final String userId;
  final String name;
  final String relation;
  final String phone;

  EmergencyContactModel({
    required this.id,
    required this.userId,
    required this.name,
    this.relation = '',
    required this.phone,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'contact_name': name,
    'relation': relation,
    'phone': phone,
  };

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) =>
      EmergencyContactModel(
        id: map['id']?.toString() ?? '',
        userId: map['user_id'] ?? '',
        name: map['contact_name'] ?? '',
        relation: map['relation'] ?? '',
        phone: map['phone'] ?? '',
      );
}
