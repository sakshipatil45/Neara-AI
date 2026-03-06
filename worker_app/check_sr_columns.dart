import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final client = SupabaseClient(
    'https://dusgfqvvjtpdnstjwjvv.supabase.co',
    'sb_publishable_DwFD22YKXPAoq1wYbnrY5A_we0Id-cB',
  );

  try {
    final res = await client
        .from('service_requests')
        .select()
        .limit(1)
        .single();
    print('Columns in service_requests: ${res.keys.toList()}');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
