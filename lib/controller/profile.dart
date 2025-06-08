import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:monet/models/result.dart';
import 'package:monet/models/user.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/services/auth_service.dart';

class ProfileController {
  // Get current user profile
  static Future<Result<UserModel>> getProfile() async {
    try {
      final response = await ApiService.get(ApiRoutes.profileUrl, {});

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final result = response.data['result'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format");
      }

      // Merge token from Hive
      final userBox = await Hive.openBox(UserModel.userBox);
      final existingUser = userBox.get(0);
      if (existingUser != null && existingUser.token != null) {
        result['user']['token'] = existingUser.token;
      }

      final userModel = await AuthService.update(result['user']);
      return Result(
          isSuccess: true,
          message: response.data['message'] ?? "Profile retrieved successfully",
          results: userModel
      );
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  // Update user profile
  static Future<Result<UserModel>> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? bio,
    String? avatar,
    DateTime? dateOfBirth,
    String? gender,
    String? country,
    String? city,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'name': name,
        'email': email,
      };

      if (phone != null) data['phone'] = phone;
      if (bio != null) data['bio'] = bio;
      if (avatar != null) data['avatar'] = avatar;
      if (dateOfBirth != null) data['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) data['gender'] = gender;
      if (country != null) data['country'] = country;
      if (city != null) data['city'] = city;

      final response = await ApiService.put(ApiRoutes.profileUrl, data);

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      final result = response.data['result'];
      if (result == null) {
        return Result(isSuccess: false, message: "Invalid response format");
      }

      // Merge token from Hive
      final userBox = await Hive.openBox(UserModel.userBox);
      final existingUser = userBox.get(0);
      if (existingUser != null && existingUser.token != null) {
        result['user']['token'] = existingUser.token;
      }

      final userModel = await AuthService.update(result['user']);
      return Result(
          isSuccess: true,
          message: response.data['message'] ?? "Profile updated successfully",
          results: userModel
      );
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];
      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  // Update user password
  static Future<Result> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await ApiService.put(ApiRoutes.updatePasswordUrl, {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });

      String message = "Password updated successfully";
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
}