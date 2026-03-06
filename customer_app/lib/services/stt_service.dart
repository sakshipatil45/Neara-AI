import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Speech-to-text powered by the Sarvam AI saaras:v3 model.
///
/// Records audio locally as a 16 kHz mono WAV file, then POSTs it to the
/// Sarvam API. Language is auto-detected server-side — no locale
/// configuration needed. Supports hi-IN, mr-IN, en-IN, ta-IN, te-IN and more.
class SttService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _tempFilePath;

  static const String _apiKey = 'sk_651i5g2d_cphlKTY1YLAkDzB4NQ6lXHjv';
  static const String _sttUrl = 'https://api.sarvam.ai/speech-to-text';

  bool get isListening => _isRecording;

  /// No async init required for Sarvam (kept for API compatibility).
  Future<bool> init() async => true;

  // ── Core API ──────────────────────────────────────────────────────────────

  /// Starts recording audio to a temporary WAV file.
  ///
  /// Throws if microphone permission is denied or the recorder fails to start.
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) throw Exception('Microphone permission denied');

    final dir = await getTemporaryDirectory();
    _tempFilePath = '${dir.path}/sarvam_voice_input.wav';

    // Remove stale file from a previous session if present.
    final existing = File(_tempFilePath!);
    if (existing.existsSync()) existing.deleteSync();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _tempFilePath!,
    );
    _isRecording = true;
    debugPrint('Sarvam STT: recording started → $_tempFilePath');
  }

  /// Stops the recording and uploads the WAV to Sarvam AI for transcription.
  ///
  /// Returns the transcript string in the auto-detected language.
  Future<String> stopAndTranscribe() async {
    if (!_isRecording) return '';
    _isRecording = false;

    final stoppedPath = await _recorder.stop();
    final filePath = stoppedPath ?? _tempFilePath;
    if (filePath == null) throw Exception('Recording failed — no file path');

    final file = File(filePath);
    if (!file.existsSync() || file.lengthSync() < 512) {
      throw Exception('Recording too short or empty');
    }

    debugPrint('Sarvam STT: uploading ${file.lengthSync()} bytes...');
    return _transcribeFile(filePath);
  }

  /// Stops the recording without transcribing (e.g. user cancelled).
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    _isRecording = false;
    await _recorder.stop();
    debugPrint('Sarvam STT: recording cancelled');
  }

  // ── Legacy compatibility shims ─────────────────────────────────────────────
  // These keep any remaining callers of the old speech_to_text-style interface
  // compilable. Prefer the core API above for new code.

  /// Starts recording. [onResult] and [localeOverride] are ignored —
  /// Sarvam auto-detects language and returns a single final result.
  /// Call [stopAndTranscribe] to stop and retrieve the transcript.
  Future<void> startListening({
    required Function(String text) onResult,
    String? localeOverride,
  }) async {
    await startRecording();
  }

  /// Stops recording without transcribing.
  /// Prefer [stopAndTranscribe] to get the Sarvam result.
  Future<void> stopListening() async {
    await cancelRecording();
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Future<String> _transcribeFile(String filePath) async {
    final request = http.MultipartRequest('POST', Uri.parse(_sttUrl))
      ..headers['api-subscription-key'] = _apiKey
      ..fields['model'] = 'saaras:v3'
      ..fields['mode'] = 'transcribe'
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          contentType: MediaType('audio', 'wav'),
        ),
      );

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final transcript = data['transcript'] as String? ?? '';
      final lang = data['language_code'] as String? ?? 'unknown';
      debugPrint('Sarvam STT: lang=$lang → "$transcript"');
      return transcript;
    } else {
      throw Exception('Sarvam STT ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
