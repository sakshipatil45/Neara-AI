import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../jobs/screens/jobs_screen.dart';
import '../../requests/screens/requests_screen.dart';
import '../../earnings/screens/earnings_screen.dart';
import '../../profile/screens/profile_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const JobsScreen(),
    const RequestsScreen(),
    const EarningsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: AppTheme.primaryBlue.withOpacity(0.1),
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: _selectedIndex == 0
                    ? AppTheme.primaryBlue
                    : const Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.home_rounded,
                color: AppTheme.primaryBlue,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.work_outline_rounded,
                color: _selectedIndex == 1
                    ? AppTheme.primaryBlue
                    : const Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.work_rounded,
                color: AppTheme.primaryBlue,
              ),
              label: 'Jobs',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.notifications_none_rounded,
                color: _selectedIndex == 2
                    ? AppTheme.primaryBlue
                    : const Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.notifications_rounded,
                color: AppTheme.primaryBlue,
              ),
              label: 'Requests',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.account_balance_wallet_outlined,
                color: _selectedIndex == 3
                    ? AppTheme.primaryBlue
                    : const Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.account_balance_wallet_rounded,
                color: AppTheme.primaryBlue,
              ),
              label: 'Earnings',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline_rounded,
                color: _selectedIndex == 4
                    ? AppTheme.primaryBlue
                    : const Color(0xFF64748B),
              ),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: AppTheme.primaryBlue,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
