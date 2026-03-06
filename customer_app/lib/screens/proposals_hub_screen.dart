import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import 'negotiation_screen.dart';
import 'payment_screen.dart';
import 'service_completion_screen.dart';

class ProposalsHubScreen extends ConsumerWidget {
  const ProposalsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proposalsHubProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Proposals & Payments'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.textSecondary,
            ),
            onPressed: () => ref.read(proposalsHubProvider.notifier).load(),
          ),
        ],
      ),
      body: state.isLoading && state.items.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : state.items.isEmpty && state.error == null
          ? const _EmptyState()
          : _HubBody(state: state),
    );
  }
}

//  Body

class _HubBody extends ConsumerWidget {
  final ProposalsHubState state;
  const _HubBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responding = state.items.where((i) => i.needsResponse).toList();
    final advanceDue = state.items.where((i) => i.needsAdvancePay).toList();
    final finalDue = state.items.where((i) => i.needsFinalPay).toList();
    final others = state.items
        .where(
          (i) => !i.needsResponse && !i.needsAdvancePay && !i.needsFinalPay,
        )
        .toList();

    return RefreshIndicator(
      color: AppTheme.primaryBlue,
      onRefresh: () => ref.read(proposalsHubProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          if (state.error != null) _ErrorBanner(message: state.error!),

          if (finalDue.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.lock_open_rounded,
              label: 'Final Payment Due',
              color: AppTheme.warningOrange,
              count: finalDue.length,
            ),
            ...finalDue.map((item) => _FinalPayCard(item: item)),
            const SizedBox(height: 8),
          ],

          if (advanceDue.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.payment_rounded,
              label: 'Pay Advance',
              color: AppTheme.successGreen,
              count: advanceDue.length,
            ),
            ...advanceDue.map((item) => _AdvancePayCard(item: item)),
            const SizedBox(height: 8),
          ],

          if (responding.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.mark_email_unread_rounded,
              label: 'Awaiting Your Response',
              color: AppTheme.primaryBlue,
              count: responding.length,
            ),
            ...responding.map((item) => _ProposalResponseCard(item: item)),
            const SizedBox(height: 8),
          ],

          if (others.isNotEmpty) ...[
            _SectionHeader(
              icon: Icons.history_rounded,
              label: 'Other Proposals',
              color: AppTheme.textTertiary,
              count: others.length,
            ),
            ...others.map(
              (item) => _ProposalResponseCard(item: item, readOnly: true),
            ),
          ],
        ],
      ),
    );
  }
}

//  Section Header

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//  Proposal Response Card

class _ProposalResponseCard extends ConsumerStatefulWidget {
  final ProposalItem item;
  final bool readOnly;

  const _ProposalResponseCard({required this.item, this.readOnly = false});

  @override
  ConsumerState<_ProposalResponseCard> createState() =>
      _ProposalResponseCardState();
}

class _ProposalResponseCardState extends ConsumerState<_ProposalResponseCard> {
  bool _isActing = false;

