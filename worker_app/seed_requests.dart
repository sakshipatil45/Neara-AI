import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

void main() async {
  try {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    print('Connected to Supabase. Seeding service_requests...');
    final client = Supabase.instance.client;

    // Create a mock request
    final mockRequest = {
      'service_category': 'Electrical Repair',
      'location_name': 'Koramangala, Bangalore',
      'issue_description':
          'The main fuse keeps tripping whenever I turn on the AC. Need an urgent check-up.',
      'estimated_payment': '₹500 - ₹800',
      'status': 'CREATED',
      'customer_id': '00000000-0000-0000-0000-000000000000', // Mock UUID
      'created_at': DateTime.now().toIso8601String(),
    };

    final res = await client
        .from('service_requests')
        .insert(mockRequest)
        .select();
    print('Successfully inserted mock request:');
    print(res);

    // Create another one
    final mockRequest2 = {
      'service_category': 'Plumbing Repair',
      'location_name': 'Indiranagar, Bangalore',
      'issue_description':
          'Kitchen sink is leaking and causing water damage to the cabinets below.',
      'estimated_payment': '₹300 - ₹450',
      'status': 'CREATED',
      'customer_id': '00000000-0000-0000-0000-000000000000',
      'created_at': DateTime.now().toIso8601String(),
    };

    await client.from('service_requests').insert(mockRequest2);
    print('Successfully inserted second mock request.');
  } catch (e) {
    print('Error seeding data: $e');
  }
  exit(0);
}
