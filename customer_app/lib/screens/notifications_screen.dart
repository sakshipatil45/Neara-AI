import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _pushNotifications = true;
  bool _emailAlerts = false;

  final List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Service Booked Successfully',
      'body': 'Your plumber will arrive at 10:00 AM tomorrow.',
      'time': '2 hours ago',
      'icon': Icons.check_circle_outline,
      'color': Colors.green,
      'isRead': false,
    },
    {
      'title': 'New Feedback Received',
      'body': 'A professional has completed your cleaning service.',
      'time': '5 hours ago',
      'icon': Icons.star_border,
      'color': Colors.blue,
      'isRead': true,
    },
    {
      'title': 'Wallet Balance Low',
      'body': 'Your wallet balance is below ₹100. Please top up.',
      'time': 'Yesterday',
      'icon': Icons.warning_amber_outlined,
      'color': Colors.orange,
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: 'Activity'),
              Tab(text: 'Settings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Activity Tab
            _buildActivityTab(),
            // Settings Tab
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: Colors.black12),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: notification['color'].withValues(alpha: 0.1),
            child: Icon(
              notification['icon'],
              color: notification['color'],
              size: 24,
            ),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  notification['title'],
                  style: TextStyle(
                    fontWeight: notification['isRead']
                        ? FontWeight.normal
                        : FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              if (!notification['isRead'])
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                notification['body'],
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                notification['time'],
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _notifications[index]['isRead'] = true;
            });
          },
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Notification Preferences',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Control how you receive updates and alerts.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 32),
        _buildSettingToggle(
          title: 'Push Notifications',
          subtitle: 'Receive instant alerts on your device.',
          value: _pushNotifications,
          onChanged: (val) => setState(() => _pushNotifications = val),
        ),
        const Divider(height: 40),
        _buildSettingToggle(
          title: 'Email Notifications',
          subtitle: 'Receive summaries and receipts via email.',
          value: _emailAlerts,
          onChanged: (val) => setState(() => _emailAlerts = val),
        ),
      ],
    );
  }

  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }
}
