import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:monet/controller/notification.dart';
import 'package:monet/models/notification.dart';
import 'package:monet/models/result.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static NotificationService get instance => _instance;

  // State management
  final ValueNotifier<List<NotificationModel>> notifications = ValueNotifier<List<NotificationModel>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  // Initialize service
  Future<void> init() async {
    try {
      // Initialize local notifications
      const AndroidInitializationSettings initAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(android: initAndroid, iOS: initIOS);

      await localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      // Load from local storage first
      await loadFromStorage();

      // Then refresh from API
      await refreshNotifications();
    } catch (e) {
      error.value = 'Error initializing notification service: ${e.toString()}';
    }
  }

  // Load notifications from local storage
  Future<void> loadFromStorage() async {
    isLoading.value = true;
    try {
      final Result<List<NotificationModel>> result = await NotificationController.load();
      if (result.isSuccess && result.results != null) {
        notifications.value = result.results!;
        _updateUnreadCount();
      }
    } catch (e) {
      error.value = 'Error loading notifications from storage: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Refresh notifications from API
  Future<void> refreshNotifications({
    bool? isRead,
    String? type,
    String? priority,
    bool? recent,
    bool? today,
  }) async {
    isLoading.value = true;
    error.value = null;

    try {
      final Result<List<NotificationModel>> result = await NotificationController.getAll(
        isRead: isRead,
        type: type,
        priority: priority,
        recent: recent,
        today: today,
      );

      if (result.isSuccess && result.results != null) {
        notifications.value = result.results!;
        _updateUnreadCount();
      } else {
        error.value = result.message;
      }
    } catch (e) {
      error.value = 'Error refreshing notifications: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }

  // Get a single notification
  Future<NotificationModel?> getNotification(String uuid) async {
    try {
      final Result<NotificationModel> result = await NotificationController.get(uuid);
      if (result.isSuccess && result.results != null) {
        return result.results;
      } else {
        error.value = result.message;
        return null;
      }
    } catch (e) {
      error.value = 'Error getting notification: ${e.toString()}';
      return null;
    }
  }

  Future<NotificationModel?> createNotification({
    required String title,
    required String message,
    String? type,
    Map<String, dynamic>? data,
    String? priority,
    String? channel,
    String? actionUrl,
    String? icon,
    DateTime? scheduledAt,
  }) async {
    try {
      final Result<NotificationModel> result = await NotificationController.create(
        title: title,
        message: message,
        type: type,
        data: data,
        priority: priority,
        channel: channel,
        actionUrl: actionUrl,
        icon: icon,
        scheduledAt: scheduledAt,
      );

      if (result.isSuccess && result.results != null) {
        await refreshNotifications();
        return result.results;
      } else {
        error.value = result.message;
        return null;
      }
    } catch (e) {
      error.value = 'Error creating notification: ${e.toString()}';
      return null;
    }
  }

  Future<bool> markAsRead(String uuid) async {
    try {
      final Result<NotificationModel> result = await NotificationController.markAsRead(uuid);
      if (result.isSuccess && result.results != null) {
        // Update the notification in the list
        final updatedList = List<NotificationModel>.from(notifications.value);
        final index = updatedList.indexWhere((n) => n.uuid == uuid);
        if (index != -1) {
          updatedList[index] = result.results!;
          notifications.value = updatedList;
          _updateUnreadCount();
        }
        return true;
      } else {
        error.value = result.message;
        return false;
      }
    } catch (e) {
      error.value = 'Error marking notification as read: ${e.toString()}';
      return false;
    }
  }

  // Mark notification as unread
  Future<bool> markAsUnread(String uuid) async {
    try {
      final Result<NotificationModel> result = await NotificationController.markAsUnread(uuid);
      if (result.isSuccess && result.results != null) {
        // Update the notification in the list
        final updatedList = List<NotificationModel>.from(notifications.value);
        final index = updatedList.indexWhere((n) => n.uuid == uuid);
        if (index != -1) {
          updatedList[index] = result.results!;
          notifications.value = updatedList;
          _updateUnreadCount();
        }
        return true;
      } else {
        error.value = result.message;
        return false;
      }
    } catch (e) {
      error.value = 'Error marking notification as unread: ${e.toString()}';
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final Result<int> result = await NotificationController.markAllAsRead();
      if (result.isSuccess) {
        await refreshNotifications();
        return true;
      } else {
        error.value = result.message;
        return false;
      }
    } catch (e) {
      error.value = 'Error marking all notifications as read: ${e.toString()}';
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String uuid) async {
    try {
      final Result<void> result = await NotificationController.delete(uuid);
      if (result.isSuccess) {
        // Remove from the list
        final updatedList = List<NotificationModel>.from(notifications.value);
        updatedList.removeWhere((n) => n.uuid == uuid);
        notifications.value = updatedList;
        _updateUnreadCount();
        return true;
      } else {
        error.value = result.message;
        return false;
      }
    } catch (e) {
      error.value = 'Error deleting notification: ${e.toString()}';
      return false;
    }
  }

  // Delete all read notifications
  Future<bool> deleteAllRead() async {
    try {
      final Result<int> result = await NotificationController.deleteAllRead();
      if (result.isSuccess) {
        await refreshNotifications();
        return true;
      } else {
        error.value = result.message;
        return false;
      }
    } catch (e) {
      error.value = 'Error deleting read notifications: ${e.toString()}';
      return false;
    }
  }

  // Delete all notifications
  Future<bool> deleteAll() async {
    try {
      final Result<int> result = await NotificationController.deleteAll();
      if (result.isSuccess) {
        notifications.value = [];
        unreadCount.value = 0;
        return true;
      } else {
        error.value = result.message;
        return false;
      }
    } catch (e) {
      error.value = 'Error deleting all notifications: ${e.toString()}';
      return false;
    }
  }

  // Bulk delete notifications
  Future<bool> bulkDelete(List<String> uuids) async {
    try {
      final Result<int> result = await NotificationController.bulkDelete(uuids) as Result<int>;
      if (result.isSuccess) {
        await refreshNotifications();
        return true;
      } else {
        error.value = result.message;
        return false;
      }
    } catch (e) {
      error.value = 'Error bulk deleting notifications: ${e.toString()}';
      return false;
    }
  }

  // Get filtered notifications
  List<NotificationModel> getFilteredNotifications({
    bool? isRead,
    String? type,
    String? priority,
    bool? today,
    bool? recent,
  }) {
    return notifications.value.where((notification) {
      if (isRead != null && notification.isRead != isRead) return false;
      if (type != null && notification.type != type) return false;
      if (priority != null && notification.priority != priority) return false;

      if (today == true) {
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        if (notification.createdAt.isBefore(todayStart)) return false;
      }

      if (recent == true) {
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        if (notification.createdAt.isBefore(thirtyDaysAgo)) return false;
      }

      return true;
    }).toList();
  }

  // Show a system notification
  Future<void> showSystemNotification(NotificationModel notification) async {
    try {
      // Set up notification details
      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        notification.type, // channel ID
        notification.type.toUpperCase(), // channel name
        channelDescription: 'Channel for ${notification.type} notifications',
        importance: notification.isHighPriority()
            ? Importance.high
            : Importance.defaultImportance,
        priority: notification.isHighPriority()
            ? Priority.high
            : Priority.defaultPriority,
        icon: notification.icon ?? 'app_icon',
      );

      DarwinNotificationDetails iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await localNotifications.show(
        notification.uuid.hashCode, // ID
        notification.title,
        notification.message,
        platformDetails,
        payload: notification.uuid, // Store UUID as payload for tap handling
      );
    } catch (e) {
      error.value = 'Error showing system notification: ${e.toString()}';
    }
  }

  // Handle notification tap
  void _handleNotificationTap(NotificationResponse response) async {
    if (response.payload != null) {
      final uuid = response.payload!;
      // Mark as read when tapped
      await markAsRead(uuid);

      // You can handle navigation here or use a callback
      // For example, navigate to notification details page
    }
  }

  // Update unread count
  void _updateUnreadCount() {
    final count = notifications.value.where((n) => !n.isRead).length;
    unreadCount.value = count;
  }

  // Budget notification methods
  Future<void> showBudgetThresholdAlert({
    required String budgetId,
    required String budgetName,
    required String categoryName,
    required double amount,
    required double spentAmount,
    required double spentPercentage,
    required String currencySymbol,
  }) async {
    final title = 'Budget Alert: $budgetName';
    final message = 'You have spent $currencySymbol$spentAmount (${spentPercentage.toStringAsFixed(1)}%) of your $currencySymbol$amount budget for $categoryName.';

    final notification = NotificationModel(
      uuid: 'budget-threshold-$budgetId-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: 'budget',
      priority: 'high',
      createdAt: DateTime.now(),
      isRead: false,
      data: {
        'budgetId': budgetId,
        'type': 'threshold',
      },
      actionUrl: '/budget/$budgetId',
      icon: 'budget',
    );

    await createNotification(
      title: title,
      message: message,
      type: 'budget',
      priority: 'high',
      data: notification.data,
      actionUrl: notification.actionUrl,
      icon: notification.icon,
    );

    await showSystemNotification(notification);
  }

  Future<void> showBudgetOverrunAlert({
    required String budgetId,
    required String budgetName,
    required String categoryName,
    required double amount,
    required double spentAmount,
    required String currencySymbol,
  }) async {
    final title = 'Budget Exceeded: $budgetName';
    final message = 'You have spent $currencySymbol$spentAmount, exceeding your $currencySymbol$amount budget for $categoryName.';

    final notification = NotificationModel(
      uuid: 'budget-overrun-$budgetId-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: 'budget',
      priority: 'high',
      createdAt: DateTime.now(),
      isRead: false,
      data: {
        'budgetId': budgetId,
        'type': 'overrun',
      },
      actionUrl: '/budget/$budgetId',
      icon: 'budget',
    );

    await createNotification(
      title: title,
      message: message,
      type: 'budget',
      priority: 'high',
      data: notification.data,
      actionUrl: notification.actionUrl,
      icon: notification.icon,
    );

    await showSystemNotification(notification);
  }

  Future<void> scheduleBudgetAlert({
    required String budgetId,
    required String budgetName,
    required String categoryName,
    required double amount,
    required double threshold,
    required String currencySymbol,
  }) async {
    // For now, just create a record that an alert is scheduled.
    // In a real implementation, you would schedule the alert based on spending patterns
    final title = 'Budget Alert Scheduled';
    final message = 'You will be notified when spending on $budgetName reaches ${threshold.toStringAsFixed(0)}% of $currencySymbol$amount';

    await createNotification(
      title: title,
      message: message,
      type: 'budget',
      priority: 'normal',
      data: {
        'budgetId': budgetId,
        'type': 'scheduled',
        'threshold': threshold,
      },
      actionUrl: '/budget/$budgetId',
      icon: 'budget',
    );
  }

  Future<void> cancelBudgetAlerts(String budgetId) async {
    // In a more complete implementation, you would cancel scheduled notifications here
    // For now, just creating a record that alerts were cancelled
    print('Budget alerts cancelled for budget: $budgetId');
  }

  // Dispose resources
  void dispose() {
    notifications.dispose();
    isLoading.dispose();
    error.dispose();
    unreadCount.dispose();
  }
}
