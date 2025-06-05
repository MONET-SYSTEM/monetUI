import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/models/notification.dart';
import 'package:monet/models/result.dart';

class NotificationController {
  // Get all notifications with optional filters
  static Future<Result<List<NotificationModel>>> getAll({
    bool? isRead,
    String? type,
    String? priority,
    bool? recent,
    bool? today,
    int perPage = 15,
  }) async {
    try {
      final token = await _getToken();

      final Map<String, String> queryParams = {'per_page': perPage.toString()};
      if (isRead != null) queryParams['is_read'] = isRead.toString();
      if (type != null) queryParams['type'] = type;
      if (priority != null) queryParams['priority'] = priority;
      if (recent != null) queryParams['recent'] = recent.toString();
      if (today != null) queryParams['today'] = today.toString();

      final uri = Uri.parse(ApiRoutes.notifications).replace(
          queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final notificationsData = responseBody['data'] ?? [];
        final List<NotificationModel> notifications = [];

        for (var notificationData in notificationsData) {
          notifications.add(NotificationModel.fromMap(notificationData));
        }

        // Sync with local storage
        await _syncWithLocalStorage(notifications);

        return Result(
          isSuccess: true,
          results: notifications,
          message: 'Notifications retrieved successfully',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to retrieve notifications',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error fetching notifications: ${e.toString()}',
      );
    }
  }

  // Get a specific notification by UUID
  static Future<Result<NotificationModel>> get(String uuid) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse(ApiRoutes.notificationDetail(uuid)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final notification = NotificationModel.fromMap(responseBody['data']);

        // Update in local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        await notificationBox.put(notification.uuid, notification);

        return Result(
          isSuccess: true,
          results: notification,
          message: 'Notification retrieved successfully',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ?? 'Failed to retrieve notification',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error fetching notification: ${e.toString()}',
      );
    }
  }

