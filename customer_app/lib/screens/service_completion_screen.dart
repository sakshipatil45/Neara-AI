import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/payment_model.dart';
import '../models/proposal_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import '../viewmodels/workers_viewmodel.dart';
import 'review_screen.dart';

class ServiceCompletionScreen extends ConsumerStatefulWidget {
  final int requestId;
  final Proposal? proposal;

  const ServiceCompletionScreen({
    super.key,
    required this.requestId,
    this.proposal,
  });

  @override
  ConsumerState<ServiceCompletionScreen> createState() =>
      _ServiceCompletionScreenState();
}

class _ServiceCompletionScreenState
    extends ConsumerState<ServiceCompletionScreen> {
  EscrowPayment? _payment;
  bool _isLoadingPayment = true;
  bool _isPaying = false;
  bool _paymentDone = false;
  EscrowPayment? _completedPayment;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  Future<void> _loadPayment() async {
    try {
      final repo = ref.read(workerRepositoryProvider);
      var payment = await repo.fetchPayment(widget.requestId);
      // If no record exists but we have proposal data, synthesize amounts as fallback
      if (payment == null && widget.proposal != null) {
        final p = widget.proposal!;
        payment = EscrowPayment(
          id: null,
          requestId: widget.requestId,
          advanceAmount: 0,
          balanceAmount: p.totalEstimate,
          escrowStatus: 'PENDING',
        );
      }
      if (mounted) {
        setState(() {
          _payment = payment;
          _isLoadingPayment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPayment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load payment info: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _payBalance() async {
    if (_payment == null) return;

    final isFullPayment = _payment!.id == null;
    final dialogContent = isFullPayment
        ? 'Pay ₹${_payment!.totalAmount.toStringAsFixed(0)} to complete the service?'
        : 'Release ₹${_payment!.balanceAmount.toStringAsFixed(0)} from escrow to the worker?\n\nThe advance of ₹${_payment!.advanceAmount.toStringAsFixed(0)} was already held.';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        title: Text(isFullPayment ? 'Pay Full Amount' : 'Pay Balance'),
        content: Text(dialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
            ),
            child: Text(
              'Pay ₹${(isFullPayment ? _payment!.totalAmount : _payment!.balanceAmount).toStringAsFixed(0)}',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isPaying = true);

    try {
      // Simulate gateway delay
      await Future.delayed(const Duration(seconds: 2));

      final repo = ref.read(workerRepositoryProvider);
      final EscrowPayment updated;
      if (isFullPayment) {
        updated = await repo.payFullAmountOnCompletion(
          requestId: widget.requestId,
          totalAmount: _payment!.totalAmount,
        );
      } else {
        updated = await repo.payFinalBalance(_payment!.id!, widget.requestId);
      }

      if (mounted) {
        setState(() {
          _completedPayment = updated;
          _paymentDone = true;
          _isPaying = false;
        });
        ref.read(myBookingsViewModelProvider.notifier).loadBookings();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPaying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Final Payment'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
      ),
      body: _isLoadingPayment
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : _paymentDone
          ? _buildSuccessView()
          : _buildPaymentView(),
    );
  }

  Widget _buildPaymentView() {
    if (_payment == null) {
      return _buildNoPaymentFound();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job complete banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.successGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  color: AppTheme.successGreen,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Job Completed!',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      Text(
                        'Release the balance payment to the worker.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.successGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment breakdown
          Container(
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
                  'Final Payment Summary',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  label: 'Total Service Cost',
                  value: '₹${_payment!.totalAmount.toStringAsFixed(0)}',
                ),
                const SizedBox(height: 8),
                _SummaryRow(
                  label: _payment!.id == null
                      ? 'Advance Paid'
                      : 'Advance Paid (Escrow)',
                  value: _payment!.id == null
                      ? 'Not paid via app'
                      : '₹${_payment!.advanceAmount.toStringAsFixed(0)}',
                  valueColor: AppTheme.successGreen,
                ),
                const Divider(height: 24, color: AppTheme.borderDefault),
                _SummaryRow(
                  label: _payment!.id == null ? 'Total Due' : 'Balance Due',
                  value:
                      '₹${(_payment!.id == null ? _payment!.totalAmount : _payment!.balanceAmount).toStringAsFixed(0)}',
                  isBold: true,
                  highlight: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Escrow info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppTheme.primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Both advance & balance are released to the worker after your confirmation.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Pay button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isPaying ? null : _payBalance,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isPaying
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_open_rounded),
              label: Text(
                _isPaying
                    ? 'Processing...'
                    : _payment!.id == null
                    ? 'Pay ₹${_payment!.totalAmount.toStringAsFixed(0)} to Worker'
                    : 'Release ₹${_payment!.balanceAmount.toStringAsFixed(0)} to Worker',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final p = _completedPayment;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.successGreen,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Payment Complete!',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Service has been closed and payment released.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (p != null) ...[
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDefault),
                ),
                child: Column(
                  children: [
                    if (p.transactionId != null)
                      _TxnRow(label: 'Transaction ID', value: p.transactionId!),
                    const Divider(color: AppTheme.borderDefault, height: 16),
                    _TxnRow(
                      label: 'Total Paid',
                      value: '₹${p.totalAmount.toStringAsFixed(0)}',
                    ),
                    const Divider(color: AppTheme.borderDefault, height: 16),
                    const _TxnRow(label: 'Status', value: 'ESCROW RELEASED'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  // Navigate to review screen
                  final vmState = ref.read(
                    bookingDetailsViewModelProvider(widget.requestId),
                  );
                  final booking = vmState.booking;
                  if (booking != null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewScreen(
                          requestId: widget.requestId,
                          workerId: booking.workerId ?? 0,
                          workerName: booking.workerName,
                        ),
                      ),
                    );
                  } else {
                    Navigator.popUntil(context, (r) => r.isFirst);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Rate & Review Worker'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              child: const Text(
                'Skip for now',
                style: TextStyle(color: AppTheme.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPaymentFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              size: 60,
              color: AppTheme.textDisabled,
            ),
            const SizedBox(height: 16),
            Text(
              'Payment record not found.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Please contact support if this persists.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool highlight;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.highlight = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final vColor =
        valueColor ?? (highlight ? AppTheme.primaryBlue : AppTheme.textPrimary);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: vColor,
          ),
        ),
      ],
    );
  }
}

class _TxnRow extends StatelessWidget {
  final String label;
  final String value;

  const _TxnRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
