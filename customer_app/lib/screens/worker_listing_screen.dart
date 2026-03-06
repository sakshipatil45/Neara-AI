// ignore_for_file: unnecessary_underscores, unused_field, unused_import
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/worker_model.dart';
import '../models/booking_model.dart';
import '../viewmodels/workers_viewmodel.dart';

// ─────────────── NEARA Design Tokens ───────────────
class _N {
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFF3B82F6);
  static const success = Color(0xFF059669);
  static const warning = Color(0xFFEA580C);
  static const error = Color(0xFFDC2626);

  static const bg = Color(0xFFFFFFFF);
  static const bgSecondary = Color(0xFFF9FAFB);
  static const bgTertiary = Color(0xFFF3F4F6);

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF374151);
  static const textTertiary = Color(0xFF6B7280);
  static const textDisabled = Color(0xFF9CA3AF);
  static const borderDefault = Color(0xFFE5E7EB);

  static List<BoxShadow> get shadow1 => const [
        BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 1)),
        BoxShadow(color: Color(0x14000000), blurRadius: 2, offset: Offset(0, 1)),
      ];
}

// ─────────────── Worker Listing Screen ───────────────
class WorkerListingScreen extends ConsumerStatefulWidget {
  const WorkerListingScreen({super.key});

  @override
  ConsumerState<WorkerListingScreen> createState() => _WorkerListingScreenState();
}

