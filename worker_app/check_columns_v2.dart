import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final client = SupabaseClient(
    'https://dusgfqvvjtpdnstjwjvv.supabase.co',
    'sb_publishable_DwFD22YKXPAoq1wYbnrY5A_we0Id-cB',
  );

  try {
    // We'll use a RPC call or just try to select everything from a potential insert
    // to see if we can get column names from an error or success.
    // However, the best way in Supabase JS/Dart for an empty table is often just
    // checking if we can select specific columns.

    final res = await client
        .from('payments')
        .select('amount, worker_id, type')
        .limit(1);
    print('SUCCESS: Columns amount, worker_id, type exist in payments.');
  } catch (e) {
    print('COLUMN CHECK FAILED: $e');
  }
  exit(0);
}
