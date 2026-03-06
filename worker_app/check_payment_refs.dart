import 'package:supabase/supabase.dart';
import 'dart:io';

void main() async {
  final client = SupabaseClient(
    'https://dusgfqvvjtpdnstjwjvv.supabase.co',
    'sb_publishable_DwFD22YKXPAoq1wYbnrY5A_we0Id-cB',
  );

  try {
    final res = await client.from('payment_references').select().limit(1);
    if (res.isNotEmpty) {
      print('Payment References Columns: ${res.first.keys.toList()}');
    } else {
      print('Payment References table is empty.');
    }
  } catch (e) {
    print('Payment References Error: $e');
  }
  exit(0);
}
