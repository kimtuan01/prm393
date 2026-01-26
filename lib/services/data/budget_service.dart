import 'package:hive/hive.dart';
import '../../models/budget.dart';
import '../data/transaction_service.dart';
import '../../models/transaction.dart' as model;
import '../firebase/firebase_budget_repository.dart';

class BudgetService {
  BudgetService._();
  static final BudgetService _instance = BudgetService._();
  factory BudgetService() => _instance;

  final FirebaseBudgetRepository _firebaseRepo = FirebaseBudgetRepository();

  late Box<Map> _budgetsBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _budgetsBox = await Hive.openBox<Map>('budgets');

    // Migration: ensure every budget map contains a userId. Budgets without userId
    // are considered 'system' (global) and will not be surfaced in per-user listings.
    final keys = _budgetsBox.keys.toList();
    for (final key in keys) {
      final raw = _budgetsBox.get(key);
      if (raw == null) continue;
      if (!raw.containsKey('userId')) {
        raw['userId'] = 'system';
        await _budgetsBox.put(key, raw);
      }
    }

    _initialized = true;
  }

  /// Return budgets. If [userId] is provided, return only that user's budgets.
  List<Budget> getAllBudgets({String? userId}) {
    if (!_initialized) return [];
    final all = _budgetsBox.values
        .map((map) => _budgetFromMap(map.cast<String, dynamic>()))
        .toList();
    if (userId == null || userId.isEmpty) return all;
    return all.where((b) => (b.userId ?? '') == userId).toList();
  }

  Budget? getById(String id) {
    if (!_initialized) return null;
    final raw = _budgetsBox.get(id);
    if (raw == null) return null;
    return _budgetFromMap(raw.cast<String, dynamic>());
  }

  List<Budget> getBudgetsOverlapping(DateTime start, DateTime end) {
    return getAllBudgets().where((b) => b.overlaps(start, end)).toList();
  }

  Future<double> computeTotalSpentForBudget({
    required Budget budget,
    required TransactionService transactionService,
    required String? userId,
  }) async {
    final txs = await transactionService.getTransactionsByDateRange(
      budget.startDate,
      budget.endDate,
      userId: userId,
    );
    final spent = txs
        .where((t) => t.type == model.TransactionType.expense)
        .where((t) => (t.category) == budget.category)
        .where(
          (t) => budget.walletId == null || t.walletId == budget.walletId,
        ) // Filter by budget's wallet
        .fold<double>(0, (sum, t) => sum + t.amount);
    return spent;
  }

  bool existsOverlappingBudget({
    required String category,
    required DateTime start,
    required DateTime end,
    String? userId,
    String? walletId,
  }) {
    final budgets = getAllBudgets(userId: userId);
    return budgets.any(
      (b) =>
          b.category == category &&
          (walletId == null ||
              b.walletId == walletId) && // Same wallet (or null)
          !b.endDate.isBefore(start) &&
          !b.startDate.isAfter(end),
    );
  }

  Future<void> addBudget(Budget budget, {required String userId}) async {
    // Reject budgets that end in the past (date-only comparison)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final endDateOnly = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
    );
    if (endDateOnly.isBefore(todayDate)) {
      throw ArgumentError('Ngày kết thúc ngân sách không được trong quá khứ');
    }

    // Basic uniqueness: no duplicate category+overlap for same wallet (scoped to user)
    if (existsOverlappingBudget(
      category: budget.category,
      start: budget.startDate,
      end: budget.endDate,
      userId: userId,
      walletId: budget.walletId,
    )) {
      throw ArgumentError(
        'Đã có ngân sách cho danh mục này trong khoảng thời gian trùng lặp',
      );
    }
    if (!_initialized) await init();

    // Save locally with userId included
    final mapped = _budgetToMap(budget);
    mapped['userId'] = userId;
    await _budgetsBox.put(budget.id, mapped);

    // 🌐 CLOUD SYNC: Upload to Firebase asynchronously
    _firebaseRepo.saveBudget(userId, budget).catchError((e) {
      print('⚠️ [Budget] Cloud sync failed, will retry later: $e');
    });
  }

  Future<void> deleteBudget(String budgetId, {required String userId}) async {
    if (!_initialized) await init();
    await _budgetsBox.delete(budgetId);

    // 🌐 CLOUD SYNC: Delete from Firebase
    _firebaseRepo.deleteBudget(userId, budgetId).catchError((e) {
      print('⚠️ [Budget] Cloud delete failed: $e');
    });
  }

  Future<void> updateBudget(Budget budget, {required String userId}) async {
    // Reject budgets that end in the past (date-only comparison)
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final endDateOnly = DateTime(
      budget.endDate.year,
      budget.endDate.month,
      budget.endDate.day,
    );
    if (endDateOnly.isBefore(todayDate)) {
      throw ArgumentError('Ngày kết thúc ngân sách không được trong quá khứ');
    }

    // Check for overlapping budgets (excluding the current budget being updated) -- user scoped
    final overlapping = getAllBudgets(userId: userId).where(
      (b) =>
          b.id != budget.id && // Exclude current budget
          b.category == budget.category &&
          (budget.walletId == null ||
              b.walletId == budget.walletId) && // Same wallet
          !b.endDate.isBefore(budget.startDate) &&
          !b.startDate.isAfter(budget.endDate),
    );

    if (overlapping.isNotEmpty) {
      throw ArgumentError(
        'Đã có ngân sách cho danh mục này trong khoảng thời gian trùng lặp',
      );
    }

    if (!_initialized) await init();

    // Save locally with userId
    final mapped = _budgetToMap(budget);
    mapped['userId'] = userId;
    await _budgetsBox.put(budget.id, mapped);

    // 🌐 CLOUD SYNC: Upload to Firebase asynchronously
    _firebaseRepo.saveBudget(userId, budget).catchError((e) {
      print('⚠️ [Budget] Cloud sync failed: $e');
    });
  }

  Map<String, dynamic> _budgetToMap(Budget b) {
    return {
      'id': b.id,
      'category': b.category,
      'limit': b.limit,
      'startDate': b.startDate.toIso8601String(),
      'endDate': b.endDate.toIso8601String(),
      'periodType': b.periodType.toString(),
      'note': b.note,
      'walletId': b.walletId,
      'userId': b.userId, // may be null for system budgets
    };
  }

  Budget _budgetFromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'] as String,
      category: map['category'] as String,
      limit: (map['limit'] as num).toDouble(),
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      periodType: _parsePeriodType(map['periodType'] as String),
      note: map['note'] as String?,
      walletId: map['walletId'] as String?,
      userId: map['userId'] as String?,
    );
  }

  BudgetPeriodType _parsePeriodType(String str) {
    if (str.contains('month')) return BudgetPeriodType.month;
    if (str.contains('quarter')) return BudgetPeriodType.quarter;
    if (str.contains('year')) return BudgetPeriodType.year;
    return BudgetPeriodType.custom;
  }

  static BudgetPeriodType detectPeriodType(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    // Month
    if (s.day == 1 &&
        e.day == 0 &&
        e.month == s.month + 1 &&
        e.year == s.year) {
      return BudgetPeriodType.month;
    }
    // Quarter
    final qStartMonths = {1, 4, 7, 10};
    if (qStartMonths.contains(s.month) &&
        e.day == 0 &&
        e.month == s.month + 3 &&
        e.year == s.year) {
      return BudgetPeriodType.quarter;
    }
    // Year
    if (s.month == 1 &&
        s.day == 1 &&
        e.month == 12 &&
        e.day == 31 &&
        e.year == s.year) {
      return BudgetPeriodType.year;
    }
    return BudgetPeriodType.custom;
  }
}
