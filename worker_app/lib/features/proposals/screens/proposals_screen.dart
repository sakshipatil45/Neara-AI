import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/proposals_provider.dart';
import 'package:intl/intl.dart';

class ProposalsScreen extends ConsumerWidget {
  const ProposalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(workerProposalsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text(
            'My Proposals',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: const Color(0xFF64748B),
            indicatorColor: AppTheme.primaryBlue,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: const [
              Tab(text: 'Pending'),
              Tab(text: 'Accepted'),
            ],
          ),
        ),
        body: proposalsAsync.when(
          data: (proposals) => TabBarView(
            children: [
              _buildProposalList(
                context,
                proposals.where((p) => p['status'] == 'PENDING').toList(),
                'No pending proposals',
              ),
              _buildProposalList(
                context,
                proposals
                    .where(
                      (p) =>
                          p['status'] == 'ACCEPTED' ||
                          p['status'] == 'PROPOSAL_ACCEPTED',
                    )
                    .toList(),
                'No active accepted proposals',
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildProposalList(
    BuildContext context,
    List<Map<String, dynamic>> items,
    String emptyMsg,
  ) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(emptyMsg, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final proposal = items[index];
        final request = proposal['service_requests'];

        return _ProposalCard(
          proposal: proposal,
          request: request,
        ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
      },
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Map<String, dynamic> proposal;
  final Map<String, dynamic>? request;

  const _ProposalCard({required this.proposal, required this.request});

  @override
  Widget build(BuildContext context) {
    final status = proposal['status'] as String;
    final totalCost =
        (proposal['service_cost'] ?? 0) + (proposal['inspection_fee'] ?? 0);
    final date = DateTime.parse(proposal['created_at']);
    final formattedDate = DateFormat('dd MMM, hh:mm a').format(date);

    Color statusColor = Colors.orange;
    if (status == 'ACCEPTED') statusColor = Colors.green;
    if (request?['status'] == 'SERVICE_COMPLETED' ||
        request?['status'] == 'COMPLETED') {
      statusColor = AppTheme.primaryBlue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request?['status'] == 'SERVICE_COMPLETED' ||
                          request?['status'] == 'COMPLETED'
                      ? 'COMPLETED'
                      : status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request?['service_category'] ?? 'General Service',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            request?['issue_summary'] ?? 'No description provided',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Proposed Cost',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  Text(
                    '₹$totalCost',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (status == 'PENDING')
                const Text(
                  'Awaiting Customer',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
