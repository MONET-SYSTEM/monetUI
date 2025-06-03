import 'package:hive/hive.dart';
import 'package:monet/models/category.dart';

class CategoryService {
  static Future<CategoryModel> create(Map<String, dynamic> category) async {
    final categoryBox = await Hive.openBox<CategoryModel>(CategoryModel.categoryBox);

    var categoryModel = CategoryModel.fromMap(category);
    await categoryBox.put(categoryModel.id, categoryModel);

    return categoryModel;
  }

  static Future<List<CategoryModel>> createCategories(List categories) async {
    final categoryBox = await Hive.openBox<CategoryModel>(CategoryModel.categoryBox);
    await categoryBox.clear();

    List<CategoryModel> categoryModels = [];

    for (var category in categories) {
      var categoryModel = CategoryModel.fromMap(category);
      await categoryBox.put(categoryModel.id, categoryModel);
      categoryModels.add(categoryModel);
    }

    return categoryModels;
  }

  static Future<List<CategoryModel>> getCategories() async {
    final categoryBox = await Hive.openBox<CategoryModel>(CategoryModel.categoryBox);
    return categoryBox.values.toList();
  }

  static Future<List<CategoryModel>> getCategoriesByType(String type) async {
    final categoryBox = await Hive.openBox<CategoryModel>(CategoryModel.categoryBox);
    return categoryBox.values.where((category) => category.type == type).toList();
  }

  static Future<CategoryModel?> getCategory(String id) async {
    final categoryBox = await Hive.openBox<CategoryModel>(CategoryModel.categoryBox);
    return categoryBox.get(id);
  }

  static Future<void> clearCategories() async {
    final categoryBox = await Hive.openBox<CategoryModel>(CategoryModel.categoryBox);
    await categoryBox.clear();
  }
}