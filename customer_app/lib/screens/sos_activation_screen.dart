import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/sos_emergency_service.dart';

// ─── Mock contacts (name, relation, phone) ────────────────────────────────────

class _Contact {
  final String name;
  final String relation;
  final String phone;
  const _Contact(this.name, this.relation, this.phone);
}

const _contacts = [
  _Contact('Mom', 'Mother', '9876543210'),
  _Contact('Rohit Kumar', 'Friend', '9123456780'),
  _Contact('Sneha Gupta', 'Sister', '9988776655'),
];

// ─── Theme ────────────────────────────────────────────────────────────────────
const _kRed = Color(0xFFDC2626);
const _kRedDark = Color(0xFF991B1B);
const _kDarkBg = Color(0xFF1A0000);

// ─── SOSActivationScreen ──────────────────────────────────────────────────────

enum _SosPhase { countdown, activated, listening, summarized }

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

  // AI / SMS state
  String _aiSummary = '';
  bool _isSummarizing = false;
  String _locationLink = 'https://maps.google.com/?q=0,0';
  String _customerName = 'User';

  // Services
  final _sosService = SosEmergencyService();
  final _authService = AuthService();

  // Count ring animation
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  // Pulse animation (activated / listening phase)
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
    _fetchUserName();
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

  // ── Fetch customer name ──────────────────────────────────────────────────

  Future<void> _fetchUserName() async {
    final user = await _authService.getCurrentUserData();
    if (mounted && user != null && user.name.isNotEmpty) {
      setState(() {
        _customerName = user.name.split(' ').first; // First name only
      });
    }
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
    // Trigger AI + GPS + SMS
    await _processAndSend();
  }

  // ── AI + GPS + SMS pipeline ─────────────────────────────────────────────────

  Future<void> _processAndSend() async {
    setState(() {
      _phase = _SosPhase.summarized;
      _isSummarizing = true;
    });

    // 1. Get live GPS location
    try {
      final position = await LocationService.instance
          .getCurrentPosition(forceRefresh: true);
      if (position != null) {
        _locationLink =
            'https://maps.google.com/?q=${position.latitude},${position.longitude}';
      }
    } catch (_) {
      // Keep default link if GPS fails
    }

    // 2. AI summarize
    final summary = await _sosService.summarize(
      transcript: _finalWords,
      customerName: _customerName,
    );

    if (!mounted) return;
    setState(() {
      _aiSummary = summary;
      _isSummarizing = false;
    });

    // 3. Send SMS to all emergency contacts
    await _sosService.sendSmsToContacts(
      summary: summary,
      locationLink: _locationLink,
      phones: _contacts.map((c) => c.phone).toList(),
    );
  }

  // ── Cancel ──────────────────────────────────────────────────────────────────

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
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
        builder: (_, _a) {
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
                        color: _kRed.withOpacity(0.5),
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
              color: _kRed.withOpacity(0.12),
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
                  color: _kRed.withOpacity(0.5),
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
                else if (_phase == _SosPhase.summarized && _isSummarizing)
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
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
        subtitle =
            'Your live location is being shared\nwith emergency contacts.';
      case _SosPhase.activated:
        headline = '🚨 SOS Activated!';
        subtitle = 'Connecting to emergency contacts...';
      case _SosPhase.listening:
        headline = '🎙️ Listening...';
        subtitle = 'Speak your emergency message clearly.';
      case _SosPhase.summarized:
        headline = _isSummarizing ? '⏳ Generating Summary...' : '✅ Message Ready';
        subtitle = _isSummarizing
            ? 'AI is processing your message...'
            : 'Emergency summary sent to contacts.';
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
        color: Colors.white.withOpacity(0.08),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('Stop',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
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
              fontStyle:
                  _liveWords.isEmpty ? FontStyle.italic : FontStyle.normal,
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
        // Emergency summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _kRed.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kRed.withOpacity(0.4)),
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
              const SizedBox(height: 10),
              if (_isSummarizing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(
                      color: _kRed,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                Text(
                  _aiSummary.isEmpty
                      ? '🚨 Emergency Alert\n\n$_customerName has triggered an emergency SOS.'
                      : _aiSummary,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.6),
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
            color: Colors.white.withOpacity(0.06),
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
        // SMS sent confirmation
        if (!_isSummarizing) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text(
                  'SMS alert sent to emergency contacts',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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

// ─── SOS Contact Row (no call button) ─────────────────────────────────────────

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
        color: Colors.white.withOpacity(0.07),
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
              color: _kRed.withOpacity(0.25),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text(relation,
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
