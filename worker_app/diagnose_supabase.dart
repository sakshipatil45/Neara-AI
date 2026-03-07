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

    print('DEBUG: Connected to Supabase Diagnostics');
    final client = Supabase.instance.client;

    // 1. Check Tables
    print('\n--- CHECKING TABLES ---');
    try {
      final res = await client.from('service_requests').select('id').limit(1);
      print('✓ service_requests table: OK');
    } catch (e) {
      print('✗ service_requests table: $e');
    }

    try {
      final res = await client.from('proposals').select('id').limit(1);
      print('✓ proposals table: OK');
    } catch (e) {
      print('✗ proposals table: $e');
    }

    // 2. Check Storage
    print('\n--- CHECKING STORAGE ---');
    try {
      final buckets = await client.storage.listBuckets();
      print('Available Buckets: ${buckets.map((b) => b.name).toList()}');

      final bool exists = buckets.any((b) => b.name == 'job-documentation');
      if (exists) {
        print('✓ bucket "job-documentation": EXISTS');
      } else {
        print('✗ bucket "job-documentation": MISSING');
        print('Attempting to create "job-documentation" bucket...');
        try {
          await client.storage.createBucket(
            'job-documentation',
            const BucketOptions(public: true),
          );
          print('✓ bucket "job-documentation": CREATED SUCCESSFULLY');
        } catch (e) {
          print('✗ Failed to create bucket: $e');
          print(
            'NOTE: You might need to create it manually in Supabase Dashboard.',
          );
        }
      }
    } catch (e) {
      print('✗ Storage Access Error: $e');
    }

    // 3. Test Upload (Small text file)
    print('\n--- TESTING UPLOAD ---');
    try {
      final tempFile = File('upload_test.txt');
      await tempFile.writeAsString('test content');

      final path = 'tests/test_${DateTime.now().millisecondsSinceEpoch}.txt';
      await client.storage.from('job-documentation').upload(path, tempFile);
      print('✓ Upload test: SUCCESS');

      final publicUrl = client.storage
          .from('job-documentation')
          .getPublicUrl(path);
      print('✓ Public URL: $publicUrl');

      // Cleanup
      await client.storage.from('job-documentation').remove([path]);
      await tempFile.delete();
      print('✓ Cleanup test: SUCCESS');
    } catch (e) {
      print('✗ Upload test: FAILED - $e');
    }
  } catch (e) {
    print('GLOBAL ERROR: $e');
  }
  exit(0);
}