class _WorkerListingScreenState extends ConsumerState<WorkerListingScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

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
        .where((w) =>
            w.name.toLowerCase().contains(q) ||
            w.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final workersState = ref.watch(workersViewModelProvider);
    final vm = ref.read(workersViewModelProvider.notifier);
    final filtered = _filterWorkers(workersState.workers);

    return Scaffold(
      backgroundColor: _N.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Bar ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              color: _N.bg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Workers',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: _N.textPrimary,
                              letterSpacing: -0.4,
                            ),
                          ),
                          Text(
                            '${workersState.workers.length} professionals near you',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: _N.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => vm.loadWorkers(),
                        icon: const Icon(Icons.refresh_rounded,
                            color: _N.textSecondary, size: 22),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Search Bar ──
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: _N.bgTertiary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _N.borderDefault),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(Icons.search_rounded,
                              color: _N.textDisabled, size: 20),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (v) => setState(() => _searchQuery = v),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: _N.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Search by name or service...',
                              hintStyle: TextStyle(
                                fontFamily: 'Inter',
                                color: _N.textDisabled,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
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
                              child: Icon(Icons.close_rounded,
                                  color: _N.textDisabled, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Category Chips ──
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final cat = _categories[i];
                        final isSelected =
                            workersState.selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => vm.filterByCategory(cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _N.primary
                                  : _N.bgSecondary,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: isSelected
                                    ? _N.primary
                                    : _N.borderDefault,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _categoryIcons[cat] ?? Icons.build_rounded,
                                  size: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : _N.textSecondary,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : _N.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Divider
                  const Divider(height: 1, color: _N.borderDefault),
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
                              color: _N.primary),
                          SizedBox(height: 16),
                          Text('Finding workers...',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: _N.textTertiary,
                              )),
                        ],
                      ),
                    )
                  : workersState.error != null
                      ? _ErrorView(
                          message: workersState.error!,
                          onRetry: () => vm.loadWorkers(),
                        )
                      : filtered.isEmpty
                          ? _EmptyView(
                              category: workersState.selectedCategory,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) =>
                                  _WorkerCard(worker: filtered[i]),
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
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showWorkerDetails(context, ref, worker),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _N.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _N.borderDefault),
          boxShadow: _N.shadow1,
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _N.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      worker.name.isNotEmpty
                          ? worker.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: _N.primary,
                      ),
                    ),
                  ),
                ),
                if (worker.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _N.success,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
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
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _N.textPrimary,
                          ),
                        ),
                      ),
                      if (worker.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded,
                            color: _N.primary, size: 15),
                      ],
                    ],
                  ),

                  const SizedBox(height: 3),

                  // Category + exp
                  Text(
                    '${worker.category} · ${worker.experienceYears}y exp',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: _N.textTertiary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Rating + jobs + online status
                  Row(
                    children: [
                      _RatingChip(rating: worker.rating),
                      const SizedBox(width: 8),
                      Text(
                        '${worker.totalJobs} jobs',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: _N.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: worker.isOnline
                              ? _N.success.withValues(alpha: 0.08)
                              : _N.bgTertiary,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: worker.isOnline
                                ? _N.success.withValues(alpha: 0.3)
                                : _N.borderDefault,
                          ),
                        ),
                        child: Text(
                          worker.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: worker.isOnline
                                ? _N.success
                                : _N.textDisabled,
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
            Icon(Icons.arrow_forward_ios_rounded,
                color: _N.textDisabled, size: 14),
          ],
        ),
      ),
    );
  }

  void _showWorkerDetails(
      BuildContext context, WidgetRef ref, Worker worker) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BookingBottomSheet(worker: worker),
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
        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _N.textSecondary,
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
            const Icon(Icons.wifi_off_rounded,
                color: _N.textDisabled, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load workers',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _N.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: _N.textTertiary,
                )),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _N.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w600),
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
          const Icon(Icons.search_off_rounded,
              color: _N.textDisabled, size: 48),
          const SizedBox(height: 16),
          Text(
            'No $category workers found',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _N.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different category',
            style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: _N.textTertiary),
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

  @override
  void initState() {
    super.initState();
    _summaryCtrl = TextEditingController(
        text: widget.prefillSummary ?? '');
    _urgency = widget.prefillUrgency ?? 'medium';
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
          backgroundColor: _N.warning,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            color: _N.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                    color: _N.borderDefault,
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
                                  color: _N.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    widget.worker.name.isNotEmpty
                                        ? widget.worker.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: _N.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      Text(widget.worker.name,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: _N.textPrimary,
                                          )),
                                      if (widget.worker.isVerified)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 4),
                                          child: Icon(Icons.verified_rounded,
                                              color: _N.primary, size: 15),
                                        ),
                                    ]),
                                    Text(
                                        '${widget.worker.category} · ${widget.worker.experienceYears}y exp',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          color: _N.textTertiary,
                                        )),
                                  ],
                                ),
                              ),
                              _RatingChip(rating: widget.worker.rating),
                            ],
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: _N.borderDefault),
                          const SizedBox(height: 16),

                          // Heading
                          const Text(
                            'Send Booking Request',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _N.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Describe your issue and we\'ll notify the worker.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: _N.textTertiary,
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Issue Description
                          const Text(
                            'Describe the issue',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _N.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _summaryCtrl,
                            maxLines: 4,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: _N.textPrimary,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Water pipe leaking under the sink...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Inter',
                                color: _N.textDisabled,
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: _N.bgTertiary,
                              contentPadding: const EdgeInsets.all(12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: _N.borderDefault),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: _N.borderDefault),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                    color: _N.primary, width: 1.5),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Urgency selector
                          const Text(
                            'Urgency',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _N.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children:
                                ['low', 'medium', 'high'].map((u) {
                              final isSelected = _urgency == u;
                              final color = u == 'high'
                                  ? _N.error
                                  : u == 'medium'
                                      ? _N.warning
                                      : _N.success;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _urgency = u),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    margin: EdgeInsets.only(
                                        right: u != 'high' ? 8 : 0),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withValues(alpha: 0.1)
                                          : _N.bgSecondary,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isSelected
                                            ? color.withValues(alpha: 0.6)
                                            : _N.borderDefault,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        u[0].toUpperCase() +
                                            u.substring(1),
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? color
                                              : _N.textTertiary,
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
                              color: _N.bgTertiary,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _N.borderDefault),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.info_outline_rounded,
                                    color: Color(0xFF0284C7), size: 16),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Worker will confirm price after reviewing your request.',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: _N.textTertiary,
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
                              onPressed: bookingState.status ==
                                      BookingStatus.loading
                                  ? null
                                  : _submit,
                              icon: bookingState.status ==
                                      BookingStatus.loading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : const Icon(
                                      Icons.send_rounded, size: 18),
                              label: Text(
                                bookingState.status ==
                                        BookingStatus.loading
                                    ? 'Sending...'
                                    : 'Send Request',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _N.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6)),
                                textStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          if (bookingState.status ==
                              BookingStatus.error) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _N.error.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: _N.error.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                bookingState.error ?? 'Booking failed',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  color: _N.error,
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
              color: _N.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                color: _N.success, size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Request Sent!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _N.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your booking request has been sent to ${worker.name}.\nYou\'ll be notified once they accept.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: _N.textTertiary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _N.bgSecondary,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _N.borderDefault),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: _N.textTertiary, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Typical response time: 5–15 minutes',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: _N.textSecondary,
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
                foregroundColor: _N.primary,
                side: const BorderSide(color: _N.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(
                    fontFamily: 'Inter', fontWeight: FontWeight.w600),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}
