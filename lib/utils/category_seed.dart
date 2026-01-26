import '../services/data/transaction_service.dart';
import 'package:uuid/uuid.dart';
import '../models/category_group.dart';
import '../services/data/category_group_service.dart';

class CategorySeed {
  static String _normalizeCategoryName(String name) {
    final normalized = name.trim().toLowerCase();
    const canonicalMap = {
      'du lịch & nghỉ dưỡng': 'du lịch',
      'gia đình & trẻ em': 'gia đình',
      'hóa đơn & tiện ích': 'hóa đơn',
      'quần áo & phụ kiện': 'quần áo',
      'thể thao & fitness': 'thể thao',
      'y tế & sức khỏe': 'y tế',
    };
    return canonicalMap[normalized] ?? normalized;
  }

  // Shared mapping of variant names -> canonical normalized name.
  // Reused by deduplication and cleanup routines to keep behaviour consistent.
  static const Map<String, String> _canonicalMap = {
    'du lịch & nghỉ dưỡng': 'du lịch',
    'gia đình & trẻ em': 'gia đình',
    'hóa đơn & tiện ích': 'hóa đơn',
    'quần áo & phụ kiện': 'quần áo',
    'thể thao & fitness': 'thể thao',
    'y tế & sức khỏe': 'y tế',
  };

