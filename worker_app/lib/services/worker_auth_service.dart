import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/worker_model.dart';

class WorkerAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _sessionKey = 'auth_user_id';

  // Login using mobile and password (Database query)
  Future<UserModel?> loginWorker(String mobile, String password) async {
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
        final user = UserModel.fromJson(response);
        await _saveSession(user.id);
        return user;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Register using mobile and password (Database insert)
  Future<UserModel> registerWorker({
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
            'role': 'worker',
          })
          .select()
          .single();

      final user = UserModel.fromJson(response);
      await _saveSession(user.id);
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // Check if worker profile exists for a user
  Future<bool> checkProfileExists(String userId) async {
    try {
      final response = await _supabase
          .from('workers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Create worker profile: Insert into workers table
  Future<void> createWorkerProfile(WorkerModel worker) async {
    await _supabase.from('workers').insert(worker.toJson());
  }

  // Sign out
  Future<void> logoutWorker() async {
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

      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, userId);
  }
}