  Future<void> _accept() async {
    final p = widget.item.proposal;
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
              "Accepting will lock in this estimate. You'll pay the advance now and the balance after service completion.",
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Total Estimate',
              value: 'Rs.${p.totalEstimate.toStringAsFixed(0)}',
            ),
            _DetailRow(
              label: 'Advance (${p.advancePercent.toStringAsFixed(0)}%)',
              value: 'Rs.${p.advanceAmount.toStringAsFixed(0)}',
              highlight: true,
            ),
            _DetailRow(
              label: 'Balance on completion',
              value: 'Rs.${p.balanceAmount.toStringAsFixed(0)}',
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
          .read(proposalsHubProvider.notifier)
          .respondToProposal(p.id, widget.item.requestId, 'ACCEPTED');
      if (!mounted) return;
      final booking = _buildBooking(widget.item);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            requestId: widget.item.requestId,
            proposal: p,
            booking: booking,
          ),
        ),
      );
      if (mounted) ref.read(proposalsHubProvider.notifier).load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  Future<void> _reject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Proposal'),
        content: const Text(
          'The worker will be notified. More workers may still submit proposals.',
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
          .read(proposalsHubProvider.notifier)
          .respondToProposal(
            widget.item.proposal.id,
            widget.item.requestId,
            'REJECTED',
          );
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Proposal rejected.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActing = false);
    }
  }

  void _negotiate() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NegotiationScreen(
          proposal: widget.item.proposal,
          requestId: widget.item.requestId,
        ),
      ),
    ).then((_) => ref.read(proposalsHubProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final p = item.proposal;
    final statusColor = _proposalStatusColor(p.status);
    final canAct = !widget.readOnly && (p.isPending || p.isNegotiating);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.isAccepted
              ? AppTheme.successGreen.withValues(alpha: 0.35)
              : p.isNegotiating
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
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    _CategoryChip(label: item.serviceCategory),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.issueSummary,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusChip(
                      label: _proposalStatusLabel(p.status),
                      color: statusColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.borderDefault),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.backgroundTertiary,
                      backgroundImage: p.workerProfileImage != null
                          ? NetworkImage(p.workerProfileImage!)
                          : null,
                      child: p.workerProfileImage == null
                          ? Text(
                              (p.workerName?.isNotEmpty == true)
                                  ? p.workerName![0].toUpperCase()
                                  : 'W',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.workerName ?? 'Worker',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 13,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                p.workerRating ?? '-',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rs.${p.totalEstimate.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Advance Rs.${p.advanceAmount.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (p.estimatedTime != null || p.notes != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (p.estimatedTime != null) ...[
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          p.estimatedTime!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (p.notes != null) ...[
                        const Icon(
                          Icons.notes_rounded,
                          size: 13,
                          color: AppTheme.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            p.notes!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              if (canAct) ...[
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isActing ? null : _reject,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorRed,
                            side: BorderSide(
                              color: AppTheme.errorRed.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                          onPressed: _isActing ? null : _negotiate,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            side: const BorderSide(color: Color(0xFF7C3AED)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                          onPressed: _isActing ? null : _accept,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 10),
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
                const SizedBox(height: 14),
            ],
          ),
          if (_isActing)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

//  Advance Pay Card

class _AdvancePayCard extends ConsumerWidget {
  final ProposalItem item;
  const _AdvancePayCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = item.proposal;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.35),
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
          Row(
            children: [
              _CategoryChip(label: item.serviceCategory),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.issueSummary,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay Now (Advance)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  Text(
                    'Rs.${p.advanceAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Balance on completion: Rs.${p.balanceAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.payment_rounded, size: 18),
                label: const Text('Pay Escrow'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final booking = _buildBooking(item);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        requestId: item.requestId,
                        proposal: p,
                        booking: booking,
                      ),
                    ),
                  );
                  ref.read(proposalsHubProvider.notifier).load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//  Final Pay Card

class _FinalPayCard extends ConsumerWidget {
  final ProposalItem item;
  const _FinalPayCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = item.proposal;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.35),
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
          Row(
            children: [
              _CategoryChip(
                label: item.serviceCategory,
                color: AppTheme.warningOrange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.issueSummary,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Completed — Release Balance',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                  ),
                  Text(
                    'Rs.${p.balanceAmount.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppTheme.warningOrange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Worker: ${p.workerName ?? "Worker"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.lock_open_rounded, size: 18),
                label: const Text('Pay Balance'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.warningOrange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ServiceCompletionScreen(
                        requestId: item.requestId,
                        proposal: item.proposal,
                      ),
                    ),
                  );
                  ref.read(proposalsHubProvider.notifier).load();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

//  Shared helper

BookingRequest _buildBooking(ProposalItem item) {
  return BookingRequest(
    id: item.requestId,
    customerId: 'fc91af88-9664-4953-a342-01f50a9ea2c6',
    workerId: item.proposal.workerId,
    serviceCategory: item.serviceCategory,
    issueSummary: item.issueSummary,
    urgency: 'medium',
    status: item.bookingStatus,
  );
}

Color _proposalStatusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return AppTheme.primaryBlue;
    case 'ACCEPTED':
      return AppTheme.successGreen;
    case 'REJECTED':
      return AppTheme.errorRed;
    case 'NEGOTIATING':
      return const Color(0xFF7C3AED);
    case 'COUNTER_OFFERED':
      return const Color(0xFFD97706);
    default:
      return AppTheme.textTertiary;
  }
}

String _proposalStatusLabel(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return 'New';
    case 'ACCEPTED':
      return 'Accepted';
    case 'REJECTED':
      return 'Rejected';
    case 'NEGOTIATING':
      return 'Negotiating';
    case 'COUNTER_OFFERED':
      return 'Counter Offer';
    default:
      return status;
  }
}

//  Reusable widgets

class _CategoryChip extends StatelessWidget {
  final String label;
  final Color color;
  const _CategoryChip({required this.label, this.color = AppTheme.primaryBlue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _DetailRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? AppTheme.primaryBlue : AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: highlight ? AppTheme.primaryBlue : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.errorRed, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.errorRed, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 40,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No proposals yet',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'When workers respond to your service requests, their proposals will appear here.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
