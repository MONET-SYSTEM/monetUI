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

  static Future delete(String accountId) async {
    final accountBox = await Hive.openBox(AccountModel.accountBox);
    await accountBox.clear();
  }

  static Future<AccountModel> update(Map<String, dynamic> account) async {
    final accountBox = await Hive.openBox(AccountModel.accountBox);

    final updatedAccount = AccountModel.fromMap(account);

    // Find the existing account by ID
    AccountModel? existingAccount;
    int existingIndex = -1;

    for (int i = 0; i < accountBox.length; i++) {
      final acc = accountBox.getAt(i) as AccountModel;
      if (acc.id == updatedAccount.id) {
        existingAccount = acc;
        existingIndex = i;
        break;
      }
    }

    if (existingIndex != -1) {
      // Update existing account with the new data
      // Make sure to completely replace the old account with the new one
      await accountBox.putAt(existingIndex, updatedAccount);
    } else {
      // Add as new if not found
      await accountBox.add(updatedAccount);
    }

    return updatedAccount;
  }



}

