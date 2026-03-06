import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;

  Future<bool> init() async {
    if (!_isInitialized) {
      _isInitialized = await _speech.initialize(
        onError: (error) => debugPrint('STT Error: $error'),
        onStatus: (status) => debugPrint('STT Status: $status'),
      );
    }
    return _isInitialized;
  }

  /// Starts listening to the microphone.
  /// [localeId] controls the transcription language (e.g., 'en-IN', 'hi-IN', 'mr-IN').
  Future<void> startListening({
    required Function(String text) onResult,
    String localeId = 'en-IN',
  }) async {
    final ready = await init();
    if (ready) {
      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        localeId: localeId,
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } else {
      throw Exception('Speech to Text initialization failed');
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  bool get isListening => _speech.isListening;
  
  Future<List<stt.LocaleName>> getLocales() async {
     final ready = await init();
     if(ready){
       return await _speech.locales();
     }
     return [];
  }
}
