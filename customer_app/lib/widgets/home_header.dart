import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.onSurface),
                const SizedBox(width: 4),
                Text(
                  'Koramangala, Bangalore',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 20),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
          ),
        )
      ],
    );
  }
}
