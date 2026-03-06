import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'withdraw_earnings_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Earnings',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: earningsAsync.when(
        data: (stats) {
          final history = stats['history'] as List<dynamic>;
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(earningsStatsProvider),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _card(
                          'Today',
                          '₹${stats['today']?.toStringAsFixed(0)}',
                          const Color(0xFF10B981),
                          Icons.today_rounded,
                        ),
                        const SizedBox(width: 12),
                        _card(
                          'Weekly',
                          '₹${stats['week']?.toStringAsFixed(0)}',
                          AppTheme.primaryBlue,
                          Icons.date_range_rounded,
                        ),
                        const SizedBox(width: 12),
                        _card(
                          'Monthly',
                          '₹${stats['month']?.toStringAsFixed(0)}',
                          Colors.purple,
                          Icons.calendar_month_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _totalCard(
                    context,
                    'Withdrawal Balance',
                    '₹${stats['total']?.toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Recent Payments',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (history.isEmpty)
                    _empty()
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: history.length,
                      itemBuilder: (c, i) => _item(history[i]),
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _card(String l, String v, Color c, IconData i) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: c.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(i, size: 16, color: c),
            ),
            const SizedBox(height: 16),
            Text(
              l,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              v,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _totalCard(BuildContext context, String l, String v) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, const Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                v,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                ),
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(v.replaceAll('₹', '')) ?? 0.0;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => WithdrawEarningsScreen(totalBalance: amount),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Withdraw',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale();
  }

  Widget _empty() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.history_rounded, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text(
            'No history yet',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(Map<String, dynamic> job) {
    final amountStr = job['estimated_payment']?.toString() ?? '₹0';
    final amount =
        double.tryParse(amountStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final category = job['service_category'] ?? 'Service';
    final dateStr = job['created_at'];
    final formattedDate = dateStr != null
        ? '${DateTime.parse(dateStr).day}/${DateTime.parse(dateStr).month}'
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Color(0xFF64748B),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '$formattedDate • Payment Received',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF10B981),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
