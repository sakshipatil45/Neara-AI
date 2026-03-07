import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker_model.dart';
import '../theme/app_theme.dart';
import '../viewmodels/workers_viewmodel.dart';
import '../services/location_service.dart';
import 'worker_map_screen.dart';

// ─────────────── Worker Listing Screen ───────────────
class WorkerListingScreen extends ConsumerStatefulWidget {
  /// When pushed from the intent summary, pre-select a category and pre-fill
  /// the booking sheet with the AI-detected data.
  final String? initialCategory;
  final String? prefillSummary;
  final String? prefillUrgency;

  const WorkerListingScreen({
    super.key,
    this.initialCategory,
    this.prefillSummary,
    this.prefillUrgency,
  });

  @override
  ConsumerState<WorkerListingScreen> createState() =>
      _WorkerListingScreenState();
}

class _WorkerListingScreenState extends ConsumerState<WorkerListingScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(workersViewModelProvider.notifier);
      if (widget.initialCategory != null) {
        notifier.filterByCategory(widget.initialCategory!);
      } else if (ref.read(workersViewModelProvider).workers.isEmpty) {
        // First visit — load the default (all) worker list.
        notifier.loadWorkers();
      }
    });
  }

  static const _categories = [
    'All',
    'Plumber',
    'Electrician',
    'Mechanic',
    'Maid',
    'Gas Service',
  ];

  final Map<String, IconData> _categoryIcons = {
    'All': Icons.apps_rounded,
    'Plumber': Icons.plumbing_rounded,
    'Electrician': Icons.electrical_services_rounded,
    'Mechanic': Icons.car_repair_rounded,
    'Maid': Icons.cleaning_services_rounded,
    'Gas Service': Icons.local_fire_department_rounded,
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Worker> _filterWorkers(List<Worker> workers) {
    if (_searchQuery.isEmpty) return workers;
    final q = _searchQuery.toLowerCase();
    return workers
        .where(
          (w) =>
              w.name.toLowerCase().contains(q) ||
              w.category.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersViewModelProvider);
    final vm = ref.read(workersViewModelProvider.notifier);
    final filtered = _filterWorkers(workersState.workers);

    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              color: AppTheme.backgroundPrimary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button (only when pushed onto nav stack)
                      if (Navigator.canPop(context))
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.textSecondary,
                            size: 20,
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.initialCategory != null
                                  ? '${widget.initialCategory} Workers'
                                  : 'Find Workers',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            Text(
                              '${workersState.workers.length} professionals near you',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => vm.loadWorkers(),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: AppTheme.textSecondary,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  // AI-intent context banner
                  if (widget.prefillSummary != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.prefillSummary!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Search Bar ──
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundTertiary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderDefault),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Icon(
                            Icons.search_rounded,
                            color: AppTheme.textDisabled,
                            size: 20,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              hintText: 'Search by name or service...',
                              hintStyle: TextStyle(
                                color: AppTheme.textDisabled,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Icon(
                                Icons.close_rounded,
                                color: AppTheme.textDisabled,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Category Chips ──
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final isSelected = workersState.selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => vm.filterByCategory(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryBlue
                                  : AppTheme.backgroundSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryBlue
                                    : AppTheme.borderDefault,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcons[cat] ?? Icons.build_rounded,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppTheme.borderDefault),
                ],
              ),
            ),

            // ── Workers List ──
            Expanded(
              child: workersState.isLoading
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryBlue,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Finding workers...',
                            style: TextStyle(color: AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    )
                  : workersState.error != null
                  ? _ErrorView(
                      message: workersState.error!,
                      onRetry: () => vm.loadWorkers(),
                    )
                  : filtered.isEmpty
                  ? _EmptyView(category: workersState.selectedCategory)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _WorkerCard(
                        worker: filtered[i],
                        prefillCategory: workersState.selectedCategory,
                        prefillSummary: widget.prefillSummary,
                        prefillUrgency: widget.prefillUrgency,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Worker Card ───────────────
class _WorkerCard extends ConsumerWidget {
  final Worker worker;
  final String? prefillCategory;
  final String? prefillSummary;
  final String? prefillUrgency;
  const _WorkerCard({
    required this.worker,
    this.prefillCategory,
    this.prefillSummary,
    this.prefillUrgency,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showWorkerDetails(context, ref, worker),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderDefault),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      worker.name.isNotEmpty
                          ? worker.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),
                if (worker.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + verified
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          worker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      if (worker.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppTheme.primaryBlue,
                          size: 16,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Category + exp
                  Text(
                    '${worker.category} · ${worker.experienceYears}y exp',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                  const SizedBox(height: 8),

                  // Rating + jobs + online status
                  Row(
                    children: [
                      _RatingChip(rating: worker.rating),
                      const SizedBox(width: 8),
                      Text(
                        '${worker.totalJobs} jobs',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: worker.isOnline
                              ? AppTheme.successGreen.withOpacity(0.08)
                              : AppTheme.backgroundTertiary,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: worker.isOnline
                                ? AppTheme.successGreen.withOpacity(0.3)
                                : AppTheme.borderDefault,
                          ),
                        ),
                        child: Text(
                          worker.isOnline ? 'ONLINE' : 'OFFLINE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: worker.isOnline
                                ? AppTheme.successGreen
                                : AppTheme.textDisabled,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Book arrow
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textDisabled,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkerDetails(BuildContext context, WidgetRef ref, Worker worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingBottomSheet(
        worker: worker,
        prefillCategory: prefillCategory,
        prefillSummary: prefillSummary,
        prefillUrgency: prefillUrgency,
      ),
    );
  }
}

// ─────────────── Rating Chip ───────────────
class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ─────────────── Error View ───────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              color: AppTheme.textDisabled,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load workers',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────── Empty View ───────────────
class _EmptyView extends StatelessWidget {
  final String category;
  const _EmptyView({required this.category});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: AppTheme.textDisabled,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'No $category workers found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different category',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─────────────── Booking Bottom Sheet ───────────────
class BookingBottomSheet extends ConsumerStatefulWidget {
  final Worker worker;
  final String? prefillCategory;
  final String? prefillSummary;
  final String? prefillUrgency;

  const BookingBottomSheet({
    super.key,
    required this.worker,
    this.prefillCategory,
    this.prefillSummary,
    this.prefillUrgency,
  });

  @override
  ConsumerState<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends ConsumerState<BookingBottomSheet> {
  late TextEditingController _summaryCtrl;
  String _urgency = 'medium';
  bool _submitted = false;
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _summaryCtrl = TextEditingController(text: widget.prefillSummary ?? '');
    _urgency = widget.prefillUrgency ?? 'medium';
    _fetchDistance();
  }

  Future<void> _fetchDistance() async {
    await LocationService.instance.getCurrentPosition();
    final d = LocationService.instance.distanceTo(
      widget.worker.latitude,
      widget.worker.longitude,
    );
    if (mounted && d != null) setState(() => _distanceKm = d);
  }

  @override
  void dispose() {
    _summaryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_summaryCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please describe the issue'),
          backgroundColor: AppTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final vm = ref.read(bookingViewModelProvider.notifier);
    final success = await vm.sendBooking(
      workerId: widget.worker.id,
      serviceCategory: widget.prefillCategory ?? widget.worker.category,
      issueSummary: _summaryCtrl.text.trim(),
      urgency: _urgency,
    );

    if (success && mounted) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingViewModelProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.backgroundPrimary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.gray300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: _submitted
                    ? _SuccessView(worker: widget.worker)
                    : ListView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        children: [
                          // Worker header
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.worker.name.isNotEmpty
                                        ? widget.worker.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          widget.worker.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineMedium,
                                        ),
                                        if (widget.worker.isVerified)
                                          const Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Icon(
                                              Icons.verified_rounded,
                                              color: AppTheme.primaryBlue,
                                              size: 16,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '${widget.worker.category} · ${widget.worker.experienceYears}y exp',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              _RatingChip(rating: widget.worker.rating),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: AppTheme.borderDefault),

                          // Distance + View on Map row
                          if (_distanceKm != null ||
                              widget.worker.latitude != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (_distanceKm != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryBlue.withOpacity(
                                        0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppTheme.primaryBlue.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.near_me_rounded,
                                          size: 13,
                                          color: AppTheme.primaryBlue,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          LocationService.formatDistance(
                                            _distanceKm!,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                if (widget.worker.latitude != null &&
                                    widget.worker.longitude != null)
                                  OutlinedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WorkerMapScreen(
                                          worker: widget.worker,
                                        ),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.map_rounded,
                                      size: 14,
                                    ),
                                    label: const Text('View on Map'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.textSecondary,
                                      side: const BorderSide(
                                        color: AppTheme.borderDefault,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],

                          const SizedBox(height: 16),

                          // Heading
                          const Text(
                            'Send Booking Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Describe your issue and we\'ll notify the worker.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textTertiary,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Issue Description
                          const Text(
                            'Describe the issue',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _summaryCtrl,
                            maxLines: 4,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.textPrimary,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Water pipe leaking under the sink...',
                              hintStyle: const TextStyle(
                                color: AppTheme.textDisabled,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: AppTheme.backgroundTertiary,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderDefault,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderDefault,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryBlue,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Urgency selector
                          const Text(
                            'Urgency',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: ['low', 'medium', 'high'].map((u) {
                              final isSelected = _urgency == u;
                              final color = u == 'high'
                                  ? AppTheme.errorRed
                                  : u == 'medium'
                                  ? AppTheme.warningOrange
                                  : AppTheme.successGreen;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _urgency = u),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: EdgeInsets.only(
                                      right: u != 'high' ? 8 : 0,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withOpacity(0.1)
                                          : AppTheme.backgroundSecondary,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? color.withOpacity(0.6)
                                            : AppTheme.borderDefault,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        u[0].toUpperCase() + u.substring(1),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? color
                                              : AppTheme.textTertiary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 28),

                          // Pricing note
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundTertiary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderDefault),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Color(0xFF0284C7),
                                  size: 16,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Worker will confirm price after reviewing your request.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textTertiary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed:
                                  bookingState.status == BookingStatus.loading
                                  ? null
                                  : _submit,
                              icon: bookingState.status == BookingStatus.loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                bookingState.status == BookingStatus.loading
                                    ? 'Sending...'
                                    : 'Send Request',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          if (bookingState.status == BookingStatus.error) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.errorRed.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.errorRed.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                bookingState.error ?? 'Booking failed',
                                style: const TextStyle(
                                  color: AppTheme.errorRed,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────── Booking Success View ───────────────
class _SuccessView extends StatelessWidget {
  final Worker worker;
  const _SuccessView({required this.worker});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.successGreen,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Request Sent!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your booking request has been sent to ${worker.name}.\nYou\'ll be notified once they accept.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textTertiary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderDefault),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: AppTheme.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Typical response time: 5–15 minutes',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
