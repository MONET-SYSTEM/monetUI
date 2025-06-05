import 'package:flutter/material.dart';
import 'package:monet/controller/notification.dart';
import 'package:monet/models/notification.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> notifications = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  String? errorMessage;
  final ScrollController _scrollController = ScrollController();
  int currentPage = 1;
  static const int perPage = 15;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreNotifications();
    }
  }

  Future<void> _loadNotifications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        isLoading = true;
        currentPage = 1;
        notifications.clear();
        errorMessage = null;
      });
    }

    try {
      final result = await NotificationController.getAll(perPage: perPage);

      if (result.isSuccess && result.results != null) {
        setState(() {
          notifications = result.results!;
          isLoading = false;
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = result.message;
          isLoading = false;
        });

        // Try loading from local storage if API fails
        final localResult = await NotificationController.load();
        if (localResult.isSuccess && localResult.results != null) {
          setState(() {
            notifications = localResult.results!;
            errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load notifications: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      currentPage++;
      final result = await NotificationController.getAll(perPage: perPage);

      if (result.isSuccess && result.results != null && result.results!.isNotEmpty) {
        setState(() {
          notifications.addAll(result.results!);
        });
      }
    } catch (e) {
      currentPage--; // Revert page increment on error
    } finally {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final result = await NotificationController.markAllAsRead();

      if (result.isSuccess) {
        setState(() {
          for (var notification in notifications) {
            notification.markAsRead();
          }
        });

        _showSnackBar('All notifications marked as read');
      } else {
        _showSnackBar(result.message ?? 'Failed to mark all as read');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  Future<void> _deleteAllRead() async {
    final shouldDelete = await _showConfirmDialog(
      'Remove All Read',
      'Are you sure you want to remove all read notifications? This action cannot be undone.',
    );

    if (shouldDelete == true) {
      try {
        final result = await NotificationController.deleteAllRead();

        if (result.isSuccess) {
          setState(() {
            notifications.removeWhere((notification) => notification.isRead);
          });

          _showSnackBar('${result.results} read notifications removed');
        } else {
          _showSnackBar(result.message ?? 'Failed to remove read notifications');
        }
      } catch (e) {
        _showSnackBar('Error: $e');
      }
    }
  }

  Future<void> _deleteAll() async {
    final shouldDelete = await _showConfirmDialog(
      'Remove All',
      'Are you sure you want to remove all notifications? This action cannot be undone.',
    );

    if (shouldDelete == true) {
      try {
        final result = await NotificationController.deleteAll();

        if (result.isSuccess) {
          setState(() {
            notifications.clear();
          });

          _showSnackBar('${result.results} notifications removed');
        } else {
          _showSnackBar(result.message ?? 'Failed to remove all notifications');
        }
      } catch (e) {
        _showSnackBar('Error: $e');
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final result = await NotificationController.markAsRead(notification.uuid);

      if (result.isSuccess) {
        setState(() {
          final index = notifications.indexWhere((n) => n.uuid == notification.uuid);
          if (index != -1) {
            notifications[index] = result.results!;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to mark as read: $e');
    }
  }

  Future<void> _deleteNotification(NotificationModel notification) async {
    final shouldDelete = await _showConfirmDialog(
      'Remove Notification',
      'Are you sure you want to remove this notification?',
    );

    if (shouldDelete == true) {
      try {
        final result = await NotificationController.delete(notification.uuid);

        if (result.isSuccess) {
          setState(() {
            notifications.removeWhere((n) => n.uuid == notification.uuid);
          });

          _showSnackBar('Notification removed');
        } else {
          _showSnackBar(result.message ?? 'Failed to remove notification');
        }
      } catch (e) {
        _showSnackBar('Error: $e');
      }
    }
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remove', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMenuOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Mark all read'),
                onTap: () {
                  Navigator.pop(context);
                  _markAllAsRead();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove all read'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAllRead();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Remove all', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteAll();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () => _showMenuOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Menu options bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _markAllAsRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: _deleteAllRead,
                  child: const Text(
                    'Remove all read',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadNotifications(refresh: true),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null && notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadNotifications(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(0),
      itemCount: notifications.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final notification = notifications[index];
        return NotificationItem(
          notification: notification,
          onTap: () => _markAsRead(notification),
          onDelete: () => _deleteNotification(notification),
          time: _formatTime(notification.createdAt),
        );
      },
    );
  }
}

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final String time;

  const NotificationItem({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDelete,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.uuid),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        onDelete?.call();
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFF8F9FA),
            border: const Border(
              bottom: BorderSide(color: Color(0xFFE5E5E5), width: 0.5),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon/indicator
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6, right: 12),
                decoration: BoxDecoration(
                  color: notification.isRead ? Colors.transparent : Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notification.type != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTypeColor(notification.type!).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notification.type!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              color: _getTypeColor(notification.type!),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Time and priority indicator
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (time.isNotEmpty)
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  if (notification.priority == 'high' || notification.priority == 'urgent')
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.priority_high,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'budget':
        return Colors.orange;
      case 'payment':
        return Colors.green;
      case 'alert':
        return Colors.red;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}