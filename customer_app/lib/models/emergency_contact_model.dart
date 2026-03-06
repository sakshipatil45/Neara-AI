class EmergencyContactModel {
  final String id;
  final String userId;
  final String name;
  final String phone;

  EmergencyContactModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'phone': phone,
      };

  factory EmergencyContactModel.fromMap(Map<String, dynamic> map) =>
      EmergencyContactModel(
        id: map['id'] ?? '',
        userId: map['user_id'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
      );
}
