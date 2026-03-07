import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CreateProposalScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> requestData;

  const CreateProposalScreen({super.key, required this.requestData});

  @override
  ConsumerState<CreateProposalScreen> createState() =>
      _CreateProposalScreenState();
}

class _CreateProposalScreenState extends ConsumerState<CreateProposalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inspectionFeeController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedArrivalTime = '20 minutes';
  double _advancePercentage = 30.0;
  bool _isLoading = false;

  final List<String> _arrivalOptions = [
    '10 minutes',
    '20 minutes',
    '30 minutes',
    '45 minutes',
    '1 hour',
  ];

  final List<double> _advanceOptions = [0, 20, 30, 40, 50];

  @override
  void dispose() {
    _inspectionFeeController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _inspectionFee =>
      double.tryParse(_inspectionFeeController.text) ?? 0.0;
  double get _servicePrice => double.tryParse(_priceController.text) ?? 0.0;
  double get _totalServicePrice => _inspectionFee + _servicePrice;
  double get _advanceAmount => (_totalServicePrice * _advancePercentage) / 100;
  double get _remainingAmount => _totalServicePrice - _advanceAmount;

  Future<void> _submitProposal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final worker = await ref.read(currentWorkerProvider.future);
      if (worker == null) throw Exception('Worker profile not found');

      final requestId = widget.requestData['id'];
      if (requestId == null) throw Exception('Request ID missing');

      await ref
          .read(dashboardServiceProvider)
          .sendProposal(
            requestId: requestId,
            workerId: worker.id,
            serviceCost: _totalServicePrice,
            advancePercent: _advancePercentage,
            arrivalTime: _selectedArrivalTime,
            notes: _notesController.text.trim(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proposal Sent Successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        // Refresh dashboard data
        ref.invalidate(incomingRequestsProvider);
        // Navigate back to dashboard (pop until first)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send proposal: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceType = widget.requestData['service_category'] ?? 'Service';
    final location = widget.requestData['location_name'] ?? 'Local Area';
    final customerName = widget.requestData['customer_name'] ?? 'Customer';
    final description =
        widget.requestData['issue_summary'] ??
        widget.requestData['issue_description'] ??
        'No description';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'Send Proposal',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              'Set your service price and advance payment',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request Summary Card
              _buildSummaryCard(
                serviceType,
                location,
                description,
                customerName,
              ),

              const SizedBox(height: 32),

              // Form Fields
              _buildSectionTitle(
                'Inspection Fee (Optional)',
                Icons.search_rounded,
              ),
              const SizedBox(height: 12),
              _buildInspectionFeeInput(),

              const SizedBox(height: 24),

              _buildSectionTitle('Your Service Price', Icons.payments_rounded),
              const SizedBox(height: 12),
              _buildPriceInput(),

              const SizedBox(height: 24),

              _buildSectionTitle(
                'Estimated Arrival Time',
                Icons.access_time_filled_rounded,
              ),
              const SizedBox(height: 12),
              _buildArrivalDropdown(),

              const SizedBox(height: 24),

              _buildSectionTitle(
                'Advance Payment Required',
                Icons.account_balance_wallet_rounded,
              ),
              const SizedBox(height: 12),
              _buildAdvanceSelector(),

              const SizedBox(height: 16),

              // Auto-calculation Card
              if (_totalServicePrice > 0)
                _buildCalculationCard().animate().fadeIn().slideY(
                  begin: 0.1,
                  end: 0,
                ),

              const SizedBox(height: 24),

              _buildSectionTitle(
                'Message to Customer (Optional)',
                Icons.chat_bubble_rounded,
              ),
              const SizedBox(height: 12),
              _buildNotesInput(),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitProposal,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Send Proposal',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String service,
    String loc,
    String desc,
    String customerName,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.handyman_rounded,
                  color: AppTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                service,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              const Text(
                '1.2 km away',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(Icons.person_rounded, customerName),
          const SizedBox(height: 8),
          _buildSummaryItem(Icons.location_on_rounded, loc),
          const SizedBox(height: 8),
          _buildSummaryItem(Icons.article_rounded, desc, maxLines: 2),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildSummaryItem(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF475569)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceInput() {
    return TextFormField(
      controller: _priceController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'e.g. 500',
        prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Please enter a price';
        if (double.tryParse(val) == null || double.parse(val) <= 0)
          return 'Enter a valid amount';
        return null;
      },
    );
  }

  Widget _buildInspectionFeeInput() {
    return TextFormField(
      controller: _inspectionFeeController,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'e.g. 150',
        prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      validator: (val) {
        if (val != null && val.isNotEmpty) {
          if (double.tryParse(val) == null || double.parse(val) < 0) {
            return 'Enter a valid amount';
          }
        }
        return null;
      },
    );
  }

  Widget _buildArrivalDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedArrivalTime,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF64748B),
          ),
          items: _arrivalOptions
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) => setState(() => _selectedArrivalTime = val!),
        ),
      ),
    );
  }

  Widget _buildAdvanceSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _advanceOptions.map((percent) {
          final isSelected = _advancePercentage == percent;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _advancePercentage = percent),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${percent.toInt()}%',
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : const Color(0xFF64748B),
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCalculationCard() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildCalcRow(
            'Inspection Fee',
            '₹${_inspectionFee.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 8),
          _buildCalcRow(
            'Service Price',
            '₹${_servicePrice.toStringAsFixed(0)}',
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          _buildCalcRow(
            'Total Fee',
            '₹${_totalServicePrice.toStringAsFixed(0)}',
            isHighlight: true,
          ),
          const SizedBox(height: 16),
          _buildCalcRow(
            'Advance to be paid now',
            '₹${_advanceAmount.toStringAsFixed(0)}',
            isHighlight: true,
          ),
          const SizedBox(height: 12),
          _buildCalcRow(
            'Remaining after service',
            '₹${_remainingAmount.toStringAsFixed(0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight
                ? const Color(0xFF10B981)
                : const Color(0xFF64748B),
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isHighlight
                ? const Color(0xFF10B981)
                : const Color(0xFF1E293B),
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return TextFormField(
      controller: _notesController,
      maxLines: 4,
      maxLength: 200,
      decoration: InputDecoration(
        hintText: 'I will bring tools and complete the repair quickly...',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
