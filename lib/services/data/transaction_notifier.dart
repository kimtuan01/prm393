import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import 'transaction_service.dart';
import 'notification_service.dart';
import '../firebase/sync_service.dart';

/// Global notifier to trigger automatic updates across all screens
/// when transactions are added, edited, or deleted
class TransactionNotifier with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final NotificationService _notificationService = NotificationService();
  final SyncService _syncService = SyncService();

  /// Notify all listeners to refresh transaction data
  void notifyTransactionChanged() {
    notifyListeners();
  }

  /// Wrapper for adding transaction that notifies all screens
  Future<void> addTransactionAndNotify(Transaction transaction) async {
    await _transactionService.addTransaction(transaction);
    await _notificationService.init();
    await _notificationService.emitTransactionAdded(transaction);
    await _notificationService.evaluateBudgetsAfterTransaction(
      tx: transaction,
      userId: transaction.userId,
    );

    // 🌐 Auto sync to Firebase (non-blocking)
    _syncService.syncAllPendingTransactions().catchError((e) {
      debugPrint('⚠️ Auto sync failed: $e');
    });

    notifyTransactionChanged();
  }

  /// Wrapper for updating transaction that notifies all screens
  Future<void> updateTransactionAndNotify(Transaction transaction) async {
    await _transactionService.updateTransaction(transaction);
    await _notificationService.init();
    await _notificationService.emitTransactionUpdated(transaction);
    await _notificationService.evaluateBudgetsAfterTransaction(
      tx: transaction,
      userId: transaction.userId,
    );

    // 🌐 Auto sync to Firebase (non-blocking)
    _syncService.syncAllPendingTransactions().catchError((e) {
      debugPrint('⚠️ Auto sync failed: $e');
    });

    notifyTransactionChanged();
  }

  /// Wrapper for deleting transaction that notifies all screens
  Future<void> deleteTransactionAndNotify(String transactionId) async {
    await _transactionService.deleteTransaction(transactionId);
    await _notificationService.init();
    await _notificationService.emitTransactionDeleted(transactionId);

    // 🌐 Auto sync to Firebase (non-blocking)
    _syncService.syncAllPendingTransactions().catchError((e) {
      debugPrint('⚠️ Auto sync failed: $e');
    });

    notifyTransactionChanged();
  }
}
