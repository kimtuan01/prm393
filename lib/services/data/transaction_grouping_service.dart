import 'package:intl/intl.dart';
import '../../models/transaction.dart' as model;

/// Service để group và format transactions
class TransactionGroupingService {
  /// Group transactions by date với label format
  /// Returns map với key là date label (Hôm nay, Hôm qua, Thứ X - DD/MM/YYYY)
  static Map<String, List<model.Transaction>> groupTransactionsByDate(
    List<model.Transaction> transactions,
  ) {
    final grouped = <String, List<model.Transaction>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    // Sort transactions by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    for (var transaction in transactions) {
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      // Determine date label
      final dateLabel = _getDateLabel(transactionDate, today, yesterday);

      grouped.putIfAbsent(dateLabel, () => []).add(transaction);
    }

    return grouped;
  }

  /// Group transactions by month với label format Tháng MM/YYYY
  static Map<String, List<model.Transaction>> groupTransactionsByMonth(
    List<model.Transaction> transactions,
  ) {
    final grouped = <String, List<model.Transaction>>{};

    // Sort transactions by date descending (newest first)
    transactions.sort((a, b) => b.date.compareTo(a.date));

    for (var transaction in transactions) {
      // Format: "Tháng 12 - 2025" or just "Tháng 12"
      final month = transaction.date.month;
      final year = transaction.date.year;
      final dateLabel = 'Tháng $month - $year';
      grouped.putIfAbsent(dateLabel, () => []).add(transaction);
    }

    return grouped;
  }

  /// Group transactions by category name
  static Map<String, List<model.Transaction>> groupTransactionsByCategory(
    List<model.Transaction> transactions,
  ) {
    final grouped = <String, List<model.Transaction>>{};

    // Sort by date desc to keep newest first inside each category
    transactions.sort((a, b) => b.date.compareTo(a.date));

    for (final transaction in transactions) {
      final category = transaction.category;
      grouped.putIfAbsent(category, () => []).add(transaction);
    }

    return grouped;
  }

  /// Format date label (Hôm nay, Hôm qua, hoặc Thứ X - DD/MM/YYYY)
  static String _getDateLabel(
    DateTime date,
    DateTime today,
    DateTime yesterday,
  ) {
    if (date == today) {
      return 'Hôm nay';
    } else if (date == yesterday) {
      return 'Hôm qua';
    } else {
      // Get day of week
      const dayOfWeek = [
        'Thứ 2',
        'Thứ 3',
        'Thứ 4',
        'Thứ 5',
        'Thứ 6',
        'Thứ 7',
        'Chủ nhật',
      ];
      final dayIndex = date.weekday - 1;
      final dayName = dayIndex >= 0 && dayIndex < 7
          ? dayOfWeek[dayIndex]
          : 'Unknown';
      final dateStr = DateFormat('dd/MM/yyyy').format(date);
      return '$dayName - $dateStr';
    }
  }

  /// Get day of month from date label
  static int getDayFromDate(DateTime date) {
    return date.day;
  }

  /// Sum transaction amounts by type
  static double sumByType(
    List<model.Transaction> transactions,
    model.TransactionType type,
  ) {
    return transactions
        .where((t) => t.type == type)
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  /// Filter transactions by month
  static List<model.Transaction> filterByMonth(
    List<model.Transaction> transactions,
    DateTime month,
  ) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);

    return transactions
        .where(
          (t) =>
              t.date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
              t.date.isBefore(endOfMonth.add(Duration(days: 1))),
        )
        .toList();
  }

  /// Filter transactions by date range
  static List<model.Transaction> filterByDateRange(
    List<model.Transaction> transactions,
    DateTime start,
    DateTime end,
  ) {
    return transactions
        .where(
          (t) =>
              t.date.isAfter(start.subtract(Duration(days: 1))) &&
              t.date.isBefore(end.add(Duration(days: 1))),
        )
        .toList();
  }

  /// Filter transactions by wallet id
  static List<model.Transaction> filterByWallet(
    List<model.Transaction> transactions,
    String walletId,
  ) {
    if (walletId == 'all' || walletId.isEmpty) {
      return transactions;
    }
    return transactions.where((t) => (t.walletId ?? '') == walletId).toList();
  }

  /// Sort transactions
  static List<model.Transaction> sortTransactions(
    List<model.Transaction> transactions,
    String sortBy,
  ) {
    final sorted = List<model.Transaction>.from(transactions);

    switch (sortBy) {
      case 'Mới nhất':
        sorted.sort((a, b) => b.date.compareTo(a.date));
        break;
      case 'Cũ nhất':
        sorted.sort((a, b) => a.date.compareTo(b.date));
        break;
      case 'Số tiền cao nhất':
        sorted.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'Số tiền thấp nhất':
        sorted.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }

    return sorted;
  }
}
