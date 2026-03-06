import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _sessionKey = 'auth_user_id';

  // Login using mobile and password (Database query)
  Future<UserModel?> loginUser(String mobile, String password) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('phone', mobile)
          .eq(
            'password',
            password,
          ) // Stored as plain text for this custom implementation
          .maybeSingle();

      if (response != null) {
        final user = UserModel.fromMap(response);
        await _saveSession(user.id);
        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Register using mobile and password (Database insert)
  Future<UserModel> registerUser({
    required String name,
    required String mobile,
    required String password,
  }) async {
    try {
      // 1. Insert into users table
      final response = await _supabase
          .from('users')
          .insert({
            'name': name,
            'phone': mobile,
            'password': password,
            'role': 'customer',
          })
          .select()
          .single();

      final user = UserModel.fromMap(response);
      await _saveSession(user.id);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  // Get current session data
  Future<String?> getLoggedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  // Get current user data from users table based on local session
  Future<UserModel?> getCurrentUserData() async {
    final userId = await getLoggedUserId();
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // Update user data (name, phone)
  Future<void> updateUserData({
    required String userId,
    required String name,
    required String phone,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({'name': name, 'phone': phone})
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  // Update password
  Future<void> updatePassword({
    required String userId,
    required String newPassword,
  }) async {
    try {
      await _supabase
          .from('users')
          .update({'password': newPassword})
          .eq('id', userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
  }
}