  /// Seeds system category groups if they are missing.
  ///
  /// Returns the list of names that were actually added. Useful for admin
  /// feedback UI to show what was newly created.
  static Future<List<String>> seedIfNeeded([
    CategoryGroupService? service,
  ]) async {
    final serviceToUse = service ?? CategoryGroupService();
    final uuid = Uuid();

    // Existing groups
    final existing = await serviceToUse.getAll();
    final existingSet = existing
        .map((e) => '${e.type.index}::${_normalizeCategoryName(e.name)}')
        .toSet();

    final added = <String>[];

    // Define system defaults per request
    final defaults = <CategoryGroup>[
      // ===== EXPENSE (System) - Sắp xếp alphabetically, "Khác" ở cuối =====
      CategoryGroup(
        id: uuid.v4(),
        name: 'Ăn uống',
        type: CategoryType.expense,
        iconKey: 'food',
        colorValue: 0xFF4CAF50,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Đi lại',
        type: CategoryType.expense,
        iconKey: 'car',
        colorValue: 0xFFFF9800,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Du lịch',
        type: CategoryType.expense,
        iconKey: 'travel',
        colorValue: 0xFF03A9F4,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Gia đình',
        type: CategoryType.expense,
        iconKey: 'family',
        colorValue: 0xFF795548,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Giáo dục',
        type: CategoryType.expense,
        iconKey: 'education',
        colorValue: 0xFF3F51B5,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Giải trí',
        type: CategoryType.expense,
        iconKey: 'entertainment',
        colorValue: 0xFFFFC107,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Hóa đơn',
        type: CategoryType.expense,
        iconKey: 'bill',
        colorValue: 0xFFFF5722,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Làm đẹp',
        type: CategoryType.expense,
        iconKey: 'beauty',
        colorValue: 0xFFFF4081,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Mua sắm',
        type: CategoryType.expense,
        iconKey: 'shopping',
        colorValue: 0xFF9C27B0,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Nhà cửa',
        type: CategoryType.expense,
        iconKey: 'home',
        colorValue: 0xFF8BC34A,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Phí & Lệ phí',
        type: CategoryType.expense,
        iconKey: 'fee',
        colorValue: 0xFF607D8B,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Quần áo',
        type: CategoryType.expense,
        iconKey: 'clothing',
        colorValue: 0xFFE91E63,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Thể thao',
        type: CategoryType.expense,
        iconKey: 'fitness',
        colorValue: 0xFF00BCD4,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Y tế',
        type: CategoryType.expense,
        iconKey: 'health',
        colorValue: 0xFF4DD0E1,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      // "Khác" ở dưới cùng
      CategoryGroup(
        id: uuid.v4(),
        name: 'Khác (Khoản chi)',
        type: CategoryType.expense,
        iconKey: 'other',
        colorValue: 0xFF9E9E9E,
        isSystem: true,
        createdAt: DateTime.now(),
      ),

      // ===== INCOME (System) - Sắp xếp alphabetically, "Khác" ở cuối =====
      CategoryGroup(
        id: uuid.v4(),
        name: 'Đầu tư',
        type: CategoryType.income,
        iconKey: 'investment',
        colorValue: 0xFF673AB7,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Lương',
        type: CategoryType.income,
        iconKey: 'salary',
        colorValue: 0xFF2196F3,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Thưởng',
        type: CategoryType.income,
        iconKey: 'bonus',
        colorValue: 0xFF00BCD4,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      // "Khác" ở dưới cùng
      CategoryGroup(
        id: uuid.v4(),
        name: 'Khác (Khoản thu)',
        type: CategoryType.income,
        iconKey: 'other_income',
        colorValue: 0xFF9E9E9E,
        isSystem: true,
        createdAt: DateTime.now(),
      ),

      // ===== LOANS/DEBT (System) - Vay / Nợ categories =====
      CategoryGroup(
        id: uuid.v4(),
        name: 'Vay',
        type: CategoryType.loan,
        iconKey: 'loan',
        colorValue: 0xFF2196F3,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Nợ',
        type: CategoryType.loan,
        iconKey: 'debt',
        colorValue: 0xFF1976D2,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Cho vay',
        type: CategoryType.loan,
        iconKey: 'collect',
        colorValue: 0xFF4CAF50,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
      CategoryGroup(
        id: uuid.v4(),
        name: 'Thu hồi nợ',
        type: CategoryType.loan,
        iconKey: 'repay',
        colorValue: 0xFF43A047,
        isSystem: true,
        createdAt: DateTime.now(),
      ),
    ];

    for (final c in defaults) {
      final key = '${c.type.index}::${_normalizeCategoryName(c.name)}';
      if (!existingSet.contains(key)) {
        // add only missing defaults
        try {
          await serviceToUse.add(c);
          added.add(c.name);
        } catch (_) {
          // ignore if already exists due to race/edge case
        }
      }
    }

    return added;
  }

  /// Remove duplicate categories per type (keeps a single canonical category per normalized name).
  /// Deduplication rules:
  /// - Prefer categories with `isSystem == true` as the canonical keeper.
  /// - If multiple system categories exist with the same name, keep the oldest (by createdAt) and remove the rest (force delete).
  /// - Non-system duplicates are deleted and system duplicates are force-deleted when necessary.
  /// Returns the number of deleted categories.
  static Future<int> deduplicateCategories([
    CategoryGroupService? service,
  ]) async {
    final svc = service ?? CategoryGroupService();
    final all = await svc.getAll();

    // Use shared canonical map declared above
    final canonicalMap = _canonicalMap;

    // Group by (type, canonical_normalized_name)
    final Map<String, List<CategoryGroup>> groups = {};
    for (final cat in all) {
      final normalized = cat.name.trim().toLowerCase();
      final canonical = canonicalMap[normalized] ?? normalized;
      final key = '${cat.type.index}::$canonical';
      groups.putIfAbsent(key, () => []).add(cat);
    }

    var deleted = 0;
    final txService = TransactionService();
    await txService.init();

    for (final entry in groups.entries) {
      final list = entry.value;
      if (list.length <= 1) continue;

      // Determine canonical keeper: prefer system categories first, then older createdAt
      list.sort((a, b) {
        if (a.isSystem != b.isSystem) return a.isSystem ? -1 : 1;
        return a.createdAt.compareTo(b.createdAt);
      });

      final keeper = list.first;
      final toRemove = list.sublist(1);

      for (final rem in toRemove) {
        try {
          // If the names differ, update transactions to point to the keeper's name
          if (rem.name.trim() != keeper.name.trim()) {
            await txService.bulkRenameCategory(rem.name, keeper.name);
          }

          // Force delete duplicates (including system duplicates if present)
          await svc.delete(rem.id, force: true);
          deleted++;
        } catch (_) {
          // ignore deletion failures
        }
      }
    }

    return deleted;
  }

  /// Clean up invalid income categories (expense categories mistakenly typed as income).
  /// Removes known invalid names; force delete so mislabeled system entries are corrected as well.
  static Future<int> cleanupInvalidIncomeCategories([
    CategoryGroupService? service,
  ]) async {
    final svc = service ?? CategoryGroupService();
    final all = await svc.getAll();

    // List of expense category names that shouldn't exist in income type
    final invalidIncomeNames = {
      'du lịch',
      'gia đình',
      'hóa đơn',
      'nhà ở',
      'quần áo',
      'thể thao',
      'y tế',
    };

    var deletedCount = 0;
    final incomeCategories = all
        .where((c) => c.type == CategoryType.income)
        .toList();

    for (final cat in incomeCategories) {
      final normalized = cat.name.trim().toLowerCase();
      if (invalidIncomeNames.contains(normalized)) {
        try {
          await svc.delete(cat.id, force: true);
          deletedCount++;
        } catch (_) {
          // ignore
        }
      }
    }

    return deletedCount;
  }

  /// Clean up invalid expense categories (outdated/renamed categories).
  /// Removes known outdated/combined names; force delete to ensure cleanup.
  static Future<int> cleanupInvalidExpenseCategories([
    CategoryGroupService? service,
  ]) async {
    final svc = service ?? CategoryGroupService();
    final all = await svc.getAll();

    var deletedCount = 0;
    final expenseCategories = all
        .where((c) => c.type == CategoryType.expense)
        .toList();

    // Known combined/outdated names we want removed (they should be
    // normalized/deduplicated instead). These keys are normalized
    // lowercase forms matching the canonical map variants.
    final invalidExpenseNames = {
      'du lịch & nghỉ dưỡng',
      'gia đình & trẻ em',
      'hóa đơn & tiện ích',
      'quần áo & phụ kiện',
      'thể thao & fitness',
      'y tế & sức khỏe',
    };

    for (final cat in expenseCategories) {
      final normalized = cat.name.trim().toLowerCase();
      if (invalidExpenseNames.contains(normalized)) {
        try {
          await svc.delete(cat.id, force: true);
          deletedCount++;
        } catch (_) {
          // ignore
        }
      }
    }

    return deletedCount;
  }

  /// Run a full cleanup: deduplicate, remove invalid names, and reseed missing defaults.
  /// Returns a summary map with counts: { 'deduped': n, 'removed_income': m, 'removed_expense': k, 'reseeded': [..] }
  static Future<Map<String, dynamic>> runFullCleanup([
    CategoryGroupService? service,
  ]) async {
    final svc = service ?? CategoryGroupService();

    final deduped = await deduplicateCategories(svc);
    final removedIncome = await cleanupInvalidIncomeCategories(svc);
    final removedExpense = await cleanupInvalidExpenseCategories(svc);

    // Ensure canonical defaults exist after cleanup
    final reseeded = await seedIfNeeded(svc);

    return {
      'deduped': deduped,
      'removed_income': removedIncome,
      'removed_expense': removedExpense,
      'reseeded': reseeded,
    };
  }

  /// Reset system categories (DEV only): delete and reseed.
  /// Returns list of names that were removed and re-added.
  static Future<List<String>> resetSystemCategoriesForDev([
    CategoryGroupService? service,
  ]) async {
    final svc = service ?? CategoryGroupService();
    final existing = await svc.getAll();
    final removed = existing
        .where((e) => e.isSystem)
        .map((e) => e.name)
        .toList();

    // Delete system categories
    await svc.deleteSystemCategories();

    // Reseed
    final added = await seedIfNeeded(svc);

    return removed..addAll(added);
  }
}
