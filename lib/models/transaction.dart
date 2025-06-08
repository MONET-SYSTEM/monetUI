// lib/models/transaction.dart
import 'package:hive/hive.dart';
import 'package:monet/models/category.dart';
import 'package:intl/intl.dart';

part 'transaction.g.dart';

@HiveType(typeId: 6)
class TransactionModel {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String accountId;

  @HiveField(2)
  late String accountName;

  @HiveField(3)
  CategoryModel? category;

  @HiveField(4)
  late double amount;

  @HiveField(5)
  String? amountFormatted;

  @HiveField(6)
  late String type;

  @HiveField(7)
  String? description;

  @HiveField(8)
  late String transactionDate;

  @HiveField(9)
  late bool isReconciled;

  @HiveField(10)
  String? reference;

  static String transactionBox = 'transactions';

  TransactionModel();

  static TransactionModel fromMap(Map<String, dynamic> transaction) {
    var model = TransactionModel();
    model.id = transaction['id'].toString();
    model.accountId = transaction['account_id'].toString();
    model.accountName = transaction['account_name'] ?? '';
    model.category = transaction['category'] != null
        ? CategoryModel.fromMap(transaction['category'])
        : null;

    // Fix the null conversion issue
    model.amount = (transaction['amount'] != null)
        ? (transaction['amount'] is num ? (transaction['amount'] as num).toDouble() : double.tryParse(transaction['amount'].toString()) ?? 0.0)
        : 0.0;

    model.amountFormatted = transaction['amount_formatted'] ?? "";
    model.type = transaction['type'] ?? 'expense';
    model.description = transaction['description'];

    // Better date handling to preserve time if available
    String dateString = transaction['transaction_date'] ?? DateTime.now().toString().substring(0, 10);
    model.transactionDate = dateString;

    // Improved handling for is_reconciled field
    model.isReconciled = transaction['is_reconciled'] == null
        ? false
        : (transaction['is_reconciled'] is bool
        ? transaction['is_reconciled']
        : transaction['is_reconciled'] == 1 || transaction['is_reconciled'] == '1');

    model.reference = transaction['reference'];

    return model;
  }

  // Format date for display
  String getFormattedTime() {
    try {
      // For date-only format (YYYY-MM-DD)
      if (transactionDate.length == 10 && transactionDate.contains('-')) {
        // For date-only strings, show date in more readable format
        final dateTime = DateTime.parse(transactionDate);
        return DateFormat('MMM d').format(dateTime); // Show "May 20" instead of time
      }

      // If it has a time component
      final dateTime = DateTime.parse(transactionDate);

      // If the time is exactly midnight (00:00:00), show the date instead of time
      if (dateTime.hour == 0 && dateTime.minute == 0 && dateTime.second == 0) {
        return DateFormat('MMM d').format(dateTime);
      }

      return DateFormat('hh:mm a').format(dateTime);
    } catch (e) {
      print("Date format error: $e for date: $transactionDate");
      return DateFormat('MMM d').format(DateTime.now()); // Return today's date as fallback
    }
  }

  // Get the transaction date as DateTime object
  DateTime getTransactionDate() {
    try {
      return DateTime.parse(transactionDate);
    } catch (e) {
      // Handle date-only format
      if (transactionDate.length == 10) {
        return DateTime.parse('${transactionDate}T00:00:00');
      }
      return DateTime.now(); // Fallback
    }
  }

  // Add a copyWith method for updating fields
  TransactionModel copyWith({
    String? id,
    String? accountId,
    String? accountName,
    CategoryModel? category,
    double? amount,
    String? amountFormatted,
    String? type,
    String? description,
    String? transactionDate,
    bool? isReconciled,
    String? reference,
  }) {
    final model = TransactionModel();
    model.id = id ?? this.id;
    model.accountId = accountId ?? this.accountId;
    model.accountName = accountName ?? this.accountName;
    model.category = category ?? this.category;
    model.amount = amount ?? this.amount;
    model.amountFormatted = amountFormatted ?? this.amountFormatted;
    model.type = type ?? this.type;
    model.description = description ?? this.description;
    model.transactionDate = transactionDate ?? this.transactionDate;
    model.isReconciled = isReconciled ?? this.isReconciled;
    model.reference = reference ?? this.reference;
    return model;
  }
}
