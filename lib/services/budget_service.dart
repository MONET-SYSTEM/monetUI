// lib/services/budget_service.dart

import 'package:hive/hive.dart';
import 'package:monet/models/budget.dart';

class BudgetService {
  static const _boxName = BudgetModel.boxName;
  static Box<BudgetModel>? _box;

  static Future<Box<BudgetModel>> _openBox() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<BudgetModel>(_boxName);
    }
    return _box!;
  }

  static Future<BudgetModel> save(BudgetModel budget) async {
    final box = await _openBox();
    await box.put(budget.id, budget);
    return budget;
  }

  static Future<List<BudgetModel>> saveAll(List<BudgetModel> budgets) async {
    final box = await _openBox();
    await box.clear();
    for (var b in budgets) {
      if (b.id.isNotEmpty) {
        await box.put(b.id, b);
      }
    }
    return budgets;
  }

  static Future<List<BudgetModel>> getAll() async {
    final box = await _openBox();
    return box.values.toList();
  }

  static Future<BudgetModel?> getById(String id) async {
    final box = await _openBox();
    return box.get(id);
  }

  static Future<bool> delete(String id) async {
    final box = await _openBox();
    if (box.containsKey(id)) {
      await box.delete(id);
      return true;
    }
    return false;
  }

  static Future<void> deleteAll() async {
    final box = await _openBox();
    await box.clear();
  }
}
