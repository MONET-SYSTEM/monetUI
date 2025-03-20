import 'package:hive/hive.dart';
import 'package:monet/models/currency.dart';

class CurrencyService {

  static Future<CurrencyModel> create(Map<String, dynamic> currency) async {
    final currencyBox = await Hive.openBox(CurrencyModel.currencyBox);

    var currencyModel = CurrencyModel();
    currencyModel.id = currency['id'];
    currencyModel.name = currency['name'];
    currencyModel.code = currency['code'];
    currencyModel.symbol = currency['symbol'];
    currencyModel.symbolPosition = currency['symbol_position'];
    currencyModel.thousandSeparator = currency['thousand_separator'] ;
    currencyModel.decimalSeparator = currency['decimal_separator'] ;
    currencyModel.decimalPlaces = currency['decimal_places'] ;
    currencyModel.sample = currency['sample'];

    await currencyBox.put(currencyModel.id, currencyModel);
    return currencyModel;
  }

  static Future<List<CurrencyModel>> createCurrencies(List currencies) async {
    final currencyBox = await Hive.openBox(CurrencyModel.currencyBox);
    await currencyBox.clear();

    List<CurrencyModel> currencyModels= [];

    for(var currency in currencies) {
      var currencyModel = CurrencyModel();
      currencyModel.id = currency['id'];
      currencyModel.name = currency['name'];
      currencyModel.code = currency['code'];
      currencyModel.symbol = currency['symbol'];
      currencyModel.symbolPosition = currency['symbol_position'];
      currencyModel.thousandSeparator = currency['thousand_separator'] ;
      currencyModel.decimalSeparator = currency['decimal_separator'] ;
      currencyModel.decimalPlaces = currency['decimal_places'] ;
      currencyModel.sample = currency['sample'];

      await currencyBox.put(currencyModel.id, currencyModel);
      currencyModels.add(currencyModel);
    }
    return currencyModels;
  }
}