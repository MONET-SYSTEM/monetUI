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

  // Add update method
  static Future<Result> update(String id, String name, String code, String symbol) async {
    try {
      // Prepare data for API call
      final data = {
        'name': name,
        'code': code,
        'symbol': symbol,
      };

      // Make API call to update currency
      final response = await ApiService.put('${ApiRoutes.currencyUrl}/$id', data);

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      // Update local storage
      final updatedCurrencyData = response.data['results'];
      if (updatedCurrencyData != null) {
        final updatedCurrency = await CurrencyService.update(id, updatedCurrencyData);
        return Result(
            isSuccess: true,
            message: response.data['message'] ?? "Currency updated successfully",
            results: updatedCurrency
        );
      }

      return Result(isSuccess: true, message: response.data['message'] ?? "Currency updated successfully");
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  // Add create method
  static Future<Result> create(String name, String code, String symbol) async {
    try {
      final data = {
        'name': name,
        'code': code,
        'symbol': symbol,
      };

      final response = await ApiService.post(ApiRoutes.currencyUrl, data);

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      // Add to local storage
      final currencyData = response.data['results'];
      if (currencyData != null) {
        final currency = await CurrencyService.create(currencyData);
        return Result(
            isSuccess: true,
            message: response.data['message'] ?? "Currency created successfully",
            results: currency
        );
      }

      return Result(isSuccess: true, message: response.data['message'] ?? "Currency created successfully");
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  // Add method to get all currencies from local storage
  static Future<Result> getAll() async {
    try {
      final currencies = await CurrencyService.getAll();
      return Result(isSuccess: true, message: "Currencies retrieved successfully", results: currencies);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  // Add method to get specific currency
  static Future<Result> get(String id) async {
    try {
      final currency = await CurrencyService.get(id);
      if (currency != null) {
        return Result(isSuccess: true, message: "Currency retrieved successfully", results: currency);
      } else {
        return Result(isSuccess: false, message: "Currency not found");
      }
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }
}
