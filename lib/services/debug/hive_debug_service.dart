import 'package:hive/hive.dart';
import '../../models/user.dart';
import '../../models/transaction.dart' as model;

/// Service để debug và quản lý Hive database
class HiveDebugService {
  /// Kiểm tra tất cả tài khoản đã đăng ký
  static Future<List<User>> getAllUsers() async {
    try {
      final box = await Hive.openBox<User>('users');
      return box.values.toList();
    } catch (e) {
      print('Error getting users: $e');
      return [];
    }
  }

  /// In ra console tất cả tài khoản
  static Future<void> printAllUsers() async {
    final users = await getAllUsers();
    print('\n========== USERS IN HIVE ==========');
    print('Total: ${users.length} users');
    for (var i = 0; i < users.length; i++) {
      final user = users[i];
      print('\n[$i] User:');
      print('  - ID: ${user.id}');
      print('  - Name: ${user.fullName}');
      print('  - Email: ${user.email}');
      print('  - Verified: ${user.isVerified}');
      print('  - Created: ${user.createdAt}');
    }
    print('===================================\n');
  }

  /// Đếm số lượng users
  static Future<int> countUsers() async {
    final users = await getAllUsers();
    return users.length;
  }

  /// Lấy tất cả giao dịch
  static Future<List<model.Transaction>> getAllTransactions() async {
    try {
      final box = await Hive.openBox<model.Transaction>('transactions');
      return box.values.toList();
    } catch (e) {
      print('Error getting transactions: $e');
      return [];
    }
  }

  /// 🗑️ XÓA TOÀN BỘ DATA (LOCAL HIVE ONLY)
  /// Xóa tất cả boxes: users, transactions, wallets, budgets, categories, session
  static Future<void> deleteAllLocalData() async {
    try {
      print('🗑️ [Debug] Starting to delete all local data...');

      // Danh sách tất cả boxes cần xóa
      final boxNames = [
        'users',
        'transactions',
        'wallets',
        'budgets',
        'categories',
        'category_groups',
        'session',
        'app_settings',
      ];

      int deletedBoxes = 0;
      for (var boxName in boxNames) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            final box = Hive.box(boxName);
            await box.clear();
            print('  ✅ Cleared box: $boxName');
          } else {
            final box = await Hive.openBox(boxName);
            await box.clear();
            await box.close();
            print('  ✅ Cleared box: $boxName');
          }
          deletedBoxes++;
        } catch (e) {
          print('  ⚠️ Error clearing $boxName: $e');
        }
      }

      print('✅ [Debug] Deleted $deletedBoxes boxes successfully!');
      print(
        '📝 Note: Firebase cloud data NOT deleted. Clear manually from Firebase Console.',
      );
    } catch (e) {
      print('❌ [Debug] Error deleting data: $e');
      rethrow;
    }
  }

  /// 🗑️ XÓA CHỈ TRANSACTIONS (Hive local)
  static Future<void> deleteAllTransactions() async {
    try {
      final box = await Hive.openBox<model.Transaction>('transactions');
      await box.clear();
      print('✅ Deleted all transactions from Hive');
    } catch (e) {
      print('❌ Error deleting transactions: $e');
      rethrow;
    }
  }

  /// 🗑️ XÓA CHỈ USERS (Hive local)
  static Future<void> deleteAllUsers() async {
    try {
      final userBox = await Hive.openBox<User>('users');
      await userBox.clear();

      final sessionBox = await Hive.openBox('session');
      await sessionBox.clear();

      print('✅ Deleted all users and session from Hive');
    } catch (e) {
      print('❌ Error deleting users: $e');
      rethrow;
    }
  }

  /// In ra console tất cả giao dịch
  static Future<void> printAllTransactions() async {
    final transactions = await getAllTransactions();
    print('\n========== TRANSACTIONS IN HIVE ==========');
    print('Total: ${transactions.length} transactions');
    for (var i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      print('\n[$i] Transaction:');
      print('  - Category: ${t.category}');
      print('  - Amount: ${t.amount} ₫');
      print('  - Type: ${t.type}');
      print('  - Date: ${t.date}');
      print('  - Note: ${t.note ?? "N/A"}');
    }
    print('==========================================\n');
  }

  /// Xóa tất cả users (NGUY HIỂM!)
  static Future<void> clearAllUsers() async {
    final box = await Hive.openBox<User>('users');
    await box.clear();
    print('✅ Cleared all users');
  }

  /// Xóa tất cả transactions (NGUY HIỂM!)
  static Future<void> clearAllTransactions() async {
    final box = await Hive.openBox<model.Transaction>('transactions');
    await box.clear();
    print('✅ Cleared all transactions');
  }

  /// Xóa tất cả data (NGUY HIỂM!)
  static Future<void> clearAllData() async {
    await clearAllUsers();
    await clearAllTransactions();

    final sessionBox = await Hive.openBox('session');
    await sessionBox.clear();

    final preferencesBox = await Hive.openBox('preferences');
    await preferencesBox.clear();

    print('✅ Cleared all Hive data');
  }

  /// Lấy thông tin tổng quan
  static Future<Map<String, dynamic>> getDatabaseStats() async {
    final users = await getAllUsers();
    final transactions = await getAllTransactions();

    final sessionBox = await Hive.openBox('session');
    final preferencesBox = await Hive.openBox('preferences');

    return {
      'users': users.length,
      'transactions': transactions.length,
      'session_keys': sessionBox.keys.length,
      'preferences_keys': preferencesBox.keys.length,
      'total_expense': transactions
          .where((t) => t.type == model.TransactionType.expense)
          .fold<double>(0, (sum, t) => sum + t.amount),
      'total_income': transactions
          .where((t) => t.type == model.TransactionType.income)
          .fold<double>(0, (sum, t) => sum + t.amount),
    };
  }

  /// In thông tin tổng quan
  static Future<void> printDatabaseStats() async {
    final stats = await getDatabaseStats();
    print('\n========== DATABASE STATS ==========');
    print('Users: ${stats['users']}');
    print('Transactions: ${stats['transactions']}');
    print('Session keys: ${stats['session_keys']}');
    print('Preferences keys: ${stats['preferences_keys']}');
    print('Total Expense: ${stats['total_expense']} ₫');
    print('Total Income: ${stats['total_income']} ₫');
    print('Balance: ${stats['total_income'] - stats['total_expense']} ₫');
    print('====================================\n');
  }
}
