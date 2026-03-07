import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/worker_listing_screen.dart';

class QuickServicesList extends StatelessWidget {
  const QuickServicesList({super.key});

  static const List<_ServiceData> _services = [
    _ServiceData(
      name: 'Plumber',
      category: 'Plumber',
      icon: Icons.plumbing_rounded,
      bg: Color(0xFFEFF6FF),
      fg: Color(0xFF2563EB),
    ),
    _ServiceData(
      name: 'Electrician',
      category: 'Electrician',
      icon: Icons.electrical_services_rounded,
      bg: Color(0xFFFFF7ED),
      fg: Color(0xFFEA580C),
    ),
    _ServiceData(
      name: 'Mechanic',
      category: 'Mechanic',
      icon: Icons.car_repair_rounded,
      bg: Color(0xFFF1F5F9),
      fg: Color(0xFF475569),
    ),
    _ServiceData(
      name: 'Appliance',
      category: 'Gas Service',
      icon: Icons.kitchen_rounded,
      bg: Color(0xFFECFDF5),
      fg: Color(0xFF059669),
    ),
    _ServiceData(
      name: 'Cleaning',
      category: 'Maid',
      icon: Icons.cleaning_services_rounded,
      bg: Color(0xFFF0FDFA),
      fg: Color(0xFF0D9488),
    ),
    _ServiceData(
      name: 'Carpenter',
      category: 'All',
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkerListingScreen()),
              ),
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
  final String category;
  final IconData icon;
  final Color bg;
  final Color fg;
  const _ServiceData({
    required this.name,
    required this.category,
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [data.bg, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.fg.withValues(alpha: 0.18)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkerListingScreen(
                initialCategory: data.category == 'All' ? null : data.category,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [data.bg, data.fg.withValues(alpha: 0.12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
