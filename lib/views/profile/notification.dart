import 'package:flutter/material.dart';
import 'package:monet/controller/notification.dart';
import 'package:monet/models/notification.dart';
import 'package:monet/models/result.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/local_notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String? errorMessage;
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    LocalNotificationService.initialize(); // Ensure local notifications are initialized
    _loadNotifications();
    _loadUnreadCount();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await NotificationController.getNotifications();

    if (mounted) {
      setState(() {
        isLoading = false;
        if (result.isSuccess) {
          notifications = result.results ?? [];
        } else {
          errorMessage = result.message;
        }
      });
    }
  }

  Future<void> _loadUnreadCount() async {
    final result = await NotificationController.getUnreadCount();
    if (mounted && result.isSuccess) {
      setState(() {
        unreadCount = result.results ?? 0;
      });
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() => isRefreshing = true);
    await _loadNotifications();
    await _loadUnreadCount();
    setState(() => isRefreshing = false);
  }

  Future<void> _markAsRead(String notificationId, int index) async {
    final result = await NotificationController.markAsRead(notificationId);

    if (result.isSuccess && mounted) {
      setState(() {
        notifications[index] = result.results!;
        if (unreadCount > 0) unreadCount--;
      });

      // Show local notification
      await LocalNotificationService.showNotification(
        id: notificationId.hashCode,
        title: notifications[index].title,
        body: notifications[index].message,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final result = await NotificationController.markAllAsRead();

    if (result.isSuccess && mounted) {
      setState(() {
        notifications = notifications.map((n) {
          n.isRead = true;
          n.readAt = DateTime.now().toIso8601String();
          return n;
        }).toList();
        unreadCount = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteNotification(String notificationId, int index) async {
    final result = await NotificationController.deleteNotification(notificationId);

    if (result.isSuccess && mounted) {
      setState(() {
        final wasUnread = !notifications[index].isRead;
        notifications.removeAt(index);
        if (wasUnread && unreadCount > 0) unreadCount--;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification deleted'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() { isLoading = true; });
      final result = await NotificationController.deleteAllNotifications();
      if (mounted) {
        setState(() {
          notifications.clear();
          unreadCount = 0;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildNotificationIcon(String type) {
    switch (type) {
      case 'budget_created':
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.account_balance_wallet,
            color: Colors.green.shade600,
            size: 24,
          ),
        );
      case 'expense_added':
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.trending_down,
            color: Colors.red.shade600,
            size: 24,
          ),
        );
      case 'income_added':
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.trending_up,
            color: Colors.blue.shade600,
            size: 24,
          ),
        );
      default:
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.notifications,
            color: Colors.grey.shade600,
            size: 24,
          ),
        );
    }
  }

  String _formatTimeAgo(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return '';
    try {
      // Try parsing as ISO8601 or fallback to other formats
      DateTime? dateTime;
      try {
        dateTime = DateTime.parse(dateTimeString);
      } catch (_) {
        // Try parsing as yyyy-MM-dd or yyyy/MM/dd
        final regex = RegExp(r'^(\\d{4})[-/](\\d{2})[-/](\\d{2})');
        final match = regex.firstMatch(dateTimeString);
        if (match != null) {
          dateTime = DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          );
        }
      }
      if (dateTime == null) return '';
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      if (difference.inDays > 0) {
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildNotificationItem(NotificationModel notification, int index) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id, index);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? Colors.grey.shade200 : Colors.blue.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id, index);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationIcon(notification.type),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTimeAgo(notification.data?['created_at']?.toString()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (notification.readAt != null)
                          Text(
                            'Read',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        title: Row(
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade500,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () async {
                final allRead = notifications.every((n) => n.isRead);
                if (allRead) {
                  await _deleteAllNotifications();
                } else {
                  await _markAllAsRead();
                }
              },
              child: Text(
                notifications.every((n) => n.isRead) ? 'Delete all' : 'Mark all read',
                style: TextStyle(
                  color: notifications.every((n) => n.isRead)
                      ? Colors.red.shade600
                      : Colors.blue.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        )
            : notifications.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ll see your notifications here when you have them',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            return _buildNotificationItem(notifications[index], index);
          },
        ),
      ),
    );
  }
}