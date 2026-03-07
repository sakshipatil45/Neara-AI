import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proposal_model.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import 'negotiation_screen.dart';
import 'payment_screen.dart';

class ProposalScreen extends ConsumerStatefulWidget {
  final int requestId;

  const ProposalScreen({super.key, required this.requestId});

  @override
  ConsumerState<ProposalScreen> createState() => _ProposalScreenState();
}

class _ProposalScreenState extends ConsumerState<ProposalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept(Proposal proposal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Accept Proposal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'By accepting, you agree to pay the advance amount now. The worker will then head to your location.',
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'Total Estimate',
              value: '₹${proposal.totalEstimate.toStringAsFixed(0)}',
            ),
            _SummaryRow(
              label: 'Advance (${proposal.advancePercent.toStringAsFixed(0)}%)',
              value: '₹${proposal.advanceAmount.toStringAsFixed(0)}',
              highlight: true,
            ),
            _SummaryRow(
              label: 'Balance on Completion',
              value: '₹${proposal.balanceAmount.toStringAsFixed(0)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Accept & Pay Advance'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isActing = true);

    try {
      await ref
          .read(bookingDetailsViewModelProvider(widget.requestId).notifier)
          .respondToProposal(proposal.id, 'ACCEPTED');

      if (!mounted) return;

      // Navigate to payment screen
      final state = ref.read(bookingDetailsViewModelProvider(widget.requestId));
      if (state.booking != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              requestId: widget.requestId,
              proposal: proposal,
              booking: state.booking!,
            ),
          ),
        );
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      }
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
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _handleReject(Proposal proposal) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Proposal'),
        content: const Text(
          'Are you sure you want to reject this proposal? The worker will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorRed),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isActing = true);
    try {
      await ref
          .read(bookingDetailsViewModelProvider(widget.requestId).notifier)
          .respondToProposal(proposal.id, 'REJECTED');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposal rejected. Waiting for new offers.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  void _handleNegotiate(Proposal proposal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            NegotiationScreen(proposal: proposal, requestId: widget.requestId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingDetailsViewModelProvider(widget.requestId));
    final proposals = state.proposals;
    final booking = state.booking;

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Worker Proposals'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      body: state.isLoading && proposals.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : proposals.isEmpty
          ? _buildEmptyState()
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (booking != null) _buildBookingHeader(context, booking),
                    const SizedBox(height: 16),
                    Text(
                      '${proposals.length} Proposal${proposals.length > 1 ? 's' : ''} Received',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    ...proposals.map(
                      (p) => _ProposalCard(
                        proposal: p,
                        isActing: _isActing,
                        canAct: booking?.needsProposalAction ?? false,
                        onAccept: () => _handleAccept(p),
                        onReject: () => _handleReject(p),
                        onNegotiate: () => _handleNegotiate(p),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
                if (_isActing)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x55000000),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildBookingHeader(BuildContext context, BookingRequest booking) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderDefault),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.build_circle_outlined,
              color: AppTheme.primaryBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceCategory,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  booking.issueSummary,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_empty_rounded,
            size: 64,
            color: AppTheme.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            'No proposals yet',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Workers will send their proposals shortly.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Proposal proposal;
  final bool isActing;
  final bool canAct;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onNegotiate;

  const _ProposalCard({
    required this.proposal,
    required this.isActing,
    required this.canAct,
    required this.onAccept,
    required this.onReject,
    required this.onNegotiate,
  });

  Color get _statusColor {
    switch (proposal.status) {
      case 'ACCEPTED':
        return AppTheme.successGreen;
      case 'REJECTED':
        return AppTheme.errorRed;
      case 'NEGOTIATING':
      case 'COUNTERED':
        return const Color(0xFF7C3AED);
      default:
        return AppTheme.primaryBlue;
    }
  }

  String get _statusLabel {
    switch (proposal.status) {
      case 'ACCEPTED':
        return 'Accepted';
      case 'REJECTED':
        return 'Rejected';
      case 'NEGOTIATING':
        return 'Negotiating';
      case 'COUNTERED':
        return 'Counter Sent';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: proposal.isAccepted
              ? AppTheme.successGreen.withValues(alpha: 0.4)
              : proposal.isNegotiating
              ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
              : AppTheme.borderDefault,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.backgroundTertiary,
                  backgroundImage: proposal.workerProfileImage != null
                      ? NetworkImage(proposal.workerProfileImage!)
                      : null,
                  child: proposal.workerProfileImage == null
                      ? Text(
                          proposal.workerName?.isNotEmpty == true
                              ? proposal.workerName![0].toUpperCase()
                              : 'W',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        proposal.workerName ?? 'Worker',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            proposal.workerRating ?? '4.5',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.borderDefault),
          const SizedBox(height: 16),

          // Price breakdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _SummaryRow(
                  label: 'Inspection Fee',
                  value: '₹${proposal.inspectionFee.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Estimated Repair Cost',
                  value: '₹${proposal.serviceCost.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                const Divider(color: AppTheme.borderDefault),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: 'Total Estimate',
                  value: '₹${proposal.totalEstimate.toStringAsFixed(0)}',
                  isBold: true,
                ),
                const SizedBox(height: 4),
                _SummaryRow(
                  label:
                      'Advance Required (${proposal.advancePercent.toStringAsFixed(0)}%)',
                  value: '₹${proposal.advanceAmount.toStringAsFixed(0)}',
                  highlight: true,
                ),
                _SummaryRow(
                  label: 'Balance on Completion',
                  value: '₹${proposal.balanceAmount.toStringAsFixed(0)}',
                ),
              ],
            ),
          ),

          if (proposal.estimatedTime != null || proposal.notes != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.borderDefault),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (proposal.estimatedTime != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Est. time: ${proposal.estimatedTime}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  if (proposal.notes != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.notes_rounded,
                          size: 14,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            proposal.notes!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // Actions
          if (canAct && proposal.isPending || proposal.isNegotiating) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isActing ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: BorderSide(
                          color: AppTheme.errorRed.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isActing ? null : onNegotiate,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7C3AED),
                        side: const BorderSide(color: Color(0xFF7C3AED)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Negotiate'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: isActing ? null : onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool highlight;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: highlight
                ? AppTheme.primaryBlue
                : isBold
                ? AppTheme.textPrimary
                : AppTheme.textSecondary,
            fontWeight: isBold || highlight ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: highlight ? AppTheme.primaryBlue : AppTheme.textPrimary,
            fontWeight: isBold || highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
