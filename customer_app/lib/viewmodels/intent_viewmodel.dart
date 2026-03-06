import 'dart:async';
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
  final EmergencyInterpretation intent;
  IntentSuccess(this.intent);
}

class IntentError extends IntentState {
  final String message;
  IntentError(this.message);
}

/// Shown when recording stopped but no speech was detected.
class IntentEmpty extends IntentState {}

// ----- PROVIDERS -----
final sttServiceProvider = Provider<SttService>((ref) => SttService());
final aiIntentServiceProvider = Provider<AiIntentService>(
  (ref) => AiIntentService(),
);

/// The locale the user has chosen for speech recognition.
/// `null` means auto-detect from device locale.
final selectedLocaleProvider =
    NotifierProvider<SelectedLocaleNotifier, String?>(
      SelectedLocaleNotifier.new,
    );

class SelectedLocaleNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void select(String? locale) => state = locale;
}

final intentViewModelProvider = NotifierProvider<IntentViewModel, IntentState>(
  () {
    return IntentViewModel();
  },
);

// ----- VIEW MODEL -----
class IntentViewModel extends Notifier<IntentState> {
  String _lastRecognizedWords = '';

  /// Timer that fires if the user hasn't spoken anything after [_noSpeechTimeout].
  Timer? _noSpeechTimer;

  /// Timer that fires if speech has started but there's been [_silenceTimeout] of silence.
  Timer? _silenceTimer;

  /// How long to wait for ANY speech before auto-cancelling (user tapped but didn't speak).
  static const Duration _noSpeechTimeout = Duration(seconds: 5);

  /// How long of silence (after some speech) before auto-submitting.
  static const Duration _silenceTimeout = Duration(seconds: 2);

  @override
  IntentState build() {
    ref.onDispose(_cancelTimers);
    return IntentIdle();
  }

  void _cancelTimers() {
    _noSpeechTimer?.cancel();
    _noSpeechTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = IntentError('Microphone permission denied');
      return;
    }

    _lastRecognizedWords = '';
    state = IntentListening('');
    _cancelTimers();

    // If the user taps but says nothing within 5s → cancel gracefully
    _noSpeechTimer = Timer(_noSpeechTimeout, () {
      if (state is IntentListening && _lastRecognizedWords.trim().isEmpty) {
        _cancelRecording();
      }
    });

    try {
      final sttService = ref.read(sttServiceProvider);
      final localeOverride = ref.read(selectedLocaleProvider);
      await sttService.startListening(
        localeOverride: localeOverride,
        onResult: (words) {
          _lastRecognizedWords = words;
          if (state is IntentListening) {
            state = IntentListening(words);

            if (words.trim().isNotEmpty) {
              // Speech detected → cancel the no-speech watchdog
              _noSpeechTimer?.cancel();
              _noSpeechTimer = null;

              // Reset silence timer on every new word
              _silenceTimer?.cancel();
              _silenceTimer = Timer(_silenceTimeout, () {
                if (state is IntentListening) {
                  stopRecordingAndAnalyze();
                }
              });
            }
          }
        },
      );
    } catch (e) {
      _cancelTimers();
      state = IntentError(e.toString());
      ref.read(sttServiceProvider).stopListening();
    }
  }

  /// Called when the user has tapped without saying anything (no-speech timeout).
  Future<void> _cancelRecording() async {
    _cancelTimers();
    final sttService = ref.read(sttServiceProvider);
    await sttService.stopListening();
    state = IntentEmpty();
    // Auto-reset back to idle after a brief moment
    Future.delayed(const Duration(seconds: 2), () {
      if (state is IntentEmpty) state = IntentIdle();
    });
  }

  Future<void> stopRecordingAndAnalyze() async {
    if (state is! IntentListening) return;

    _cancelTimers();
    final sttService = ref.read(sttServiceProvider);
    await sttService.stopListening();

    final trimmed = _lastRecognizedWords.trim();
    if (trimmed.isEmpty) {
      // User tapped stop without saying anything
      state = IntentEmpty();
      Future.delayed(const Duration(seconds: 2), () {
        if (state is IntentEmpty) state = IntentIdle();
      });
      return;
    }

    state = IntentProcessing();

    try {
      final aiService = ref.read(aiIntentServiceProvider);
      final intent = await aiService.analyzeIntent(trimmed);
      state = IntentSuccess(intent);
    } catch (e) {
      state = IntentError('Failed to analyze audio: $e');
    }
  }

  void reset() {
    _cancelTimers();
    state = IntentIdle();
  }
}
