import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
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

      final token = result['token'] ?? '';
      final userModel = await AuthService.create(result['user'], token);
      final user = await AuthService.get();
      print('Token after register: \'${user?.token}\'');

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

      // Debug print to verify token is saved
      final user = await AuthService.get();
      print('Token after login: \'${user?.token}\'');

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
      await AccountService.delete("");

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

      // Always ensure token is set in userModel after update
      final userModel = await AuthService.update(result['user']);
      if (result['token'] != null && result['token'].toString().isNotEmpty) {
        userModel.token = result['token'];
        final userBox = await Hive.openBox(UserModel.userBox);
        await userBox.put(0, userModel);
        print('Token after verification: \'${userModel.token}\'');
      } else {
        // If token is not present in result, ensure userModel.token is not empty
        print('Token after verification: \'${userModel.token}\'');
      }
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

  static Future<bool> hasPin() async {
    return await AuthService.hasPin();
  }

  static Future<Result> googleSignUp(String idToken) async {
    try {
      final response = await ApiService.post(ApiRoutes.googleSignUpUrl, {
        'id_token': idToken
      });

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final result = response.data['result'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }

      final token = result['token'] ?? '';
      final userModel = await AuthService.create(result['user'], token);
      final user = await AuthService.get();
      print('Token after Google sign up: \'${user?.token}\'');

      return Result(isSuccess: true, message: response.data['message'] ?? "Registration successful", results: userModel);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> googleSignUpWithAccessToken(String accessToken) async {
    try {
      final response = await ApiService.post(ApiRoutes.googleSignUpUrl, {
        'access_token': accessToken
      });

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final result = response.data['result'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }

      final token = result['token'] ?? '';
      final userModel = await AuthService.create(result['user'], token);
      final user = await AuthService.get();
      print('Token after Google sign up with access token: \'${user?.token}\'');

      return Result(isSuccess: true, message: response.data['message'] ?? "Registration successful", results: userModel);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> googleLogin(String idToken) async {
    try {
      final response = await ApiService.post(ApiRoutes.googleLoginUrl, {
        'id_token': idToken
      });

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final result = response.data['result'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }

      final token = result['token'] ?? '';
      final userModel = await AuthService.create(result['user'], token);
      final user = await AuthService.get();
      print('Token after Google login: \'${user?.token}\'');

      return Result(isSuccess: true, message: response.data['message'] ?? "Login successful", results: userModel);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> googleLoginWithAccessToken(String accessToken) async {
    try {
      // Use the same URL as googleLogin but with access_token parameter
      final response = await ApiService.post(ApiRoutes.googleLoginUrl, {
        'access_token': accessToken
      });

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final result = response.data['result'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format from server");
      }

      final token = result['token'] ?? '';
      final userModel = await AuthService.create(result['user'], token);
      final user = await AuthService.get();
      print('Token after Google login with access token: \'${user?.token}\'');

      return Result(isSuccess: true, message: response.data['message'] ?? "Login successful", results: userModel);
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }
}