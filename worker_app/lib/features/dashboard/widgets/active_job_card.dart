import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../jobs/screens/active_job_screen.dart';

class ActiveJobCard extends StatefulWidget {
  final Map<String, dynamic> jobData;

  const ActiveJobCard({super.key, required this.jobData});

  @override
  State<ActiveJobCard> createState() => _ActiveJobCardState();
}

class _ActiveJobCardState extends State<ActiveJobCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveJobScreen(jobData: widget.jobData),
          ),
        );
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 16),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isPressed ? 0.02 : 0.08),
              blurRadius: _isPressed ? 10 : 20,
              offset: Offset(0, _isPressed ? 4 : 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.handyman_rounded,
                          color: AppTheme.primaryBlue,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.jobData['service_category'] ?? 'Active Job',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF3B82F6),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Ongoing',
                                  style: TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.jobData['status']?.replaceAll('_', ' ') ??
                          'ACTIVE',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: const Color(0xFFF1F5F9)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Location details shared upon acceptance',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ActiveJobScreen(jobData: widget.jobData),
                          ),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text(
                        'Navigate',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E293B),
                        side: const BorderSide(
                          color: Color(0xFFE2E8F0),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ActiveJobScreen(jobData: widget.jobData),
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: const Text(
                        'Complete',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
