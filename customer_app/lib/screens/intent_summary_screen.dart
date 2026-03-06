import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_intent_model.dart';
import '../theme/app_theme.dart';
import 'worker_listing_screen.dart';

class IntentSummaryScreen extends ConsumerStatefulWidget {
  final EmergencyInterpretation intent;

  const IntentSummaryScreen({super.key, required this.intent});

  @override
  ConsumerState<IntentSummaryScreen> createState() =>
      _IntentSummaryScreenState();
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

    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _enterCtrl,
            curve: const Cubic(0.2, 0, 0, 1), // Emphasized easing
          ),
        );

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
      case EmergencyUrgency.critical:
        return AppTheme.statusError;
      case EmergencyUrgency.high:
        return AppTheme.statusWarning;
      case EmergencyUrgency.medium:
        return AppTheme.primaryBlue;
      case EmergencyUrgency.low:
        return AppTheme.statusSuccess;
    }
  }

  String _urgencyLabel() => widget.intent.urgency.name.toUpperCase();

  // ── Category helpers ──
  IconData _categoryIcon() {
    switch (widget.intent.serviceCategory) {
      case ServiceCategory.plumber:
        return Icons.plumbing_rounded;
      case ServiceCategory.electrician:
        return Icons.electrical_services_rounded;
      case ServiceCategory.mechanic:
        return Icons.car_repair_rounded;
      case ServiceCategory.maid:
        return Icons.cleaning_services_rounded;
      case ServiceCategory.roadsideAssistance:
        return Icons.local_taxi_rounded;
      case ServiceCategory.gasService:
        return Icons.local_fire_department_rounded;
      case ServiceCategory.other:
        return Icons.home_repair_service_rounded;
    }
  }

  String _categoryLabel() {
    switch (widget.intent.serviceCategory) {
      case ServiceCategory.plumber:
        return 'Plumber';
      case ServiceCategory.electrician:
        return 'Electrician';
      case ServiceCategory.mechanic:
        return 'Mechanic';
      case ServiceCategory.maid:
        return 'Cleaning & Maid';
      case ServiceCategory.roadsideAssistance:
        return 'Roadside Assistance';
      case ServiceCategory.gasService:
        return 'Gas Service';
      case ServiceCategory.other:
        return 'Home Service';
    }
  }

  /// Maps ServiceCategory to the string used by WorkerListingScreen's filter.
  String _workerCategory() {
    switch (widget.intent.serviceCategory) {
      case ServiceCategory.plumber:
        return 'Plumber';
      case ServiceCategory.electrician:
        return 'Electrician';
      case ServiceCategory.mechanic:
        return 'Mechanic';
      case ServiceCategory.maid:
        return 'Maid';
      case ServiceCategory.gasService:
        return 'Gas Service';
      default:
        return 'All';
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgColor = _urgencyColor();
    final intent = widget.intent;
    final confidencePct = (intent.confidence * 100).round();

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
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
                    color: AppTheme.backgroundPrimary,
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.borderDefault,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Request Summary',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
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
                            color: AppTheme.backgroundPrimary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderDefault),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryBlue,
                                      AppTheme.primaryBlue,
                                    ],
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
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryBlue
                                                .withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.auto_awesome_rounded,
                                                color: AppTheme.primaryBlue,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              const Text(
                                                'AI Detected',
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  color: AppTheme.primaryBlue,
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
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: urgColor.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: urgColor.withOpacity(0.3),
                                            ),
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
                                            color: AppTheme.primaryBlue
                                                .withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            _categoryIcon(),
                                            color: AppTheme.primaryBlue,
                                            size: 26,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Service Needed',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                color: AppTheme.textTertiary,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              _categoryLabel(),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headlineMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppTheme.textPrimary,
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
                            color: AppTheme.backgroundPrimary,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderDefault),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                        color: AppTheme.textSecondary,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                        () => _isEditing = !_isEditing,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppTheme.primaryBlue
                                                .withOpacity(0.4),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _isEditing
                                                  ? Icons.check_rounded
                                                  : Icons.edit_rounded,
                                              color: AppTheme.primaryBlue,
                                              size: 13,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _isEditing ? 'Save' : 'Edit',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                color: AppTheme.primaryBlue,
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
                                          color: AppTheme.textPrimary,
                                          fontSize: 15,
                                          height: 1.6,
                                        ),
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor:
                                              AppTheme.backgroundSecondary,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppTheme.borderDefault,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppTheme.borderDefault,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: const BorderSide(
                                              color: AppTheme.primaryBlue,
                                              width: 1.5,
                                            ),
                                          ),
                                          contentPadding: const EdgeInsets.all(
                                            12,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _editCtrl.text,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          color: AppTheme.textPrimary,
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
                              color: AppTheme.backgroundPrimary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderDefault),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppTheme.infoBlue,
                                  size: 16,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    intent.reason,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: AppTheme.textTertiary,
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
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: intent.riskFactors.map((r) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.warningOrange.withOpacity(
                                    0.07,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.warningOrange.withOpacity(
                                      0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  r,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppTheme.warningOrange,
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
                                color: AppTheme.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '$confidencePct%',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppTheme.textSecondary,
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
                            backgroundColor: AppTheme.borderDefault,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryBlue,
                            ),
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
                    color: AppTheme.backgroundPrimary,
                    border: Border(
                      top: BorderSide(color: AppTheme.borderDefault, width: 1),
                    ),
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
                              foregroundColor: AppTheme.primaryBlue,
                              side: const BorderSide(
                                color: AppTheme.primaryBlue,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => WorkerListingScreen(
                                    initialCategory: _workerCategory(),
                                    prefillSummary: _editCtrl.text,
                                    prefillUrgency: widget.intent.urgency.name,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.search_rounded, size: 18),
                            label: const Text('Find Workers'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
