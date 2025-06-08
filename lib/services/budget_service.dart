import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:monet/models/budget.dart';
import 'package:monet/models/result.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';

class BudgetService {
  static Future<Result<List<BudgetModel>>> loadBudgets() async {
    try {
      // Assuming ApiService.get expects endpoint and headers
      final response = await ApiService.get(ApiRoutes.budgetUrl, {});

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.data);
        if (decodedData['status'] == 'success' && decodedData['data'] != null) {
          List<dynamic> budgetsData = decodedData['data'];
          List<BudgetModel> budgets = budgetsData
              .map((json) => BudgetModel.fromJson(json))
              .toList();
          return Result<List<BudgetModel>>(
              isSuccess: true,
              results: budgets,
              message: 'Budgets loaded successfully'
          );
        }
        return Result<List<BudgetModel>>(
            isSuccess: false,
            message: decodedData['message'] ?? 'Failed to load budgets'
        );
      }
      return Result<List<BudgetModel>>(
          isSuccess: false,
          message: 'Failed to load budgets. Status code: ${response.statusCode}'
      );
    } catch (e) {
      return Result<List<BudgetModel>>(
          isSuccess: false,
          message: 'Error: ${e.toString()}'
      );
    }
  }

  static Future<Result<BudgetModel>> getBudget(String id) async {
    try {
      final response = await ApiService.get('${ApiRoutes.budgetUrl}/$id', {});

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.data);
        if (decodedData['status'] == 'success' && decodedData['data'] != null) {
          BudgetModel budget = BudgetModel.fromJson(decodedData['data']);
          return Result<BudgetModel>(
              isSuccess: true,
              results: budget,
              message: 'Budget retrieved successfully'
          );
        }
        return Result<BudgetModel>(
            isSuccess: false,
            message: decodedData['message'] ?? 'Budget not found'
        );
      }
      return Result<BudgetModel>(
          isSuccess: false,
          message: 'Failed to get budget. Status code: ${response.statusCode}'
      );
    } catch (e) {
      return Result<BudgetModel>(
          isSuccess: false,
          message: 'Error: ${e.toString()}'
      );
    }
  }

  static Future<Result<BudgetModel>> createBudget(BudgetModel budget) async {
    try {
      final response = await ApiService.post(ApiRoutes.budgetUrl, budget.toJson());

      if (response.statusCode == 201) {
        final Map<String, dynamic> decodedData = jsonDecode(response.data);
        if (decodedData['status'] == 'success' && decodedData['data'] != null) {
          BudgetModel createdBudget = BudgetModel.fromJson(decodedData['data']);
          return Result<BudgetModel>(
              isSuccess: true,
              results: createdBudget,
              message: 'Budget created successfully'
          );
        }
        return Result<BudgetModel>(
            isSuccess: false,
            message: decodedData['message'] ?? 'Failed to create budget'
        );
      }

      // Try to parse error messages
      try {
        final Map<String, dynamic> errorData = jsonDecode(response.data);
        return Result<BudgetModel>(
            isSuccess: false,
            message: errorData['message'] ?? 'Failed to create budget'
        );
      } catch (_) {
        return Result<BudgetModel>(
            isSuccess: false,
            message: 'Failed to create budget. Status code: ${response.statusCode}'
        );
      }
    } catch (e) {
      return Result<BudgetModel>(
          isSuccess: false,
          message: 'Error: ${e.toString()}'
      );
    }
  }

  static Future<Result<BudgetModel>> updateBudget(BudgetModel budget) async {
    try {
      final response = await ApiService.put('${ApiRoutes.budgetUrl}/${budget.id}', budget.toJson());

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.data);
        if (decodedData['status'] == 'success' && decodedData['data'] != null) {
          BudgetModel updatedBudget = BudgetModel.fromJson(decodedData['data']);
          return Result<BudgetModel>(
              isSuccess: true,
              results: updatedBudget,
              message: 'Budget updated successfully'
          );
        }
        return Result<BudgetModel>(
            isSuccess: false,
            message: decodedData['message'] ?? 'Failed to update budget'
        );
      }
      return Result<BudgetModel>(
          isSuccess: false,
          message: 'Failed to update budget. Status code: ${response.statusCode}'
      );
    } catch (e) {
      return Result<BudgetModel>(
          isSuccess: false,
          message: 'Error: ${e.toString()}'
      );
    }
  }

  static Future<Result> deleteBudget(String id) async {
    try {
      final response = await ApiService.delete('${ApiRoutes.budgetUrl}/$id');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = jsonDecode(response.data);
        if (decodedData['status'] == 'success') {
          return Result(
              isSuccess: true,
              message: decodedData['message'] ?? 'Budget deleted successfully'
          );
        }
        return Result(
            isSuccess: false,
            message: decodedData['message'] ?? 'Failed to delete budget'
        );
      }
      return Result(
          isSuccess: false,
          message: 'Failed to delete budget. Status code: ${response.statusCode}'
      );
    } catch (e) {
      return Result(
          isSuccess: false,
          message: 'Error: ${e.toString()}'
      );
    }
  }
}