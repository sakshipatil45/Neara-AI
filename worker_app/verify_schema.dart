import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final client = SupabaseClient(
    'https://dusgfqvvjtpdnstjwjvv.supabase.co',
    'sb_publishable_DwFD22YKXPAoq1wYbnrY5A_we0Id-cB',
  );

  try {
    // Try to select from payments to see if it exists
    final paymentsRes = await client.from('payments').select().limit(1);
    print('Payments table exists!');
    if (paymentsRes.isNotEmpty) {
      print('Payments Columns: ${paymentsRes.first.keys.toList()}');
    } else {
      print('Payments table is empty.');
    }
  } catch (e) {
    print('Payments table check failed: $e');
  }

  try {
    final srRes = await client
        .from('service_requests')
        .select()
        .limit(1)
        .single();
    print('Service Requests Columns: ${srRes.keys.toList()}');
  } catch (e) {
    print('Service Requests check failed: $e');
  }

  exit(0);
}
