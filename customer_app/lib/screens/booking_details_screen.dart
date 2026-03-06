import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import '../models/booking_model.dart';
import '../models/proposal_model.dart';

class BookingDetailsScreen extends ConsumerWidget {
  final int requestId;

  const BookingDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookingDetailsViewModelProvider(requestId));
    final booking = state.booking;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: state.isLoading && booking == null
          ? const Center(child: CircularProgressIndicator())
          : booking == null
              ? const Center(child: Text('Booking not found', style: TextStyle(color: Colors.white)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(booking),
                      const SizedBox(height: 32),
                      _buildTimeline(context, booking.status),
                      const SizedBox(height: 32),
                      if (state.proposals.isNotEmpty && 
                          (booking.status == 'CREATED' || booking.status == 'MATCHING' || booking.status == 'PROPOSAL_SENT'))
                        _buildProposalsSection(context, ref, state.proposals),
                      if (booking.workerName != null)
                        _buildWorkerInfo(booking),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeader(BookingRequest booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                booking.serviceCategory.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: booking.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  booking.statusText,
                  style: TextStyle(color: booking.statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            booking.issueSummary,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time, size: 16, color: Colors.white38),
              const SizedBox(width: 4),
              Text(
                'Urgency: ${booking.urgency}',
                style: const TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(BuildContext context, String currentStatus) {
    final stages = [
      'CREATED',
      'PROPOSAL_SENT',
      'PROPOSAL_ACCEPTED',
      'WORKER_COMING',
      'SERVICE_STARTED',
      'SERVICE_COMPLETED'
    ];

    int currentIndex = stages.indexOf(currentStatus.toUpperCase());
    if (currentIndex == -1) currentIndex = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Progress',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stages.length,
          itemBuilder: (context, index) {
            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;
            
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isCurrent ? const Color(0xFF2563EB) : Colors.white12,
                        border: isCurrent ? Border.all(color: Colors.white, width: 2) : null,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    if (index < stages.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: isCompleted ? const Color(0xFF2563EB) : Colors.white12,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _stageToLabel(stages[index]),
                        style: TextStyle(
                          color: isCompleted || isCurrent ? Colors.white : Colors.white24,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isCurrent)
                        Text(
                          'Currently here',
                          style: TextStyle(color: const Color(0xFF2563EB).withOpacity(0.7), fontSize: 12),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _stageToLabel(String stage) {
    switch (stage) {
      case 'CREATED': return 'Finding Worker';
      case 'PROPOSAL_SENT': return 'Worker Proposals';
      case 'PROPOSAL_ACCEPTED': return 'Worker Assigned';
      case 'WORKER_COMING': return 'Worker is on the way';
      case 'SERVICE_STARTED': return 'Task in progress';
      case 'SERVICE_COMPLETED': return 'Completed';
      default: return stage;
    }
  }

  Widget _buildProposalsSection(BuildContext context, WidgetRef ref, List<Proposal> proposals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Received Offers',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...proposals.map((p) => _ProposalCard(proposal: p, onAccept: () {
          ref.read(bookingDetailsViewModelProvider(requestId).notifier).respondToProposal(p.id, 'ACCEPTED');
        }, onReject: () {
          ref.read(bookingDetailsViewModelProvider(requestId).notifier).respondToProposal(p.id, 'REJECTED');
        })),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildWorkerInfo(BookingRequest booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: booking.workerProfileImage != null 
                    ? NetworkImage(booking.workerProfileImage!) 
                    : null,
                child: booking.workerProfileImage == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.workerName ?? 'Worker',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text('Assigned Expert', style: TextStyle(color: Colors.white60, fontSize: 14)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {}, // Chat/Call functionality
                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF2563EB)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProposalCard extends StatelessWidget {
  final Proposal proposal;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ProposalCard({required this.proposal, required this.onAccept, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 12,
                backgroundColor: Colors.white10,
                child: Icon(Icons.person, size: 14, color: Colors.white54),
              ),
              const SizedBox(width: 8),
              Text(
                proposal.workerName ?? 'Worker Offer',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Text(proposal.workerRating ?? '4.5', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 16),
          _PriceRow(label: 'Inspection Fee', value: '₹${proposal.inspectionFee.toStringAsFixed(0)}'),
          _PriceRow(label: 'Estimated Cost', value: '₹${proposal.serviceCost.toStringAsFixed(0)}'),
          const Divider(color: Colors.white10, height: 24),
          _PriceRow(
            label: 'Total Estimate', 
            value: '₹${proposal.totalEstimate.toStringAsFixed(0)}',
            isBold: true,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept Offer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;

  const _PriceRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isBold ? Colors.white70 : Colors.white38, fontSize: 14)),
          Text(
            value, 
            style: TextStyle(
              color: Colors.white, 
              fontSize: 16, 
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
