import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final _client = Supabase.instance.client;

  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required String phone,
    String? email,
    String role = 'customer',
  }) async {
    await _client.from('users').upsert({
      'id': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'role': role,
    });
  }
}
