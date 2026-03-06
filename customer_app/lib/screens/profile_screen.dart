import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
gayatri
import 'edit_profile_screen.dart';
import 'wallet_screen.dart';
import 'notifications_screen.dart';
import 'emergency_contacts_screen.dart';

import '../theme/app_theme.dart';
main

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await _authService.getCurrentUserData();
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
          if (user == null) {
            _errorMessage = 'No active session found.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Could not load profile. Check your connection.';
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logoutUser();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryBlue),
        ),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundSecondary,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_off_outlined,
                  size: 64,
                  color: AppTheme.textDisabled,
                ),
                const SizedBox(height: 20),
                Text(
                  _errorMessage ?? 'Failed to load profile.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loadUserData,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Go to Login'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundSecondary,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppTheme.backgroundPrimary,
        elevation: 0,
        centerTitle: false,
        leading: widget.onBack != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleLogout();
                      },
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.backgroundPrimary,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderDefault),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppTheme.primaryBlue.withValues(
                      alpha: 0.08,
                    ),
                    child: Text(
                      _user!.name.isNotEmpty
                          ? _user!.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _user!.name,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _user!.phone,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // New Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _buildSectionCard([
                    _buildProfileItem(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      value: 'Update your personal information',
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(user: _user!),
                          ),
                        );
                        if (updated == true) {
                          _loadUserData();
                        }
                      },
                      showArrow: true,
                    ),
                  ]),

                  const SizedBox(height: 12),

                  _buildSectionCard([
                    _buildProfileItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      value: 'Check balance and payment history',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalletScreen(),
                          ),
                        );
                      },
                      showArrow: true,
                    ),
                  ]),

                  const SizedBox(height: 12),

                  _buildSectionCard([
                    _buildProfileItem(
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      value: 'Manage your alert preferences',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                      },
                      showArrow: true,
                    ),
                  ]),

                  const SizedBox(height: 12),

                  _buildSectionCard([
                    _buildProfileItem(
                      icon: Icons.contact_emergency_outlined,
                      title: 'Emergency Contacts',
                      value: 'Manage your safety contacts',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const EmergencyContactsScreen(),
                          ),
                        );
                      },
                      showArrow: true,
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Basic Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: Text(
                      'Account Details',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Card(
                    elevation: 0,
                    color: AppTheme.backgroundPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppTheme.borderDefault),
                    ),
                    child: Column(
                      children: [
                        _buildProfileItem(
                          icon: Icons.person_outline,
                          title: 'Full Name',
                          value: _user!.name,
                        ),
                        Divider(
                          height: 1,
                          color: Colors.grey.shade100,
                          indent: 56,
                        ),
                        _buildProfileItem(
                          icon: Icons.phone_android_outlined,
                          title: 'Mobile Number',
                          value: _user!.phone,
                        ),
                        const Divider(
                          height: 1,
                          color: AppTheme.borderDefault,
                          indent: 56,
                        ),
                        _buildProfileItem(
                          icon: Icons.badge_outlined,
                          title: 'Role',
                          value: _user!.role.toUpperCase(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // App Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 0,
                color: AppTheme.backgroundPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.borderDefault),
                ),
                child: Column(
                  children: [
                    _buildProfileItem(
                      icon: Icons.info_outline,
                      title: 'App Version',
                      value: '1.0.0',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Card(
      elevation: 0,
      color: AppTheme.backgroundPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.borderDefault),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
    bool showArrow = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.textSecondary, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodySmall),
      trailing: showArrow
          ? const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppTheme.textDisabled,
            )
          : null,
      onTap: onTap,
    );
  }
}
