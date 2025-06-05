import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 5)
class CategoryModel {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  String? icon;

  @HiveField(3)
  late String type;

  @HiveField(4)
  String? colourCode;

  @HiveField(5)
  String? description;

  @HiveField(6)
  late int isSystem;

  static String categoryBox = 'categories';

  get uuid => null;

  static CategoryModel fromMap(Map<String, dynamic> category) {
    var categoryModel = CategoryModel();
    categoryModel.id = category['id'];
    categoryModel.name = category['name'];
    categoryModel.icon = category['icon'];
    categoryModel.type = category['type'];

    // Handle null and type conversion for colour_code
    if (category['colour_code'] != null) {
      // If string, keep as string, if number convert to string
      categoryModel.colourCode = category['colour_code'].toString();
    } else {
      categoryModel.colourCode = null;
    }

    categoryModel.description = category['description'];
    categoryModel.isSystem = category['is_system'] is bool
        ? (category['is_system'] ? 1 : 0)
        : (category['is_system'] ?? 0);  // Handle null

    return categoryModel;
  }

  @override
  String toString() => name;
}