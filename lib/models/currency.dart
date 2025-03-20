import 'package:hive/hive.dart';

part 'currency.g.dart';

@HiveType(typeId: 2)
class CurrencyModel{
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String code;

  @HiveField(3)
  late String symbol;

  @HiveField(4)
  late String symbolPosition;

  @HiveField(5)
  late String thousandSeparator;

  @HiveField(6)
  late String decimalSeparator;

  @HiveField(7)
  late int decimalPlaces;

  @HiveField(8)
  late String sample;


  static String currencyBox = 'currencies';

  bool isEqual(CurrencyModel model) {
    return id == model.id;
  }

  @override
  String toString() => "$name ($code)";
}