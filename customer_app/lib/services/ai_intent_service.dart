import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/env.dart';
import '../models/service_intent_model.dart';

class AiIntentService {
  late final GenerativeModel _model;

  AiIntentService() {
    final apiKey = Env.geminiApiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      throw Exception('GEMINI_API_KEY is missing from .env');
    }
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  /// Takes transcribed user audio text (in English, Hindi, or Marathi)
  /// and asks Gemini to parse it into a ServiceIntentModel.
  Future<ServiceIntentModel> analyzeIntent(String text) async {
    final prompt = '''
You are an intelligent intent parser for an emergency and hyperlocal service application in India.
The user will provide a text input (which might be in English, Hindi, or Marathi) describing a problem they are facing.
Your goal is to extract the core service required, determine the urgency, and summarize the issue clearly.

Possible `service_category` examples: plumber, electrician, mechanic, appliance_repair, roadside_assistance, etc.
Possible `urgency` values: low, medium, high.

Translate the summary to English if it is in another language, but keep it very short and descriptive.

Return ONLY a valid JSON object matching this exact format:
{
  "service_category": "string",
  "urgency": "string",
  "summary": "string"
}

User Input: "$text"
''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    
    final responseText = response.text;
    if (responseText == null) {
      throw Exception('Failed to generate AI response');
    }

    // Clean JSON response if it's wrapped in markdown blocks
    String cleanJson = responseText;
    if (cleanJson.startsWith('```json')) {
      cleanJson = cleanJson.substring(7);
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
    } else if (cleanJson.startsWith('```')) {
      cleanJson = cleanJson.substring(3);
      if (cleanJson.endsWith('```')) {
        cleanJson = cleanJson.substring(0, cleanJson.length - 3);
      }
    }

    try {
      final jsonMap = json.decode(cleanJson.trim());
      return ServiceIntentModel.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to decode AI response into JSON: $e\nResponse: $responseText');
    }
  }
}
