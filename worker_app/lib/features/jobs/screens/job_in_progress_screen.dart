import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'job_completion_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';

class JobInProgressScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> jobData;

  const JobInProgressScreen({super.key, required this.jobData});

  @override
  ConsumerState<JobInProgressScreen> createState() =>
      _JobInProgressScreenState();
}

class _JobInProgressScreenState extends ConsumerState<JobInProgressScreen> {
  bool _isLoading = false;
  late Timer _timer;
  int _secondsElapsed = 0;
  Map<String, dynamic>? _proposalData;
  String? _beforePhotoUrl;
  String? _afterPhotoUrl;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.jobData['status'] ?? 'WORKER_COMING';
    _startTimer();
    _fetchProposalData();
  }

  Future<void> _fetchProposalData() async {
    final requestId = widget.jobData['id'];
    if (requestId == null) return;

    // Fetch photos and started_at from passed jobData (which now includes jobs table data)
    setState(() {
      _beforePhotoUrl = widget.jobData['before_photo_url'];
      _afterPhotoUrl = widget.jobData['after_photo_url'];

      // If we have a started_at time, calculate elapsed seconds
      final startedAtStr = widget.jobData['started_at'];
      if (startedAtStr != null) {
        final startedAt = DateTime.parse(startedAtStr);
        _secondsElapsed = DateTime.now().difference(startedAt).inSeconds;
      }
    });

    final proposal = await ref
        .read(dashboardServiceProvider)
        .getAcceptedProposal(requestId);
    if (mounted && proposal != null) {
      setState(() => _proposalData = proposal);
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);

        // Auto-check for advance payment every 5 seconds if worker has arrived
        if (_secondsElapsed % 5 == 0 && _currentStatus == 'WORKER_ARRIVED') {
          _checkAdvanceAuto();
        }
      }
    });
  }

  Future<void> _checkAdvanceAuto() async {
    final requestId = widget.jobData['id'];
    if (requestId == null) return;

    final isPaid = await ref
        .read(dashboardServiceProvider)
        .hasAdvancePayment(requestId);

    if (isPaid && mounted && _currentStatus == 'WORKER_ARRIVED') {
      print('DEBUG: [JobInProgress] Payment detected! Auto-transitioning...');
      _updateStatus('ADVANCE_PAYMENT_DONE');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  Future<void> _callCustomer() async {
    final phone = widget.jobData['customer_phone'];
    if (phone != null) {
      final url = Uri.parse('tel:$phone');
      if (await canLaunchUrl(url)) await launchUrl(url);
    }
  }

  Future<void> _updateStatus(String nextStatus) async {
    // Validation: Require Before Photo to start service
    if (nextStatus == 'SERVICE_STARTED' && _beforePhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a "Before Work" photo first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validation: Require After Photo to complete service
    if ((nextStatus == 'SERVICE_COMPLETED' || nextStatus == 'COMPLETED') &&
        _afterPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an "After Work" photo first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final id = widget.jobData['id'];
      final workerId = widget.jobData['worker_id'];

      // Ensure proposal data is loaded before proceeding with completion
      if (_proposalData == null) {
        await _fetchProposalData();
      }

      final inspectionFee = (_proposalData?['inspection_fee'] ?? 0).toDouble();
      final serviceCost = (_proposalData?['service_cost'] ?? 0).toDouble();
      double totalAmount = inspectionFee + serviceCost;

      // Fallback if proposal data hasn't loaded (unlikely but safe)
      if (totalAmount == 0) {
        final est = widget.jobData['estimated_payment']?.toString() ?? '0';
        totalAmount =
            double.tryParse(est.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
      }

      if (nextStatus == 'SERVICE_COMPLETED' || nextStatus == 'COMPLETED') {
        final advancePercent = (_proposalData?['advance_percent'] ?? 0)
            .toDouble();
        final advanceAmount = totalAmount * (advancePercent / 100);
        final balanceAmount = totalAmount - advanceAmount;

        await ref
            .read(dashboardServiceProvider)
            .completeJob(
              id,
              amount: balanceAmount > 0 ? balanceAmount : totalAmount,
              workerId: workerId,
            );
      } else {
        // Special case for Confirm Advance button: check payment first
        if (nextStatus == 'ADVANCE_PAYMENT_DONE') {
          final isPaid = await ref
              .read(dashboardServiceProvider)
              .hasAdvancePayment(id);
          if (!isPaid) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Waiting for customer to pay advance...'),
                  backgroundColor: Colors.blueGrey,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          }
        }

        await ref
            .read(dashboardServiceProvider)
            .updateJobStatus(id, nextStatus);
      }

      setState(() => _currentStatus = nextStatus);

      if (nextStatus == 'SERVICE_COMPLETED' || nextStatus == 'COMPLETED') {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => JobCompletionScreen(
                jobData: widget.jobData,
                displayAmount: '₹${totalAmount.toStringAsFixed(0)}',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Work in Progress',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildTimer(),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildPhotoSection(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryBlue, const Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Text(
            'ELAPSED TIME',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_secondsElapsed),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ).animate().scale();
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          _infoRow(
            Icons.person_rounded,
            widget.jobData['customer_name'] ?? 'Customer',
            'Customer',
          ),
          const Divider(height: 32),
          _infoRow(
            Icons.build_circle_rounded,
            widget.jobData['service_category'] ?? 'Service',
            'Category',
          ),
          const Divider(height: 32),
          _infoRow(
            Icons.location_on_rounded,
            widget.jobData['location_name'] ?? 'Location',
            'Address',
          ),
          const Divider(height: 32),
          _infoRow(
            Icons.payments_rounded,
            _proposalData != null
                ? '₹${((_proposalData!['inspection_fee'] ?? 0) + (_proposalData!['service_cost'] ?? 0)).toStringAsFixed(0)}'
                : widget.jobData['estimated_payment'] ?? '₹0',
            'Total Payment',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData i, String v, String l) {
    return Row(
      children: [
        Icon(i, color: const Color(0xFF64748B), size: 20),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              v,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'JOB DOCUMENTATION',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
            if (_currentStatus == 'WORKER_ARRIVED' && _beforePhotoUrl == null)
              const Text(
                'Required*',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (_currentStatus == 'SERVICE_STARTED' && _afterPhotoUrl == null)
              const Text(
                'Required*',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _photoBox(
              'Before',
              _beforePhotoUrl,
              (_currentStatus == 'WORKER_ARRIVED' ||
                      _currentStatus == 'ADVANCE_PAYMENT_DONE' ||
                      _currentStatus == 'SERVICE_STARTED')
                  ? () => _pick(true)
                  : null,
              isEnabled:
                  _beforePhotoUrl != null ||
                  _currentStatus == 'WORKER_ARRIVED' ||
                  _currentStatus == 'ADVANCE_PAYMENT_DONE' ||
                  _currentStatus == 'SERVICE_STARTED',
            ),
            const SizedBox(width: 16),
            _photoBox(
              'After',
              _afterPhotoUrl,
              (_currentStatus == 'SERVICE_STARTED' ||
                      _currentStatus == 'SERVICE_COMPLETED' ||
                      _currentStatus == 'COMPLETED')
                  ? () => _pick(false)
                  : null,
              isEnabled:
                  _afterPhotoUrl != null ||
                  _currentStatus == 'SERVICE_STARTED' ||
                  _currentStatus == 'SERVICE_COMPLETED' ||
                  _currentStatus == 'COMPLETED',
            ),
          ],
        ),
      ],
    );
  }

  Widget _photoBox(
    String l,
    String? u,
    VoidCallback? o, {
    bool isEnabled = true,
  }) {
    return Expanded(
      child: InkWell(
        onTap: isEnabled ? o : (u != null ? () => _showImagePreview(u) : null),
        child: Opacity(
          opacity: isEnabled || u != null ? 1.0 : 0.5,
          child: Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: u != null
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE2E8F0),
                width: u != null ? 2 : 1,
              ),
              image: u != null
                  ? DecorationImage(
                      image: NetworkImage(u),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.2),
                        BlendMode.darken,
                      ),
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  u != null
                      ? Icons.remove_red_eye_rounded
                      : Icons.add_a_photo_rounded,
                  color: u != null ? Colors.white : const Color(0xFF94A3B8),
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  l,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: u != null ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (u == null && isEnabled)
                  const Text(
                    'Tap to upload',
                    style: TextStyle(fontSize: 9, color: Color(0xFF94A3B8)),
                  ),
                if (u != null)
                  const Text(
                    'Tap to view',
                    style: TextStyle(fontSize: 9, color: Colors.white70),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 30,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(bool b) async {
    final picker = ImagePicker();

    // Show selection dialog
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Photo Source',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _sourceButton(
                  Icons.camera_alt_rounded,
                  'Camera',
                  ImageSource.camera,
                ),
                _sourceButton(
                  Icons.photo_library_rounded,
                  'Gallery',
                  ImageSource.gallery,
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (image == null) return;

    setState(() => _isLoading = true);
    try {
      final requestId = widget.jobData['id'].toString();
      final type = b ? 'before' : 'after';

      final publicUrl = await ref
          .read(dashboardServiceProvider)
          .uploadJobPhoto(requestId, type, image.path);

      if (mounted) {
        if (publicUrl != null) {
          // Save URL to database
          await ref
              .read(dashboardServiceProvider)
              .saveJobPhotoUrl(requestId, type, publicUrl);

          setState(() {
            if (b)
              _beforePhotoUrl = publicUrl;
            else
              _afterPhotoUrl = publicUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${b ? "Before" : "After"} photo uploaded successfully!',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          throw Exception('Upload failed');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _sourceButton(IconData icon, String label, ImageSource source) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryBlue, size: 30),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    String label = '';
    String next = '';
    Color c = AppTheme.primaryBlue;
    IconData icon = Icons.check_circle_rounded;

    if (_currentStatus == 'WORKER_COMING' ||
        _currentStatus == 'ADVANCE_PAID' ||
        _currentStatus == 'ACCEPTED' ||
        _currentStatus == 'PROPOSAL_ACCEPTED') {
      label = 'Confirm Arrival';
      next = 'WORKER_ARRIVED';
      icon = Icons.location_on_rounded;
    } else if (_currentStatus == 'WORKER_ARRIVED') {
      label = 'Confirm Advance';
      next = 'ADVANCE_PAYMENT_DONE';
      c = Colors.orange;
      icon = Icons.payments_rounded;
    } else if (_currentStatus == 'ADVANCE_PAYMENT_DONE') {
      label = 'Start Service';
      next = 'SERVICE_STARTED';
      c = const Color(0xFF8B5CF6);
      icon = Icons.play_arrow_rounded;
    } else if (_currentStatus == 'SERVICE_STARTED') {
      label = 'Complete Job';
      next = 'SERVICE_COMPLETED';
      c = const Color(0xFF10B981);
      icon = Icons.task_alt_rounded;
    } else if (_currentStatus == 'SERVICE_COMPLETED' ||
        _currentStatus == 'COMPLETED') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 8),
              Text(
                'Full Payment Completed',
                style: TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    } else
      return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _updateStatus(next),
            icon: _isLoading
                ? const SizedBox.shrink()
                : Icon(icon, color: Colors.white),
            label: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: c,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _callCustomer,
            icon: const Icon(Icons.call_rounded),
            label: const Text('Call Customer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
