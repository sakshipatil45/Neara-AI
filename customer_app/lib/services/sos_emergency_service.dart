// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../core/env.dart';

// Reuse the same channel registered in MainActivity.kt
const _kSosChannel = MethodChannel('com.example.customer_app/sos_shortcut');

/// Handles AI summarization and background SMS sending for Emergency SOS.
class SosEmergencyService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'meta-llama/llama-3.1-8b-instruct:free';
  static const Duration _timeout = Duration(seconds: 12);

  // ── AI Summarization ──────────────────────────────────────────────────────

  /// Returns a short formatted emergency summary.
  ///
  /// Format examples:
  ///   🚨 Emergency Alert
  ///
  ///   Fire reported at Sakshi's location.
  ///   Accident reported near Rahul.
  Future<String> summarize({
    required String transcript,
    required String customerName,
  }) async {
    if (transcript.trim().isEmpty) {
      return '🚨 Emergency Alert\n\nEmergency SOS triggered by $customerName.';
    }

    try {
      final apiKey = Env.openRouterApiKey;
      if (apiKey.isEmpty || apiKey == 'YOUR_OPENROUTER_API_KEY_HERE') {
        return _fallbackSummary(transcript, customerName);
      }

      final systemPrompt = '''
You are an emergency alert message generator.
Given a voice transcript of someone in an emergency, generate ONE short alert message.

STRICT FORMAT — output ONLY this, nothing else:
🚨 Emergency Alert

<brief description of what happened> near <Name> OR at <Name>'s location.

RULES:
- Do NOT use the word "user".
- Do NOT say "Immediate assistance required".
- Do NOT say "user's location".
- Use the person's name naturally (e.g. "near Sakshi", "at Sakshi's location").
- Keep the description SHORT — 5-8 words maximum.
- Use natural language. Examples:
    "Fire reported at Sakshi's location."
    "Accident reported near Rahul."
    "Medical emergency near Priya."
    "Gas leak reported at Aman's location."
- Output ONLY the two-line message. No extra text.
''';

      final userMessage =
          'Customer name: $customerName\nTranscript: "$transcript"';

      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://neara.app',
              'X-Title': 'Neara Customer App',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': userMessage},
              ],
              'temperature': 0.2,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            (data['choices'][0]['message']['content'] as String).trim();
        print('✅ SOS AI summary: $content');
        if (content.contains('Emergency Alert')) return content;
        return '🚨 Emergency Alert\n\n$content';
      } else {
        print('⚠️ OpenRouter ${response.statusCode}: ${response.body}');
        return _fallbackSummary(transcript, customerName);
      }
    } on TimeoutException {
      print('⏱️ SOS AI timeout');
      return _fallbackSummary(transcript, customerName);
    } catch (e) {
      print('❌ SOS AI error: $e');
      return _fallbackSummary(transcript, customerName);
    }
  }

  String _fallbackSummary(String transcript, String name) {
    final t = transcript.toLowerCase();
    String issue;
    if (t.contains('fire')) {
      issue = "Fire reported at $name's location.";
    } else if (t.contains('accident')) {
      issue = 'Accident reported near $name.';
    } else if (t.contains('medical') ||
        t.contains('ambulance') ||
        t.contains('hospital')) {
      issue = 'Medical emergency near $name.';
    } else if (t.contains('theft') ||
        t.contains('robbery') ||
        t.contains('attack')) {
      issue = 'Security threat near $name.';
    } else if (t.contains('gas') || t.contains('leak')) {
      issue = "Gas leak at $name's location.";
    } else {
      issue = 'Emergency SOS triggered by $name.';
    }
    return '🚨 Emergency Alert\n\n$issue';
  }

  // ── Background SMS via native SmsManager ─────────────────────────────────

  /// Sends SMS **silently in the background** via Android SmsManager.
  /// Requests SEND_SMS runtime permission if not already granted.
  Future<void> sendSmsToContacts({
    required String summary,
    required String locationLink,
    required List<String> phones,
  }) async {
    if (phones.isEmpty) return;

    // ── Request SMS permission at runtime ──────────────────────────────────
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      print('📋 Requesting SEND_SMS permission...');
      final result = await Permission.sms.request();
      if (!result.isGranted) {
        print('❌ SEND_SMS permission denied (${result.name}). SMS not sent.');
        if (result.isPermanentlyDenied) {
          print('⚙️  User must enable SMS in App Settings.');
        }
        return;
      }
    }
    print('✅ SEND_SMS permission granted');

    final body = '$summary\n\nLive Location:\n$locationLink';

    for (final phone in phones) {
      try {
        final ok = await _kSosChannel.invokeMethod<bool>('sendSms', {
          'phone': phone,
          'message': body,
        });
        print('📲 SMS to $phone: ${ok == true ? "sent" : "failed"}');
      } catch (e) {
        print('❌ SMS to $phone: $e');
      }
    }
  }
}
