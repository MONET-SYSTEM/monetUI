import 'package:hive/hive.dart';
import 'package:monet/models/currency.dart';

class CurrencyService {

  static Future<CurrencyModel> create(Map<String, dynamic> currency) async {
    final currencyBox = await Hive.openBox(CurrencyModel.currencyBox);

    var currencyModel = CurrencyModel.fromMap(currency);

    await currencyBox.put(currencyModel.id, currencyModel);
    return currencyModel;
  }

  static Future<List<CurrencyModel>> createCurrencies(List currencies) async {
    final currencyBox = await Hive.openBox(CurrencyModel.currencyBox);
    await currencyBox.clear();

    List<CurrencyModel> currencyModels= [];

    for(var currency in currencies) {
      var currencyModel = CurrencyModel.fromMap(currency);

      await currencyBox.put(currencyModel.id, currencyModel);
      currencyModels.add(currencyModel);
    }
    return currencyModels;
  }

  // Add update method
  static Future<CurrencyModel?> update(String id, Map<String, dynamic> updatedCurrency) async {
    final currencyBox = await Hive.openBox(CurrencyModel.currencyBox);

    if (currencyBox.containsKey(id)) {
      var currencyModel = CurrencyModel.fromMap(updatedCurrency);
      await currencyBox.put(id, currencyModel);
      return currencyModel;
    }

    return null;
  }

  // Add get method to retrieve specific currency
  static Future<CurrencyModel?> get(String id) async {
    final currencyBox = await Hive.openBox(CurrencyModel.currencyBox);
    return currencyBox.get(id);
  }

  // Add getAll method to retrieve all currencies
  static Future<List<CurrencyModel>> getAll() async {
    final currencyBox = await Hive.openBox(CurrencyModel.currencyBox);
    return currencyBox.values.cast<CurrencyModel>().toList();
  }

  // Add delete method
  static Future<bool> delete(String id) async {
    final currencyBox = await Hive.openBox(CurrencyModel.currencyBox);

    if (currencyBox.containsKey(id)) {
      await currencyBox.delete(id);
      return true;
    }

    return false;
  }
}