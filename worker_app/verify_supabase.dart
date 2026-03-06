import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  try {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    print('Connected to Supabase. Fetching service_requests...');
    final client = Supabase.instance.client;

    // Fetch all requests without filter
    final allRes = await client.from('service_requests').select().limit(5);
    print('All requests (limit 5):');
    print(allRes);

    // Fetch filtering on status
    final filterRes = await client
        .from('service_requests')
        .select()
        .inFilter('status', ['CREATED', 'MATCHING'])
        .limit(5);
    print('\nFiltered requests (status in CREATED, MATCHING):');
    print(filterRes);
  } catch (e) {
    print('Error: \$e');
  }
  exit(0);
}
