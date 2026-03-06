import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final client = SupabaseClient(
    'https://dusgfqvvjtpdnstjwjvv.supabase.co',
    'sb_publishable_DwFD22YKXPAoq1wYbnrY5A_we0Id-cB',
  );

  try {
    final paymentsRes = await client.from('payments').select().limit(1);
    if (paymentsRes.isNotEmpty) {
      print('Payments Full Columns: ${paymentsRes.first.keys.toList()}');
    } else {
      print(
        'Payments table is empty, columns cannot be inferred from a select.',
      );
      // Try to insert a dummy to see if it fails or use a different meta query if possible
      // But for now, let's just assume the user might have different columns if it was blank
    }
  } catch (e) {
    print('Payments Error: $e');
  }

  try {
    final srRes = await client
        .from('service_requests')
        .select()
        .limit(1)
        .single();
    print('Service Requests Full Columns: ${srRes.keys.toList()}');
  } catch (e) {
    print('Service Requests Error: $e');
  }

  exit(0);
}
