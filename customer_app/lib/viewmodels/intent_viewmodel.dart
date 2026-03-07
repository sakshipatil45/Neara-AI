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
  Timer? _maxDurationTimer;

  /// Silence detection via periodic amplitude polling.
  Timer? _pollTimer;
  Timer? _silenceTimer;

  /// Auto-stops recording if the user never speaks within this window.
  Timer? _noSpeechTimer;
  bool _hasSpeechStarted = false;

  /// dBFS above this = speech detected (0 = max, -160 = total silence).
  static const double _silenceThresholdDb = -40.0;

  /// How long silence must persist after speech before auto-stopping.
  static const Duration _silenceDelay = Duration(milliseconds: 1500);

  /// Maximum recording duration (hard cap).
  static const Duration _maxRecordDuration = Duration(seconds: 60);

  /// If no speech is detected within this time, auto-cancel recording.
  static const Duration _noSpeechTimeout = Duration(seconds: 7);

  @override
  IntentState build() {
    ref.onDispose(_cancelTimers);
    return IntentIdle();
  }

  void _cancelTimers() {
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    _noSpeechTimer?.cancel();
    _noSpeechTimer = null;
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

      // ── Silence / no-speech detection via polling ────────────────────
      // Poll amplitude every 150 ms.
      // • Before first speech: cancel after _noSpeechTimeout (user never spoke).
      // • After speech starts: silence countdown triggers auto-stop.
      _hasSpeechStarted = false;

      // If the user never speaks within the timeout, cancel and show hint.
      _noSpeechTimer = Timer(_noSpeechTimeout, () {
        if (state is IntentListening && !_hasSpeechStarted) {
          _cancelAndShowEmpty();
        }
      });

      _pollTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
        if (state is! IntentListening) {
          _pollTimer?.cancel();
          return;
        }
        final db = await sttService.getAmplitudeDb();
        if (db > _silenceThresholdDb) {
          // Speech detected — kill the no-speech watchdog.
          _hasSpeechStarted = true;
          _noSpeechTimer?.cancel();
          _noSpeechTimer = null;
          _silenceTimer?.cancel();
          _silenceTimer = null;
        } else if (_hasSpeechStarted) {
          _silenceTimer ??= Timer(_silenceDelay, () {
            if (state is IntentListening) stopRecordingAndAnalyze();
          });
        }
      });
    } catch (e) {
      _cancelTimers();
      state = IntentError(e.toString());
    }
  }

  /// Stops recording immediately when no speech was detected.
  Future<void> _cancelAndShowEmpty() async {
    _cancelTimers();
    final sttService = ref.read(sttServiceProvider);
    await sttService.cancelRecording();
    state = IntentEmpty();
    Future.delayed(const Duration(seconds: 2), () {
      if (state is IntentEmpty) state = IntentIdle();
    });
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

    // If no speech was detected at all, skip the API call entirely.
    if (!_hasSpeechStarted) {
      final sttService = ref.read(sttServiceProvider);
      await sttService.cancelRecording();
      state = IntentEmpty();
      Future.delayed(const Duration(seconds: 2), () {
        if (state is IntentEmpty) state = IntentIdle();
      });
      return;
    }

    state = IntentProcessing();

    try {
      final sttService = ref.read(sttServiceProvider);
      final rawTranscript = await sttService.stopAndTranscribe();

      // Preprocess and validate transcript
      final cleanedTranscript = _preprocessTranscript(rawTranscript);

      if (cleanedTranscript == null) {
        state = IntentEmpty();
        Future.delayed(const Duration(seconds: 2), () {
          if (state is IntentEmpty) state = IntentIdle();
        });
        return;
      }

      final aiService = ref.read(aiIntentServiceProvider);
      final intent = await aiService.analyzeIntent(cleanedTranscript);
      state = IntentSuccess(intent);
    } catch (e) {
      state = IntentError('Failed to analyze audio: $e');
    }
  }

  // ── Text Preprocessing ────────────────────────────────────────────────

  /// Normalizes text by removing extra whitespace, filler words, and cleaning punctuation.
  String _normalizeText(String text) {
    return text
        .trim()
        .toLowerCase()
        // Remove extra whitespace
        .replaceAll(RegExp(r'\s+'), ' ')
        // Remove common filler words
        .replaceAll(RegExp(r'\b(um|uh|er|ah|like|you know|so|well)\b'), '')
        // Clean excessive punctuation but keep basic ones
        .replaceAll(RegExp(r'[.]{2,}'), '.')
        .replaceAll(RegExp(r'[!]{2,}'), '!')
        .replaceAll(RegExp(r'[?]{2,}'), '?')
        // Remove extra spaces again after filler word removal
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Detects if text contains gibberish or meaningless patterns.
  bool _isGibberish(String text) {
    if (text.length < 2) return true;

    // Check for repeated characters (aaaaa, hehehe)
    if (RegExp(r'(.)\1{4,}').hasMatch(text)) {
      return true;
    }

    // Check for excessive repeated patterns (lalala, nanana)
    if (RegExp(r'(\w{1,3})\1{3,}').hasMatch(text)) {
      return true;
    }

    final words = text.split(' ');
    if (words.isEmpty) return true;

    int problematicWords = 0;

    for (final word in words) {
      if (word.length < 1) continue;

      // Very long words are suspicious (>20 chars)
      if (word.length > 20) {
        problematicWords++;
        continue;
      }

      // Words with no vowels (except very short ones)
      if (word.length > 3 && !RegExp(r'[aeiouAEIOU]').hasMatch(word)) {
        problematicWords++;
        continue;
      }

      // Words that are just repeated characters
      if (RegExp(r'^(.)\1+$').hasMatch(word)) {
        problematicWords++;
      }
    }

    // If more than 40% of words seem problematic, it's likely gibberish
    return problematicWords > (words.length * 0.4);
  }

  /// Validates if text has reasonable language characteristics.
  bool _isValidLanguage(String text) {
    if (text.length < 2) return false;

    // Check for reasonable character distribution
    final hasDevanagari = RegExp(r'[\u0900-\u097F]').hasMatch(text);
    final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(text);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(text);
    final hasOtherScripts = RegExp(
      r'[\u0980-\u0CFF]',
    ).hasMatch(text); // Bengali, Tamil, etc.

    // Should have at least some recognizable script
    if (!hasDevanagari && !hasLatin && !hasOtherScripts) {
      return false;
    }

    // Check for random symbol spam
    final symbolCount = RegExp(r'[^\w\s\u0900-\u0CFF]').allMatches(text).length;
    return symbolCount < (text.length * 0.3); // Less than 30% symbols
  }

  /// Validates if text length is within reasonable bounds.
  bool _isValidLength(String text) {
    final words = text.trim().split(RegExp(r'\s+'));
    // Should have 1-50 words for a reasonable voice request
    return words.length >= 1 && words.length <= 50 && text.length <= 500;
  }

  /// Preprocesses transcript with validation and normalization.
  /// Returns null if transcript is invalid/gibberish.
  String? _preprocessTranscript(String rawTranscript) {
    final cleaned = rawTranscript.trim();

    // Basic validation
    if (cleaned.isEmpty) {
      return null;
    }

    // Length validation
    if (!_isValidLength(cleaned)) {
      print(
        'STT: Invalid length - transcript: "${cleaned.substring(0, cleaned.length > 50 ? 50 : cleaned.length)}..."',
      );
      return null;
    }

    // Language validation
    if (!_isValidLanguage(cleaned)) {
      print(
        'STT: Invalid language/script detected in: "${cleaned.substring(0, cleaned.length > 50 ? 50 : cleaned.length)}..."',
      );
      return null;
    }

    // Normalize text
    final normalized = _normalizeText(cleaned);

    // Gibberish detection (after normalization)
    if (_isGibberish(normalized)) {
      print('STT: Gibberish detected in normalized text: "$normalized"');
      return null;
    }

    // Final validation - ensure we still have meaningful content
    if (normalized.isEmpty || normalized.length < 2) {
      return null;
    }

    print('STT: Preprocessed "$rawTranscript" → "$normalized"');
    return normalized;
  }

  void reset() {
    _cancelTimers();
    state = IntentIdle();
  }
}
