import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class IntentProcessingScreen extends StatefulWidget {
  const IntentProcessingScreen({super.key});

  @override
  State<IntentProcessingScreen> createState() => _IntentProcessingScreenState();
}

class _IntentProcessingScreenState extends State<IntentProcessingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _stepFadeController;
  late Animation<double> _pulseAnim;
  late Animation<double> _fadeAnim;

  int _currentStep = 0;

  final List<ProcessStepItem> steps = const [
    ProcessStepItem(icon: Icons.mic_rounded, label: 'Voice captured'),
    ProcessStepItem(
      icon: Icons.translate_rounded,
      label: 'Transcribing audio...',
    ),
    ProcessStepItem(
      icon: Icons.psychology_rounded,
      label: 'Analyzing intent...',
    ),
    ProcessStepItem(
      icon: Icons.category_rounded,
      label: 'Identifying service type...',
    ),
    ProcessStepItem(
      icon: Icons.summarize_rounded,
      label: 'Generating summary...',
    ),
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    _stepFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _animateSteps();
  }

  void _animateSteps() async {
    for (int i = 0; i < steps.length; i++) {
      if (!mounted) return;
      setState(() => _currentStep = i);
      await Future.delayed(const Duration(milliseconds: 700));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _stepFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              const Spacer(),

              // ── Pulsing AI Orb ──
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow ring
                      Transform.scale(
                        scale: _pulseAnim.value * 1.25,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.10),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Mid ring
                      Transform.scale(
                        scale: _pulseAnim.value * 1.1,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryBlue.withOpacity(0.18),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      // Core orb – Level 3 shadow
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.primaryBlue.withOpacity(0.8),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.35),
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 6),
                            ),
                            BoxShadow(
                              color: AppTheme.primaryBlue.withOpacity(0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 40),

              // ── Heading ──
              Text(
                'Analyzing Your Request',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our AI is understanding your situation',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),

              const SizedBox(height: 48),

              // ── Step Tracker ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderDefault),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1E000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                    BoxShadow(
                      color: Color(0x3D000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(steps.length, (index) {
                    final isDone = index < _currentStep;
                    final isActive = index == _currentStep;
                    final isPending = index > _currentStep;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          // Step indicator
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? AppTheme.statusSuccess
                                  : isActive
                                  ? AppTheme.primaryBlue
                                  : AppTheme.backgroundSecondary,
                              border: isActive
                                  ? Border.all(
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.3,
                                      ),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Center(
                              child: isDone
                                  ? const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    )
                                  : isActive
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      steps[index].icon,
                                      color: AppTheme.textDisabled,
                                      size: 15,
                                    ),
                            ),
                          ),

                          const SizedBox(width: 14),

                          // Label
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 250),
                              style:
                                  Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    height: 1.5,
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isDone
                                        ? AppTheme.statusSuccess
                                        : isActive
                                        ? AppTheme.textPrimary
                                        : AppTheme.textDisabled,
                                  ) ??
                                  const TextStyle(),
                              child: Text(steps[index].label),
                            ),
                          ),

                          // Right indicator
                          if (isDone)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF059669),
                              size: 16,
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

              const Spacer(flex: 2),

              // ── Footer note ──
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Text(
                  'Powered by AI · Multilingual Support',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textDisabled,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProcessStepItem {
  final IconData icon;
  final String label;

  const ProcessStepItem({required this.icon, required this.label});
}
