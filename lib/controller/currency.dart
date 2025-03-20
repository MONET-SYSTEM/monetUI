import 'package:dio/dio.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/models/result.dart';
import 'package:monet/services/currency_service.dart';

class CurrencyController {
  static Future<Result> load() async {
    try {
      final response = await ApiService.get(ApiRoutes.currencyUrl, {});

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final results = response.data['results'];
      if (results == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }

      final currencies = await CurrencyService.createCurrencies(results['currencies']);
      return Result(isSuccess: true, message: response.data['message'], results: currencies);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }
}