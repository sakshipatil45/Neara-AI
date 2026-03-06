import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'booking_details_screen.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/my_bookings_viewmodel.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myBookingsViewModelProvider);

    // Show a banner whenever a worker sends a new proposal in realtime.
    ref.listen<int>(newProposalAlertProvider, (prev, next) {
      if (prev == null || next <= (prev)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.mark_email_unread_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'A worker sent you a new proposal!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () =>
                ref.read(myBookingsViewModelProvider.notifier).loadBookings(),
          ),
        ],
      ),
      body: state.isLoading && state.bookings.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
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
          Icon(Icons.history_outlined, size: 80, color: AppTheme.textDisabled),
          const SizedBox(height: 24),
          Text(
            'No bookings yet',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'Your service requests will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(
    BuildContext context,
    List<BookingRequest> bookings,
  ) {
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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
              builder: (context) =>
                  BookingDetailsScreen(requestId: booking.id!),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: booking.statusColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: booking.statusColor.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      booking.statusText.toUpperCase(),
                      style: TextStyle(
                        color: booking.statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    _formatDate(booking.createdAt),
                    style: Theme.of(context).textTheme.bodySmall,
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
                          style: Theme.of(context).textTheme.headlineSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.serviceCategory,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textDisabled,
                  ),
                ],
              ),
              if (booking.workerName != null) ...[
                const SizedBox(height: 16),
                const Divider(color: AppTheme.borderDefault, height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.backgroundTertiary,
                      backgroundImage: booking.workerProfileImage != null
                          ? NetworkImage(booking.workerProfileImage!)
                          : null,
                      child: booking.workerProfileImage == null
                          ? const Icon(
                              Icons.person,
                              size: 16,
                              color: AppTheme.textDisabled,
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      booking.workerName!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF59E0B),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '4.8', // Placeholder rating
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
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
