import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../viewmodels/my_bookings_viewmodel.dart';
import '../viewmodels/workers_viewmodel.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final int requestId;
  final int workerId;
  final String? workerName;

  const ReviewScreen({
    super.key,
    required this.requestId,
    required this.workerId,
    this.workerName,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _submitted = false;

  static const String _customerId = 'fc91af88-9664-4953-a342-01f50a9ea2c6';

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating before submitting.'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(workerRepositoryProvider);
      await repo.submitReview(
        requestId: widget.requestId,
        workerId: widget.workerId,
        customerId: _customerId,
        rating: _rating,
        comment: _commentCtrl.text.trim().isEmpty
            ? null
            : _commentCtrl.text.trim(),
      );

      if (mounted) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });
        ref.read(myBookingsViewModelProvider.notifier).loadBookings();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: ${e.toString()}'),
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
        title: const Text('Rate & Review'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        automaticallyImplyLeading: !_submitted,
      ),
      body: _submitted ? _buildThankYou() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Worker avatar
          CircleAvatar(
            radius: 44,
            backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person_rounded,
              size: 44,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            widget.workerName ?? 'Worker',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            'How was your experience?',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),

          const SizedBox(height: 32),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _rating = star),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: star <= _rating
                        ? const Color(0xFFF59E0B)
                        : AppTheme.textDisabled,
                    size: 44,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 8),
          Text(
            _ratingLabel,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: _rating > 0
                  ? const Color(0xFFF59E0B)
                  : AppTheme.textDisabled,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 32),

          // Comment field
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Share more details about your experience (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderDefault),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.borderDefault),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.primaryBlue,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppTheme.backgroundPrimary,
            ),
          ),

          const SizedBox(height: 32),

          // Quick tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickTags.map((tag) {
              return ActionChip(
                label: Text(tag),
                onPressed: () {
                  final current = _commentCtrl.text;
                  if (!current.contains(tag)) {
                    _commentCtrl.text = current.isEmpty
                        ? tag
                        : '$current, $tag';
                  }
                },
                backgroundColor: AppTheme.backgroundPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppTheme.borderDefault),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 36),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit Review'),
            ),
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text(
              'Skip',
              style: TextStyle(color: AppTheme.textTertiary),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildThankYou() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Color(0xFFF59E0B),
                size: 52,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Thank You!',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your review helps the community find great workers.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return Icon(
                  i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: i < _rating
                      ? const Color(0xFFF59E0B)
                      : AppTheme.textDisabled,
                  size: 28,
                );
              }),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Great';
      case 5:
        return 'Excellent!';
      default:
        return 'Tap to rate';
    }
  }

  static const List<String> _quickTags = [
    'Punctual',
    'Professional',
    'Clean work',
    'Friendly',
    'Good pricing',
    'Highly recommended',
    'Would hire again',
  ];
}
