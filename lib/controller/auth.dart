import 'package:dio/dio.dart';
import 'package:monet/controller/account.dart';
import 'package:monet/models/user.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/account_service.dart';
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

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final result = response.data['result'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }

      final userModel = await AuthService.create(result['user'], result['token']);
      return Result(isSuccess: true, message: response.data['message'] ?? "Registration successful", results: userModel);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
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

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final result = response.data['result'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }

      final userModel = await AuthService.create(result['user'], result['token']);

      // TODO: Improve Load Account
      await AccountController.load();

      return Result(isSuccess: true, message: response.data['message'] ?? "Login successful", results: userModel);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> logout() async {
    try {
      final response = await ApiService.post(ApiRoutes.logoutUrl, {});
      await AuthService.delete();
      await AccountService.delete();

      String message = "Logout successful";
      if (response.data != null && response.data['message'] != null) {
        message = response.data['message'];
      }

      return Result(isSuccess: true, message: message);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
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

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final result = response.data['result'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }

      final userModel = await AuthService.update(result['user']);
      return Result(isSuccess: true, message: response.data['message'] ?? "Verification successful", results: userModel);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> otp() async {
    try {
      final response = await ApiService.post(ApiRoutes.otpUrl, {});

      String message = "OTP sent successfully";
      if (response.data != null && response.data['message'] != null) {
        message = response.data['message'];
      }

      return Result(isSuccess: true, message: message);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
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

      String message = "Reset OTP sent successfully";
      if (response.data != null && response.data['message'] != null) {
        message = response.data['message'];
      }

      return Result(isSuccess: true, message: message);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
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

      String message = "Password reset successfully";
      if (response.data != null && response.data['message'] != null) {
        message = response.data['message'];
      }

      return Result(isSuccess: true, message: message);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> setPin(String pin) async {
    try {
      await AuthService.setPin(pin);
      return Result(isSuccess: true, message: "PIN set successfully");
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }
}