import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/worker_model.dart';
import '../providers/dashboard_provider.dart';

class WorkerStatusCard extends ConsumerWidget {
  final WorkerModel worker;

  const WorkerStatusCard({super.key, required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Worker Status',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: worker.isOnline
                                ? AppTheme.successGreen
                                : Colors.grey[400],
                            boxShadow: worker.isOnline
                                ? [
                                    BoxShadow(
                                      color: AppTheme.successGreen.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          worker.isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            color: worker.isOnline
                                ? AppTheme.successGreen
                                : Colors.grey[600],
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Transform.scale(
                  scale: 1.2,
                  child: Switch(
                    value: worker.isOnline,
                    activeColor: Colors.white,
                    activeTrackColor: AppTheme.successGreen,
                    inactiveThumbColor: Colors.grey[400],
                    inactiveTrackColor: Colors.grey[200],
                    onChanged: (value) async {
                      try {
                        final service = ref.read(dashboardServiceProvider);
                        await service.updateWorkerStatus(worker.userId, value);
                        ref.invalidate(
                          currentWorkerProvider,
                        ); // Refresh to show new state
                      } catch (e) {
                        // silently handle
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(height: 1, color: Colors.grey.withOpacity(0.1)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Radius',
                  '${worker.serviceRadiusKm?.toStringAsFixed(0) ?? 0} km',
                  Icons.my_location_rounded,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.2),
                ),
                _buildStatItem(
                  context,
                  'Rating',
                  '${worker.rating?.toStringAsFixed(1) ?? 'N/A'}',
                  Icons.star_rounded,
                  iconColor: Colors.amber,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.2),
                ),
                _buildStatItem(
                  context,
                  'Jobs',
                  '${worker.totalJobs ?? 0}',
                  Icons.work_rounded,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor ?? AppTheme.primaryBlue),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
