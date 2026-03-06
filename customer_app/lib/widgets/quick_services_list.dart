import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class QuickServicesList extends StatelessWidget {
  const QuickServicesList({super.key});

  static const List<_ServiceData> _services = [
    _ServiceData(
      name: 'Plumber',
      icon: Icons.plumbing_rounded,
      bg: Color(0xFFEFF6FF),
      fg: Color(0xFF2563EB),
    ),
    _ServiceData(
      name: 'Electrician',
      icon: Icons.electrical_services_rounded,
      bg: Color(0xFFFFF7ED),
      fg: Color(0xFFEA580C),
    ),
    _ServiceData(
      name: 'Mechanic',
      icon: Icons.car_repair_rounded,
      bg: Color(0xFFF1F5F9),
      fg: Color(0xFF475569),
    ),
    _ServiceData(
      name: 'Appliance',
      icon: Icons.kitchen_rounded,
      bg: Color(0xFFECFDF5),
      fg: Color(0xFF059669),
    ),
    _ServiceData(
      name: 'Cleaning',
      icon: Icons.cleaning_services_rounded,
      bg: Color(0xFFF0FDFA),
      fg: Color(0xFF0D9488),
    ),
    _ServiceData(
      name: 'Carpenter',
      icon: Icons.handyman_rounded,
      bg: Color(0xFFFDF4FF),
      fg: Color(0xFF9333EA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Services',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See all',
                style: TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: _services.length,
          itemBuilder: (context, index) => _ServiceTile(data: _services[index]),
        ),
      ],
    );
  }
}

class _ServiceData {
  final String name;
  final IconData icon;
  final Color bg;
  final Color fg;
  const _ServiceData({
    required this.name,
    required this.icon,
    required this.bg,
    required this.fg,
  });
}

class _ServiceTile extends StatelessWidget {
  final _ServiceData data;
  const _ServiceTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundPrimary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderDefault),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: data.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(data.icon, size: 24, color: data.fg),
              ),
              const SizedBox(height: 8),
              Text(
                data.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
