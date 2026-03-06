import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import '../models/booking_model.dart';
import 'booking_details_screen.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBookingsViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => ref.read(myBookingsViewModelProvider.notifier).loadBookings(),
          ),
        ],
      ),
      body: state.isLoading && state.bookings.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : state.bookings.isEmpty
              ? _buildEmptyState(context)
              : _buildBookingsList(context, state.bookings),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 24),
          const Text(
            'No bookings yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your service requests will appear here.',
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(BuildContext context, List<BookingRequest> bookings) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingCard(booking: booking);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingRequest booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingDetailsScreen(requestId: booking.id!),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: booking.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: booking.statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      booking.statusText.toUpperCase(),
                      style: TextStyle(
                        color: booking.statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(booking.createdAt),
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _ServiceIcon(category: booking.serviceCategory),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.issueSummary,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Category: ${booking.serviceCategory}',
                          style: const TextStyle(color: Colors.white60, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white24),
                ],
              ),
              if (booking.workerName != null) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.white10,
                      backgroundImage: booking.workerProfileImage != null
                          ? NetworkImage(booking.workerProfileImage!)
                          : null,
                      child: booking.workerProfileImage == null
                          ? const Icon(Icons.person, size: 14, color: Colors.white24)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Assigned: ${booking.workerName}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month}';
  }
}

class _ServiceIcon extends StatelessWidget {
  final String category;
  const _ServiceIcon({required this.category});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (category.toLowerCase()) {
      case 'plumber':
        icon = Icons.plumbing;
        color = Colors.blue;
        break;
      case 'electrician':
        icon = Icons.flash_on;
        color = Colors.yellow;
        break;
      case 'mechanic':
        icon = Icons.directions_car;
        color = Colors.orange;
        break;
      default:
        icon = Icons.handyman;
        color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
