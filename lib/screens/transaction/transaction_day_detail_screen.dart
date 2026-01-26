import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../widgets/transaction/transaction_item.dart';
import '../../widgets/transaction/compact_summary.dart';
import 'transaction_detail_screen.dart';

/// Màn hình chi tiết giao dịch theo ngày
class TransactionDayDetailScreen extends StatelessWidget {
  final DateTime selectedDate;
  final List<model.Transaction> transactions;
  final NumberFormat currencyFormat;

  const TransactionDayDetailScreen({
    super.key,
    required this.selectedDate,
    required this.transactions,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate day balance (income - expense)
    final totalIncome = transactions
        .where((t) => t.type == model.TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final dayBalance = totalIncome - totalExpense;

    // Format date
    final dateStr = DateFormat('dd/MM/yyyy').format(selectedDate);
    final dayOfWeekStr = _getDayOfWeek(selectedDate);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Tổng hợp giao dịch theo ngày',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Date header with balance
            Container(
              color: AppTheme.primaryTeal,
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Date
                  Text(
                    '$dayOfWeekStr - $dateStr',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Summary using CompactSummaryWidget
                  CompactSummaryWidget(
                    totalBalance: dayBalance,
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    currencyFormat: currencyFormat,
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Transactions list
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giao dịch (${transactions.length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Column(
                    children: transactions
                        .map(
                          (transaction) => Column(
                            children: [
                              TransactionItemWidget(
                                transaction: transaction,
                                currencyFormat: currencyFormat,
                                onTap: () async {
                                  final deleted = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TransactionDetailScreen(
                                            transaction: transaction,
                                            currencyFormat: currencyFormat,
                                          ),
                                    ),
                                  );
                                  if (deleted == true) {
                                    Navigator.pop(context, true);
                                  }
                                },
                              ),
                              SizedBox(height: 8),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    const days = [
      'Thứ 2',
      'Thứ 3',
      'Thứ 4',
      'Thứ 5',
      'Thứ 6',
      'Thứ 7',
      'Chủ nhật',
    ];
    final dayIndex = date.weekday - 1;
    return dayIndex >= 0 && dayIndex < 7 ? days[dayIndex] : 'Unknown';
  }
}
