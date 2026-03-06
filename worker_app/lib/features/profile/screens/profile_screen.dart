import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'reviews_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfile(BuildContext context, dynamic user, dynamic worker) {
    if (user == null || worker == null) return;
    final name = TextEditingController(text: user.name);
    final cat = TextEditingController(text: worker.category);
    final exp = TextEditingController(text: worker.experienceYears?.toString());

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: cat,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: exp,
              decoration: const InputDecoration(labelText: 'Years Exp'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated! (Simulated)')),
              );
              Navigator.pop(c);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worker = ref.watch(currentWorkerProvider).value;
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF1E293B)),
            onPressed: () => _showEditProfile(context, user, worker),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              child: Text(
                user?.name[0].toUpperCase() ?? 'W',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Worker',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            Text(
              worker?.category ?? 'Professional',
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat(
                  'Rating',
                  '${worker?.rating ?? 0}',
                  Icons.star_rounded,
                  Colors.orange,
                ),
                _stat(
                  'Jobs',
                  '${worker?.totalJobs ?? 0}',
                  Icons.handyman_rounded,
                  Colors.blue,
                ),
                _stat(
                  'Exp',
                  '${worker?.experienceYears ?? 0}yr',
                  Icons.workspace_premium_rounded,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _menu(
              Icons.reviews_rounded,
              'My Reviews',
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const ReviewsScreen()),
              ),
            ),
            _menu(
              Icons.account_balance_wallet_rounded,
              'Withdrawal Settings',
              () {},
            ),
            _menu(Icons.notifications_active_rounded, 'Notifications', () {}),
            _menu(Icons.security_rounded, 'Security', () {}),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => ref.read(authServiceProvider).logoutWorker(),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String l, String v, IconData i, Color c) {
    return Column(
      children: [
        Icon(i, color: c, size: 28),
        const SizedBox(height: 8),
        Text(
          v,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(l, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _menu(IconData i, String t, VoidCallback o) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        leading: Icon(i, color: Colors.grey),
        title: Text(t, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right),
        onTap: o,
      ),
    );
  }
}
