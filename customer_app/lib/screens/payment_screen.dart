import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proposal_model.dart';
import '../models/booking_model.dart';
import '../models/payment_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/workers_viewmodel.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import 'booking_details_screen.dart';

enum _PaymentMethod { upi, card, wallet }

class PaymentScreen extends ConsumerStatefulWidget {
  final int requestId;
  final Proposal proposal;
  final BookingRequest booking;

  const PaymentScreen({
    super.key,
    required this.requestId,
    required this.proposal,
    required this.booking,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen>
    with SingleTickerProviderStateMixin {
  _PaymentMethod _selectedMethod = _PaymentMethod.upi;
  bool _isProcessing = false;
  bool _paymentDone = false;
  EscrowPayment? _escrowPayment;
  late AnimationController _successAnimCtrl;
  late Animation<double> _successAnim;

  @override
  void initState() {
    super.initState();
    _successAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successAnim = CurvedAnimation(
      parent: _successAnimCtrl,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _successAnimCtrl.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate payment gateway processing (mock)
      await Future.delayed(const Duration(seconds: 2));

      final repo = ref.read(workerRepositoryProvider);
      final payment = await repo.createAdvancePayment(
        requestId: widget.requestId,
        advanceAmount: widget.proposal.advanceAmount,
        balanceAmount: widget.proposal.balanceAmount,
        workerId: widget.booking.workerId,
        customerId: widget.booking.customerId,
      );

      setState(() {
        _escrowPayment = payment;
        _paymentDone = true;
        _isProcessing = false;
      });

      _successAnimCtrl.forward();

      // Refresh bookings list
      ref.read(myBookingsViewModelProvider.notifier).loadBookings();
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String get _methodLabel {
    switch (_selectedMethod) {
      case _PaymentMethod.upi:
        return 'UPI / PhonePe / GPay';
      case _PaymentMethod.card:
        return 'Credit / Debit Card';
      case _PaymentMethod.wallet:
        return 'Neara Wallet';
    }
  }

  IconData get _methodIcon {
    switch (_selectedMethod) {
      case _PaymentMethod.upi:
        return Icons.account_balance_rounded;
      case _PaymentMethod.card:
        return Icons.credit_card_rounded;
      case _PaymentMethod.wallet:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Secure Payment'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        leading: _paymentDone
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _paymentDone ? _buildSuccessView() : _buildPaymentForm(),
    );
  }

  Widget _buildPaymentForm() {
    final proposal = widget.proposal;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Escrow info banner
          Container(
            padding: const EdgeInsets.all(14),
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
                  Icons.verified_user_rounded,
                  color: AppTheme.successGreen,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Protected by Escrow',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successGreen,
                        ),
                      ),
                      Text(
                        'Your advance is held safely. Released only when you confirm service completion.',
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

          // Amount breakdown
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
                  'Payment Breakdown',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _AmountRow(
                  label: 'Worker: ${proposal.workerName ?? 'N/A'}',
                  value: '',
                  isHeader: true,
                ),
                const SizedBox(height: 8),
                _AmountRow(
                  label: 'Inspection Fee',
                  value: '₹${proposal.inspectionFee.toStringAsFixed(0)}',
                ),
                _AmountRow(
                  label: 'Service Cost',
                  value: '₹${proposal.serviceCost.toStringAsFixed(0)}',
                ),
                const Divider(height: 24, color: AppTheme.borderDefault),
                _AmountRow(
                  label: 'Total Estimate',
                  value: '₹${proposal.totalEstimate.toStringAsFixed(0)}',
                  isBold: true,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _AmountRow(
                        label:
                            'Advance (${proposal.advancePercent.toStringAsFixed(0)}%) — Pay Now',
                        value: '₹${proposal.advanceAmount.toStringAsFixed(0)}',
                        highlight: true,
                        isBold: true,
                      ),
                      const SizedBox(height: 4),
                      _AmountRow(
                        label: 'Balance — Pay After Completion',
                        value: '₹${proposal.balanceAmount.toStringAsFixed(0)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Payment method selector
          Text(
            'Payment Method',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),

          ..._PaymentMethod.values.map(
            (method) => _MethodTile(
              method: method,
              isSelected: _selectedMethod == method,
              onTap: () => setState(() => _selectedMethod = method),
            ),
          ),

          const SizedBox(height: 24),

          // Mock UPI input
          if (_selectedMethod == _PaymentMethod.upi)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDefault),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPI ID',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'yourname@upi',
                      prefixIcon: const Icon(
                        Icons.account_balance_rounded,
                        color: AppTheme.primaryBlue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundSecondary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 32),

          // Pay button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_methodIcon, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Pay ₹${proposal.advanceAmount.toStringAsFixed(0)} via $_methodLabel',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 12,
                  color: AppTheme.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  '256-bit SSL encrypted',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _successAnim,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successGreen,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Payment Successful!',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '₹${widget.proposal.advanceAmount.toStringAsFixed(0)} held in escrow',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            if (_escrowPayment != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderDefault),
                ),
                child: Column(
                  children: [
                    _TxnDetail(
                      label: 'Transaction ID',
                      value: _escrowPayment!.transactionId ?? 'N/A',
                    ),
                    const Divider(color: AppTheme.borderDefault, height: 16),
                    _TxnDetail(
                      label: 'Amount Held',
                      value:
                          '₹${_escrowPayment!.advanceAmount.toStringAsFixed(0)}',
                    ),
                    const Divider(color: AppTheme.borderDefault, height: 16),
                    _TxnDetail(
                      label: 'Balance Due',
                      value:
                          '₹${_escrowPayment!.balanceAmount.toStringAsFixed(0)}',
                    ),
                    const Divider(color: AppTheme.borderDefault, height: 16),
                    _TxnDetail(
                      label: 'Status',
                      value: 'ESCROW HELD',
                      valueColor: AppTheme.successGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Worker is now notified and will arrive at your location.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BookingDetailsScreen(requestId: widget.requestId),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Track Worker'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final _PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  String get _label {
    switch (method) {
      case _PaymentMethod.upi:
        return 'UPI / Net Banking';
      case _PaymentMethod.card:
        return 'Credit / Debit Card';
      case _PaymentMethod.wallet:
        return 'Neara Wallet';
    }
  }

  String get _subtitle {
    switch (method) {
      case _PaymentMethod.upi:
        return 'PhonePe, Google Pay, Paytm';
      case _PaymentMethod.card:
        return 'Visa, MasterCard, RuPay';
      case _PaymentMethod.wallet:
        return 'Balance: ₹500';
    }
  }

  IconData get _icon {
    switch (method) {
      case _PaymentMethod.upi:
        return Icons.account_balance_rounded;
      case _PaymentMethod.card:
        return Icons.credit_card_rounded;
      case _PaymentMethod.wallet:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : AppTheme.borderDefault,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                    : AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _icon,
                color: isSelected
                    ? AppTheme.primaryBlue
                    : AppTheme.textSecondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(_subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Radio<_PaymentMethod>(
              value: method,
              groupValue: isSelected ? method : null,
              onChanged: (_) => onTap(),
              activeColor: AppTheme.primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool highlight;
  final bool isHeader;

  const _AmountRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.highlight = false,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isHeader) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textTertiary),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: highlight ? AppTheme.primaryBlue : AppTheme.textSecondary,
              fontWeight: isBold || highlight
                  ? FontWeight.w600
                  : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: highlight ? AppTheme.primaryBlue : AppTheme.textPrimary,
              fontWeight: isBold || highlight
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnDetail extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TxnDetail({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
