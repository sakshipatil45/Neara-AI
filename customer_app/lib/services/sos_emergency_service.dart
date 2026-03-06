// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter_sms/flutter_sms.dart';
import 'package:http/http.dart' as http;

import '../core/env.dart';

/// Handles AI summarization and SMS sending for the Emergency SOS feature.
class SosEmergencyService {
  static const String _baseUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'meta-llama/llama-3.1-8b-instruct:free';
  static const Duration _timeout = Duration(seconds: 12);

  // ── AI Summarization ──────────────────────────────────────────────────────

  /// Takes the raw speech-to-text [transcript] and [customerName],
  /// returns a short, formatted emergency summary string.
  ///
  /// Format:
  ///   🚨 Emergency Alert
  ///
  ///   <Name> is facing an emergency: <short issue>.
  Future<String> summarize({
    required String transcript,
    required String customerName,
  }) async {
    if (transcript.trim().isEmpty) {
      return '🚨 Emergency Alert\n\n$customerName has triggered an emergency SOS.';
    }

    try {
      final apiKey = Env.openRouterApiKey;
      if (apiKey.isEmpty || apiKey == 'YOUR_OPENROUTER_API_KEY_HERE') {
        return _fallbackSummary(transcript, customerName);
      }

      final systemPrompt = '''
You are an emergency alert message generator.
Given a voice transcript of someone in an emergency, generate ONE short message.

Rules:
- Output ONLY the message, no extra text.
- Format EXACTLY like this (fill in the blanks):
🚨 Emergency Alert

<Name> is facing an emergency: <brief issue in 5-8 words>.

- Replace <Name> with the customer name provided.
- Replace <brief issue> with a concise description of what they described.
- Do NOT say "Immediate assistance required".
- Do NOT say "user's location".
- Keep it natural and human.
- Maximum 2 lines total after the header.
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
        // Ensure the summary starts with the emoji header
        if (content.contains('Emergency Alert')) return content;
        return '🚨 Emergency Alert\n\n$customerName is facing an emergency: $content';
      } else {
        print('⚠️ OpenRouter error ${response.statusCode}: ${response.body}');
        return _fallbackSummary(transcript, customerName);
      }
    } on TimeoutException {
      print('⏱️ SOS AI timeout — using fallback');
      return _fallbackSummary(transcript, customerName);
    } catch (e) {
      print('❌ SOS AI error: $e — using fallback');
      return _fallbackSummary(transcript, customerName);
    }
  }

  String _fallbackSummary(String transcript, String name) {
    final t = transcript.toLowerCase();
    String issue;
    if (t.contains('fire')) {
      issue = 'Fire reported nearby.';
    } else if (t.contains('accident')) {
      issue = 'Accident reported.';
    } else if (t.contains('medical') || t.contains('ambulance') || t.contains('hospital')) {
      issue = 'Medical emergency.';
    } else if (t.contains('theft') || t.contains('robbery') || t.contains('attack')) {
      issue = 'Security threat reported.';
    } else if (t.contains('gas') || t.contains('leak')) {
      issue = 'Gas leak reported.';
    } else if (transcript.trim().isNotEmpty) {
      final trimmed = transcript.trim();
      issue = trimmed.length > 60 ? '${trimmed.substring(0, 57)}...' : trimmed;
    } else {
      issue = 'Emergency SOS activated.';
    }
    return '🚨 Emergency Alert\n\n$name is facing an emergency: $issue';
  }

  // ── SMS Sending ───────────────────────────────────────────────────────────

  /// Sends an SMS to all [phones] with the [summary] and [locationLink].
  Future<void> sendSmsToContacts({
    required String summary,
    required String locationLink,
    required List<String> phones,
  }) async {
    if (phones.isEmpty) return;

    final body = '$summary\n\nLive Location:\n$locationLink';

    try {
      final result = await sendSMS(message: body, recipients: phones);
      print('📲 SMS result: $result');
    } catch (e) {
      print('❌ SMS send error: $e');
    }
  }
}
