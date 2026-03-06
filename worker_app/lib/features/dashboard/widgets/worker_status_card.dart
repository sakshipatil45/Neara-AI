import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/worker_model.dart';
import '../providers/dashboard_provider.dart';
import '../../../services/location_service.dart';

class WorkerStatusCard extends ConsumerWidget {
  final WorkerModel worker;

  const WorkerStatusCard({super.key, required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS',
                      style: TextStyle(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (worker.isOnline)
                          Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.successGreen,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.successGreen.withOpacity(
                                        0.6,
                                      ),
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .fade(begin: 0.6, end: 1.0, duration: 800.ms)
                              .scale(
                                begin: const Offset(0.9, 0.9),
                                end: const Offset(1.1, 1.1),
                                duration: 800.ms,
                              )
                        else
                          Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        const SizedBox(width: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.0, -0.2),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                          child: Text(
                            worker.isOnline ? 'ONLINE' : 'OFFLINE',
                            key: ValueKey<bool>(worker.isOnline),
                            style: TextStyle(
                              color: worker.isOnline
                                  ? AppTheme.successGreen
                                  : const Color(0xFF64748B),
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: worker.isOnline,
                    activeColor: Colors.white,
                    activeTrackColor: AppTheme.successGreen,
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFCBD5E1),
                    onChanged: (value) async {
                      try {
                        final service = ref.read(dashboardServiceProvider);
                        await service.updateWorkerStatus(worker.userId, value);

                        // Handle tracking
                        if (value) {
                          ref.read(locationServiceProvider).startTracking();
                        } else {
                          ref.read(locationServiceProvider).stopTracking();
                        }

                        ref.invalidate(currentWorkerProvider);
                      } catch (e) {
                        // silently handle
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Radius',
                  '${worker.serviceRadiusKm?.toStringAsFixed(0) ?? 0} km',
                  Icons.radar_rounded,
                  iconColor: const Color(0xFF3B82F6),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
                _buildStatItem(
                  context,
                  'Rating',
                  '${worker.rating?.toStringAsFixed(1) ?? 'N/A'}',
                  Icons.star_rounded,
                  iconColor: const Color(0xFFF59E0B),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFF1F5F9)),
                _buildStatItem(
                  context,
                  'Jobs',
                  '${worker.totalJobs ?? 0}',
                  Icons.task_alt_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: iconColor ?? AppTheme.primaryBlue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
