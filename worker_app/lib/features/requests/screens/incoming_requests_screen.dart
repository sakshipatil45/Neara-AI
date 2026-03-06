import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/request_list_card.dart';
import 'request_details_screen.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IncomingRequestsScreen extends ConsumerWidget {
  const IncomingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingRequestsAsync = ref.watch(incomingRequestsProvider);

    // Show banner when a new request arrives while this screen is open.
    ref.listen<Map<String, dynamic>?>(newRequestAlertProvider, (_, next) {
      if (next == null) return;
      final category = next['service_category'] ?? 'Service Request';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.fiber_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'New request just arrived: $category',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      ref.read(newRequestAlertProvider.notifier).dismiss();
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E293B),
            size: 20,
          ),
        ),
        title: const Text(
          'Incoming Requests',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: incomingRequestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: AppTheme.primaryBlue,
            onRefresh: () async {
              await ref.read(incomingRequestsProvider.notifier).refresh();
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child:
                        const Text(
                              'Service requests near you',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 100.ms)
                            .slideX(
                              begin: -0.1,
                              end: 0,
                              curve: Curves.easeOutQuart,
                            ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return RequestListCard(
                            requestData: requests[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RequestDetailsScreen(
                                    requestData: requests[index],
                                  ),
                                ),
                              );
                            },
                          )
                          .animate()
                          .fadeIn(
                            delay: Duration(milliseconds: 200 + (index * 100)),
                          )
                          .slideY(
                            begin: 0.1,
                            end: 0,
                            curve: Curves.easeOutQuart,
                          );
                    }, childCount: requests.length),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => _buildEmptyState(), // Show empty area on failure
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 64,
              color: AppTheme.primaryBlue.withOpacity(0.5),
            ),
          ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),
          const Text(
            'No nearby requests right now',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 8),
          const Text(
            'We\'ll notify you when a customer\nneeds your services nearby.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
