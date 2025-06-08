import 'package:monet/models/budget.dart';
import 'package:monet/models/result.dart';
import 'package:monet/services/budget_service.dart';
import 'package:flutter/material.dart';

class BudgetController {
  static Future<Result<List<BudgetModel>>> loadBudgets() async {
    return await BudgetService.loadBudgets();
  }

  static Future<Result<BudgetModel>> getBudget(String id) async {
    return await BudgetService.getBudget(id);
  }

  static Future<Result<BudgetModel>> createBudget(BudgetModel budget) async {
    return await BudgetService.createBudget(budget);
  }

  static Future<Result<BudgetModel>> updateBudget(BudgetModel budget) async {
    return await BudgetService.updateBudget(budget);
  }

  static Future<Result> deleteBudget(String id) async {
    return await BudgetService.deleteBudget(id);
  }

  // Calculate progress percentage (0-1)
  static double calculateProgress(BudgetModel budget) {
    if (budget.amount <= 0) return 0.0;
    return (budget.spent / budget.amount).clamp(0.0, 1.0);
  }

  // Check if budget is exceeded
  static bool isBudgetExceeded(BudgetModel budget) {
    return budget.spent > budget.amount;
  }

  // Format budget period for display
  static String formatPeriod(String period) {
    switch (period.toLowerCase()) {
      case 'daily': return 'Daily';
      case 'weekly': return 'Weekly';
      case 'monthly': return 'Monthly';
      case 'quarterly': return 'Quarterly';
      case 'yearly': return 'Yearly';
      default: return 'Monthly';
    }
  }

  // Get color based on budget progress
  static Color getProgressColor(BudgetModel budget) {
    if (budget.status == 'inactive') return Colors.grey;
    if (budget.status == 'completed') return Colors.green;
    if (budget.status == 'exceeded' || budget.spent > budget.amount) return Colors.red;

    double progress = calculateProgress(budget);
    if (progress >= budget.notificationThreshold / 100) return Colors.amber;
    return Colors.green;
  }

  // Update budget spent amount and recalculate status
  static Future<Result<BudgetModel>> updateBudgetSpent(String budgetId, double newSpentAmount) async {
    try {
      final budgetResult = await getBudget(budgetId);
      if (!budgetResult.isSuccess) {
        return Result(isSuccess: false, message: budgetResult.message);
      }

      BudgetModel budget = budgetResult.results!;
      budget.spent = newSpentAmount;
      budget.remaining = budget.amount - newSpentAmount;

      // Auto-update status based on spent amount
      if (budget.status == 'active') {
        if (budget.spent >= budget.amount) {
          budget.status = 'exceeded';
        }
      }

      return await updateBudget(budget);
    } catch (e) {
      return Result(isSuccess: false, message: 'Failed to update budget spent: ${e.toString()}');
    }
  }
}