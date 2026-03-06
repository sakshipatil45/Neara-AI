import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_intent_service.dart';
import '../services/stt_service.dart';
import '../models/service_intent_model.dart';
import 'package:permission_handler/permission_handler.dart';

// ----- STATES -----
abstract class IntentState {}

class IntentIdle extends IntentState {}

class IntentListening extends IntentState {
  final String currentWords;
  IntentListening(this.currentWords);
}

class IntentProcessing extends IntentState {}

class IntentSuccess extends IntentState {
  final ServiceIntentModel intent;
  IntentSuccess(this.intent);
}

class IntentError extends IntentState {
  final String message;
  IntentError(this.message);
}

// ----- PROVIDERS -----
final sttServiceProvider = Provider<SttService>((ref) => SttService());
final aiIntentServiceProvider = Provider<AiIntentService>((ref) => AiIntentService());

final intentViewModelProvider = NotifierProvider<IntentViewModel, IntentState>(() {
  return IntentViewModel();
});

// ----- VIEW MODEL -----
class IntentViewModel extends Notifier<IntentState> {
  String currentLocale = 'en-IN'; // Default locale
  String _lastRecognizedWords = '';

  @override
  IntentState build() {
    return IntentIdle();
  }

  void setLocale(String localeId) {
    currentLocale = localeId;
  }

  Future<void> startRecording() async {
    // Check permission
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = IntentError('Microphone permission denied');
      return;
    }

    _lastRecognizedWords = '';
    state = IntentListening('');

    try {
      final sttService = ref.read(sttServiceProvider);
      await sttService.startListening(
        localeId: currentLocale,
        onResult: (words) {
          _lastRecognizedWords = words;
          // Update UI with partial results safely if still listening
          if (state is IntentListening) {
            state = IntentListening(words);
          }
        },
      );
    } catch (e) {
      state = IntentError(e.toString());
      ref.read(sttServiceProvider).stopListening();
    }
  }

  Future<void> stopRecordingAndAnalyze() async {
    if (state is! IntentListening) return;
    
    final sttService = ref.read(sttServiceProvider);
    await sttService.stopListening();
    state = IntentProcessing();

    if (_lastRecognizedWords.trim().isEmpty) {
      // If no words were parsed by STT, reset to idle
      state = IntentIdle();
      return;
    }

    try {
      final aiService = ref.read(aiIntentServiceProvider);
      final intent = await aiService.analyzeIntent(_lastRecognizedWords);
      state = IntentSuccess(intent);
    } catch (e) {
      state = IntentError('Failed to analyze audio: $e');
    }
  }
  
  // Helper to reset back to idle after a success/error
  void reset() {
    state = IntentIdle();
  }
}
