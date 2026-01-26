import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/budget.dart';

// ============================================================================
// FIREBASE BUDGET REPOSITORY - Cloud storage for budgets
// ============================================================================

class FirebaseBudgetRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection path: users/{userId}/budgets/{budgetId}
  CollectionReference<Map<String, dynamic>> _getUserBudgetsRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  // ================= CREATE/UPDATE =================
  Future<void> saveBudget(String userId, Budget budget) async {
    try {
      final ref = _getUserBudgetsRef(userId);
      await ref.doc(budget.id).set(_budgetToMap(budget));
      print('✅ [Firebase] Saved budget: ${budget.id}');
    } catch (e) {
      print('❌ [Firebase] Error saving budget: $e');
      rethrow;
    }
  }

  // ================= BATCH SAVE =================
  Future<void> saveBudgets(String userId, List<Budget> budgets) async {
    if (budgets.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final ref = _getUserBudgetsRef(userId);

      for (var budget in budgets) {
        batch.set(ref.doc(budget.id), _budgetToMap(budget));
      }

      await batch.commit();
      print('✅ [Firebase] Saved ${budgets.length} budgets');
    } catch (e) {
      print('❌ [Firebase] Error batch saving budgets: $e');
      rethrow;
    }
  }

  // ================= READ =================
  Future<List<Budget>> getAllBudgets(String userId) async {
    try {
      final snapshot = await _getUserBudgetsRef(userId).get();
      return snapshot.docs.map((doc) => _budgetFromMap(doc.data())).toList();
    } catch (e) {
      print('❌ [Firebase] Error getting budgets: $e');
      return [];
    }
  }

  Future<Budget?> getBudgetById(String userId, String budgetId) async {
    try {
      final doc = await _getUserBudgetsRef(userId).doc(budgetId).get();
      if (!doc.exists) return null;
      return _budgetFromMap(doc.data()!);
    } catch (e) {
      print('❌ [Firebase] Error getting budget: $e');
      return null;
    }
  }

  // ================= DELETE =================
  Future<void> deleteBudget(String userId, String budgetId) async {
    try {
      await _getUserBudgetsRef(userId).doc(budgetId).delete();
      print('✅ [Firebase] Deleted budget: $budgetId');
    } catch (e) {
      print('❌ [Firebase] Error deleting budget: $e');
      rethrow;
    }
  }

  // ================= HELPERS =================
  Map<String, dynamic> _budgetToMap(Budget budget) {
    return {
      'id': budget.id,
      'category': budget.category,
      'limit': budget.limit,
      'startDate': budget.startDate.toIso8601String(),
      'endDate': budget.endDate.toIso8601String(),
      'periodType': budget.periodType.name,
      'note': budget.note,
      'walletId': budget.walletId,
    };
  }

  Budget _budgetFromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      category: map['category'],
      limit: (map['limit'] as num).toDouble(),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      periodType: BudgetPeriodType.values.firstWhere(
        (e) => e.name == map['periodType'],
        orElse: () => BudgetPeriodType.month,
      ),
      note: map['note'],
      walletId: map['walletId'],
    );
  }
}
