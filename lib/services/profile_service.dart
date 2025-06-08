import 'package:flutter/foundation.dart';
import 'package:monet/controller/profile.dart';
import 'package:monet/models/result.dart';
import 'package:monet/models/user.dart';

class ProfileService {
  // Singleton pattern
  static final ProfileService _instance = ProfileService._internal();
  static ProfileService get instance => _instance;

  factory ProfileService() => _instance;
  ProfileService._internal();

  // State management
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);
  final ValueNotifier<String?> error = ValueNotifier<String?>(null);
  final ValueNotifier<UserModel?> user = ValueNotifier<UserModel?>(null);

  // Fetch current user profile
  Future<Result<UserModel>> fetchProfile() async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await ProfileController.getProfile();

      if (result.isSuccess && result.results != null) {
        user.value = result.results;
      } else {
        error.value = result.message;
      }

      return result;
    } catch (e) {
      error.value = e.toString();
      return Result(isSuccess: false, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Update user profile
  Future<Result<UserModel>> updateProfile({
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
    isLoading.value = true;
    error.value = null;

    try {
      final result = await ProfileController.updateProfile(
        name: name,
        email: email,
        phone: phone,
        bio: bio,
        avatar: avatar,
        dateOfBirth: dateOfBirth,
        gender: gender,
        country: country,
        city: city,
      );

      if (result.isSuccess && result.results != null) {
        user.value = result.results;
      } else {
        error.value = result.message;
      }

      return result;
    } catch (e) {
      error.value = e.toString();
      return Result(isSuccess: false, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Update password
  Future<Result> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    isLoading.value = true;
    error.value = null;

    try {
      final result = await ProfileController.updatePassword(
        currentPassword: currentPassword,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );

      if (!result.isSuccess) {
        error.value = result.message;
      }

      return result;
    } catch (e) {
      error.value = e.toString();
      return Result(isSuccess: false, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  // Clean up resources
  void dispose() {
    isLoading.dispose();
    error.dispose();
    user.dispose();
  }
}