  // Create a new notification
  static Future<Result<NotificationModel>> create({
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
      final token = await _getToken();

      final Map<String, dynamic> requestData = {
        'title': title,
        'message': message,
      };

      if (type != null) requestData['type'] = type;
      if (data != null) requestData['data'] = data;
      if (priority != null) requestData['priority'] = priority;
      if (channel != null) requestData['channel'] = channel;
      if (actionUrl != null) requestData['action_url'] = actionUrl;
      if (icon != null) requestData['icon'] = icon;
      if (scheduledAt != null)
        requestData['scheduled_at'] = scheduledAt.toIso8601String();

      final response = await http.post(
        Uri.parse(ApiRoutes.notifications),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final notification = NotificationModel.fromMap(responseBody['data']);

        // Save to local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        await notificationBox.put(notification.uuid, notification);

        return Result(
          isSuccess: true,
          results: notification,
          message: 'Notification created successfully',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ?? 'Failed to create notification',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error creating notification: ${e.toString()}',
      );
    }
  }

  // Update an existing notification
  static Future<Result<NotificationModel>> update(String uuid, {
    String? title,
    String? message,
    String? type,
    Map<String, dynamic>? data,
    String? priority,
    String? channel,
    String? actionUrl,
    String? icon,
    DateTime? scheduledAt,
  }) async {
    try {
      final token = await _getToken();

      final Map<String, dynamic> requestData = {};

      if (title != null) requestData['title'] = title;
      if (message != null) requestData['message'] = message;
      if (type != null) requestData['type'] = type;
      if (data != null) requestData['data'] = data;
      if (priority != null) requestData['priority'] = priority;
      if (channel != null) requestData['channel'] = channel;
      if (actionUrl != null) requestData['action_url'] = actionUrl;
      if (icon != null) requestData['icon'] = icon;
      if (scheduledAt != null)
        requestData['scheduled_at'] = scheduledAt.toIso8601String();

      final response = await http.put(
        Uri.parse(ApiRoutes.notificationDetail(uuid)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final notification = NotificationModel.fromMap(responseBody['data']);

        // Update in local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        await notificationBox.put(notification.uuid, notification);

        return Result(
          isSuccess: true,
          results: notification,
          message: 'Notification updated successfully',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ?? 'Failed to update notification',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error updating notification: ${e.toString()}',
      );
    }
  }

  // Mark a notification as read
  static Future<Result<NotificationModel>> markAsRead(String uuid) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse(ApiRoutes.notificationMarkRead(uuid)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final notification = NotificationModel.fromMap(responseBody['data']);

        // Update in local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        await notificationBox.put(notification.uuid, notification);

        return Result(
          isSuccess: true,
          results: notification,
          message: 'Notification marked as read',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to mark notification as read',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error marking notification as read: ${e.toString()}',
      );
    }
  }

  // Mark a notification as unread
  static Future<Result<NotificationModel>> markAsUnread(String uuid) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse(ApiRoutes.notificationMarkUnread(uuid)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final notification = NotificationModel.fromMap(responseBody['data']);

        // Update in local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        await notificationBox.put(notification.uuid, notification);

        return Result(
          isSuccess: true,
          results: notification,
          message: 'Notification marked as unread',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to mark notification as unread',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error marking notification as unread: ${e.toString()}',
      );
    }
  }

  // Mark all notifications as read
  static Future<Result<int>> markAllAsRead() async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse(ApiRoutes.notificationsMarkAllRead),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update all notifications in local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        for (var notification in notificationBox.values) {
          if (!notification.isRead) {
            notification.markAsRead();
            await notificationBox.put(notification.uuid, notification);
          }
        }

        return Result(
          isSuccess: true,
          results: responseBody['count'],
          message: responseBody['message'] ??
              'All notifications marked as read',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to mark all notifications as read',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error marking all notifications as read: ${e.toString()}',
      );
    }
  }

  // Delete a notification
  static Future<Result<void>> delete(String uuid) async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse(ApiRoutes.notificationDetail(uuid)),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Remove from local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        await notificationBox.delete(uuid);

        return Result(
          isSuccess: true,
          message: responseBody['message'] ??
              'Notification deleted successfully',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ?? 'Failed to delete notification',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error deleting notification: ${e.toString()}',
      );
    }
  }

  // Delete all read notifications
  static Future<Result<int>> deleteAllRead() async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse(ApiRoutes.notificationsRead),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Remove read notifications from local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        final readNotifications = notificationBox.values
            .where((n) => n.isRead)
            .toList();
        for (var notification in readNotifications) {
          await notificationBox.delete(notification.uuid);
        }

        return Result(
          isSuccess: true,
          results: responseBody['count'],
          message: responseBody['message'] ?? 'All read notifications deleted',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to delete read notifications',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error deleting read notifications: ${e.toString()}',
      );
    }
  }

  // Delete all notifications
  static Future<Result<int>> deleteAll() async {
    try {
      final token = await _getToken();

      final response = await http.delete(
        Uri.parse(ApiRoutes.notificationsAll),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Clear local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        await notificationBox.clear();

        return Result(
          isSuccess: true,
          results: responseBody['count'],
          message: responseBody['message'] ?? 'All notifications deleted',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to delete all notifications',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error deleting all notifications: ${e.toString()}',
      );
    }
  }


  // Get latest unread notifications
  static Future<Result<List<NotificationModel>>> getLatestUnread(
      {int limit = 5}) async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('${ApiRoutes.notificationsLatestUnread}?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final notificationsData = responseBody['data'] ?? [];
        final List<NotificationModel> notifications = [];

        for (var notificationData in notificationsData) {
          notifications.add(NotificationModel.fromMap(notificationData));
        }

        return Result(
          isSuccess: true,
          results: notifications,
          message: 'Latest unread notifications retrieved successfully',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to retrieve latest unread notifications',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error fetching latest unread notifications: ${e.toString()}',
      );
    }
  }

  // Get notifications by type
  static Future<Result<List<NotificationModel>>> getByType(String type,
      {bool? isRead, int perPage = 15}) async {
    try {
      final token = await _getToken();

      final Map<String, String> queryParams = {'per_page': perPage.toString()};
      if (isRead != null) queryParams['is_read'] = isRead.toString();

      final uri = Uri.parse(ApiRoutes.notificationsByTypeFilter(type)).replace(
          queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final notificationsData = responseBody['data'] ?? [];
        final List<NotificationModel> notifications = [];

        for (var notificationData in notificationsData) {
          notifications.add(NotificationModel.fromMap(notificationData));
        }

        return Result(
          isSuccess: true,
          results: notifications,
          message: 'Notifications of type $type retrieved successfully',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to retrieve notifications of type $type',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error fetching notifications of type $type: ${e.toString()}',
      );
    }
  }

  // Get urgent notifications
  static Future<Result<List<NotificationModel>>> getUrgent() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse(ApiRoutes.notificationsUrgent),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final notificationsData = responseBody['data'] ?? [];
        final List<NotificationModel> notifications = [];

        for (var notificationData in notificationsData) {
          notifications.add(NotificationModel.fromMap(notificationData));
        }

        return Result(
          isSuccess: true,
          results: notifications,
          message: 'Urgent notifications retrieved successfully',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to retrieve urgent notifications',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error fetching urgent notifications: ${e.toString()}',
      );
    }
  }

  // Bulk mark notifications as read
  static Future<Result<int>> bulkMarkAsRead(
      List<String> notificationUuids) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse(ApiRoutes.notificationsBulkMarkRead),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'notification_uuids': notificationUuids,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Update notifications in local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        for (var uuid in notificationUuids) {
          final notification = notificationBox.get(uuid);
          if (notification != null && !notification.isRead) {
            notification.markAsRead();
            await notificationBox.put(uuid, notification);
          }
        }

        return Result(
          isSuccess: true,
          results: responseBody['count'],
          message: responseBody['message'] ?? 'Notifications marked as read',
        );
      } else {
        return Result(
          isSuccess: false,
          message: responseBody['message'] ??
              'Failed to mark notifications as read',
        );
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error marking notifications as read: ${e.toString()}',
      );
    }
  }

  // Bulk delete notifications
  static Future<Result> bulkDelete(List<String> notificationUuids) async {
    try {
      final token = await _getToken();

      final response = await http.post(
        Uri.parse(ApiRoutes.notificationsBulkDelete),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'notification_uuids': notificationUuids,
        }),
      );

      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Remove notifications from local storage
        final notificationBox = await Hive.openBox<NotificationModel>(
            NotificationModel.notificationBox);
        for (var uuid in notificationUuids) {
          await notificationBox.delete(uuid);
        }

        return Result(
          isSuccess: true,
          results: responseBody['count'],
          message: responseBody['message'] ??
              'Notifications deleted successfully',
        );
      } else {
        var result = Result(
          isSuccess: false,
          message: responseBody['message'] ?? 'Failed to delete notifications',
        );
        return result;
      }
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error deleting notifications: ${e.toString()}',
      );
    }
  }

  // Load notifications from local storage
  static Future<Result<List<NotificationModel>>> load() async {
    try {
      final notificationBox = await Hive.openBox<NotificationModel>(
          NotificationModel.notificationBox);
      final notifications = notificationBox.values.toList();

      return Result(
        isSuccess: true,
        results: notifications,
        message: 'Notifications loaded from local storage',
      );
    } catch (e) {
      return Result(
        isSuccess: false,
        message: 'Error loading notifications from local storage: ${e
            .toString()}',
      );
    }
  }

  // Helper method to get user token
  static Future<String> _getToken() async {
    final box = await Hive.openBox('user');
    return box.get('token') ?? '';
  }

  // Helper method to sync notifications with local storage
  static Future<void> _syncWithLocalStorage(
      List<NotificationModel> notifications) async {
    final notificationBox = await Hive.openBox<NotificationModel>(
        NotificationModel.notificationBox);

    // Clear existing notifications if this is a full refresh
    if (notifications.length > 5) {
      await notificationBox.clear();
    }

    // Add all notifications to box using UUID as key
    for (var notification in notifications) {
      await notificationBox.put(notification.uuid, notification);
    }
  }
}