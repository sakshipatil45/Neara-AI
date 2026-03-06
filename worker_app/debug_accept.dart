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

    final client = Supabase.instance.client;

    print('--- Checking service_requests table ---');
    final reqs = await client.from('service_requests').select().limit(1);
    if (reqs.isEmpty) {
      print('service_requests table is empty');
    } else {
      print('Sample request: ${reqs.first}');
      print('Columns: ${reqs.first.keys.toList()}');
    }

    print('\n--- Checking workers table ---');
    final workers = await client.from('workers').select().limit(1);
    if (workers.isEmpty) {
      print('workers table is empty');
    } else {
      print('Sample worker: ${workers.first}');
      print('Columns: ${workers.first.keys.toList()}');
    }

    print('\n--- Checking users table ---');
    final users = await client.from('users').select().limit(1);
    if (users.isEmpty) {
      print('users table is empty');
    } else {
      print('Sample user: ${users.first}');
      print('Columns: ${users.first.keys.toList()}');
    }
  } catch (e) {
    print('Detailed Error: $e');
  }
  exit(0);
}
