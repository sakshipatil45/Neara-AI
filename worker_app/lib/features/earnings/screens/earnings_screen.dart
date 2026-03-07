import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'withdraw_earnings_screen.dart';

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
          final history = stats['history'] as List<dynamic>? ?? [];
          final total = stats['total'] ?? 0.0;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.read(earningsStatsProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWalletCard(context, ref, total),
                  const SizedBox(height: 32),
                  _buildSectionHeader('WEEKLY ANALYTICS'),
                  const SizedBox(height: 16),
                  _buildWeeklyChart(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('RECENT TRANSACTIONS'),
                  const SizedBox(height: 16),
                  if (history.isEmpty)
                    _empty()
                  else
                    ...history.map((h) {
                      try {
                        final job = (h as Map?)?.cast<String, dynamic>() ?? {};
                        return _buildTransactionTileFromJob(job);
                      } catch (e) {
                        return const SizedBox.shrink();
                      }
                    }).toList(),
                  const SizedBox(height: 48),
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

  Widget _buildWalletCard(BuildContext context, WidgetRef ref, double balance) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AVAILABLE BALANCE',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${balance.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) =>
                            WithdrawEarningsScreen(totalBalance: balance),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryBlue,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Withdraw to Bank',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF64748B),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Trend',
                style: TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Text(
                'Last 7 Days',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildChartBar('M', 40),
              _buildChartBar('T', 70),
              _buildChartBar('W', 50),
              _buildChartBar('T', 90, isHighlight: true),
              _buildChartBar('F', 30),
              _buildChartBar('S', 60),
              _buildChartBar('S', 45),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(
    String day,
    double heightFactor, {
    bool isHighlight = false,
  }) {
    return Column(
      children: [
        Container(
          width: 16,
          height: heightFactor,
          decoration: BoxDecoration(
            color: isHighlight ? AppTheme.primaryBlue : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            color: const Color(0xFF64748B),
            fontSize: 10,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTileFromJob(Map<String, dynamic> job) {
    final amount = (job['amount'] as num?)?.toDouble() ?? 0.0;
    final category = job['service_category']?.toString() ?? 'Service';
    final dateStr = job['created_at']?.toString();

    String formattedDate = 'N/A';
    if (dateStr != null) {
      final parsed = DateTime.tryParse(dateStr);
      if (parsed != null) {
        final hours = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
        final period = parsed.hour >= 12 ? 'PM' : 'AM';
        final mins = parsed.minute.toString().padLeft(2, '0');
        formattedDate = '${parsed.day}/${parsed.month}, $hours:$mins $period';
      }
    }

    final isAdvance = job['type']?.toString() == 'ADVANCE';
    final typeLabel = isAdvance ? 'Advance: ' : 'Job: ';

    return _buildTransactionTile(
      '$typeLabel$category',
      '+ ₹${amount.toStringAsFixed(0)}',
      formattedDate,
      Icons.south_west_rounded,
      const Color(0xFF10B981), // safeGreen equivalent
    );
  }

  Widget _buildTransactionTile(
    String title,
    String amount,
    String date,
    IconData icon,
    Color amountColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: amountColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 40,
              color: Color(0xFFCBD5E1),
            ),
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
      ),
    );
  }
}
