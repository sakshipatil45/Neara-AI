import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/emergency_ai_service.dart';
import '../services/location_service.dart';
import '../services/sms_service.dart';

// ─── Mock contacts (same list as EmergencyPage) ───────────────────────────────

class _Contact {
  final String name;
  final String relation;
  const _Contact(this.name, this.relation);
}

const _contacts = [
  _Contact('Mom', 'Mother'),
  _Contact('Rohit Kumar', 'Friend'),
  _Contact('Sneha Gupta', 'Sister'),
];

// ─── Theme ────────────────────────────────────────────────────────────────────
const _kRed = Color(0xFFDC2626);
const _kRedDark = Color(0xFF991B1B);
const _kDarkBg = Color(0xFF1A0000);

// ─── SOSActivationScreen ──────────────────────────────────────────────────────

enum _SosPhase { countdown, activated, listening, summarizing, summarized }

class SOSActivationScreen extends StatefulWidget {
  const SOSActivationScreen({super.key});

  @override
  State<SOSActivationScreen> createState() => _SOSActivationScreenState();
}

class _SOSActivationScreenState extends State<SOSActivationScreen>
    with TickerProviderStateMixin {
  // Countdown
  int _countdown = 5;
  Timer? _timer;

  // Phase
  _SosPhase _phase = _SosPhase.countdown;

  // Voice
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechReady = false;
  String _liveWords = '';
  String _finalWords = '';
  bool _isListening = false;

  // AI & Location State
  String _aiSummary = '';
  String _locationLink = 'https://maps.google.com/?q=18.516726,73.856255';

  // Count ring animation
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  // Pulse animation (activated phase)
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _ringAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ringController, curve: Curves.linear),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    HapticFeedback.heavyImpact();
    _startCountdown();
    _initSpeech();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ringController.dispose();
    _pulseController.dispose();
    if (_isListening) _speech.stop();
    super.dispose();
  }

  // ── Speech init ─────────────────────────────────────────────────────────────

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status == PermissionStatus.granted) {
      _speechReady = await _speech.initialize(
        onError: (_) {},
        onStatus: (_) {},
      );
    }
  }

  // ── Countdown logic ─────────────────────────────────────────────────────────

  void _startCountdown() {
    _ringController.forward(from: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_countdown <= 1) {
        t.cancel();
        _activateSOS();
      } else {
        setState(() => _countdown--);
        HapticFeedback.lightImpact();
        _ringController.forward(from: 0);
      }
    });
  }

  void _activateSOS() {
    HapticFeedback.heavyImpact();
    setState(() {
      _countdown = 0;
      _phase = _SosPhase.activated;
    });
    _pulseController.repeat(reverse: true);
    // Auto-start voice after brief pause
    Future.delayed(const Duration(milliseconds: 1200), _startListening);
  }

  // ── Voice recording ─────────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (!_speechReady || !mounted) return;
    setState(() {
      _phase = _SosPhase.listening;
      _liveWords = '';
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() => _liveWords = result.recognizedWords);
        if (result.finalResult) {
          _finalWords = result.recognizedWords;
        }
      },
      localeId: 'en-IN',
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    // Auto-stop after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isListening) _stopListening();
    });
  }

  Future<void> _stopListening() async {
    await _speech.stop();
    if (!mounted) return;
    final words = _finalWords.isNotEmpty ? _finalWords : _liveWords;
    setState(() {
      _isListening = false;
      _finalWords = words;
    });
    _pulseController.stop();

    // Start processing (AI + Location + SMS)
    _processEmergency();
  }

  Future<void> _processEmergency() async {
    setState(() {
      _phase = _SosPhase.summarizing;
    });

    // 1. Fetch live location
    final location = await LocationService.getLiveLocationLink();
    if (!mounted) return;
    
    setState(() {
      _locationLink = location;
    });

    // 2. Generate summary with AI (OpenRouter)
    // Using "Sakshi" as customer name for now
    final summary = await EmergencyAiService.generateEmergencySummary(
      _finalWords,
      "Sakshi",
    );

    if (!mounted) return;

    setState(() {
      _aiSummary = summary;
      _phase = _SosPhase.summarized;
    });

    // 3. Send SMS to all emergency contacts
    final phones = _contacts.map((e) => '9123456789').toList(); // Placeholder phones for mock contacts
    await SmsService.sendEmergencySms(
      phones: phones,
      summary: _aiSummary,
      locationLink: _locationLink,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  void _cancelSOS() {
    _timer?.cancel();
    if (_isListening) _speech.stop();
    Navigator.pop(context);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                  ),
                  const Expanded(
                    child: Text(
                      'Emergency SOS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_phase == _SosPhase.countdown)
                    GestureDetector(
                      onTap: _cancelSOS,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ),

            // ── Main scroll body ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // ── Central indicator ─────────────────────────────
                    _buildCentralIndicator(),

                    const SizedBox(height: 28),

                    // ── Status text ───────────────────────────────────
                    _buildStatusText(),

                    const SizedBox(height: 36),

                    // ── Phase-specific section ────────────────────────
                    if (_phase == _SosPhase.summarizing) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(color: _kRed, strokeWidth: 3),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_phase == _SosPhase.summarized) ...[
                      _buildSummaryCard(),
                      const SizedBox(height: 20),
                    ],
                    if (_phase == _SosPhase.listening) ...[
                      _buildListeningCard(),
                      const SizedBox(height: 20),
                    ],

                    // ── Contacts ──────────────────────────────────────
                    _buildContactsSection(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Central indicator (countdown ring or SOS circle) ─────────────────────

  Widget _buildCentralIndicator() {
    if (_phase == _SosPhase.countdown) {
      return AnimatedBuilder(
        animation: _ringAnimation,
        builder: (_, _) {
          return SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Progress ring
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _ringAnimation.value,
                    strokeWidth: 8,
                    color: _kRed,
                    backgroundColor: Colors.white12,
                  ),
                ),
                // Number
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFFEF4444), _kRedDark],
                      center: Alignment(-0.3, -0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kRed.withValues(alpha: 0.5),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Activated / listening / summarized
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (_, child) {
        final scale = _phase == _SosPhase.listening
            ? 1.0 + _pulseController.value * 0.06
            : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kRed.withValues(alpha: 0.12),
            ),
          ),
          // Button
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Color(0xFFEF4444), _kRedDark],
                center: Alignment(-0.3, -0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: _kRed.withValues(alpha: 0.5),
                  blurRadius: 32,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_phase == _SosPhase.listening)
                  const Icon(Icons.mic, color: Colors.white, size: 32)
                else
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 32),
                const SizedBox(height: 4),
                const Text(
                  'SOS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status text ───────────────────────────────────────────────────────────

  Widget _buildStatusText() {
    String headline;
    String subtitle;

    switch (_phase) {
      case _SosPhase.countdown:
        headline = 'Sending SOS in $_countdown seconds...';
        subtitle = 'Your live location is being shared\nwith emergency contacts.';
      case _SosPhase.activated:
        headline = '🚨 SOS Activated!';
        subtitle = 'Connecting to emergency contacts...';
      case _SosPhase.listening:
        headline = '🎙️ Listening...';
        subtitle = 'Speak your emergency message clearly.';
      case _SosPhase.summarizing:
        headline = '🧠 Processing...';
        subtitle = 'Generating emergency summary and fetching location...';
      case _SosPhase.summarized:
        headline = '✅ Message Sent';
        subtitle = 'Emergency alert has been sent to your contacts.';
    }

    return Column(
      children: [
        Text(
          headline,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ── Listening card ────────────────────────────────────────────────────────

  Widget _buildListeningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kRed,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Recording',
                style: TextStyle(
                  color: _kRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _stopListening,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Stop',
                      style:
                          TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _liveWords.isEmpty
                ? 'Speak now — e.g. "There is a fire in my house"'
                : _liveWords,
            style: TextStyle(
              color: _liveWords.isEmpty ? Colors.white38 : Colors.white,
              fontSize: 14,
              height: 1.5,
              fontStyle: _liveWords.isEmpty
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

  Widget _buildSummaryCard() {
    return Column(
      children: [
        // Emergency text
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kRed.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kRed.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.emergency, color: _kRed, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Emergency Summary',
                    style: TextStyle(
                        color: _kRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _aiSummary,
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Location link
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white60, size: 14),
                  SizedBox(width: 6),
                  Text('Live Location',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6),
              SelectableText(
                _locationLink,
                style: const TextStyle(
                  color: Color(0xFF60A5FA),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF60A5FA),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Contacts section ──────────────────────────────────────────────────────

  Widget _buildContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Contacts',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ..._contacts.map((c) => _SosContactRow(name: c.name, relation: c.relation)),
      ],
    );
  }
}

// ─── SOS Contact Row ──────────────────────────────────────────────────────────

class _SosContactRow extends StatelessWidget {
  final String name;
  final String relation;

  const _SosContactRow({required this.name, required this.relation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _kRed.withValues(alpha: 0.25),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(relation,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
