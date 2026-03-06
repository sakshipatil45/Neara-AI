import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final client = SupabaseClient(
    'https://dusgfqvvjtpdnstjwjvv.supabase.co',
    'sb_publishable_DwFD22YKXPAoq1wYbnrY5A_we0Id-cB',
  );

  print('--- Checking Tables ---');

  try {
    final payments = await client.from('payments').select().limit(5);
    print('Payments found: ${payments.length}');
    if (payments.isNotEmpty) print('Sample Payment: ${payments.first}');
  } catch (e) {
    print('Payments Error: $e');
  }

  try {
    final jobs = await client.from('jobs').select().limit(5);
    print('Jobs found: ${jobs.length}');
    if (jobs.isNotEmpty) print('Sample Job: ${jobs.first}');
  } catch (e) {
    print('Jobs Error: $e');
  }

  exit(0);
}
