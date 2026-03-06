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
    final res = await client
        .from('service_requests')
        .select()
        .limit(1)
        .single();
    print('DEBUG: Request Data:');
    print(res);
    print('DEBUG: Keys: ${res.keys.toList()}');
  } catch (e) {
    print('Error: $e');
  }
  exit(0);
}
