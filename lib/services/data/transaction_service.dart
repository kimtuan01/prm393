import 'package:hive/hive.dart';
import '../../models/transaction.dart';
import 'wallet_service.dart';
import '../firebase/sync_service.dart';

class TransactionService {
  static const String _boxName = 'transactions';
  Box<Transaction>? _box;
  final SyncService _syncService = SyncService();

  // ================= SINGLETON =================
  static final TransactionService _instance = TransactionService._internal();
  factory TransactionService() => _instance;
  TransactionService._internal();

  // ================= INIT =================
  Future<void> init() async {
    if (_box == null || !_box!.isOpen) {
      _box = await Hive.openBox<Transaction>(_boxName);
    }
  }

  // ================= ADD =================
  Future<void> addTransaction(Transaction transaction) async {
    await init();
    final walletService = WalletService();

    // Ensure transaction has walletId — do not auto-assign. UI must require selection.
    if (transaction.walletId == null || transaction.walletId!.isEmpty) {
      throw ArgumentError('Transaction.walletId must be set before saving');
    }

    // 🔥 HYBRID: Save locally first (offline-first approach)
    transaction.isSynced = false;
    transaction.updatedAt = DateTime.now();
    await _box!.put(transaction.id, transaction);

    // Apply to wallet balances
    await walletService.applyTransaction(transaction);

    // 🌐 CLOUD SYNC: Upload to Firebase asynchronously
    _syncService.syncAllPendingTransactions();
  }

  // ================= GET ALL (OPTIMIZED) =================
  Future<List<Transaction>> getAllTransactions({String? userId}) async {
    await init();
    if (userId == null || userId.isEmpty) {
      return [];
    }

    // 🔥 SNAPSHOT DATA → TRÁNH LIVE ITERABLE (FIX ANR)
    final List<Transaction> all = List<Transaction>.from(_box!.values);

    return all.where((t) => t.userId == userId).toList();
  }

  // ================= GET BY TYPE =================
  Future<List<Transaction>> getTransactionsByType(
    TransactionType type, {
    String? userId,
  }) async {
    await init();
    if (userId == null || userId.isEmpty) {
      return [];
    }

    final List<Transaction> all = List<Transaction>.from(_box!.values);

    return all.where((t) => t.type == type && t.userId == userId).toList();
  }

  // ================= GET BY DATE RANGE =================
  Future<List<Transaction>> getTransactionsByDateRange(
    DateTime start,
    DateTime end, {
    String? userId,
  }) async {
    await init();
    if (userId == null || userId.isEmpty) {
      return [];
    }

    final List<Transaction> all = List<Transaction>.from(_box!.values);

    return all.where((t) {
      return t.userId == userId &&
          t.date.isAfter(start.subtract(const Duration(days: 1))) &&
          t.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  // ================= CURRENT MONTH =================
  Future<List<Transaction>> getCurrentMonthTransactions({
    String? userId,
  }) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getTransactionsByDateRange(startOfMonth, endOfMonth, userId: userId);
  }

  // ================= UPDATE =================
  Future<void> updateTransaction(Transaction transaction) async {
    await init();
    final walletService = WalletService();

    final old = _box!.get(transaction.id);
    if (old != null) {
      await walletService.revertTransaction(old);
    }

    // Ensure walletId exists — caller must provide wallet selection explicitly.
    if (transaction.walletId == null || transaction.walletId!.isEmpty) {
      throw ArgumentError('Transaction.walletId must be set before updating');
    }

    // 🔥 HYBRID: Update locally with sync flag
    transaction.isSynced = false;
    transaction.updatedAt = DateTime.now();
    await _box!.put(transaction.id, transaction);

    await walletService.applyTransaction(transaction);

    // 🌐 CLOUD SYNC: Upload changes to Firebase
    _syncService.syncAllPendingTransactions();
  }

  // ================= DELETE =================
  Future<void> deleteTransaction(String id) async {
    await init();
    final walletService = WalletService();
    final tx = _box!.get(id);
    if (tx != null) {
      await walletService.revertTransaction(tx);

      // 🌐 CLOUD SYNC: Delete from Firebase asynchronously
      _syncService.deleteFromCloud(tx);
    }
    await _box!.delete(id);
  }

  // ================= TOTAL EXPENSE =================
  Future<double> getCurrentMonthExpense({String? userId}) async {
    final transactions = await getCurrentMonthTransactions(userId: userId);

    return transactions
        .where((t) => t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  // ================= TOTAL INCOME =================
  Future<double> getCurrentMonthIncome({String? userId}) async {
    final transactions = await getCurrentMonthTransactions(userId: userId);

    return transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  // ================= ADMIN =================
  Future<List<Transaction>> getAllTransactionsAdmin() async {
    await init();

    // snapshot để an toàn
    return List<Transaction>.from(_box!.values);
  }

  // ================= GET BY ID =================
  Future<Transaction?> getById(String id) async {
    await init();
    return _box!.get(id);
  }

  Future<List<Transaction>> getTransactionsByUserId(String userId) async {
    await init();

    final List<Transaction> all = List<Transaction>.from(_box!.values);

    return all.where((t) => t.userId == userId).toList();
  }

  /// Bulk rename category labels across all transactions.
  /// Returns the number of transactions updated.
  Future<int> bulkRenameCategory(String fromName, String toName) async {
    await init();
    final normalizedFrom = fromName.trim().toLowerCase();
    var updated = 0;
    final now = DateTime.now();

    for (final tx in List<Transaction>.from(_box!.values)) {
      if (tx.category.trim().toLowerCase() == normalizedFrom) {
        tx.category = toName;
        tx.isSynced = false;
        tx.updatedAt = now;
        await _box!.put(tx.id, tx);
        updated++;
      }
    }

    if (updated > 0) {
      _syncService.syncAllPendingTransactions();
    }

    return updated;
  }

  // ================= CLEAR =================
  Future<void> clearAll() async {
    await init();
    await _box!.clear();
  }

  // ================= CLOSE =================
  Future<void> close() async {
    await _box?.close();
  }
}
