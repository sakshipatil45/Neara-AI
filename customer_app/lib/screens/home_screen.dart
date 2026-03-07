import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/home_header.dart';
import '../widgets/voice_hero_card.dart';
import '../widgets/sos_card.dart';
import '../widgets/quick_services_list.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.screenBackgroundGradient,
        ),
        child: CustomScrollView(
          slivers: [
            // ── Sticky header ──
            SliverAppBar(
              pinned: true,
              expandedHeight: 0,
              backgroundColor: AppTheme.backgroundPrimary,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.08),
              flexibleSpace: const SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: HomeHeader(),
                ),
              ),
              toolbarHeight: 72,
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Voice section label ──
                    _SectionLabel(
                      icon: Icons.mic_rounded,
                      label: 'Book a Service',
                      iconColor: AppTheme.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    const VoiceHeroCard(),
                    const SizedBox(height: 24),

                    // ── Emergency ──
                    _SectionLabel(
                      icon: Icons.emergency_rounded,
                      label: 'Emergency',
                      iconColor: AppTheme.errorRed,
                    ),
                    const SizedBox(height: 12),
                    const SosCard(),
                    const SizedBox(height: 24),

                    // ── Quick services ──
                    const QuickServicesList(),
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
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
