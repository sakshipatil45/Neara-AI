import 'package:flutter/material.dart';

class QuickServicesList extends StatelessWidget {
  const QuickServicesList({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      {'name': 'Plumber', 'icon': Icons.plumbing, 'color': Colors.blue.shade100},
      {'name': 'Electrician', 'icon': Icons.electrical_services, 'color': Colors.orange.shade100},
      {'name': 'Mechanic', 'icon': Icons.car_repair, 'color': Colors.grey.shade300},
      {'name': 'Appliance', 'icon': Icons.kitchen, 'color': Colors.green.shade100},
      {'name': 'Cleaning', 'icon': Icons.cleaning_services, 'color': Colors.teal.shade100},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quick Services',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: services.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final service = services[index];
              return _buildServiceItem(
                context,
                service['name'] as String,
                service['icon'] as IconData,
                service['color'] as Color,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiceItem(BuildContext context, String name, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {},
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
