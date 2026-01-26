import 'package:hive/hive.dart';

part 'category_group.g.dart';

@HiveType(typeId: 10)
class CategoryGroup extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name; // Ăn uống, Lương, Di chuyển...

  @HiveField(2)
  CategoryType type; // income / expense

  @HiveField(3)
  String iconKey; // food, salary, transport...

  @HiveField(4)
  int colorValue; // 0xFF4CAF50

  @HiveField(5)
  bool isSystem; // true = mặc định, false = user tạo

  @HiveField(6)
  DateTime createdAt;

  CategoryGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorValue,
    this.isSystem = false,
    required this.createdAt,
  });
}

@HiveType(typeId: 11)
enum CategoryType {
  @HiveField(0)
  expense,

  @HiveField(1)
  income,

  @HiveField(2)
  loan,
}
