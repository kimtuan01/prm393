import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../models/app_notification.dart';
import '../../models/budget.dart';
import '../../models/transaction.dart' as model;
import 'budget_service.dart';
import 'transaction_service.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._();
  NotificationService._();
  factory NotificationService() => _instance;

  late Box<Map> _notifBox;
  late Box _prefsBox;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _notifBox = await Hive.openBox<Map>('notifications');
    _prefsBox = await Hive.openBox('notification_prefs');
    _initialized = true;
  }

  List<AppNotification> getAll() {
    if (!_initialized) return [];
    return _notifBox.values
        .map((e) => AppNotification.fromMap(e.cast<String, dynamic>()))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get unreadCount => getAll().where((n) => !n.isRead).length;

  Future<void> add(AppNotification n) async {
    if (!_initialized) await init();
    if (n.uniqueKey != null) {
      final exists = _notifBox.values.any((e) {
        final m = e.cast<String, dynamic>();
        return (m['uniqueKey'] == n.uniqueKey);
      });
      if (exists) return;
    }
    await _notifBox.put(n.id, n.toMap());
    notifyListeners();
  }

  Future<void> markRead(String id, {bool read = true}) async {
    if (!_initialized) return;
    final map = _notifBox.get(id);
    if (map == null) return;
    map['isRead'] = read;
    await _notifBox.put(id, map);
    notifyListeners();
  }

  Future<void> markAllRead() async {
    if (!_initialized) return;
    for (final k in _notifBox.keys) {
      final map = _notifBox.get(k);
      if (map == null) continue;
      map['isRead'] = true;
      await _notifBox.put(k, map);
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    if (!_initialized) return;
    await _notifBox.delete(id);
    notifyListeners();
  }

  // ================= Prefs =================
  bool get enableBudgetAlerts =>
      (_prefsBox.get('enableBudgetAlerts') as bool?) ?? true;
  set enableBudgetAlerts(bool v) => _prefsBox.put('enableBudgetAlerts', v);

  bool get enableTransactionAlerts =>
      (_prefsBox.get('enableTransactionAlerts') as bool?) ?? true;
  set enableTransactionAlerts(bool v) =>
      _prefsBox.put('enableTransactionAlerts', v);

  int get budgetThresholdPercent =>
      (_prefsBox.get('budgetThresholdPercent') as int?) ?? 80;
  set budgetThresholdPercent(int v) =>
      _prefsBox.put('budgetThresholdPercent', v);

  int get budgetEndSoonDays =>
      (_prefsBox.get('budgetEndSoonDays') as int?) ?? 3;
  set budgetEndSoonDays(int v) => _prefsBox.put('budgetEndSoonDays', v);

  // ================= Emitters =================
  Future<void> emitTransactionAdded(model.Transaction tx) async {
    if (!_initialized) await init();
    if (!enableTransactionAlerts) return;
    await add(
      AppNotification(
        id: const Uuid().v4(),
        type: NotificationType.transaction,
        level: NotificationLevel.success,
        title: 'Thêm giao dịch thành công',
        message: _txSummary(tx),
        createdAt: DateTime.now(),
        route: 'transaction_detail',
        params: {'transactionId': tx.id},
      ),
    );
  }

  Future<void> emitTransactionUpdated(model.Transaction tx) async {
    if (!_initialized) await init();
    if (!enableTransactionAlerts) return;
    await add(
      AppNotification(
        id: const Uuid().v4(),
        type: NotificationType.transaction,
        level: NotificationLevel.info,
        title: 'Sửa giao dịch thành công',
        message: _txSummary(tx),
        createdAt: DateTime.now(),
        route: 'transaction_detail',
        params: {'transactionId': tx.id},
      ),
    );
  }

  Future<void> emitTransactionDeleted(String txId) async {
    if (!_initialized) await init();
    if (!enableTransactionAlerts) return;
    await add(
      AppNotification(
        id: const Uuid().v4(),
        type: NotificationType.transaction,
        level: NotificationLevel.info,
        title: 'Xóa giao dịch thành công',
        message: 'Giao dịch đã được xóa',
        createdAt: DateTime.now(),
      ),
    );
  }

  // ================= Budget evaluation =================
  Future<void> evaluateBudgetsAfterTransaction({
    required model.Transaction tx,
    required String? userId,
  }) async {
    if (!_initialized) await init();
    if (!enableBudgetAlerts) return;

    final budgetService = BudgetService();
    await budgetService.init();
    final txService = TransactionService();
    await txService.init();

    // Evaluate budgets overlapping transaction date (user-scoped)
    final budgets = budgetService
        .getAllBudgets(userId: userId)
        .where((b) => b.overlaps(tx.date, tx.date) && b.category == tx.category)
        .toList();

    for (final b in budgets) {
      final spent = await budgetService.computeTotalSpentForBudget(
        budget: b,
        transactionService: txService,
        userId: userId,
      );
      final percent = b.limit <= 0 ? 0 : ((spent / b.limit) * 100).floor();

      // Threshold alert (e.g., 80%)
      final threshold = budgetThresholdPercent;
      if (percent >= threshold && percent < 100) {
        final key = 'budget-$threshold-${b.id}-${b.endDate.toIso8601String()}';
        await add(
          AppNotification(
            id: const Uuid().v4(),
            type: NotificationType.budget,
            level: NotificationLevel.warning,
            title: 'Đã dùng $percent% ngân sách',
            message: 'Danh mục ${b.category} (${_periodText(b)})',
            createdAt: DateTime.now(),
            uniqueKey: key,
            route: 'budget_detail',
            params: {'budgetId': b.id},
          ),
        );
      }

      // 100% or exceeded
      if (percent >= 100) {
        final key = 'budget-100-${b.id}-${b.endDate.toIso8601String()}';
        await add(
          AppNotification(
            id: const Uuid().v4(),
            type: NotificationType.budget,
            level: NotificationLevel.error,
            title: 'Vượt 100% ngân sách',
            message: 'Danh mục ${b.category} (${_periodText(b)})',
            createdAt: DateTime.now(),
            uniqueKey: key,
            route: 'budget_detail',
            params: {'budgetId': b.id},
          ),
        );
      }
    }

    // End soon alerts for all active budgets
    final now = DateTime.now();
    final all = budgetService.getAllBudgets(userId: userId);
    for (final b in all) {
      if (b.endDate.isBefore(now)) continue; // already ended
      final daysLeft = b.endDate.difference(now).inDays;
      if (daysLeft <= budgetEndSoonDays) {
        final key = 'budget-end-${b.id}-${b.endDate.toIso8601String()}';
        await add(
          AppNotification(
            id: const Uuid().v4(),
            type: NotificationType.budget,
            level: NotificationLevel.info,
            title: 'Ngân sách sắp kết thúc',
            message:
                'Danh mục ${b.category} còn $daysLeft ngày (${_periodText(b)})',
            createdAt: DateTime.now(),
            uniqueKey: key,
            route: 'budget_detail',
            params: {'budgetId': b.id},
          ),
        );
      }
    }
  }

  String _txSummary(model.Transaction tx) {
    final type = tx.type == model.TransactionType.expense
        ? 'Khoản chi'
        : tx.type == model.TransactionType.income
        ? 'Khoản thu'
        : 'Vay/Nợ';
    return '$type • ${tx.category} • ${tx.amount.toStringAsFixed(0)} VND';
  }

  String _periodText(Budget b) {
    return '${b.startDate.day}/${b.startDate.month} - ${b.endDate.day}/${b.endDate.month}';
  }
}
