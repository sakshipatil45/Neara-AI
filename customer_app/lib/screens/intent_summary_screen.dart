// ignore_for_file: unnecessary_underscores, unused_field, dead_code
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_intent_model.dart';

// ─────────────── NEARA Design Tokens ───────────────
class _DS {
  // Colors
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF1E40AF);
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFEA580C);
  static const error = Color(0xFFDC2626);
  static const info = Color(0xFF0284C7);

  static const bg = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF9FAFB);
  static const bgTertiary = Color(0xFFF3F4F6);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF374151);
  static const textTertiary = Color(0xFF6B7280);
  static const textDisabled = Color(0xFF9CA3AF);

  static const borderDefault = Color(0xFFE5E7EB);
  static const borderFocus = Color(0xFF2563EB);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray800 = Color(0xFF1F2937);

  // Shadows – Level 1
  static List<BoxShadow> get shadow1 => const [
        BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 1)),
        BoxShadow(color: Color(0x3D000000), blurRadius: 2, offset: Offset(0, 1)),
      ];

}

class IntentSummaryScreen extends ConsumerStatefulWidget {
  final EmergencyInterpretation intent;

  const IntentSummaryScreen({super.key, required this.intent});

  @override
  ConsumerState<IntentSummaryScreen> createState() => _IntentSummaryScreenState();
}

class _IntentSummaryScreenState extends ConsumerState<IntentSummaryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _enterCtrl;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  late TextEditingController _editCtrl;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _editCtrl = TextEditingController(text: widget.intent.issueSummary);

    // Enter: Slide up + fade in (300ms Standard easing from design system)
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Cubic(0.2, 0, 0, 1), // Emphasized easing
    ));

    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _editCtrl.dispose();
    super.dispose();
  }

  // ── Urgency helpers ──
  Color _urgencyColor() {
    switch (widget.intent.urgency) {
      case EmergencyUrgency.critical: return _DS.error;
      case EmergencyUrgency.high: return _DS.warning;
      case EmergencyUrgency.medium: return _DS.info;
      case EmergencyUrgency.low: return _DS.success;
    }
  }

  String _urgencyLabel() => widget.intent.urgency.name.toUpperCase();

  // ── Category helpers ──
  IconData _categoryIcon() {
    switch (widget.intent.serviceCategory) {
      case ServiceCategory.plumber: return Icons.plumbing_rounded;
      case ServiceCategory.electrician: return Icons.electrical_services_rounded;
      case ServiceCategory.mechanic: return Icons.car_repair_rounded;
      case ServiceCategory.maid: return Icons.cleaning_services_rounded;
      case ServiceCategory.roadsideAssistance: return Icons.local_taxi_rounded;
      case ServiceCategory.gasService: return Icons.local_fire_department_rounded;
      case ServiceCategory.other: return Icons.home_repair_service_rounded;
    }
  }

  String _categoryLabel() {
    switch (widget.intent.serviceCategory) {
      case ServiceCategory.plumber: return 'Plumber';
      case ServiceCategory.electrician: return 'Electrician';
      case ServiceCategory.mechanic: return 'Mechanic';
      case ServiceCategory.maid: return 'Cleaning & Maid';
      case ServiceCategory.roadsideAssistance: return 'Roadside Assistance';
      case ServiceCategory.gasService: return 'Gas Service';
      case ServiceCategory.other: return 'Home Service';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgColor = _urgencyColor();
    final intent = widget.intent;
    final confidencePct = (intent.confidence * 100).round();

    return Scaffold(
      backgroundColor: _DS.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [
                // ── App Bar ──
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: _DS.bg,
                    border: Border(
                      bottom: BorderSide(color: _DS.borderDefault, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: _DS.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Request Summary',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _DS.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ── Scrollable Body ──
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── AI Category Hero Card ──
                        Container(
                          decoration: BoxDecoration(
                            color: _DS.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _DS.borderDefault),
                            boxShadow: _DS.shadow1,
                          ),
                          child: Column(
                            children: [
                              // Header stripe
                              Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  gradient: LinearGradient(
                                    colors: [_DS.primary, _DS.primaryLight],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // AI label
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: _DS.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.auto_awesome_rounded,
                                                  color: _DS.primary, size: 12),
                                              SizedBox(width: 4),
                                              Text(
                                                'AI Detected',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  color: _DS.primary,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Spacer(),
                                        // Urgency badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: urgColor.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(
                                                color: urgColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            _urgencyLabel(),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              color: urgColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    // Category row
                                    Row(
                                      children: [
                                        Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: _DS.primary.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            _categoryIcon(),
                                            color: _DS.primary,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Service Needed',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                color: _DS.textTertiary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _categoryLabel(),
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                color: _DS.textPrimary,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: -0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Problem Summary Card ──
                        Container(
                          decoration: BoxDecoration(
                            color: _DS.bg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _DS.borderDefault),
                            boxShadow: _DS.shadow1,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Problem Summary',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: _DS.textSecondary,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          setState(() => _isEditing = !_isEditing),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: _DS.primary.withValues(alpha: 0.4)),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _isEditing
                                                  ? Icons.check_rounded
                                                  : Icons.edit_rounded,
                                              color: _DS.primary,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _isEditing ? 'Save' : 'Edit',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                color: _DS.primary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _isEditing
                                    ? TextField(
                                        controller: _editCtrl,
                                        maxLines: 4,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          color: _DS.textPrimary,
                                          fontSize: 15,
                                          height: 1.6,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: _DS.bgTertiary,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            borderSide: const BorderSide(
                                                color: _DS.borderDefault),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            borderSide: const BorderSide(
                                                color: _DS.borderDefault),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            borderSide: const BorderSide(
                                                color: _DS.borderFocus,
                                                width: 1.5),
                                          ),
                                          contentPadding:
                                              const EdgeInsets.all(12),
                                        ),
                                      )
                                    : Text(
                                        _editCtrl.text,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          color: _DS.textPrimary,
                                          fontSize: 15,
                                          height: 1.6,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                              ],
                            ),
                          ),
                        ),

                        // ── AI Reason ──
                        if (intent.reason.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _DS.bgTertiary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _DS.borderDefault),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: _DS.info, size: 16),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    intent.reason,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: _DS.textTertiary,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // ── Risk Factors ──
                        if (intent.riskFactors.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Risk Factors',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _DS.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: intent.riskFactors.map((r) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _DS.warning.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: _DS.warning.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  r,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: _DS.warning,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],

                        // ── Confidence Bar ──
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'AI Confidence',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: _DS.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$confidencePct%',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: _DS.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: intent.confidence,
                            minHeight: 6,
                            backgroundColor: _DS.bgTertiary,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_DS.primary),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // ── Action Buttons (sticky bottom) ──
                Container(
                  decoration: const BoxDecoration(
                    color: _DS.bg,
                    border: Border(
                        top: BorderSide(color: _DS.borderDefault, width: 1)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Row(
                    children: [
                      // Edit Request
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                setState(() => _isEditing = !_isEditing),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Edit Request'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _DS.primary,
                              side: const BorderSide(
                                  color: _DS.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Proceed – Primary CTA
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'Finding workers nearby...',
                                    style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500),
                                  ),
                                  backgroundColor: _DS.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                  margin: const EdgeInsets.all(16),
                                ),
                              );
                            },
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('Find Workers'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _DS.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              textStyle: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
