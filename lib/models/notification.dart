import 'dart:convert';
import 'package:hive/hive.dart';

part 'notification.g.dart';

@HiveType(typeId: 10)
class NotificationModel {
  @HiveField(0)
  late String uuid;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String message;

  @HiveField(3)
  late String type;

  @HiveField(4)
  late String priority;

  @HiveField(5)
  late String channel;

  @HiveField(6)
  String? icon;

  @HiveField(7)
  String? actionUrl;

  @HiveField(8)
  Map<String, dynamic>? data;

  @HiveField(9)
  late bool isRead;

  @HiveField(10)
  late DateTime createdAt;

  @HiveField(11)
  DateTime? readAt;

  static String notificationBox = 'notifications';

  NotificationModel({
    String? uuid,
    String? title,
    String? message,
    String? type,
    String? priority,
    String? channel,
    this.icon,
    this.actionUrl,
    this.data,
    bool? isRead,
    DateTime? createdAt,
    this.readAt,
  }) {
    this.uuid = uuid ?? '';
    this.title = title ?? '';
    this.message = message ?? '';
    this.type = type ?? 'general';
    this.priority = priority ?? 'medium';
    this.channel = channel ?? 'app';
    this.isRead = isRead ?? false;
    this.createdAt = createdAt ?? DateTime.now();
  }

  static NotificationModel fromMap(Map<String, dynamic> notification) {
    // Parse the data field if it's a string
    Map<String, dynamic>? parsedData;
    if (notification['data'] is String) {
      try {
        parsedData = jsonDecode(notification['data']);
      } catch (e) {
        parsedData = null;
      }
    } else if (notification['data'] is Map) {
      parsedData = Map<String, dynamic>.from(notification['data']);
    }

    return NotificationModel(
      uuid: notification['uuid'] ?? notification['id']?.toString(),
      title: notification['title'],
      message: notification['message'],
      type: notification['type'],
      priority: notification['priority'],
      channel: notification['channel'],
      icon: notification['icon'],
      actionUrl: notification['action_url'],
      data: parsedData,
      isRead: notification['is_read'] is bool
          ? notification['is_read']
          : notification['is_read'] == 1,
      createdAt: notification['created_at'] != null
          ? DateTime.parse(notification['created_at'])
          : DateTime.now(),
      readAt: notification['read_at'] != null
          ? DateTime.parse(notification['read_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'channel': channel,
      'icon': icon,
      'action_url': actionUrl,
      'data': data != null ? jsonEncode(data) : null,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  void markAsRead() {
    if (!isRead) {
      isRead = true;
      readAt = DateTime.now();
    }
  }

  bool isHighPriority() {
    return priority.toLowerCase() == 'high';
  }

  bool hasAction() {
    return actionUrl != null && actionUrl!.isNotEmpty;
  }

  bool isEqual(NotificationModel other) {
    return uuid == other.uuid;
  }

  @override
  String toString() {
    return 'Notification: $title';
  }
}