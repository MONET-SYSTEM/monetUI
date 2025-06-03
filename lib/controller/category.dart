import 'package:dio/dio.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/models/result.dart';
import 'package:monet/services/category_service.dart';

class CategoryController {
  static Future<Result> load() async {
    try {
      final response = await ApiService.get(ApiRoutes.categoryUrl, {});

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      if (response.data['status'] == 'success' && response.data['data'] != null) {
        print("API returned ${response.data['data'].length} categories");
        print("First category sample: ${response.data['data'].isNotEmpty ? response.data['data'][0] : 'none'}");

        final categories = await CategoryService.createCategories(response.data['data']);
        return Result(isSuccess: true, message: "Categories loaded successfully", results: categories);
      } else {
        // If data is not in the expected format
        return Result(isSuccess: false, message: "Invalid response format from server");
      }
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      print("Exception in CategoryController.load(): $e");
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result> createCategory({
    required String name,
    required String type,
    String? icon,
    String? colourCode,
    String? description,
  }) async {
    try {
      final data = {
        'name': name,
        'type': type,
        'icon': icon,
        'colour_code': colourCode,
        'description': description,
        'is_system': 0, // User created categories are not system categories
      };

      final response = await ApiService.post(ApiRoutes.categoryUrl, data);

      if (response.data == null) {
        return Result(isSuccess: false, message: "Empty response from server");
      }

      if (response.data['status'] == 'success' && response.data['data'] != null) {
        // Create the category in local storage
        final categoryModel = await CategoryService.create(response.data['data']);
        return Result(isSuccess: true, message: "Category created successfully", results: categoryModel);
      } else {
        return Result(isSuccess: false, message: "Failed to create category");
      }
    } on DioException catch (e) {
      final message = ApiService.errorMessage(e);
      final errors = e.response?.data?['errors'];

      return Result(isSuccess: false, message: message, errors: errors);
    } catch (e) {
      print("Exception in CategoryController.createCategory(): $e");
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }
}
