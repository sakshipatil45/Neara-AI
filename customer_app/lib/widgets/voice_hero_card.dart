import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../viewmodels/intent_viewmodel.dart';
import '../screens/intent_processing_screen.dart';
import '../screens/intent_summary_screen.dart';

class VoiceHeroCard extends ConsumerStatefulWidget {
  const VoiceHeroCard({super.key});

  @override
  ConsumerState<VoiceHeroCard> createState() => _VoiceHeroCardState();
}

class _VoiceHeroCardState extends ConsumerState<VoiceHeroCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _processingNavigated = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // Proactively request permission when card loads
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
    super.dispose();
  }

  void _listenToIntentState() {
    ref.listen<IntentState>(intentViewModelProvider, (previous, next) {
      if (next is IntentListening) {
        _pulseController.repeat(reverse: true);
        _processingNavigated = false;
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }

      if (next is IntentProcessing && !_processingNavigated) {
        _processingNavigated = true;
        // Navigate to animated processing screen
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const IntentProcessingScreen(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }

      if (next is IntentError) {
        // Pop processing screen if open
        if (_processingNavigated) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          _processingNavigated = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        ref.read(intentViewModelProvider.notifier).reset();
      } else if (next is IntentSuccess) {
        // Replace processing screen with full-screen summary
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => IntentSummaryScreen(intent: next.intent),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
            transitionDuration: const Duration(milliseconds: 400),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
             color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
             blurRadius: 20,
             offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How can we help you?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
              ),
              _buildLanguageToggle(viewModel),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            intentState is IntentListening 
                ? (intentState.currentWords.isEmpty ? 'Listening...' : intentState.currentWords)
                : intentState is IntentProcessing
                    ? 'Understanding your request...'
                    : 'Tap and tell us what you need in English, Hindi, or Marathi.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: intentState is IntentListening ? Theme.of(context).primaryColor : Colors.grey.shade600,
                  fontWeight: intentState is IntentListening ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
          const SizedBox(height: 32),
          // Pulsing Voice Button Design
          GestureDetector(
            onTap: () {
              if (intentState is IntentIdle || intentState is IntentError) {
                viewModel.startRecording();
              } else if (intentState is IntentListening) {
                viewModel.stopRecordingAndAnalyze();
              }
            },
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: intentState is IntentListening ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                          spreadRadius: intentState is IntentListening ? 12 * _pulseAnimation.value : 8,
                          blurRadius: intentState is IntentListening ? 25 * _pulseAnimation.value : 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: intentState is IntentProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Icon(
                              intentState is IntentListening ? Icons.stop : Icons.mic,
                              color: Colors.white,
                              size: 40,
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          if (intentState is IntentListening)
            Text(
              'Tap to stop',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade500),
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageToggle(IntentViewModel viewModel) {
    return PopupMenuButton<String>(
      initialValue: viewModel.currentLocale,
      onSelected: (String locale) {
        setState(() {
          viewModel.setLocale(locale);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              viewModel.currentLocale == 'hi-IN' ? 'HI' : viewModel.currentLocale == 'mr-IN' ? 'MR' : 'EN',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor, size: 20),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'en-IN',
          child: Text('English (India)'),
        ),
        const PopupMenuItem<String>(
          value: 'hi-IN',
          child: Text('हिंदी (Hindi)'),
        ),
        const PopupMenuItem<String>(
          value: 'mr-IN',
          child: Text('मराठी (Marathi)'),
        ),
      ],
    );
  }
}
