import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get openRouterApiKey {
    return dotenv.env['OPENROUTER_API_KEY'] ?? '';
  }
}
