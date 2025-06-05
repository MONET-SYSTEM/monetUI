// lib/models/transfer.dart
import 'package:hive/hive.dart';
import 'package:monet/models/transaction.dart';
import 'package:monet/models/account.dart';

part 'currency_transfer.g.dart';

@HiveType(typeId: 7)
class CurrencyTransferModel {
  @HiveField(0)
  late String transferId;

  @HiveField(1)
  late TransactionModel outgoing;

  @HiveField(2)
  late TransactionModel incoming;

  @HiveField(3)
  late double exchangeRate;

  @HiveField(4)
  late bool usedRealTimeRate;

  @HiveField(5)
  late AccountModel sourceAccount;

  @HiveField(6)
  late AccountModel destinationAccount;

  static String currencyTransferBox = 'currency_transfers';

  get id => null;

  static CurrencyTransferModel fromMap(Map<String, dynamic> data) {
    var model = CurrencyTransferModel();
    model.transferId = data['transfer_id'];
    model.outgoing = TransactionModel.fromMap(data['outgoing']);
    model.incoming = TransactionModel.fromMap(data['incoming']);
    model.exchangeRate = (data['exchange_rate'] as num).toDouble();
    model.usedRealTimeRate = data['used_real_time_rate'] == '1';

    // Parse account information
    Map<String, dynamic> sourceData = data['source_account'];
    Map<String, dynamic> destData = data['destination_account'];

    // In a real implementation, you would fetch the complete account models
    // from your AccountService or create lightweight versions here

    return model;
  }
}