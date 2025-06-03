import 'package:hive/hive.dart';
import 'package:monet/models/transaction.dart';

class TransactionService {
  static Future<TransactionModel> create(Map<String, dynamic> transaction) async {
    final transactionBox = await Hive.openBox<TransactionModel>(TransactionModel.transactionBox);

    // Ensure transaction has an ID
    if (transaction['id'] == null) {
      throw Exception("Transaction data must include an ID");
    }

    var transactionModel = TransactionModel.fromMap(transaction);
    await transactionBox.put(transactionModel.id, transactionModel);

    return transactionModel;
  }

  static Future<List<TransactionModel>> createTransactions(List transactions) async {
    final transactionBox = await Hive.openBox<TransactionModel>(TransactionModel.transactionBox);

    await transactionBox.clear();

    List<TransactionModel> transactionModels = [];

    for (var transaction in transactions) {
      try {
        if (transaction == null || transaction['id'] == null) continue;

        var transactionModel = TransactionModel.fromMap(transaction);
        await transactionBox.put(transactionModel.id, transactionModel);
        transactionModels.add(transactionModel);
      } catch (e) {
        print("Error creating transaction: $e");
        // Skip this transaction and continue with others
      }
    }

    return transactionModels;
  }

  static Future<List<TransactionModel>> getTransactions() async {
    final transactionBox = await Hive.openBox<TransactionModel>(TransactionModel.transactionBox);
    return transactionBox.values.toList();
  }

  static Future<TransactionModel?> getTransactionById(String id) async {
    final transactionBox = await Hive.openBox<TransactionModel>(TransactionModel.transactionBox);
    return transactionBox.get(id);
  }

  static Future<List<TransactionModel>> getTransactionsByAccountId(String accountId) async {
    final transactionBox = await Hive.openBox<TransactionModel>(TransactionModel.transactionBox);
    return transactionBox.values.where((tx) => tx.accountId == accountId).toList();
  }

  static Future<List<TransactionModel>> getTransactionsByType(String type) async {
    final transactionBox = await Hive.openBox<TransactionModel>(TransactionModel.transactionBox);
    return transactionBox.values.where((tx) => tx.type.toLowerCase() == type.toLowerCase()).toList();
  }

  static Future<void> delete(String id) async {
    final transactionBox = await Hive.openBox<TransactionModel>(TransactionModel.transactionBox);
    await transactionBox.delete(id);
  }

  static Future<void> deleteAll() async {
    final transactionBox = await Hive.openBox<TransactionModel>(TransactionModel.transactionBox);
    await transactionBox.clear();
  }
}