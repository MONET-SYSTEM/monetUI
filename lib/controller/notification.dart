import 'package:dio/dio.dart';
import 'package:monet/models/notification.dart';
import 'package:monet/models/result.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/services/notification_service.dart';

class NotificationController {
  // Fetch all notifications
  static Future<Result<List<NotificationModel>>> getNotifications() async {
    try {
      final response = await ApiService.get(ApiRoutes.notificationUrl, {});

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        final notifications = await NotificationService.saveNotifications(data);

        return Result(
          isSuccess: true,
          message: 'Notifications retrieved successfully',
          results: notifications,
        );
      } else {
        return Result(
          isSuccess: false,
          message: 'Failed to retrieve notifications',
        );
      }
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      // Try to get local notifications if API call fails
      try {
        final localNotifications = await NotificationService.getLocalNotifications();
        return Result(
          isSuccess: true,
          message: 'Using cached notifications',
          results: localNotifications,
        );
      } catch (_) {
        return Result(isSuccess: false, message: message, errors: errors);
      }
    } catch (e) {
      print(e);
      return Result(
        isSuccess: false,
        message: AppStrings.anErrorOccurredTryAgain,
      );
    }
  }

  // Get unread notification count
  static Future<Result<int>> getUnreadCount() async {
    try {
      final response = await ApiService.get(
        '${ApiRoutes.notificationUrl}/unread-count',
        {},
      );

      if (response.statusCode == 200) {
        final count = response.data['count'] as int;
        return Result(
          isSuccess: true,
          message: 'Unread count retrieved successfully',
          results: count,
        );
      } else {
        return Result(
          isSuccess: false,
          message: 'Failed to retrieve unread count',
        );
      }
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      // Try to calculate local unread count if API call fails
      try {
        final notifications = await NotificationService.getLocalNotifications();
        final unreadCount = notifications.where((n) => !n.isRead).length;
        return Result(
          isSuccess: true,
          message: 'Using calculated unread count',
          results: unreadCount,
        );
      } catch (_) {
        return Result(isSuccess: false, message: message, errors: errors);
      }
    } catch (e) {
      print(e);
      return Result(
        isSuccess: false,
        message: AppStrings.anErrorOccurredTryAgain,
      );
    }
  }

  // Mark a notification as read
  static Future<Result<NotificationModel>> markAsRead(String notificationId) async {
    try {
      final response = await ApiService.put(
        '${ApiRoutes.notificationUrl}/$notificationId/read',
        {'is_read': true},
      );

      if (response.statusCode == 200) {
        // Update local notification
        final notification = await NotificationService.markAsRead(notificationId);
        return Result(
          isSuccess: true,
          message: 'Notification marked as read',
          results: notification,
        );
      } else {
        return Result(
          isSuccess: false,
          message: 'Failed to mark notification as read',
        );
      }
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      // Try to update locally even if API call fails
      try {
        final notification = await NotificationService.markAsRead(notificationId);
        return Result(
          isSuccess: true,
          message: 'Notification marked as read locally',
          results: notification,
        );
      } catch (_) {
        return Result(isSuccess: false, message: message, errors: errors);
      }
    } catch (e) {
      print(e);
      return Result(
        isSuccess: false,
        message: AppStrings.anErrorOccurredTryAgain,
      );
    }
  }

  // Mark all notifications as read
  static Future<Result<bool>> markAllAsRead() async {
    try {
      final response = await ApiService.put(
        '${ApiRoutes.notificationUrl}/mark-all-read',
        {},
      );

      if (response.statusCode == 200) {
        // Update all local notifications
        await NotificationService.markAllAsRead();
        return Result(
          isSuccess: true,
          message: 'All notifications marked as read',
          results: true,
        );
      } else {
        return Result(
          isSuccess: false,
          message: 'Failed to mark all notifications as read',
        );
      }
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      // Try to update locally even if API call fails
      try {
        await NotificationService.markAllAsRead();
        return Result(
          isSuccess: true,
          message: 'All notifications marked as read locally',
          results: true,
        );
      } catch (_) {
        return Result(isSuccess: false, message: message, errors: errors);
      }
    } catch (e) {
      print(e);
      return Result(
        isSuccess: false,
        message: AppStrings.anErrorOccurredTryAgain,
      );
    }
  }

  // Delete a notification
  static Future<Result<bool>> deleteNotification(String notificationId) async {
    try {
      final response = await ApiService.delete(
        '${ApiRoutes.notificationUrl}/$notificationId',
      );

      if (response.statusCode == 200) {
        // Delete from local storage
        await NotificationService.deleteNotification(notificationId);
        return Result(
          isSuccess: true,
          message: 'Notification deleted successfully',
          results: true,
        );
      } else {
        return Result(
          isSuccess: false,
          message: 'Failed to delete notification',
        );
      }
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      // Try to delete locally even if API call fails
      try {
        await NotificationService.deleteNotification(notificationId);
        return Result(
          isSuccess: true,
          message: 'Notification deleted locally',
          results: true,
        );
      } catch (_) {
        return Result(isSuccess: false, message: message, errors: errors);
      }
    } catch (e) {
      print(e);
      return Result(
        isSuccess: false,
        message: AppStrings.anErrorOccurredTryAgain,
      );
    }
  }

  // Delete all notifications
  static Future<Result<bool>> deleteAllNotifications() async {
    try {
      // Use the correct endpoint for delete all notifications
      final response = await ApiService.delete('${ApiRoutes.notificationUrl}/delete-all');
      if (response.statusCode == 200) {
        await NotificationService.clearNotifications();
        return Result(
          isSuccess: true,
          message: 'All notifications deleted',
          results: true,
        );
      }
      // Always clear local notifications if API call fails
      await NotificationService.clearNotifications();
      return Result(
        isSuccess: true,
        message: 'All notifications deleted locally',
        results: true,
      );
    } catch (e) {
      print(e);
      return Result(
        isSuccess: false,
        message: AppStrings.anErrorOccurredTryAgain,
      );
    }
  }
}