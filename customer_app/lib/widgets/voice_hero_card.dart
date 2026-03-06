import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../viewmodels/intent_viewmodel.dart';
import '../screens/intent_processing_screen.dart';
import '../screens/intent_summary_screen.dart';
import '../theme/app_theme.dart';

class VoiceHeroCard extends ConsumerStatefulWidget {
  const VoiceHeroCard({super.key});

  @override
  ConsumerState<VoiceHeroCard> createState() => _VoiceHeroCardState();
}

class _VoiceHeroCardState extends ConsumerState<VoiceHeroCard>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  bool _processingNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _requestPermissionProactively();
  }

  Future<void> _requestPermissionProactively() async {
    final status = await Permission.microphone.status;
    if (status.isDenied) {
      await Permission.microphone.request();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _listenToIntentState() {
    ref.listen<IntentState>(intentViewModelProvider, (previous, next) {
      if (next is IntentListening) {
        _pulseController.repeat(reverse: true);
        _waveController.repeat();
        _processingNavigated = false;
      } else {
        _pulseController.stop();
        _pulseController.reset();
        _waveController.stop();
        _waveController.reset();
      }

      if (next is IntentProcessing && !_processingNavigated) {
        _processingNavigated = true;
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const IntentProcessingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }

      if (next is IntentError) {
        if (_processingNavigated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          _processingNavigated = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        ref.read(intentViewModelProvider.notifier).reset();
      } else if (next is IntentSuccess) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                IntentSummaryScreen(intent: next.intent),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        _processingNavigated = false;
        ref.read(intentViewModelProvider.notifier).reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _listenToIntentState();
    final intentState = ref.watch(intentViewModelProvider);
    final viewModel = ref.read(intentViewModelProvider.notifier);

    final isListening = intentState is IntentListening;
    final isEmpty = intentState is IntentEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isListening
              ? AppTheme.primaryBlue.withValues(alpha: 0.4)
              : AppTheme.borderDefault,
          width: isListening ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isListening
                ? AppTheme.primaryBlue.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isListening ? 24 : 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isListening
                          ? 'Listening\u2026'
                          : isEmpty
                          ? 'Nothing heard'
                          : 'What do you need?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isListening
                                ? AppTheme.primaryBlue
                                : AppTheme.textPrimary,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isListening
                          ? 'Speak in English, Hindi, or Marathi'
                          : isEmpty
                          ? 'Tap the mic and speak clearly'
                          : 'Tap the mic and describe your need',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              _LanguagePillRow(disabled: isListening),
            ],
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () {
              if (intentState is IntentIdle ||
                  intentState is IntentError ||
                  intentState is IntentEmpty) {
                viewModel.startRecording();
              } else if (intentState is IntentListening) {
                viewModel.stopRecordingAndAnalyze();
              }
            },
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isListening ? _pulseAnimation.value : 1.0,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isListening)
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isEmpty
                                    ? [AppTheme.textDisabled, AppTheme.gray300]
                                    : [
                                        AppTheme.primaryBlue,
                                        AppTheme.primaryDark,
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isEmpty
                                              ? AppTheme.textDisabled
                                              : AppTheme.primaryBlue)
                                          .withValues(
                                            alpha: isListening ? 0.42 : 0.22,
                                          ),
                                  blurRadius: isListening ? 28 : 16,
                                  spreadRadius: isListening ? 4 : 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isListening
                                    ? Icons.stop_rounded
                                    : isEmpty
                                    ? Icons.mic_off_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: isListening
                      ? _buildWaveform(intentState.currentWords)
                      : _buildIdleHint(context, intentState),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveform(String currentWords) {
    return Column(
      key: const ValueKey('waveform'),
      children: [
        AnimatedBuilder(
          animation: _waveController,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(9, (i) {
                final phase = (i / 9) * 2 * math.pi;
                final height =
                    8.0 +
                    18.0 *
                        (0.5 +
                            0.5 *
                                math.sin(
                                  _waveController.value * 2 * math.pi + phase,
                                ));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(
                        alpha: 0.45 + 0.55 * (height / 26.0),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(height: 12),
        if (currentWords.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDefault),
            ),
            child: Text(
              '"$currentWords"',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        if (currentWords.isEmpty)
          const Text(
            'Say something\u2026',
            style: TextStyle(fontSize: 13, color: AppTheme.textDisabled),
          ),
        const SizedBox(height: 8),
        const Text(
          'Tap to submit',
          style: TextStyle(fontSize: 12, color: AppTheme.textDisabled),
        ),
      ],
    );
  }

  Widget _buildIdleHint(BuildContext context, IntentState state) {
    if (state is IntentEmpty) {
      return Column(
        key: const ValueKey('empty'),
        children: [
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppTheme.warningOrange,
              ),
              const SizedBox(width: 6),
              const Text(
                'No speech detected \u2014 try again',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.warningOrange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Wrap(
      key: const ValueKey('idle'),
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: const [
        _ExampleChip('"My pipe is leaking"'),
        _ExampleChip('"Electrician chahiye"'),
        _ExampleChip('"AC repair urgent"'),
      ],
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;
  const _ExampleChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.backgroundTertiary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderDefault),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textTertiary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Language pill row  (EN / हि / मर)
// ---------------------------------------------------------------------------

class _LangOption {
  final String label;
  final String? localeId; // null = auto
  const _LangOption(this.label, this.localeId);
}

class _LanguagePillRow extends ConsumerWidget {
  /// While recording is active the pills are non-interactive.
  final bool disabled;
  const _LanguagePillRow({required this.disabled});

  static const _options = [
    _LangOption('Auto', null),
    _LangOption('EN', 'en-IN'),
    _LangOption('हि', 'hi-IN'),
    _LangOption('मर', 'mr-IN'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedLocaleProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _options.map((opt) {
        final isActive = opt.localeId == selected;
        return GestureDetector(
          onTap: disabled
              ? null
              : () => ref
                    .read(selectedLocaleProvider.notifier)
                    .select(opt.localeId),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(left: 4),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primaryBlue
                  : AppTheme.primaryBlue.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive
                    ? AppTheme.primaryBlue
                    : AppTheme.primaryBlue.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              opt.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? Colors.white : AppTheme.primaryBlue,
                letterSpacing: 0.2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
