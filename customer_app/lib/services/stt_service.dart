import 'package:flutter/widgets.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  /// Supported locales — order is fallback priority only (device locale is checked first).
  static const List<String> _supportedLocales = ['hi-IN', 'mr-IN', 'en-IN'];

  /// Language codes that should produce Devanagari output.
  static const Set<String> _devanagariLangs = {'hi', 'mr', 'ne', 'bho', 'mai'};

  Future<bool> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );
    }
    return _isInitialized;
  }

  /// Picks the best locale for the current device language.
  ///
  /// Priority:
  /// 1. Device system locale (e.g. hi-IN → Devanagari output, mr-IN → Devanagari)
  /// 2. First supported locale available on the device
  /// 3. Hard-coded fallback to en-IN
  Future<String> _resolveAutoLocale() async {
    final available = await _speech.locales();
    final availableIds = available.map((l) => l.localeId).toSet();

    // 1. Honour the device system locale so Hindi/Marathi users get Devanagari.
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    final lang = deviceLocale.languageCode; // 'hi', 'mr', 'en', …
    final country = deviceLocale.countryCode ?? 'IN';
    final exact = '$lang-$country'; // e.g. 'hi-IN'

    if (availableIds.contains(exact) && _supportedLocales.contains(exact)) {
      debugPrint('STT locale from device system locale: $exact');
      return exact;
    }

    // Partial match: device language with '-IN' suffix (handles 'hi-US' device → 'hi-IN')
    if (_devanagariLangs.contains(lang)) {
      final indiaVariant = '$lang-IN';
      if (availableIds.contains(indiaVariant)) {
        debugPrint('STT locale from device language ($lang): $indiaVariant');
        return indiaVariant;
      }
    }

    // 2. Fallback: first supported locale available on the device.
    for (final preferred in _supportedLocales) {
      if (availableIds.contains(preferred)) {
        debugPrint('STT locale fallback: $preferred');
        return preferred;
      }
    }

    debugPrint('STT locale hard-coded fallback: en-IN');
    return 'en-IN';
  }

  /// Starts listening.
  ///
  /// Pass [localeOverride] (e.g. `'hi-IN'`) to force a specific language.
  /// If omitted, the device system locale is used with fallback to en-IN.
  Future<void> startListening({
    required Function(String text) onResult,
    String? localeOverride,
  }) async {
    final ready = await init();
    if (!ready) throw Exception('Speech to Text initialization failed');

    final localeId = localeOverride ?? await _resolveAutoLocale();
    debugPrint(
      'STT locale: $localeId${localeOverride != null ? " (user-selected)" : " (auto-resolved)"}',
    );

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
      },
      localeId: localeId,
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
        // Listen for up to 30s; silence timeout handled in ViewModel
        listenMode: stt.ListenMode.dictation,
      ),
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;

  Future<List<stt.LocaleName>> getLocales() async {
    final ready = await init();
    if (ready) return await _speech.locales();
    return [];
  }
}
