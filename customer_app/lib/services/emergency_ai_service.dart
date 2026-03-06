import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/env.dart';

/// Calls OpenRouter API to generate a structured emergency summary.
class EmergencyAiService {
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _model = 'openai/gpt-3.5-turbo';

  /// Generates a short, formatted emergency alert message.
  ///
  /// transcription -- raw speech-to-text captured during the SOS.
  /// customerName -- name of the customer in distress.
  ///
  /// Returns a string in the format:
  ///   🚨 Emergency Alert
  ///
  ///   <Name> is facing an emergency: <concise issue description>.
  static Future<String> generateEmergencySummary(
    String transcription,
    String customerName,
  ) async {
    // Priority: OpenRouter key, then fallback to Gemini key (per user's "already in project" comment)
    String apiKey = Env.openRouterApiKey;
    if (apiKey.isEmpty || apiKey.contains('YOUR_OPENROUTER')) {
      apiKey = Env.geminiApiKey;
    }

    // Fallback if both are missing
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      return _fallback(customerName);
    }

    // Fallback if no speech was captured
    if (transcription.trim().isEmpty) {
      return _fallback(customerName);
    }

    final prompt = '''
You are an emergency alert system. 
A person named "$customerName" has triggered an SOS and said: "$transcription"

Generate a SHORT, CLEAR emergency alert message.

Rules:
- Do NOT use phrases like "immediate assistance required" or "user's location"
- Keep it under 15 words after the colon
- Format MUST be exactly:
  🚨 Emergency Alert

  $customerName is facing an emergency: <concise description of the issue>.

Return ONLY the formatted message. Nothing else.
''';

    try {
      final response = await http
          .post(
            Uri.parse(_openRouterUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer': 'https://neara.app',
              'X-Title': 'Neara Emergency SOS',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'max_tokens': 80,
              'temperature': 0.3,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content =
            data['choices']?[0]?['message']?['content'] as String?;
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
    } catch (_) {
      // Fall through to fallback
    }

    return _fallback(customerName);
  }

  static String _fallback(String customerName) {
    return '🚨 Emergency Alert\n\n$customerName is facing an emergency and needs help.';
  }
}
