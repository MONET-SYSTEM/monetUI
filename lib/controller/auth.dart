import 'package:dio/dio.dart';
import 'package:monet/models/user.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/models/result.dart';
import 'package:monet/services/auth_service.dart';

class AuthController {
  static Future<Result> register(String name, String email, String password) async {
    try {
      final response = await ApiService.post(ApiRoutes.registerUrl, {
        'name': name,
        'email': email,
        'password': password
      });

      final results = response.data['results'];
      final userModel = await AuthService.create(results['user'], results['token']);

      return Result(isSuccess: true, message: response.data['message'], results: userModel);
    }  on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result<UserModel>> login(String email, String password) async {
    try {
      final response = await ApiService.post(ApiRoutes.loginUrl, {
        'email': email,
        'password': password
      });

      final results = response.data['results'];
      final userModel = await AuthService.create(results['user'], results['token']);

      return Result(isSuccess: true, message: response.data['message'], results: userModel);
    }  on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> logout() async {
    try {
      final response = await ApiService.post(ApiRoutes.logoutUrl, {});

      await AuthService.delete();

      return Result(isSuccess: true, message: response.data['message']);
    }  on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> verify(String otp) async {
    try {
      final response = await ApiService.post(ApiRoutes.verifyUrl, {
        'otp': otp
      });

      final results = response.data['results'];
      final userModel = await AuthService.update(results['user']);

      return Result(isSuccess: true, message: response.data['message'], results: userModel);
    }  on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> otp() async {
    try {
      final response = await ApiService.post(ApiRoutes.otpUrl, {});

      return Result(isSuccess: true, message: response.data['message']);

    }  on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> resetOtp(String email) async {
    try {
      final response = await ApiService.post(ApiRoutes.resetOtpUrl, {
        'email': email
      });

      return Result(isSuccess: true, message: response.data['message']);

    }  on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> resetPassword(String email, String otp, String password, String passwordConfirmation) async {
    try {
      final response = await ApiService.post(ApiRoutes.resetPasswordUrl, {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      return Result(isSuccess: true, message: response.data['message']);

    }  on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> setPin(String pin) async {
    try {
      final user = AuthService.setPin(pin);
      return Result(isSuccess: true, message: "");
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

}
