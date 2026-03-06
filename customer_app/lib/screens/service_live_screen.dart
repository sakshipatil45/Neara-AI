import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import '../viewmodels/workers_viewmodel.dart';
import 'service_completion_screen.dart';

class ServiceLiveScreen extends ConsumerStatefulWidget {
  final int requestId;

  const ServiceLiveScreen({super.key, required this.requestId});

  @override
  ConsumerState<ServiceLiveScreen> createState() => _ServiceLiveScreenState();
}

class _ServiceLiveScreenState extends ConsumerState<ServiceLiveScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _confirmCompletion(BuildContext ctx) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        title: const Text('Confirm Completion'),
        content: const Text(
          'Has the worker finished the job? This will request the final payment from you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
            ),
            child: const Text('Yes, Completed'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isConfirming = true);
    try {
      final repo = ref.read(workerRepositoryProvider);
      await repo.confirmServiceCompletion(widget.requestId);
      ref.read(myBookingsViewModelProvider.notifier).loadBookings();
      // BookingDetails realtime will update — status becomes FINAL_PAYMENT_PENDING
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingDetailsViewModelProvider(widget.requestId));
    final booking = state.booking;

    // Navigate to payment screen when status becomes FINAL_PAYMENT_PENDING
    ref.listen(bookingDetailsViewModelProvider(widget.requestId), (prev, next) {
      final b = next.booking;
      if (b != null && b.needsFinalPayment && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ServiceCompletionScreen(requestId: widget.requestId),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        title: const Text('Live Service Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: booking == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : _buildBody(context, booking),
    );
  }

  Widget _buildBody(BuildContext ctx, BookingRequest booking) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(ctx, booking),
          const SizedBox(height: 24),
          _buildWorkersteps(ctx, booking),
          const SizedBox(height: 24),
          _buildWorkerCard(ctx, booking),
          const SizedBox(height: 24),
          _buildServiceInfo(ctx, booking),
          const SizedBox(height: 32),
          if (booking.isServiceActive) _buildConfirmButton(ctx),
          if (booking.isWorkerEnRoute) _buildWorkerEnRouteNote(ctx),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext ctx, BookingRequest booking) {
    final Color color = booking.statusColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.04)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) => Container(
              width: 70 + (_pulseController.value * 10),
              height: 70 + (_pulseController.value * 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(
                  alpha: 0.12 + (_pulseController.value * 0.06),
                ),
              ),
              child: Icon(_statusIcon(booking.status), color: color, size: 38),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            booking.statusText,
            style: Theme.of(ctx).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _statusDescription(booking.status),
            style: Theme.of(
              ctx,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersteps(BuildContext ctx, BookingRequest booking) {
    final steps = [
      _Step('WORKER_COMING', 'Worker Dispatched', Icons.directions_run_rounded),
      _Step('WORKER_ARRIVED', 'Worker Arrived', Icons.place_rounded),
      _Step('SERVICE_STARTED', 'Work in Progress', Icons.construction_rounded),
      _Step('SERVICE_COMPLETED', 'Job Completed', Icons.task_alt_rounded),
    ];

    final statuses = steps.map((s) => s.status).toList();
    final currentIndex = statuses.indexOf(booking.status.toUpperCase());
    final effectiveIndex = currentIndex == -1 ? 0 : currentIndex;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Progress',
            style: Theme.of(ctx).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          ...steps.asMap().entries.map((e) {
            final i = e.key;
            final step = e.value;
            final isDone = i < effectiveIndex;
            final isCurrent = i == effectiveIndex;
            return _StepRow(
              step: step,
              isDone: isDone,
              isCurrent: isCurrent,
              isLast: i == steps.length - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(BuildContext ctx, BookingRequest booking) {
    if (booking.workerName == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDefault),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.backgroundTertiary,
            backgroundImage: booking.workerProfileImage != null
                ? NetworkImage(booking.workerProfileImage!)
                : null,
            child: booking.workerProfileImage == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 28,
                    color: AppTheme.textDisabled,
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.workerName!,
                  style: Theme.of(
                    ctx,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  booking.serviceCategory,
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.phone_rounded, color: AppTheme.successGreen),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo(BuildContext ctx, BookingRequest booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Booking Details', style: Theme.of(ctx).textTheme.headlineSmall),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.category_rounded,
            label: 'Category',
            value: booking.serviceCategory,
          ),
          _InfoRow(
            icon: Icons.description_rounded,
            label: 'Issue',
            value: booking.issueSummary,
          ),
          _InfoRow(
            icon: Icons.priority_high_rounded,
            label: 'Urgency',
            value: booking.urgency.toUpperCase(),
          ),
          if (booking.id != null)
            _InfoRow(
              icon: Icons.confirmation_number_rounded,
              label: 'Booking ID',
              value: '#${booking.id}',
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(BuildContext ctx) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isConfirming ? null : () => _confirmCompletion(ctx),
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.successGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: _isConfirming
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.task_alt_rounded),
        label: Text(
          _isConfirming ? 'Confirming...' : 'Confirm Job Completion',
          style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildWorkerEnRouteNote(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppTheme.primaryBlue,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "The worker is on the way. You'll be able to confirm completion after the service begins.",
              style: Theme.of(
                ctx,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.primaryBlue),
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'WORKER_COMING':
        return Icons.directions_run_rounded;
      case 'WORKER_ARRIVED':
        return Icons.place_rounded;
      case 'SERVICE_STARTED':
        return Icons.construction_rounded;
      case 'SERVICE_COMPLETED':
      case 'FINAL_PAYMENT_PENDING':
        return Icons.task_alt_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _statusDescription(String status) {
    switch (status.toUpperCase()) {
      case 'WORKER_COMING':
        return 'Your worker is on the way. Please be available at the location.';
      case 'WORKER_ARRIVED':
        return 'Worker has arrived. Please let them in.';
      case 'SERVICE_STARTED':
        return 'Service is in progress. Please stay available for assistance.';
      case 'SERVICE_COMPLETED':
      case 'FINAL_PAYMENT_PENDING':
        return 'Worker has marked the job done. Confirm completion to proceed with final payment.';
      default:
        return 'Tracking service status...';
    }
  }
}

class _Step {
  final String status;
  final String label;
  final IconData icon;
  const _Step(this.status, this.label, this.icon);
}

class _StepRow extends StatelessWidget {
  final _Step step;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;

  const _StepRow({
    required this.step,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    const active = AppTheme.primaryBlue;
    final inactive = AppTheme.borderDefault;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone || isCurrent
                      ? active
                      : AppTheme.backgroundSecondary,
                  border: Border.all(
                    color: isDone || isCurrent ? active : inactive,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : step.icon,
                  size: 18,
                  color: isDone || isCurrent
                      ? Colors.white
                      : AppTheme.textDisabled,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? active : inactive,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    step.label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: isDone || isCurrent
                          ? AppTheme.textPrimary
                          : AppTheme.textDisabled,
                    ),
                  ),
                  if (isCurrent)
                    Text(
                      'Current stage',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: active),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textTertiary),
          const SizedBox(width: 10),
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
