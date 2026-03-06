import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/emergency_contact_model.dart';
import 'auth_service.dart';

class EmergencyContactService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  /// Fetches emergency contacts for the currently logged-in user.
  Future<List<EmergencyContactModel>> getContacts() async {
    final userId = await _authService.getLoggedUserId();
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((e) => EmergencyContactModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Return empty list on error (table may not exist yet in some envs)
      return [];
    }
  }

  /// Adds a new emergency contact for the currently logged-in user.
  Future<EmergencyContactModel?> addContact({
    required String name,
    required String phone,
  }) async {
    final userId = await _authService.getLoggedUserId();
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('emergency_contacts')
          .insert({'user_id': userId, 'name': name, 'phone': phone})
          .select()
          .single();
      return EmergencyContactModel.fromMap(response);
    } catch (_) {
      return null;
    }
  }

  /// Deletes an emergency contact by its id.
  Future<void> deleteContact(String contactId) async {
    try {
      await _supabase
          .from('emergency_contacts')
          .delete()
          .eq('id', contactId);
    } catch (_) {}
  }
}
