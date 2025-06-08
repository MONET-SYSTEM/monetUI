import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 16) // Adjust typeId based on your existing models
class BudgetModel extends HiveObject {
  @HiveField(0)
  String id = '';

  @HiveField(1)
  String name = '';

  @HiveField(2)
  String? description;

  @HiveField(3)
  double amount = 0.0;

  @HiveField(4)
  String? categoryId;

  @HiveField(5)
  String period = 'monthly'; // daily, weekly, monthly, quarterly, yearly

  @HiveField(6)
  String startDate = '';

  @HiveField(7)
  String endDate = '';

  @HiveField(8)
  bool sendNotifications = false;

  @HiveField(9)
  int notificationThreshold = 80;

  @HiveField(10)
  String color = '#90CAF9';

  @HiveField(11)
  String status = 'active'; // active, inactive, completed, exceeded

  @HiveField(12)
  double spent = 0.0;

  @HiveField(13)
  double remaining = 0.0;

  @HiveField(14)
  dynamic category;

  // Convert from JSON
  static BudgetModel fromJson(Map<String, dynamic> json) {
    BudgetModel budget = BudgetModel();
    budget.id = json['id'] ?? json['uuid'] ?? '';
    budget.name = json['name'] ?? '';
    budget.description = json['description'];
    budget.amount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;
    budget.categoryId = json['category_id']?.toString();
    budget.period = json['period'] ?? 'monthly';
    budget.startDate = json['start_date'] ?? '';
    budget.endDate = json['end_date'] ?? '';
    budget.sendNotifications = json['send_notifications'] == true || json['send_notifications'] == 1;
    budget.notificationThreshold = json['notification_threshold'] ?? 80;
    budget.color = json['color'] ?? '#90CAF9';
    budget.status = json['status'] ?? 'active';
    budget.spent = double.tryParse(json['spent']?.toString() ?? '0') ?? 0.0;
    budget.remaining = budget.amount - budget.spent;
    budget.category = json['category'];

    return budget;
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'amount': amount,
      'category_id': categoryId,
      'period': period,
      'start_date': startDate,
      'end_date': endDate,
      'send_notifications': sendNotifications,
      'notification_threshold': notificationThreshold,
      'color': color,
      'status': status,
    };
  }

  // Create a copy with modified fields
  BudgetModel copyWith({
    String? name,
    String? description,
    double? amount,
    String? categoryId,
    String? period,
    String? startDate,
    String? endDate,
    bool? sendNotifications,
    int? notificationThreshold,
    String? color,
    String? status,
  }) {
    BudgetModel newBudget = BudgetModel();
    newBudget.id = this.id;
    newBudget.name = name ?? this.name;
    newBudget.description = description ?? this.description;
    newBudget.amount = amount ?? this.amount;
    newBudget.categoryId = categoryId ?? this.categoryId;
    newBudget.period = period ?? this.period;
    newBudget.startDate = startDate ?? this.startDate;
    newBudget.endDate = endDate ?? this.endDate;
    newBudget.sendNotifications = sendNotifications ?? this.sendNotifications;
    newBudget.notificationThreshold = notificationThreshold ?? this.notificationThreshold;
    newBudget.color = color ?? this.color;
    newBudget.status = status ?? this.status;
    newBudget.spent = this.spent;
    newBudget.remaining = amount != null ? amount - this.spent : this.remaining;
    newBudget.category = this.category;

    return newBudget;
  }
}