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

    print('--- Payments Table Sample ---');
    try {
      final res = await client.from('payments').select().limit(1);
      print(res);
    } catch (e) {
      print('Payments table error: $e');
    }

    print('\n--- Jobs Table Sample ---');
    try {
      final res = await client.from('jobs').select().limit(1);
      print(res);
    } catch (e) {
      print('Jobs table error: $e');
    }
  } catch (e) {
    print('Global Error: $e');
  }
  exit(0);
}
