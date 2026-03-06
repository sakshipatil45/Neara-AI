class UserModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.role = 'customer',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'role': role,
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'],
    name: map['name'],
    phone: map['phone'],
    email: map['email'],
    role: map['role'] ?? 'customer',
  );
}
