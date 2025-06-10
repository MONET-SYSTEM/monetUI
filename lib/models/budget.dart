// lib/models/budget.dart

import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 8)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final String? categoryId;

  @HiveField(3)
  final String name;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final double amount;

  @HiveField(6)
  final String amountText;

  @HiveField(7)
  final double spentAmount;

  @HiveField(8)
  final String spentAmountText;

  @HiveField(9)
  final String period;

  @HiveField(10)
  final DateTime startDate;

  @HiveField(11)
  final DateTime endDate;

  @HiveField(12)
  final String status;

  @HiveField(13)
  final bool sendNotifications;

  @HiveField(14)
  final int notificationThreshold;

  @HiveField(15)
  final String color;

  // New fields for the nested category object:
  @HiveField(16)
  final String? categoryName;

  @HiveField(17)
  final String? categoryIcon;

  @HiveField(18)
  final String? categoryColour;

  static const String boxName = 'budgets';

  BudgetModel({
    required this.id,
    required this.userId,
    this.categoryId,
    this.categoryName,
    this.categoryIcon,
    this.categoryColour,
    required this.name,
    this.description,
    this.amount = 0.0,
    String? amountText,
    this.spentAmount = 0.0,
    String? spentAmountText,
    required this.period,
    DateTime? startDate,
    DateTime? endDate,
    this.status = '',
    this.sendNotifications = false,
    this.notificationThreshold = 0,
    this.color = '#007bff',
  })  : amountText = amountText ?? amount.toStringAsFixed(2),
        spentAmountText = spentAmountText ?? spentAmount.toStringAsFixed(2),
        startDate = startDate ?? DateTime.now(),
        endDate = endDate ?? DateTime.now();

  factory BudgetModel.fromMap(Map<String, dynamic> json) {
    // Extract nested category if present
    final rawCat = json['category'] as Map<String, dynamic>?;
    final catId = rawCat?['id']?.toString() ?? json['category_id']?.toString();

    final rawNotif = json['send_notifications'];
    final rawThresh = json['notification_threshold'];

    return BudgetModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      categoryId: catId,
      categoryName: rawCat?['name']?.toString(),
      categoryIcon: rawCat?['icon']?.toString(),
      categoryColour: rawCat?['colour_code']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      amountText: json['amount_text']?.toString(),
      spentAmount: (json['spent_amount'] as num?)?.toDouble() ?? 0.0,
      spentAmountText: json['spent_amount_text']?.toString(),
      period: json['period']?.toString() ?? '',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : DateTime.now(),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'])
          : DateTime.now(),
      status: json['status']?.toString() ?? '',
      sendNotifications: rawNotif is bool
          ? rawNotif
          : (rawNotif?.toString() == '1'),
      notificationThreshold: rawThresh is int
          ? rawThresh
          : int.tryParse(rawThresh?.toString() ?? '') ?? 0,
      color: json['color']?.toString() ?? '#007bff',
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'user_id': userId,
    'category_id': categoryId,
    'name': name,
    'description': description,
    'amount': amount,
    'amount_text': amountText,
    'spent_amount': spentAmount,
    'spent_amount_text': spentAmountText,
    'period': period,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'status': status,
    'send_notifications': sendNotifications,
    'notification_threshold': notificationThreshold,
    'color': color,
    // We don’t send categoryName/icon/colour back to API
  };

  /// Percentage of the budget spent (0.0 – 1.0)
  double get progress =>
      amount > 0.0 ? (spentAmount / amount).clamp(0.0, 1.0) : 0.0;

  /// Create a modified copy
  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    String? categoryIcon,
    String? categoryColour,
    String? name,
    String? description,
    double? amount,
    String? amountText,
    double? spentAmount,
    String? spentAmountText,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    bool? sendNotifications,
    int? notificationThreshold,
    String? color,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColour: categoryColour ?? this.categoryColour,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      amountText: amountText ?? this.amountText,
      spentAmount: spentAmount ?? this.spentAmount,
      spentAmountText: spentAmountText ?? this.spentAmountText,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      sendNotifications: sendNotifications ?? this.sendNotifications,
      notificationThreshold:
      notificationThreshold ?? this.notificationThreshold,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is BudgetModel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Budget($name, $amount, spent: $spentAmount)';
}
