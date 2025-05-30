import 'package:hive/hive.dart';
import 'package:monet/models/account.dart';

class AccountService {

  static Future<AccountModel> create(Map<String, dynamic> accounts) async {
    final accountTypeBox = await Hive.openBox(AccountModel.accountBox);

    var accountModel = AccountModel.fromMap(accounts);

    await accountTypeBox.put(accountModel.id, accountModel);
    return accountModel;
  }

  static Future<List<AccountModel>> createAccount(List accounts) async {
    final accountBox = await Hive.openBox(AccountModel.accountBox);
    await accountBox.clear();

    List<AccountModel> accountModels= [];

    for(var account in accounts) {
      var accountModel = AccountModel.fromMap(account);

      await accountBox.put(accountModel.id, accountModel);
      accountModels.add(accountModel);
    }
    return accountModels;
  }

  static Future<AccountModel?> get() async {
    final accountBox = await Hive.openBox(AccountModel.accountBox);
    if(accountBox.isEmpty) return null;

    final accountModel = await accountBox.values.first;
    return accountModel as AccountModel?;
  }

  static Future delete() async {
    final accountBox = await Hive.openBox(AccountModel.accountBox);
    await accountBox.clear();
  }
}