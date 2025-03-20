import 'package:dio/dio.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/models/result.dart';
import 'package:monet/services/account_type_service.dart';

class AccountTypeController {
  static Future<Result> load() async {
    try {
      final response = await ApiService.get(ApiRoutes.accountTypeUrl, {});

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final results = response.data['results'];
      if (results == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }

      final accountTypes = await AccountTypeService.createAccountTypes(results['account_types']);
      return Result(isSuccess: true, message: response.data['message'], results: accountTypes);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }
}