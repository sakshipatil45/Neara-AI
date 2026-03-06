import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/proposal_model.dart';
import '../models/negotiation_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/workers_viewmodel.dart';

class NegotiationScreen extends ConsumerStatefulWidget {
  final Proposal proposal;
  final int requestId;

  const NegotiationScreen({
    super.key,
    required this.proposal,
    required this.requestId,
  });

  @override
  ConsumerState<NegotiationScreen> createState() => _NegotiationScreenState();
}

class _NegotiationScreenState extends ConsumerState<NegotiationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isFetching = true;
  List<Negotiation> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = widget.proposal.totalEstimate.toStringAsFixed(0);
    _fetchHistory();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isFetching = true);
    try {
      final repo = ref.read(workerRepositoryProvider);
      _history = await repo.fetchNegotiations(widget.proposal.id);
    } catch (_) {
      // Non-critical; show empty history
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(workerRepositoryProvider);
      final negotiation = await repo.sendCounterOffer(
        proposalId: widget.proposal.id,
        requestId: widget.requestId,
        counterAmount: amount,
        message: _messageCtrl.text.trim().isEmpty
            ? 'Counter offer: ₹${amount.toStringAsFixed(0)}'
            : _messageCtrl.text.trim(),
      );

      if (mounted) {
        setState(() {
          _history.add(negotiation);
          _messageCtrl.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Counter offer sent! Waiting for worker response.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Negotiate Offer'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current proposal summary
            _buildCurrentProposalCard(context, proposal),
            const SizedBox(height: 20),

            // Negotiation history
            if (_isFetching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppTheme.primaryBlue),
                ),
              )
            else if (_history.isNotEmpty) ...[
              Text(
                'Negotiation History',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ..._history.map((n) => _NegotiationBubble(negotiation: n)),
              const SizedBox(height: 20),
            ],

            // Counter offer form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundPrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderDefault),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Counter Offer',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Worker proposed ₹${proposal.totalEstimate.toStringAsFixed(0)}. Enter your price.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Your Offer Amount (₹)',
                        prefixIcon: const Icon(
                          Icons.currency_rupee_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundSecondary,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(val);
                        if (amount == null || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        if (amount >= proposal.totalEstimate) {
                          return 'Counter offer must be less than ₹${proposal.totalEstimate.toStringAsFixed(0)}';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Message (optional)',
                        hintText:
                            'e.g., Budget is tight, can you adjust the inspection fee?',
                        prefixIcon: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppTheme.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundSecondary,
                        alignLabelWithHint: true,
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppTheme.errorRed),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Send Counter Offer',
                                style: TextStyle(fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentProposalCard(BuildContext context, Proposal proposal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue.withValues(alpha: 0.08),
            AppTheme.primaryBlue.withValues(alpha: 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.assignment_rounded,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Worker\'s Original Offer',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BigStat(
                label: 'Total',
                value: '₹${proposal.totalEstimate.toStringAsFixed(0)}',
              ),
              _BigStat(
                label: 'Advance',
                value: '₹${proposal.advanceAmount.toStringAsFixed(0)}',
              ),
              _BigStat(
                label: 'Est. Time',
                value: proposal.estimatedTime ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NegotiationBubble extends StatelessWidget {
  final Negotiation negotiation;

  const _NegotiationBubble({required this.negotiation});

  @override
  Widget build(BuildContext context) {
    final isCustomer = negotiation.senderRole == 'customer';

    return Align(
      alignment: isCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isCustomer
              ? AppTheme.primaryBlue.withValues(alpha: 0.1)
              : AppTheme.backgroundTertiary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCustomer
                ? AppTheme.primaryBlue.withValues(alpha: 0.3)
                : AppTheme.borderDefault,
          ),
        ),
        child: Column(
          crossAxisAlignment: isCustomer
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              isCustomer ? 'Your offer' : 'Worker\'s response',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isCustomer
                    ? AppTheme.primaryBlue
                    : AppTheme.textTertiary,
              ),
            ),
            if (negotiation.counterAmount != null) ...[
              const SizedBox(height: 4),
              Text(
                '₹${negotiation.counterAmount!.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: isCustomer
                      ? AppTheme.primaryBlue
                      : AppTheme.textPrimary,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              negotiation.message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;

  const _BigStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
