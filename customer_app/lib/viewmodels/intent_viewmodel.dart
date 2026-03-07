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
  /// Timer that auto-stops recording after [_maxRecordDuration].
  /// Sarvam is a batch API with no streaming, so silence detection is not
  /// possible; the user must tap Stop or wait for this timer.
  Timer? _maxDurationTimer;

  /// Maximum recording duration before auto-submitting to Sarvam.
  static const Duration _maxRecordDuration = Duration(seconds: 60);

  @override
  IntentState build() {
    ref.onDispose(_cancelTimers);
    return IntentIdle();
  }

  void _cancelTimers() {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
  }

  Future<void> startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      state = IntentError('Microphone permission denied');
      return;
    }

    state = IntentListening('');
    _cancelTimers();

    // Auto-stop after the max duration so the user is never stuck.
    _maxDurationTimer = Timer(_maxRecordDuration, () {
      if (state is IntentListening) stopRecordingAndAnalyze();
    });

    try {
      final sttService = ref.read(sttServiceProvider);
      await sttService.startRecording();
    } catch (e) {
      _cancelTimers();
      state = IntentError(e.toString());
    }
  }

  /// Cancels an in-progress recording and returns to idle.
  /// Used when the user navigates away mid-recording.
  Future<void> cancelRecording() async {
    if (state is! IntentListening) return;
    _cancelTimers();
    final sttService = ref.read(sttServiceProvider);
    await sttService.cancelRecording();
    state = IntentEmpty();
    Future.delayed(const Duration(seconds: 2), () {
      if (state is IntentEmpty) state = IntentIdle();
    });
  }

  Future<void> stopRecordingAndAnalyze() async {
    if (state is! IntentListening) return;

    _cancelTimers();
    state = IntentProcessing();

    try {
      final sttService = ref.read(sttServiceProvider);
      final transcript = await sttService.stopAndTranscribe();

      if (transcript.trim().isEmpty) {
        state = IntentEmpty();
        Future.delayed(const Duration(seconds: 2), () {
          if (state is IntentEmpty) state = IntentIdle();
        });
        return;
      }

      final aiService = ref.read(aiIntentServiceProvider);
      final intent = await aiService.analyzeIntent(transcript.trim());
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
