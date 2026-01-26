import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import 'transaction_item.dart';

/// Widget hiển thị danh sách giao dịch được nhóm theo ngày
class TransactionListWidget extends StatelessWidget {
  final Map<String, List<model.Transaction>> groupedTransactions;
  final NumberFormat currencyFormat;
  final bool isLoading;
  final Function(DateTime, List<model.Transaction>)? onDateTapped;
  final Function(model.Transaction)? onTransactionTapped;

  const TransactionListWidget({
    super.key,
    required this.groupedTransactions,
    required this.currencyFormat,
    this.isLoading = false,
    this.onDateTapped,
    this.onTransactionTapped,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppTheme.primaryTeal),
      );
    }

    if (groupedTransactions.isEmpty) {
      return _buildEmptyState();
    }

    final entries = groupedTransactions.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: entries.asMap().entries.map((entryMap) {
          final index = entryMap.key;
          final entry = entryMap.value;
          final dateLabel = entry.key;
          final transactions = entry.value;
          final groupBg = index.isEven
              ? AppTheme.cardColor
              : AppTheme.primaryTeal.withAlpha((0.04 * 255).round());

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: GestureDetector(
                  onTap: () {
                    if (onDateTapped != null) {
                      onDateTapped!(transactions[0].date, transactions);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppTheme.primaryTeal,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.04 * 255).round()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Day/Month indicator
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.18 * 255).round()),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              _getDayOrMonthLabel(dateLabel, transactions[0]),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Date label
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Arrow icon
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Transactions for this date
              Container(
                decoration: BoxDecoration(
                  color: groupBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: transactions
                      .map(
                        (transaction) => TransactionItemWidget(
                          transaction: transaction,
                          currencyFormat: currencyFormat,
                          onTap: () => onTransactionTapped?.call(transaction),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 4),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Không có giao dịch',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Chưa có giao dịch trong khoảng thời gian này',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Extract day or month label from date label
  String _getDayOrMonthLabel(
    String dateLabel,
    model.Transaction firstTransaction,
  ) {
    // Check if it's a month-based label (contains "Tháng")
    if (dateLabel.contains('Tháng')) {
      // Return month and year abbreviation
      return '${firstTransaction.date.month}/${firstTransaction.date.year % 100}';
    }
    // Otherwise return day number
    return '${firstTransaction.date.day}';
  }
}
