import 'package:flutter/material.dart';

/// Helper class untuk mapping category ke icon, color, dan format
class CategoryHelper {
  /// Map category name ke Material Icon (dengan dukungan sinonim)
  static IconData getCategoryIcon(String category) {
    final key = category.trim().toLowerCase();
    const iconMap = {
      // Expense categories
      'ăn uống': Icons.restaurant,
      'xăng xe': Icons.local_gas_station,
      'di chuyển': Icons.directions_car,
      'shopping': Icons.shopping_bag,
      'mua sắm': Icons.shopping_bag,
      'giải trí': Icons.movie,
      'y tế': Icons.medical_services,
      'sức khỏe': Icons.local_hospital,
      'giáo dục': Icons.school,
      'hóa đơn': Icons.receipt_long,
      'điện nước': Icons.bolt,
      'nhà cửa': Icons.home,
      'quần áo': Icons.checkroom,
      'làm đẹp': Icons.face,
      'thể thao': Icons.fitness_center,
      'du lịch': Icons.flight,
      'điện thoại': Icons.phone_android,
      'internet': Icons.wifi,
      'khác': Icons.more_horiz,

      // Income / other categories
      'lương': Icons.attach_money,
      'thưởng': Icons.card_giftcard,
      'đầu tư': Icons.trending_up,
      'vay': Icons.swap_horiz,
      'nợ': Icons.swap_horiz,
      'loan': Icons.swap_horiz,
    };
    return iconMap[key] ?? Icons.category;
  }

  /// Map category name ke Color (dengan dukungan sinonim)
  static Color getCategoryColor(String category) {
    final key = category.trim().toLowerCase();
    const colorMap = {
      // Expense categories
      'ăn uống': Colors.orange,
      'xăng xe': Colors.blueGrey,
      'di chuyển': Colors.blueGrey,
      'shopping': Colors.pink,
      'mua sắm': Colors.pink,
      'giải trí': Colors.purple,
      'y tế': Colors.red,
      'sức khỏe': Colors.red,
      'giáo dục': Colors.green,
      'hóa đơn': Colors.deepOrange,
      'điện nước': Colors.amber,
      'nhà cửa': Colors.brown,
      'quần áo': Colors.indigo,
      'làm đẹp': Colors.pinkAccent,
      'thể thao': Colors.greenAccent,
      'du lịch': Colors.lightBlue,
      'điện thoại': Colors.teal,
      'internet': Colors.cyan,
      'khác': Colors.grey,

      // Income / other categories
      'lương': Colors.teal,
      'thưởng': Colors.amber,
      'đầu tư': Colors.indigo,
      'vay': Colors.blue,
      'nợ': Colors.blue,
      'loan': Colors.blue,
    };
    return colorMap[key] ?? Colors.grey;
  }

  /// Get category display name (capitalize first letter)
  static String getDisplayName(String category) {
    if (category.isEmpty) return category;
    return category[0].toUpperCase() + category.substring(1);
  }

  /// Get all available categories (gabungan lengkap)
  static List<String> getAllCategories() {
    return [
      // Expenses
      'Ăn uống',
      'Xăng xe',
      'Shopping',
      'Giải trí',
      'Y tế',
      'Giáo dục',
      'Hóa đơn',
      'Điện nước',
      'Nhà cửa',
      'Quần áo',
      'Làm đẹp',
      'Thể thao',
      'Du lịch',
      'Điện thoại',
      'Internet',
      'Khác',

      // Incomes / other
      'Lương',
      'Thưởng',
      'Đầu tư',
    ];
  }
}
