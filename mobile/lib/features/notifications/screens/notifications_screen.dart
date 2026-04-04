import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Service Completed',
      'message': 'Your plumbing service has been completed successfully',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'type': 'service',
      'read': false,
    },
    {
      'title': 'Booking Confirmed',
      'message': 'Your booking for tomorrow at 10:00 AM is confirmed',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'booking',
      'read': false,
    },
    {
      'title': 'Payment Successful',
      'message': 'Payment of \$150 has been received',
      'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
      'type': 'payment',
      'read': true,
    },
    {
      'title': 'Technician Assigned',
      'message': 'John Smith has been assigned to your service request',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'assignment',
      'read': true,
    },
  ];

  void _markAsRead(int index) {
    setState(() {
      notifications[index]['read'] = true;
    });
  }

  void _deleteNotification(int index) {
    setState(() {
      notifications.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification deleted')),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'service':
        return Icons.build;
      case 'booking':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      case 'assignment':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'service':
        return Colors.blue;
      case 'booking':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      case 'assignment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          if (notifications.any((n) => !n['read']))
            TextButton(
              onPressed: () {
                setState(() {
                  for (var notification in notifications) {
                    notification['read'] = true;
                  }
                });
              },
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All caught up! Check back later',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  color: notification['read']
                      ? Colors.white
                      : Colors.blue.withOpacity(0.05),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTypeColor(notification['type'])
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(notification['type']),
                        color: _getTypeColor(notification['type']),
                      ),
                    ),
                    title: Text(
                      notification['title'],
                      style: TextStyle(
                        fontWeight: notification['read']
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification['message']),
                        const SizedBox(height: 8),
                        Text(
                          _getTimeAgo(notification['timestamp']),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        if (!notification['read'])
                          PopupMenuItem(
                            onTap: () => _markAsRead(index),
                            child: const Row(
                              children: [
                                Icon(Icons.done),
                                SizedBox(width: 8),
                                Text('Mark as read'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          onTap: () => _deleteNotification(index),
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    onTap: () {
                      _markAsRead(index);
                    },
                  ),
                );
              },
            ),
    );
  }
}
