import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../models/proposal_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import 'service_live_screen.dart';
import 'service_completion_screen.dart';
import 'review_screen.dart';
import 'advance_payment_screen.dart';
import 'final_payment_screen.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final int requestId;

  const BookingDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingDetailsViewModelProvider(requestId));
    final booking = state.booking;

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      body: state.isLoading && booking == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : booking == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Booking not found'),
                  if (state.error != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        state.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.errorRed,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : Column(
              children: [
                if (state.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    color: AppTheme.errorRed.withValues(alpha: 0.1),
                    child: Text(
                      state.error!,
                      style: const TextStyle(
                        color: AppTheme.errorRed,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context, booking),
                        const SizedBox(height: 32),
                        _buildTimeline(context, booking.status),
                        const SizedBox(height: 32),
                        if (booking.workerName != null)
                          _buildWorkerInfo(context, booking),
                        const SizedBox(height: 24),
                        _buildLifecycleCTA(context, booking, state.proposals),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLifecycleCTA(
    BuildContext context,
    BookingRequest booking,
    List<Proposal> proposals,
  ) {
    // Worker en route or service active → live tracking
    if (booking.isWorkerEnRoute || booking.isServiceActive) {
      return _ctaButton(
        context,
        icon: Icons.location_on_rounded,
        label: booking.isServiceActive ? 'Track Service' : 'Track Worker',
        color: const Color(0xFF0284C7),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceLiveScreen(requestId: requestId),
          ),
        ),
      );
    }

    // Final payment needed
    if (booking.needsFinalPayment) {
      return _ctaButton(
        context,
        icon: Icons.lock_open_rounded,
        label: 'Pay Final Balance',
        color: AppTheme.primaryBlue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceCompletionScreen(requestId: requestId),
          ),
        ),
      );
    }

    // Review pending
    if (booking.canReview) {
      return _ctaButton(
        context,
        icon: Icons.star_rounded,
        label: 'Rate & Review',
        color: const Color(0xFFF59E0B),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewScreen(
              requestId: requestId,
              workerId: booking.workerId ?? 0,
              workerName: booking.workerName,
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _ctaButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BookingRequest booking) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.serviceCategory.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: booking.statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
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
            ],
          ),
          const SizedBox(height: 16),
          Text(
            booking.issueSummary,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'Urgency: ${booking.urgency.toUpperCase()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, String currentStatus) {
    final stages = [
      'CREATED',
      'PROPOSAL_SENT',
      'PROPOSAL_ACCEPTED',
      'WORKER_COMING',
      'SERVICE_STARTED',
      'SERVICE_COMPLETED',
    ];

    int currentIndex = stages.indexOf(currentStatus.toUpperCase());
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service Progress',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stages.length,
          itemBuilder: (context, index) {
            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isCurrent
                            ? AppTheme.primaryBlue
                            : AppTheme.gray200,
                        border: isCurrent
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    if (index < stages.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: isCompleted
                            ? AppTheme.primaryBlue
                            : AppTheme.gray200,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stageToLabel(stages[index]),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isCompleted || isCurrent
                              ? AppTheme.textPrimary
                              : AppTheme.textDisabled,
                          fontWeight: isCurrent
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isCurrent)
                        Text(
                          'Currently here',
                          style: TextStyle(
                            color: AppTheme.primaryBlue.withOpacity(0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _stageToLabel(String stage) {
    switch (stage) {
      case 'CREATED':
        return 'Finding Worker';
      case 'PROPOSAL_SENT':
        return 'Worker Proposals';
      case 'PROPOSAL_ACCEPTED':
        return 'Worker Assigned';
      case 'WORKER_COMING':
        return 'Worker is on the way';
      case 'SERVICE_STARTED':
        return 'Task in progress';
      case 'SERVICE_COMPLETED':
        return 'Completed';
      default:
        return stage;
    }
  }

  Widget _buildWorkerInfo(BuildContext context, BookingRequest booking) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.backgroundTertiary,
                backgroundImage: booking.workerProfileImage != null
                    ? NetworkImage(booking.workerProfileImage!)
                    : null,
                child: booking.workerProfileImage == null
                    ? const Icon(
                        Icons.person,
                        size: 30,
                        color: AppTheme.textDisabled,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.workerName ?? 'Worker',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      'Assigned Expert',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {}, // Chat/Call functionality
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
