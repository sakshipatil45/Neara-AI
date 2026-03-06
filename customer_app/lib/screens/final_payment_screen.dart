import 'package:flutter/material.dart';
import '../models/proposal_model.dart';
import '../models/booking_model.dart';
import '../services/worker_repository.dart';
import 'job_completion_screen.dart';

class FinalPaymentScreen extends StatefulWidget {
  final Proposal proposal;
  final BookingRequest request;

  const FinalPaymentScreen({
    super.key,
    required this.proposal,
    required this.request,
  });

  @override
  State<FinalPaymentScreen> createState() => _FinalPaymentScreenState();
}

class _FinalPaymentScreenState extends State<FinalPaymentScreen> {
  bool _isProcessing = false;
  final WorkerRepository _repository = WorkerRepository();

  Future<void> _releasePayment() async {
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 2));
      await _repository.releaseFinalPayment(widget.request.id!);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => JobCompletionScreen(
              request: widget.request,
              proposal: widget.proposal,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to release payment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.proposal.totalEstimate;
    final advancePaid = widget.proposal.advanceAmount;
    final remaining = total - advancePaid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Release Final Payment',
          style: TextStyle(color: Color(0xFF1E293B)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Color(0xFF1E293B)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Job Completed!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please review the final amount to be released to the worker.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildRow(
                    'Total Service Amount',
                    '₹${total.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 12),
                  _buildRow(
                    'Advance Paid (Escrow)',
                    '-₹${advancePaid.toStringAsFixed(0)}',
                    color: const Color(0xFF07823D),
                  ),
                  const Divider(height: 32),
                  _buildRow(
                    'Remaining to Release',
                    '₹${remaining.toStringAsFixed(0)}',
                    isBold: true,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _releasePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm & Release Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'By clicking, you confirm the job is done to your satisfaction.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? const Color(0xFF1E293B),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            fontSize: isBold ? 18 : 16,
          ),
        ),
      ],
    );
  }
}
