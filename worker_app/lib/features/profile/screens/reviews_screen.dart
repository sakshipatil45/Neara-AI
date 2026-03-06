import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workerAsync = ref.watch(currentWorkerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Reviews',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1E293B)),
      ),
      body: workerAsync.when(
        data: (worker) {
          // Mock data for demonstration if no reviews table joined yet
          final reviews = [
            {
              'name': 'Rahul S.',
              'rating': 5.0,
              'comment': 'Excellent work! Very professional and on time.',
              'date': '2 days ago',
            },
            {
              'name': 'Suresh K.',
              'rating': 4.5,
              'comment':
                  'Great fix for the plumbing issue. Highly recommended.',
              'date': '1 week ago',
            },
            {
              'name': 'Anita P.',
              'rating': 5.0,
              'comment': 'Came in 20 mins and fixed the AC immediately.',
              'date': '2 weeks ago',
            },
          ];

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          review['name'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          review['date'] as String,
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          Icons.star_rounded,
                          color: i < (review['rating'] as double).floor()
                              ? Colors.orange
                              : Colors.grey.shade300,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      review['comment'] as String,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading reviews: $e')),
      ),
    );
  }
}
