import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart' show pinSosShortcut;
import 'sos_activation_screen.dart';

// ─── Mock emergency contacts (replace with Supabase data when backend ready) ──

class _MockContact {
  final String name;
  final String relation;
  final String phone;
  const _MockContact({
    required this.name,
    required this.relation,
    required this.phone,
  });
}

const _mockContacts = [
  _MockContact(name: 'Mom', relation: 'Mother', phone: '9876543210'),
  _MockContact(name: 'Rohit Kumar', relation: 'Friend', phone: '9123456780'),
  _MockContact(name: 'Sneha Gupta', relation: 'Sister', phone: '9988776655'),
];

// ─── Theme constants (matches app theme) ─────────────────────────────────────
const Color _kRed = Color(0xFFDC2626);
const Color _kRedLight = Color(0xFFFEF2F2);
const Color _kTextPrimary = Color(0xFF111827);
const Color _kTextSecondary = Color(0xFF374151);
const Color _kTextTertiary = Color(0xFF6B7280);
const Color _kBorderDefault = Color(0xFFE5E7EB);
const Color _kBackground = Color(0xFFF9FAFB);

// ─── EmergencyPage ────────────────────────────────────────────────────────────

class EmergencyPage extends StatefulWidget {
  const EmergencyPage({super.key});

  @override
  State<EmergencyPage> createState() => _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Offer to pin the SOS shortcut to the home screen (only once)
    _maybeOfferPinShortcut();
  }

  Future<void> _maybeOfferPinShortcut() async {
    // The native side (MainActivity) checks ShortcutManager.getPinnedShortcuts()
    // to decide whether to actually show the pin dialog — so it's safe to call
    // this every time the page is opened.
    await pinSosShortcut();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onSosHold() {
    HapticFeedback.heavyImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SOSActivationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  // Back arrow
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        size: 20, color: _kTextPrimary),
                    tooltip: 'Back',
                  ),
                  const Expanded(
                    child: Text(
                      'Emergency SOS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _kTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── SOS Button section ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  // Outer pulse ring
                  AnimatedBuilder(
                    animation: _pulseScale,
                    builder: (_, child) => Transform.scale(
                      scale: _pulseScale.value,
                      child: child,
                    ),
                    child: GestureDetector(
                      onLongPress: _onSosHold,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outermost glow
                          Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kRed.withOpacity(0.08),
                            ),
                          ),
                          // Middle ring
                          Container(
                            width: 164,
                            height: 164,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kRed.withOpacity(0.15),
                            ),
                          ),
                          // Core button
                          Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(
                                colors: [Color(0xFFEF4444), Color(0xFF991B1B)],
                                center: Alignment(-0.3, -0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kRed.withOpacity(0.45),
                                  blurRadius: 24,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Tap and hold to activate SOS',
                    style: TextStyle(
                      fontSize: 14,
                      color: _kTextTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Emergency Contacts List ────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: _kBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _kRedLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.contact_phone,
                                color: _kRed, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Emergency Contacts',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _kTextPrimary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Contact cards
                      ..._mockContacts.map(
                        (c) => _ContactCard(
                          name: c.name,
                          relation: c.relation,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Contact Card ─────────────────────────────────────────────────────────────

class _ContactCard extends StatelessWidget {
  final String name;
  final String relation;

  const _ContactCard({
    required this.name,
    required this.relation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _kRedLight,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name & relation
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  relation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
