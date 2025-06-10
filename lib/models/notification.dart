import 'package:hive/hive.dart';

part 'notification.g.dart';

@HiveType(typeId: 9)
class NotificationModel {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String type;

  @HiveField(2)
  late String title;

  @HiveField(3)
  late String message;

  @HiveField(4)
  late dynamic data;

  @HiveField(5)
  late bool isRead;

  @HiveField(6)
  String? readAt;

  static String notificationBox = 'notifications';

  static NotificationModel fromMap(Map<String, dynamic> notification) {
    var notificationModel = NotificationModel();
    notificationModel.id = notification['id'];
    notificationModel.type = notification['type'];
    notificationModel.title = notification['title'];
    notificationModel.message = notification['message'];
    notificationModel.data = notification['data'];
    notificationModel.isRead = notification['is_read'] ?? false;
    notificationModel.readAt = notification['read_at'];

    return notificationModel;
  }

  bool isEqual(NotificationModel model) {
    return id == model.id;
  }

  @override
  String toString() => title;
}