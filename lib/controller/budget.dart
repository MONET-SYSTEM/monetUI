// lib/controller/budget_controller.dart

import 'package:dio/dio.dart';
import 'package:monet/models/budget.dart';
import 'package:monet/models/result.dart';
import 'package:monet/resources/app_strings.dart';
import 'package:monet/services/api.dart';
import 'package:monet/services/api_routes.dart';
import 'package:monet/services/budget_service.dart';

class BudgetController {
  static Future<Result<BudgetModel>> createBudget({
    required String name,
    required double amount,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
    String? categoryId,
    String? description,
    bool sendNotifications = true,
    int notificationThreshold = 80,
    String color = '#007bff',
  }) async {
    try {
      final payload = {
        'name': name,
        'amount': amount.toString(),
        'period': period,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (categoryId != null) 'category_id': categoryId,
        if (description != null) 'description': description,
        'send_notifications': sendNotifications ? '1' : '0',
        'notification_threshold': notificationThreshold.toString(),
        'color': color,
      };

      final response = await ApiService.post(ApiRoutes.budgetUrl, payload);
      final data = response.data['data'] as Map<String, dynamic>?;

      if (data == null || data['budget'] == null) {
        return Result(isSuccess: false, message: 'Invalid response from server.');
      }

      final budget = BudgetModel.fromMap(data['budget']);
      await BudgetService.save(budget);

      return Result(
        isSuccess: true,
        message: response.data['message'],
        results: budget,
      );
    } on DioException catch (e) {
      return _handleDioError<BudgetModel>(e);
    } catch (_) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result<List<BudgetModel>>> fetchBudgets() async {
    final response = await ApiService.get(ApiRoutes.budgetUrl, {});
    final rawData = response.data['data'];

    List<dynamic> list;

    if (rawData is List) {
      // old-style un-paginated array
      list = rawData;
    } else if (rawData is Map) {
      // Laravel ResourceCollection -> data: { data: [ … ], links, meta }
      if (rawData['data'] is List) {
        list = rawData['data'];
      }
      // if you ever change your API to wrap in 'budgets': …
      else if (rawData.containsKey('budgets') && rawData['budgets'] is List) {
        list = rawData['budgets'];
      } else {
        return Result(isSuccess: false, message: 'Unexpected payload from server');
      }
    } else {
      return Result(isSuccess: false, message: 'Invalid response format');
    }

    final budgets = list
        .cast<Map<String, dynamic>>()
        .map(BudgetModel.fromMap)
        .toList();

    await BudgetService.saveAll(budgets);
    return Result(
      isSuccess: true,
      message: response.data['message'] ?? 'Budgets loaded',
      results: budgets,
    );
  }

  static Future<Result<BudgetModel>> updateBudget({
    required String budgetId,
    String? name,
    double? amount,
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? description,
    bool? sendNotifications,
    int? notificationThreshold,
    String? color,
    String? status,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (name != null) 'name': name,
        if (amount != null) 'amount': amount.toString(),
        if (period != null) 'period': period,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
        if (categoryId != null) 'category_id': categoryId,
        if (description != null) 'description': description,
        if (sendNotifications != null)
          'send_notifications': sendNotifications ? '1' : '0',
        if (notificationThreshold != null)
          'notification_threshold': notificationThreshold.toString(),
        if (color != null) 'color': color,
        if (status != null) 'status': status,
      };

      final response =
      await ApiService.put('${ApiRoutes.budgetUrl}/$budgetId', payload);
      final data = response.data['data'] as Map<String, dynamic>?;

      if (data == null || data['budget'] == null) {
        return Result(isSuccess: false, message: 'Invalid response from server.');
      }

      final updated = BudgetModel.fromMap(data['budget']);
      await BudgetService.save(updated);

      return Result(
        isSuccess: true,
        message: response.data['message'],
        results: updated,
      );
    } on DioException catch (e) {
      return _handleDioError<BudgetModel>(e);
    } catch (_) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Future<Result<bool>> deleteBudget(String budgetId) async {
    try {
      final response =
      await ApiService.delete('${ApiRoutes.budgetUrl}/$budgetId');
      final success = response.data['success'] == true;

      if (success) {
        await BudgetService.delete(budgetId);
      }

      return Result(
        isSuccess: success,
        message: response.data['message'],
        results: success,
      );
    } on DioException catch (e) {
      return _handleDioError<bool>(e);
    } catch (_) {
      return Result(isSuccess: false, message: AppStrings.anErrorOccurredTryAgain);
    }
  }

  static Result<T> _handleDioError<T>(DioException e) {
    final msg = ApiService.errorMessage(e);
    final errs = e.response?.data?['errors'];
    return Result(isSuccess: false, message: msg, errors: errs);
  }
}
