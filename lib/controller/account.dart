import 'package:dio/dio.dart';
import 'package:monet/models/account.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/account_service.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/models/result.dart';

class AccountController {
  static Future<Result<AccountModel>> create(double initialBalance,String name, String currency, String accountType) async {
    try {
      final response = await ApiService.post(ApiRoutes.accountUrl, {
        'account_type': accountType,
        'currency': currency,
        'initial_balance': initialBalance,
        'name': name,
      });

      final result = response.data['results'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }
      print(result['account']);
      final account = await AccountService.create(result['account']);

      return Result(isSuccess: true, message: response.data['message'], results: account);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      print(e);
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result<List<AccountModel>>> load() async {
    try {
      final response = await ApiService.get(ApiRoutes.accountUrl, {});

      final result = response.data['results'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }
      print(result['account']);
      final accounts = await AccountService.createAccount(result['accounts']);

      return Result(isSuccess: true, message: response.data['message'], results: accounts);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      print(e);
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }
}