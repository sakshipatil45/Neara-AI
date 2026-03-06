import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../models/proposal_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import '../viewmodels/workers_viewmodel.dart';
import 'service_completion_screen.dart';
import 'work_photo_review_screen.dart';
import 'review_screen.dart';
import 'proposal_screen.dart';
import 'payment_screen.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final int requestId;

  const BookingDetailsScreen({super.key, required this.requestId});

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Always fetch fresh data from DB when this screen opens.
    // The provider is non-autoDispose so its build() only runs once;
    // without this, a cached (stale) state would be shown on re-navigation.
    Future.microtask(
      () => ref
          .read(bookingDetailsViewModelProvider(widget.requestId).notifier)
          .loadDetails(widget.requestId),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingDetailsViewModelProvider(widget.requestId));
    final booking = state.booking;

    // Auto-navigate on real-time status transitions
    ref.listen(bookingDetailsViewModelProvider(widget.requestId), (prev, next) {
      final b = next.booking;
      if (b == null || !mounted) return;
      if (b.isPhotoReviewPending) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => WorkPhotoReviewScreen(requestId: widget.requestId),
          ),
        );
      } else if (b.needsFinalPayment) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ServiceCompletionScreen(requestId: widget.requestId),
          ),
        );
      }
    });

    if (state.isLoading && booking == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundPrimary,
          elevation: 0,
          title: const Text('Booking Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundSecondary,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundPrimary,
          elevation: 0,
          title: const Text('Booking Details'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 56,
                color: AppTheme.textDisabled,
              ),
              const SizedBox(height: 16),
              const Text(
                'Booking not found',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
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
        ),
      );
    }

    final bool isLive = booking.isWorkerEnRoute || booking.isServiceActive;
    final Color color = booking.statusColor;
    final int step = _statusToStep(booking.status);
    const int totalSteps = 7;

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      body: CustomScrollView(
        slivers: [
          // ── Collapsible header ────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            backgroundColor: AppTheme.backgroundPrimary,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              booking.serviceCategory,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.22),
                          color.withValues(alpha: 0.10),
                          color.withValues(alpha: 0.03),
                          AppTheme.backgroundSecondary,
                        ],
                        stops: const [0.0, 0.35, 0.70, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Decorative large circle — top right
                  Positioned(
                    top: -55,
                    right: -55,
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                  // Decorative small circle — bottom left
                  Positioned(
                    bottom: 20,
                    left: -25,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 96, 20, 18),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Service category micro-label
                        Text(
                          booking.serviceCategory.toUpperCase(),
                          style: TextStyle(
                            color: color.withValues(alpha: 0.75),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Issue summary — main title
                        Text(
                          booking.issueSummary,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 21,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 13),
                        // Status row
                        Row(
                          children: [
                            if (isLive) ...[
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) => Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.successGreen.withValues(
                                      alpha: 0.5 + _pulseController.value * 0.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: AppTheme.successGreen,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            // Status pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.13),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.30),
                                ),
                              ),
                              child: Text(
                                booking.statusText.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Urgency + ID badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundPrimary.withValues(
                                  alpha: 0.60,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.borderDefault.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.bolt_rounded,
                                    size: 12,
                                    color: AppTheme.textTertiary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    booking.urgency.toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (booking.id != null) ...[
                                    const SizedBox(width: 7),
                                    Container(
                                      width: 1,
                                      height: 10,
                                      color: AppTheme.borderDefault,
                                    ),
                                    const SizedBox(width: 7),
                                    const Icon(
                                      Icons.tag_rounded,
                                      size: 12,
                                      color: AppTheme.textTertiary,
                                    ),
                                    Text(
                                      '${booking.id}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // 7-segment step progress strip
                        Row(
                          children: List.generate(totalSteps, (i) {
                            final filled = i <= step;
                            return Expanded(
                              child: Container(
                                height: 3,
                                margin: EdgeInsets.only(
                                  right: i < totalSteps - 1 ? 3.0 : 0.0,
                                ),
                                decoration: BoxDecoration(
                                  color: filled
                                      ? color
                                      : color.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (state.error != null) ...[
                    _ErrorBanner(message: state.error!),
                    const SizedBox(height: 16),
                  ],

                  // Live alert card
                  if (isLive || booking.isPhotoReviewPending) ...[
                    _LiveStatusCard(
                      booking: booking,
                      pulseController: _pulseController,
                      isLive: isLive,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Journey timeline
                  _JourneyTimeline(
                    booking: booking,
                    pulseController: _pulseController,
                    isLive: isLive,
                    currentStep: step,
                  ),
                  const SizedBox(height: 16),

                  // Worker card
                  if (booking.workerName != null) ...[
                    _WorkerCard(booking: booking),
                    const SizedBox(height: 16),
                  ],

                  // Booking details
                  _BookingInfoCard(booking: booking),
                  const SizedBox(height: 24),

                  // CTA
                  _LifecycleCTA(
                    booking: booking,
                    proposals: state.proposals,
                    requestId: widget.requestId,
                    pulseController: _pulseController,
                    ref: ref,
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

int _statusToStep(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
    case 'CREATED':
    case 'MATCHING':
      return 0;
    case 'PROPOSAL_SENT':
    case 'NEGOTIATING':
      return 1;
    case 'PROPOSAL_ACCEPTED':
    case 'ADVANCE_PAID':
      return 2;
    case 'WORKER_COMING':
    case 'WORKER_ARRIVED':
      return 3;
    case 'SERVICE_STARTED':
      return 4;
    case 'SERVICE_COMPLETED':
    case 'FINAL_PAYMENT_PENDING':
      return 5;
    case 'SERVICE_CLOSED':
    case 'PAYMENT_DONE':
    case 'RATED':
      return 6;
    default:
      return 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live Status Card
// ─────────────────────────────────────────────────────────────────────────────
class _LiveStatusCard extends StatelessWidget {
  final BookingRequest booking;
  final AnimationController pulseController;
  final bool isLive;

  const _LiveStatusCard({
    required this.booking,
    required this.pulseController,
    required this.isLive,
  });

  IconData get _icon {
    switch (booking.status.toUpperCase()) {
      case 'WORKER_COMING':
        return Icons.directions_run_rounded;
      case 'WORKER_ARRIVED':
        return Icons.place_rounded;
      case 'SERVICE_STARTED':
        return Icons.construction_rounded;
      case 'SERVICE_COMPLETED':
        return Icons.task_alt_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String get _description {
    switch (booking.status.toUpperCase()) {
      case 'WORKER_COMING':
        return 'Your worker is heading to your location. Please be available.';
      case 'WORKER_ARRIVED':
        return 'Worker has arrived at your location. Please let them in.';
      case 'SERVICE_STARTED':
        return 'Work is in progress. Stay available if the worker needs assistance.';
      case 'SERVICE_COMPLETED':
        return 'Worker finished and uploaded photos. Review them to approve.';
      default:
        return 'Tracking service status...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = booking.statusColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          if (isLive)
            AnimatedBuilder(
              animation: pulseController,
              builder: (context, child) => Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(
                    alpha: 0.12 + pulseController.value * 0.08,
                  ),
                ),
                child: Icon(_icon, color: color, size: 22),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(_icon, color: color, size: 22),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.statusText,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Journey Timeline
// ─────────────────────────────────────────────────────────────────────────────
class _JourneyTimeline extends StatelessWidget {
  final BookingRequest booking;
  final AnimationController pulseController;
  final bool isLive;
  final int currentStep;

  const _JourneyTimeline({
    required this.booking,
    required this.pulseController,
    required this.isLive,
    required this.currentStep,
  });

  static const _stages = [
    _Stage('Request Sent', 'Looking for available workers', Icons.send_rounded),
    _Stage(
      'Offer Received',
      'Worker sent a proposal',
      Icons.local_offer_rounded,
    ),
    _Stage(
      'Booking Confirmed',
      'Advance paid · Slot locked',
      Icons.verified_rounded,
    ),
    _Stage(
      'Worker En Route',
      'Heading to your location',
      Icons.directions_run_rounded,
    ),
    _Stage(
      'Service In Progress',
      'Worker is on the job',
      Icons.construction_rounded,
    ),
    _Stage(
      'Work Completed',
      'Review photos · Pay balance',
      Icons.task_alt_rounded,
    ),
    _Stage(
      'All Done',
      'Payment done · Job finalized',
      Icons.check_circle_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = currentStep;
    final stepsLeft = _stages.length - 1 - idx;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: icon + title + step count badge
          Row(
            children: [
              const Icon(
                Icons.route_rounded,
                size: 17,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Service Journey',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step ${idx + 1} of ${_stages.length}',
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Current step label
          Text(
            _stages[idx].label,
            style: const TextStyle(
              color: AppTheme.primaryBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          // Thin progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (idx + 1) / _stages.length,
              minHeight: 3,
              backgroundColor: AppTheme.borderDefault,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryBlue,
              ),
            ),
          ),
          if (stepsLeft > 0)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '$stepsLeft step${stepsLeft > 1 ? 's' : ''} remaining',
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 11,
                ),
              ),
            ),
          const SizedBox(height: 20),
          ..._stages.asMap().entries.map((e) {
            final i = e.key;
            final stage = e.value;
            final isDone = i < idx;
            final isCurrent = i == idx;
            final animate = isCurrent && isLive;
            return _TimelineStep(
              index: i,
              label: stage.label,
              sublabel: stage.sublabel,
              icon: stage.icon,
              isDone: isDone,
              isCurrent: isCurrent,
              isLast: i == _stages.length - 1,
              pulseController: animate ? pulseController : null,
            );
          }),
        ],
      ),
    );
  }
}

class _Stage {
  final String label;
  final String sublabel;
  final IconData icon;
  const _Stage(this.label, this.sublabel, this.icon);
}

class _TimelineStep extends StatelessWidget {
  final int index;
  final String label;
  final String sublabel;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;
  final bool isLast;
  final AnimationController? pulseController;

  const _TimelineStep({
    required this.index,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
    required this.isLast,
    this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppTheme.primaryBlue;
    final inactiveColor = AppTheme.borderDefault;

    // Visual sizing: current step is larger
    final double nodeSize = isCurrent ? 40.0 : 28.0;

    Widget buildNode() {
      if (isDone) {
        // Compact filled circle with checkmark
        return Container(
          width: nodeSize,
          height: nodeSize,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: activeColor,
          ),
          child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
        );
      }

      if (isCurrent) {
        if (pulseController != null) {
          // Live pulsing ring
          return AnimatedBuilder(
            animation: pulseController!,
            builder: (context, child) {
              final pulse = pulseController!.value;
              return Container(
                width: nodeSize,
                height: nodeSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor.withValues(alpha: 0.10 + pulse * 0.10),
                  border: Border.all(color: activeColor, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.15 + pulse * 0.20),
                      blurRadius: 8 + pulse * 6,
                      spreadRadius: pulse * 2,
                    ),
                  ],
                ),
                child: Icon(icon, size: 18, color: activeColor),
              );
            },
          );
        } else {
          // Static current ring
          return Container(
            width: nodeSize,
            height: nodeSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: activeColor.withValues(alpha: 0.10),
              border: Border.all(color: activeColor, width: 2.0),
              boxShadow: [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.18),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: activeColor),
          );
        }
      }

      // Pending: gray circle with step number
      return Container(
        width: nodeSize,
        height: nodeSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.backgroundSecondary,
          border: Border.all(color: inactiveColor),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDisabled,
            ),
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left column: node + connector
          SizedBox(
            width: 44,
            child: Column(
              children: [
                // Centre the node in the 44px column
                SizedBox(width: 44, child: Center(child: buildNode())),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: isDone ? activeColor : inactiveColor,
                          borderRadius: BorderRadius.circular(1),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Right column: label + sublabel
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 22,
                top: isCurrent ? 10 : 5,
                left: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontWeight: isCurrent
                                ? FontWeight.w700
                                : isDone
                                ? FontWeight.w500
                                : FontWeight.w400,
                            fontSize: isCurrent ? 14 : 13,
                            color: isDone
                                ? AppTheme.textSecondary
                                : isCurrent
                                ? AppTheme.textPrimary
                                : AppTheme.textDisabled,
                          ),
                        ),
                      ),
                      if (isCurrent) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: activeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'NOW',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isCurrent || isDone) ...[
                    const SizedBox(height: 3),
                    Text(
                      sublabel,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: isCurrent
                            ? activeColor.withValues(alpha: 0.85)
                            : AppTheme.textDisabled,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Worker Card
// ─────────────────────────────────────────────────────────────────────────────
class _WorkerCard extends StatelessWidget {
  final BookingRequest booking;
  const _WorkerCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.engineering_rounded,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Assigned Worker',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      booking.serviceCategory,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Booking Info Card
// ─────────────────────────────────────────────────────────────────────────────
class _BookingInfoCard extends StatelessWidget {
  final BookingRequest booking;

  const _BookingInfoCard({required this.booking});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}  $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = () {
      switch (booking.urgency.toLowerCase()) {
        case 'high':
          return AppTheme.errorRed;
        case 'medium':
          return AppTheme.warningOrange;
        default:
          return AppTheme.successGreen;
      }
    }();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              Text(
                'Booking Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(
            icon: Icons.build_rounded,
            label: 'Service',
            value: booking.serviceCategory,
          ),
          _DetailRow(
            icon: Icons.description_rounded,
            label: 'Issue',
            value: booking.issueSummary,
          ),
          _DetailRow(
            icon: Icons.bolt_rounded,
            label: 'Urgency',
            value: booking.urgency.toUpperCase(),
            valueColor: urgencyColor,
          ),
          if (booking.id != null)
            _DetailRow(
              icon: Icons.tag_rounded,
              label: 'Booking ID',
              value: '#${booking.id}',
            ),
          if (booking.createdAt != null)
            _DetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Requested',
              value: _formatDate(booking.createdAt!),
              isLast: true,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: valueColor ?? AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Banner
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA Section
// ─────────────────────────────────────────────────────────────────────────────
class _LifecycleCTA extends StatelessWidget {
  final BookingRequest booking;
  final List<Proposal> proposals;
  final int requestId;
  final AnimationController pulseController;
  final WidgetRef ref;

  const _LifecycleCTA({
    required this.booking,
    required this.proposals,
    required this.requestId,
    required this.pulseController,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // ── 1. PENDING ─────────────────────────────────────────────────────
    if (booking.status.toUpperCase() == 'PENDING' ||
        booking.status.toUpperCase() == 'CREATED') {
      return Column(
        children: [
          _InfoBanner(
            color: AppTheme.warningOrange,
            loading: true,
            title: 'Awaiting Worker Response',
            subtitle:
                'Your request has been sent. A worker will respond shortly.',
          ),
          const SizedBox(height: 12),
          _OutlineBtn(
            icon: Icons.cancel_outlined,
            label: 'Cancel Request',
            color: AppTheme.errorRed,
            onTap: () => _cancelRequest(context),
          ),
        ],
      );
    }

    // ── 2. Proposal received ────────────────────────────────────────────
    if (booking.needsProposalAction) {
      return _PrimaryBtn(
        icon: Icons.mark_email_unread_rounded,
        label: booking.status.toUpperCase() == 'NEGOTIATING'
            ? 'Negotiation in Progress — View'
            : "View Worker's Offer",
        color: AppTheme.primaryBlue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProposalScreen(requestId: requestId),
          ),
        ),
      );
    }

    // ── 3. Pay advance ──────────────────────────────────────────────────
    if (booking.needsAdvancePayment) {
      final proposal = proposals.isNotEmpty ? proposals.first : null;
      return _PrimaryBtn(
        icon: Icons.payment_rounded,
        label: 'Pay Advance — Confirm Booking',
        color: AppTheme.successGreen,
        onTap: proposal != null
            ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentScreen(
                    requestId: requestId,
                    proposal: proposal,
                    booking: booking,
                  ),
                ),
              )
            : () {},
      );
    }

    // ── 4. Worker en route / service active ─────────────────────────────
    if (booking.isWorkerEnRoute || booking.isServiceActive) {
      return _InfoBanner(
        color: AppTheme.primaryBlue,
        loading: false,
        pulse: true,
        pulseController: pulseController,
        title: booking.isWorkerEnRoute
            ? 'Worker is on the way'
            : 'Service in progress',
        subtitle: booking.isWorkerEnRoute
            ? "You'll be notified when the worker arrives."
            : "You'll be notified once the worker completes and uploads job photos.",
      );
    }

    // ── 5. Review work photos ────────────────────────────────────────────
    if (booking.isPhotoReviewPending) {
      return _PrimaryBtn(
        icon: Icons.preview_rounded,
        label: 'Review Work Done',
        color: AppTheme.successGreen,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkPhotoReviewScreen(requestId: requestId),
          ),
        ),
      );
    }

    // ── 6. Pay final balance ─────────────────────────────────────────────
    if (booking.needsFinalPayment) {
      return _PrimaryBtn(
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

    // ── 7. Rate & review ─────────────────────────────────────────────────
    if (booking.canReview) {
      return _PrimaryBtn(
        icon: Icons.star_rounded,
        label: 'Rate & Review Worker',
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

    // ── 8. Finalized ──────────────────────────────────────────────────────
    if (booking.isCompleted) {
      return _InfoBanner(
        color: AppTheme.successGreen,
        icon: Icons.check_circle_rounded,
        title: 'Job Completed',
        subtitle: 'This booking has been finalized. Thank you!',
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _cancelRequest(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request'),
        content: const Text(
          'Are you sure you want to cancel this service request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref
          .read(workerRepositoryProvider)
          .updateBookingStatus(booking.id!, 'CANCELLED');
      ref.read(myBookingsViewModelProvider.notifier).loadBookings();
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable button / banner widgets
// ─────────────────────────────────────────────────────────────────────────────
class _PrimaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
          elevation: 0,
        ),
        icon: Icon(icon, color: Colors.white, size: 20),
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
}

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OutlineBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final bool loading;
  final bool pulse;
  final AnimationController? pulseController;
  final String title;
  final String subtitle;

  const _InfoBanner({
    required this.color,
    this.icon,
    this.loading = false,
    this.pulse = false,
    this.pulseController,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;
    if (loading) {
      leadingWidget = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
      );
    } else if (pulse && pulseController != null) {
      leadingWidget = AnimatedBuilder(
        animation: pulseController!,
        builder: (context, child) => Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.5 + pulseController!.value * 0.5),
          ),
        ),
      );
    } else {
      leadingWidget = Icon(
        icon ?? Icons.info_outline_rounded,
        color: color,
        size: 22,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: leadingWidget),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
