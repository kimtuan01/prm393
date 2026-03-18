import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive/hive.dart';
import '../../models/transaction.dart';
import '../../models/budget.dart';
import '../../models/wallet.dart';
import '../../models/category_group.dart';
import '../../models/user.dart';
import '../data/wallet_service.dart';
import 'firebase_transaction_repository.dart';
import 'firebase_budget_repository.dart';
import 'firebase_wallet_repository.dart';
import 'firebase_category_repository.dart';
import 'firebase_user_repository.dart';

// ============================================================================
// SYNC SERVICE - Auto sync between Hive (local) and Firebase (cloud)
// ============================================================================

class SyncService {
  static const String _pendingDeleteBoxName = 'pending_transaction_deletes';
  final FirebaseTransactionRepository _transactionRepo =
      FirebaseTransactionRepository();
  final FirebaseBudgetRepository _budgetRepo = FirebaseBudgetRepository();
  final FirebaseWalletRepository _walletRepo = FirebaseWalletRepository();
  final FirebaseCategoryRepository _categoryRepo = FirebaseCategoryRepository();
  final FirebaseUserRepository _userRepo = FirebaseUserRepository();
  Timer? _syncTimer;
  bool _isSyncing = false;

  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  // ================= AUTO SYNC =================
  void startAutoSync(
    String userId, {
    Duration interval = const Duration(minutes: 5),
  }) {
    stopAutoSync(); // Stop existing timer if any

    _syncTimer = Timer.periodic(interval, (_) {
      fullSync(userId);
    });

    print(
      '✅ [Sync] Auto sync started for user $userId (every ${interval.inMinutes} minutes)',
    );
  }

  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    print('⏹️ [Sync] Auto sync stopped');
  }

  // ================= CHECK INTERNET =================
  Future<bool> hasInternet() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      // connectivity_plus 6.x returns List<ConnectivityResult>
      return !connectivityResult.contains(ConnectivityResult.none);
    } catch (e) {
      print('❌ [Sync] Error checking connectivity: $e');
      return false;
    }
  }

  Future<Box<Map>> _openPendingDeleteBox() async {
    if (Hive.isBoxOpen(_pendingDeleteBoxName)) {
      return Hive.box<Map>(_pendingDeleteBoxName);
    }
    return Hive.openBox<Map>(_pendingDeleteBoxName);
  }

  String _pendingDeleteKey(String userId, String transactionId) {
    return '$userId::$transactionId';
  }

  Future<void> queueDeleteTransaction(String userId, String transactionId) async {
    final box = await _openPendingDeleteBox();
    await box.put(_pendingDeleteKey(userId, transactionId), {
      'userId': userId,
      'transactionId': transactionId,
      'deletedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Set<String>> _getPendingDeleteIds(String userId) async {
    final box = await _openPendingDeleteBox();
    final ids = <String>{};

    for (final value in box.values) {
      final uid = value['userId'] as String? ?? '';
      if (uid != userId) continue;
      final txId = value['transactionId'] as String? ?? '';
      if (txId.isNotEmpty) {
        ids.add(txId);
      }
    }

    return ids;
  }

  Future<void> _syncPendingDeletes({String? userId}) async {
    final box = await _openPendingDeleteBox();

    final entries = box.toMap().entries.where((entry) {
      final value = entry.value;
      final uid = value['userId'] as String? ?? '';
      return userId == null || uid == userId;
    }).toList();

    if (entries.isEmpty) {
      return;
    }

    print('🧹 [Sync] Processing ${entries.length} pending deletes...');

    for (final entry in entries) {
      final value = entry.value;
      final uid = value['userId'] as String? ?? '';
      final txId = value['transactionId'] as String? ?? '';

      if (uid.isEmpty || txId.isEmpty) {
        await box.delete(entry.key);
        continue;
      }

      try {
        await _transactionRepo.deleteTransaction(uid, txId);
        await box.delete(entry.key);
        print('🗑️ [Sync] Deleted $txId from cloud (queued)');
      } catch (e) {
        print('❌ [Sync] Pending delete failed for $txId: $e');
      }
    }
  }

  // ================= SYNC PENDING TRANSACTIONS =================
  Future<void> syncAllPendingTransactions() async {
    if (_isSyncing) {
      print('⏳ [Sync] Already syncing, skipping...');
      return;
    }

    if (!await hasInternet()) {
      print('📶 [Sync] No internet, skipping sync');
      return;
    }

    _isSyncing = true;

    try {
      await _syncPendingDeletes();

      final box = await Hive.openBox<Transaction>('transactions');
      final pendingTransactions = box.values.where((t) => !t.isSynced).toList();

      if (pendingTransactions.isEmpty) {
        print('✅ [Sync] No pending transactions to sync');
        return;
      }

      print('🔄 [Sync] Syncing ${pendingTransactions.length} transactions...');

      // Group by userId
      final Map<String, List<Transaction>> groupedByUser = {};
      for (var trans in pendingTransactions) {
        groupedByUser.putIfAbsent(trans.userId, () => []).add(trans);
      }

      // Sync each user's transactions
      for (var entry in groupedByUser.entries) {
        try {
          await _transactionRepo.saveTransactions(entry.value);

          // Mark as synced in Hive
          for (var trans in entry.value) {
            trans.isSynced = true;
            await trans.save();
          }
        } catch (e) {
          print('❌ [Sync] Error syncing user ${entry.key}: $e');
        }
      }

      print('✅ [Sync] Sync completed successfully');
    } catch (e) {
      print('❌ [Sync] Error during sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ================= SYNC ALL USER DATA =================
  /// Sync all data types (budgets, wallets, categories) for a user
  Future<void> syncAllUserData(String userId) async {
    if (!await hasInternet()) {
      print('📶 [Sync] No internet, skipping sync');
      return;
    }

    print('🔄 [Sync] Syncing all data for user $userId...');

    try {
      // Sync Budgets
      final budgetBox = await Hive.openBox<Map>('budgets');
      final budgets = budgetBox.values
          .map(
            (map) => Budget(
              id: map['id'] as String,
              category: map['category'] as String,
              limit: (map['limit'] as num).toDouble(),
              startDate: DateTime.parse(map['startDate'] as String),
              endDate: DateTime.parse(map['endDate'] as String),
              periodType: _parseBudgetPeriodType(map['periodType'] as String),
              note: map['note'] as String?,
              walletId: map['walletId'] as String?,
              userId: map['userId'] as String?,
            ),
          )
          .where((b) => (b.userId ?? '') == userId)
          .toList();
      if (budgets.isNotEmpty) {
        await _budgetRepo.saveBudgets(userId, budgets);
        print('✅ [Sync] Synced ${budgets.length} budgets');
      }

      // Sync Wallets
      final walletBox = await Hive.openBox<Wallet>('wallets');
      final wallets = walletBox.values
          .where((w) => w.userId == userId)
          .toList();
      if (wallets.isNotEmpty) {
        await _walletRepo.saveWallets(userId, wallets);
        print('✅ [Sync] Synced ${wallets.length} wallets');
      }

      // Sync Categories
      final categoryBox = await Hive.openBox<CategoryGroup>('category_groups');
      final categories = categoryBox.values.toList();
      if (categories.isNotEmpty) {
        await _categoryRepo.saveCategories(userId, categories);
        print('✅ [Sync] Synced ${categories.length} categories');
      }

      // Sync User Profile
      final userBox = await Hive.openBox<User>('users');
      final user = userBox.get(userId);
      if (user != null) {
        await _userRepo.saveUser(user);
        print('✅ [Sync] Synced user profile');
      }

      print('✅ [Sync] All user data synced successfully');
    } catch (e) {
      print('❌ [Sync] Error syncing user data: $e');
    }
  }

  BudgetPeriodType _parseBudgetPeriodType(String str) {
    if (str.contains('month')) return BudgetPeriodType.month;
    if (str.contains('quarter')) return BudgetPeriodType.quarter;
    if (str.contains('year')) return BudgetPeriodType.year;
    return BudgetPeriodType.custom;
  }

  // ================= DOWNLOAD FROM CLOUD =================
  /// Download all transactions from Firebase to Hive (initial sync)
  Future<void> downloadFromCloud(String userId) async {
    if (!await hasInternet()) {
      print('📶 [Sync] No internet, cannot download from cloud');
      return;
    }

    try {
      print('⬇️ [Sync] Downloading transactions for user $userId...');

      final cloudTransactions = await _transactionRepo.getAllTransactions(
        userId,
      );
      final box = await Hive.openBox<Transaction>('transactions');
      final cloudIds = cloudTransactions.map((t) => t.id).toSet();
      final pendingDeleteIds = await _getPendingDeleteIds(userId);

      print('📥 [Sync] Downloaded ${cloudTransactions.length} transactions');

      // Merge with local data (conflict resolution: newest wins)
      for (var cloudTrans in cloudTransactions) {
        // Ignore transactions pending deletion on this device to avoid resurrecting them.
        if (pendingDeleteIds.contains(cloudTrans.id)) {
          continue;
        }

        final localTrans = box.get(cloudTrans.id);

        if (localTrans == null) {
          // New transaction from cloud
          cloudTrans.isSynced = true;
          await box.put(cloudTrans.id, cloudTrans);
        } else {
          // Conflict: compare updatedAt
          if (cloudTrans.updatedAt.isAfter(localTrans.updatedAt)) {
            // Cloud version is newer
            cloudTrans.isSynced = true;
            await box.put(cloudTrans.id, cloudTrans);
            print('🔄 [Sync] Updated ${cloudTrans.id} from cloud');
          }
        }
      }

      // If a transaction is missing from cloud but exists locally as synced,
      // treat it as deleted on another device and remove it locally.
      var removedCount = 0;
      final localUserTransactions = box.values
          .where((t) => t.userId == userId)
          .toList();

      for (final localTrans in localUserTransactions) {
        final missingOnCloud = !cloudIds.contains(localTrans.id);
        if (missingOnCloud && localTrans.isSynced) {
          await box.delete(localTrans.id);
          removedCount++;
          print('🗑️ [Sync] Removed ${localTrans.id} (deleted from cloud)');
        }
      }

      if (removedCount > 0) {
        final walletService = WalletService();
        final remaining = box.values.where((t) => t.userId == userId).toList();
        await walletService.recomputeAllBalances(remaining);
        print('✅ [Sync] Removed $removedCount stale local transactions');
      }

      print('✅ [Sync] Download completed');
    } catch (e) {
      print('❌ [Sync] Error downloading from cloud: $e');
    }
  }

  // ================= DOWNLOAD ALL USER DATA FROM CLOUD =================
  /// Download all data types from Firebase to Hive
  Future<void> downloadAllUserData(String userId) async {
    if (!await hasInternet()) {
      print('📶 [Sync] No internet, cannot download from cloud');
      return;
    }

    print('⬇️ [Sync] Downloading all data for user $userId...');

    try {
      // Download Budgets
      final cloudBudgets = await _budgetRepo.getAllBudgets(userId);
      final budgetBox = await Hive.openBox<Map>('budgets');
      for (var budget in cloudBudgets) {
        await budgetBox.put(budget.id, {
          'id': budget.id,
          'category': budget.category,
          'limit': budget.limit,
          'startDate': budget.startDate.toIso8601String(),
          'endDate': budget.endDate.toIso8601String(),
          'periodType': budget.periodType.toString(),
          'note': budget.note,
          'walletId': budget.walletId,
          'userId':
              userId, // ensure budgets downloaded from cloud are attributed to the user
        });
      }
      print('📥 [Sync] Downloaded ${cloudBudgets.length} budgets');

      // Download Wallets
      final cloudWallets = await _walletRepo.getAllWallets(userId);
      final walletBox = await Hive.openBox<Wallet>('wallets');
      for (var wallet in cloudWallets) {
        await walletBox.put(wallet.id, wallet);
      }
      print('📥 [Sync] Downloaded ${cloudWallets.length} wallets');

      // Download Categories
      final cloudCategories = await _categoryRepo.getAllCategories(userId);
      final categoryBox = await Hive.openBox<CategoryGroup>('category_groups');
      for (var category in cloudCategories) {
        await categoryBox.put(category.id, category);
      }
      print('📥 [Sync] Downloaded ${cloudCategories.length} categories');

      // Download Transactions
      await downloadFromCloud(userId);

      print('✅ [Sync] All user data downloaded successfully');
    } catch (e) {
      print('❌ [Sync] Error downloading user data: $e');
    }
  }

  // ================= UPLOAD TO CLOUD =================
  /// Upload all local transactions to Firebase (backup)
  Future<void> uploadToCloud(String userId) async {
    if (!await hasInternet()) {
      print('📶 [Sync] No internet, cannot upload to cloud');
      return;
    }

    try {
      print('⬆️ [Sync] Uploading transactions for user $userId...');

      final box = await Hive.openBox<Transaction>('transactions');
      final userTransactions = box.values
          .where((t) => t.userId == userId)
          .toList();

      await _transactionRepo.saveTransactions(userTransactions);

      // Mark all as synced
      for (var trans in userTransactions) {
        trans.isSynced = true;
        await trans.save();
      }

      print(
        '✅ [Sync] Upload completed (${userTransactions.length} transactions)',
      );
    } catch (e) {
      print('❌ [Sync] Error uploading to cloud: $e');
    }
  }

  // ================= FULL SYNC =================
  /// Full 2-way sync: download from cloud, merge, upload pending
  Future<void> fullSync(String userId) async {
    if (!await hasInternet()) {
      print('📶 [Sync] No internet, cannot perform full sync');
      return;
    }

    print('🔄 [Sync] Starting full sync for user $userId...');

    // 0. Push queued deletes first to avoid deleted data being pulled back.
    await _syncPendingDeletes(userId: userId);

    // 1. Download all data from cloud first
    await downloadAllUserData(userId);

    // 2. Upload pending changes
    await syncAllPendingTransactions();
    await syncAllUserData(userId);
    await _syncPendingDeletes(userId: userId);

    print('✅ [Sync] Full sync completed');
  }

  // ================= UPLOAD ALL LOCAL DATA TO FIREBASE =================
  /// Upload ALL local data (transactions, budgets, wallets, categories) to Firebase
  /// Use this once to migrate existing data to cloud
  Future<Map<String, dynamic>> uploadAllLocalDataToFirebase(
    String userId,
  ) async {
    if (!await hasInternet()) {
      return {'success': false, 'message': 'Không có kết nối Internet'};
    }

    print('📤 [Sync] Uploading all local data for user $userId to Firebase...');

    try {
      int transactionCount = 0;
      int deletedTransactionCount = 0;
      int budgetCount = 0;
      int walletCount = 0;
      int categoryCount = 0;

      // Upload Transactions
      final transactionBox = await Hive.openBox<Transaction>('transactions');
      final userTransactions = transactionBox.values
          .where((t) => t.userId == userId)
          .toList();
      final localTransactionIds = userTransactions.map((t) => t.id).toSet();
      if (userTransactions.isNotEmpty) {
        await _transactionRepo.saveTransactions(userTransactions);
        for (final trans in userTransactions) {
          trans.isSynced = true;
          await trans.save();
        }
        transactionCount = userTransactions.length;
        print('✅ [Sync] Uploaded $transactionCount transactions');
      }

      // Mirror local deletion state: remove cloud transactions that no longer exist locally.
      final cloudTransactions = await _transactionRepo.getAllTransactions(userId);
      for (final cloudTrans in cloudTransactions) {
        if (!localTransactionIds.contains(cloudTrans.id)) {
          await _transactionRepo.deleteTransaction(userId, cloudTrans.id);
          deletedTransactionCount++;
        }
      }
      if (deletedTransactionCount > 0) {
        print('🗑️ [Sync] Deleted $deletedTransactionCount stale cloud transactions');
      }

      // Upload Budgets
      final budgetBox = await Hive.openBox<Map>('budgets');
      final budgets = budgetBox.values
          .map(
            (map) => Budget(
              id: map['id'] as String,
              category: map['category'] as String,
              limit: (map['limit'] as num).toDouble(),
              startDate: DateTime.parse(map['startDate'] as String),
              endDate: DateTime.parse(map['endDate'] as String),
              periodType: _parseBudgetPeriodType(map['periodType'] as String),
              note: map['note'] as String?,
              walletId: map['walletId'] as String?,
              userId: map['userId'] as String?,
            ),
          )
          .where((b) => (b.userId ?? '') == userId)
          .toList();
      if (budgets.isNotEmpty) {
        await _budgetRepo.saveBudgets(userId, budgets);
        budgetCount = budgets.length;
        print('✅ [Sync] Uploaded $budgetCount budgets');
      }

      // Upload Wallets
      final walletBox = await Hive.openBox<Wallet>('wallets');
      final wallets = walletBox.values
          .where((w) => w.userId == userId)
          .toList();
      if (wallets.isNotEmpty) {
        await _walletRepo.saveWallets(userId, wallets);
        walletCount = wallets.length;
        print('✅ [Sync] Uploaded $walletCount wallets');
      }

      // Upload Categories (all categories - shared across users)
      final categoryBox = await Hive.openBox<CategoryGroup>('category_groups');
      final categories = categoryBox.values.toList();
      if (categories.isNotEmpty) {
        await _categoryRepo.saveCategories(userId, categories);
        categoryCount = categories.length;
        print('✅ [Sync] Uploaded $categoryCount categories');
      }

      final message =
          'Đã upload: $transactionCount giao dịch, xóa cloud $deletedTransactionCount giao dịch, $budgetCount ngân sách, $walletCount ví, $categoryCount danh mục';
      print('✅ [Sync] $message');

      return {
        'success': true,
        'message': message,
        'transactions': transactionCount,
        'deletedTransactions': deletedTransactionCount,
        'budgets': budgetCount,
        'wallets': walletCount,
        'categories': categoryCount,
      };
    } catch (e) {
      print('❌ [Sync] Error uploading to Firebase: $e');
      return {'success': false, 'message': 'Lỗi: ${e.toString()}'};
    }
  }

  // ================= DELETE FROM CLOUD =================
  /// Delete transaction from Firebase
  Future<void> deleteFromCloud(Transaction transaction) async {
    await queueDeleteTransaction(transaction.userId, transaction.id);

    if (!await hasInternet()) {
      print('📶 [Sync] No internet, delete will sync later');
      return;
    }

    try {
      await _syncPendingDeletes(userId: transaction.userId);
      print('🗑️ [Sync] Delete request synced for ${transaction.id}');
    } catch (e) {
      print('❌ [Sync] Error deleting from cloud: $e');
    }
  }

}
