import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/workers_viewmodel.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import 'service_completion_screen.dart';

class WorkPhotoReviewScreen extends ConsumerStatefulWidget {
  final int requestId;

  const WorkPhotoReviewScreen({super.key, required this.requestId});

  @override
  ConsumerState<WorkPhotoReviewScreen> createState() =>
      _WorkPhotoReviewScreenState();
}

class _WorkPhotoReviewScreenState extends ConsumerState<WorkPhotoReviewScreen> {
  JobRecord? _job;
  bool _isLoading = true;
  bool _isApproving = false;

  @override
  void initState() {
    super.initState();
    _loadJob();
  }

  Future<void> _loadJob() async {
    try {
      final repo = ref.read(workerRepositoryProvider);
      final job = await repo.fetchJobForRequest(widget.requestId);
      if (mounted)
        setState(() {
          _job = job;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveWork() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.backgroundPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Approve Work Done?'),
        content: const Text(
          'By approving, you confirm the service has been completed satisfactorily. This will release the final payment to the worker.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Not Yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
            ),
            child: const Text('Yes, Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isApproving = true);
    try {
      final repo = ref.read(workerRepositoryProvider);
      await repo.confirmServiceCompletion(widget.requestId);
      ref.read(myBookingsViewModelProvider.notifier).loadBookings();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ServiceCompletionScreen(requestId: widget.requestId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isApproving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Review Work Done'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryBlue),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryBlue.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.photo_library_rounded,
                  color: AppTheme.primaryBlue,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Worker has completed the job',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Review the before & after photos, then approve to release the balance payment.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Before photo
          _buildPhotoCard(
            'Before Service',
            _job?.beforePhotoUrl,
            Icons.camera_alt_rounded,
            const Color(0xFFEA580C),
          ),

          const SizedBox(height: 16),

          // After photo
          _buildPhotoCard(
            'After Service',
            _job?.afterPhotoUrl,
            Icons.check_circle_outline_rounded,
            AppTheme.successGreen,
          ),

          const SizedBox(height: 32),

          // Approve button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isApproving ? null : _approveWork,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isApproving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.verified_rounded, color: Colors.white),
              label: Text(
                _isApproving ? 'Approving...' : 'Approve Work & Pay Balance',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Dispute button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dispute resolution coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
                side: const BorderSide(color: AppTheme.errorRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.report_problem_rounded),
              label: const Text(
                'Raise a Dispute',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(
    String label,
    String? photoUrl,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderDefault),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          photoUrl != null && photoUrl.isNotEmpty
              ? Image.network(
                  photoUrl,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 220,
                          color: AppTheme.backgroundSecondary,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                  errorBuilder: (_, __, ___) => _noPhotoPlaceholder(color),
                )
              : _noPhotoPlaceholder(color),
        ],
      ),
    );
  }

  Widget _noPhotoPlaceholder(Color color) {
    return Container(
      height: 180,
      color: color.withValues(alpha: 0.06),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              color: color.withValues(alpha: 0.4),
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No photo uploaded',
              style: TextStyle(color: color.withValues(alpha: 0.5)),
            ),
          ],
        ),
      ),
    );
  }
}
