import 'package:flutter/material.dart';
import '../models/proposal_model.dart';
import '../models/booking_model.dart';
import '../services/worker_repository.dart';

class AdvancePaymentScreen extends StatefulWidget {
  final Proposal proposal;
  final BookingRequest request;

  const AdvancePaymentScreen({
    super.key,
    required this.proposal,
    required this.request,
  });

  @override
  State<AdvancePaymentScreen> createState() => _AdvancePaymentScreenState();
}

class _AdvancePaymentScreenState extends State<AdvancePaymentScreen> {
  bool _isProcessing = false;
  final WorkerRepository _repository = WorkerRepository();

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      // Simulate network delay for payment
      await Future.delayed(const Duration(seconds: 2));

      // Update Supabase status
      await _repository.confirmAdvancePayment(widget.request.id!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Successful! Worker has been notified.'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.proposal.totalEstimate;
    final advance = widget.proposal.advanceAmount;
    final remaining = total - advance;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Secure Advance Payment',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alert Note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF2563EB)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your payment is held in secure escrow and only released after job completion.',
                      style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Inspection Fee',
                    '₹${widget.proposal.inspectionFee.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Service Cost',
                    '₹${widget.proposal.serviceCost.toStringAsFixed(0)}',
                  ),
                  const Divider(height: 32),
                  _buildSummaryRow(
                    'Total Estimate',
                    '₹${total.toStringAsFixed(0)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Escrow Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(
                    'Advance to Pay Now (${widget.proposal.advancePercent.toStringAsFixed(0)}%)',
                    '₹${advance.toStringAsFixed(0)}',
                    valueColor: const Color(0xFF2563EB),
                    isBold: true,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Remaining after service',
                    '₹${remaining.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangle_circular(12),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Pay Advance Escrow',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? const Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Helper for rounded rectangle until my skill updates
  OutlinedBorder RoundedRectangle_circular(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}
