import 'package:flutter/material.dart';

/// Fixed list of expense categories and helpers used by the Budget feature.
/// Keep this list authoritative so budgets don't depend on dynamic category data.
const List<Map<String, dynamic>> fixedExpenseCategories = [
  {'name': 'Ăn uống', 'icon': Icons.restaurant},
  {'name': 'Xăng xe', 'icon': Icons.local_gas_station},
  {'name': 'Shopping', 'icon': Icons.shopping_bag},
  {'name': 'Giải trí', 'icon': Icons.movie},
  {'name': 'Y tế', 'icon': Icons.medical_services},
  {'name': 'Giáo dục', 'icon': Icons.school},
  {'name': 'Hóa đơn', 'icon': Icons.receipt},
  {'name': 'Điện nước', 'icon': Icons.bolt},
  {'name': 'Nhà cửa', 'icon': Icons.home},
  {'name': 'Quần áo', 'icon': Icons.checkroom},
  {'name': 'Làm đẹp', 'icon': Icons.face},
  {'name': 'Thể thao', 'icon': Icons.fitness_center},
  {'name': 'Du lịch', 'icon': Icons.flight},
  {'name': 'Điện thoại', 'icon': Icons.phone_android},
  {'name': 'Internet', 'icon': Icons.wifi},
  {'name': 'Khác', 'icon': Icons.more_horiz},
];

IconData iconForCategory(String categoryName) {
  final match = fixedExpenseCategories.firstWhere(
    (c) => c['name'] == categoryName,
    orElse: () => {'name': categoryName, 'icon': Icons.category},
  );
  return match['icon'] as IconData;
}

List<String> categoryNames() =>
    fixedExpenseCategories.map((c) => c['name'] as String).toList();
