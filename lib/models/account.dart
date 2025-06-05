import 'package:hive/hive.dart';
import 'package:monet/models/account_type.dart';
import 'package:monet/models/currency.dart';

part 'account.g.dart';

@HiveType(typeId: 4)
class AccountModel{
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double initialBalance;

  @HiveField(3)
  late String initialBalanceText;

  @HiveField(4)
  late double currentBalance;

  @HiveField(5)
  late String currentBalanceText;

  @HiveField(6)
  String? colourCode;

  @HiveField(7)
  late int active;

  @HiveField(8)
  late CurrencyModel currency;

  @HiveField(9)
  late AccountTypeModel accountType;

  static String accountBox = 'accounts';

  static AccountModel fromMap(Map<String, dynamic> account) {
    var accountModel = AccountModel();
    accountModel.id = account['id'];
    accountModel.name = account['name'];

    accountModel.initialBalance = (account['initial_balance'] as num).toDouble();
    accountModel.initialBalanceText = account['initial_balance_text'];

    accountModel.currentBalance = (account['current_balance'] as num).toDouble();
    accountModel.currentBalanceText = account['current_balance_text'];

    accountModel.colourCode = account['colour_code'];
    accountModel.active = account['active'] is bool
        ? (account['active'] ? 1 : 0)
        : account['active'];

    // Safely initialize currency
    if (account['currency'] != null) {
      accountModel.currency = CurrencyModel.fromMap(account['currency']);
    } else {
      // Provide a default currency if missing
      accountModel.currency = CurrencyModel()
        ..id = ''
        ..name = 'Unknown'
        ..symbol = 'PHP';
    }

    accountModel.accountType = AccountTypeModel.fromMap(account['account_type']);

    return accountModel;
  }

  bool isEqual(AccountModel model) {
    return id == model.id;
  }

  @override
  String toString() => name;
}