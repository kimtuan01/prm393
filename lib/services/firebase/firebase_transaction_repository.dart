import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/transaction.dart' as model;

// ============================================================================
// FIREBASE TRANSACTION REPOSITORY - Cloud storage for transactions
// ============================================================================

class FirebaseTransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection path: users/{userId}/transactions/{transactionId}
  CollectionReference<Map<String, dynamic>> _getUserTransactionsRef(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');
  }

  // ================= CREATE/UPDATE =================
  Future<void> saveTransaction(model.Transaction transaction) async {
    try {
      final ref = _getUserTransactionsRef(transaction.userId);
      await ref.doc(transaction.id).set(transaction.toJson());
      print('✅ [Firebase] Saved transaction: ${transaction.id}');
    } catch (e) {
      print('❌ [Firebase] Error saving transaction: $e');
      rethrow;
    }
  }

  // ================= BATCH SAVE =================
  Future<void> saveTransactions(List<model.Transaction> transactions) async {
    if (transactions.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final userId = transactions.first.userId;
      final ref = _getUserTransactionsRef(userId);

      for (var transaction in transactions) {
        batch.set(ref.doc(transaction.id), transaction.toJson());
      }

      await batch.commit();
      print('✅ [Firebase] Saved ${transactions.length} transactions');
    } catch (e) {
      print('❌ [Firebase] Error batch saving: $e');
      rethrow;
    }
  }

  // ================= GET ALL =================
  Future<List<model.Transaction>> getAllTransactions(String userId) async {
    try {
      final snapshot = await _getUserTransactionsRef(userId).get();

      return snapshot.docs.map((doc) {
        return model.Transaction.fromJson(doc.data());
      }).toList();
    } catch (e) {
      print('❌ [Firebase] Error getting transactions: $e');
      return [];
    }
  }

  // ================= GET BY DATE RANGE =================
  Future<List<model.Transaction>> getTransactionsByDateRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _getUserTransactionsRef(userId)
          .where('date', isGreaterThanOrEqualTo: start.toIso8601String())
          .where('date', isLessThanOrEqualTo: end.toIso8601String())
          .get();

      return snapshot.docs.map((doc) {
        return model.Transaction.fromJson(doc.data());
      }).toList();
    } catch (e) {
      print('❌ [Firebase] Error getting transactions by date: $e');
      return [];
    }
  }

  // ================= GET UPDATED SINCE =================
  /// Get transactions updated after a specific time (for incremental sync)
  Future<List<model.Transaction>> getUpdatedSince(
    String userId,
    DateTime since,
  ) async {
    try {
      final snapshot = await _getUserTransactionsRef(
        userId,
      ).where('updatedAt', isGreaterThan: since.toIso8601String()).get();

      return snapshot.docs.map((doc) {
        return model.Transaction.fromJson(doc.data());
      }).toList();
    } catch (e) {
      print('❌ [Firebase] Error getting updated transactions: $e');
      return [];
    }
  }

  // ================= DELETE =================
  Future<void> deleteTransaction(String userId, String transactionId) async {
    try {
      await _getUserTransactionsRef(userId).doc(transactionId).delete();
      print('✅ [Firebase] Deleted transaction: $transactionId');
    } catch (e) {
      print('❌ [Firebase] Error deleting transaction: $e');
      rethrow;
    }
  }

  // ================= STREAM (REAL-TIME) =================
  /// Listen to real-time changes (optional feature for live sync)
  Stream<List<model.Transaction>> watchTransactions(String userId) {
    return _getUserTransactionsRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return model.Transaction.fromJson(doc.data());
      }).toList();
    });
  }

  // ================= DELETE ALL FOR USER =================
  Future<void> deleteAllTransactions(String userId) async {
    try {
      final snapshot = await _getUserTransactionsRef(userId).get();
      final batch = _firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ [Firebase] Deleted all transactions for user: $userId');
    } catch (e) {
      print('❌ [Firebase] Error deleting all transactions: $e');
      rethrow;
    }
  }
}
