import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/stt_service.dart';

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SosState {}

class SosIdle extends SosState {}

class SosListening extends SosState {
  final String currentWords;
  SosListening(this.currentWords);
}

class SosRecorded extends SosState {
  final String message;
  SosRecorded(this.message);
}

class SosError extends SosState {
  final String message;
  SosError(this.message);
}

// ─── Providers ────────────────────────────────────────────────────────────────

// Reuse the same SttService instance pattern as in IntentViewModel.
final _sosSttServiceProvider = Provider<SttService>((ref) => SttService());

final emergencyViewModelProvider =
    NotifierProvider<EmergencyViewModel, SosState>(() => EmergencyViewModel());

// ─── ViewModel ────────────────────────────────────────────────────────────────

class EmergencyViewModel extends Notifier<SosState> {
  String _lastWords = '';

  @override
  SosState build() => SosIdle();

  /// Starts voice recording for SOS message.
  Future<void> startRecording() async {
    final micStatus = await Permission.microphone.request();
    if (micStatus != PermissionStatus.granted) {
      state = SosError('Microphone permission denied. Please allow access in Settings.');
      return;
    }

    _lastWords = '';
    state = SosListening('');

    try {
      final stt = ref.read(_sosSttServiceProvider);
      await stt.startListening(
        localeId: 'en-IN',
        onResult: (words) {
          _lastWords = words;
          if (state is SosListening) {
            state = SosListening(words);
          }
        },
      );
    } catch (e) {
      state = SosError(e.toString());
    }
  }

  /// Stops recording and saves the transcribed emergency message.
  Future<void> stopRecording() async {
    if (state is! SosListening) return;
    final stt = ref.read(_sosSttServiceProvider);
    await stt.stopListening();

    if (_lastWords.trim().isEmpty) {
      state = SosIdle();
    } else {
      state = SosRecorded(_lastWords.trim());
    }
  }

  /// Resets back to idle.
  void reset() => state = SosIdle();

  bool get isListening => state is SosListening;
}
