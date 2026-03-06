import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get geminiApiKey {
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  static String get openRouterApiKey {
    return dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }
}
