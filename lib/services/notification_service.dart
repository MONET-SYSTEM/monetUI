import 'package:hive/hive.dart';
import 'package:monet/models/notification.dart';

class NotificationService {
  // Save notifications to Hive
  static Future<List<NotificationModel>> saveNotifications(List<dynamic> notifications) async {
    final notificationBox = await Hive.openBox(NotificationModel.notificationBox);
    List<NotificationModel> notificationModels = [];

    for (var notification in notifications) {
      var model = NotificationModel.fromMap(notification);
      await notificationBox.put(model.id, model);
      notificationModels.add(model);
    }

    return notificationModels;
  }

  // Get all notifications from local storage
  static Future<List<NotificationModel>> getLocalNotifications() async {
    final notificationBox = await Hive.openBox(NotificationModel.notificationBox);
    List<NotificationModel> notifications = [];

    for (var key in notificationBox.keys) {
      notifications.add(notificationBox.get(key));
    }

    return notifications;
  }

  // Get unread notifications from local storage
  static Future<List<NotificationModel>> getUnreadNotifications() async {
    final notifications = await getLocalNotifications();
    return notifications.where((n) => !n.isRead).toList();
  }

  // Get unread count from local storage
  static Future<int> getUnreadCount() async {
    final notifications = await getLocalNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  // Mark notification as read in local storage
  static Future<NotificationModel> markAsRead(String notificationId) async {
    final notificationBox = await Hive.openBox(NotificationModel.notificationBox);
    NotificationModel notification = notificationBox.get(notificationId);

    notification.isRead = true;
    notification.readAt = DateTime.now().toIso8601String();
    await notificationBox.put(notificationId, notification);

    return notification;
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final notificationBox = await Hive.openBox(NotificationModel.notificationBox);

    for (var key in notificationBox.keys) {
      NotificationModel notification = notificationBox.get(key);
      if (!notification.isRead) {
        notification.isRead = true;
        notification.readAt = DateTime.now().toIso8601String();
        await notificationBox.put(key, notification);
      }
    }
  }

  // Delete a notification
  static Future<void> deleteNotification(String notificationId) async {
    final notificationBox = await Hive.openBox(NotificationModel.notificationBox);
    await notificationBox.delete(notificationId);
  }

  // Clear all notifications
  static Future<void> clearNotifications() async {
    final notificationBox = await Hive.openBox(NotificationModel.notificationBox);
    await notificationBox.clear();
  }

  // Get a notification by ID
  static Future<NotificationModel?> getNotification(String notificationId) async {
    final notificationBox = await Hive.openBox(NotificationModel.notificationBox);
    return notificationBox.get(notificationId);
  }
}