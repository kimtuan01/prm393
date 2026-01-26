import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../widgets/transaction/transaction_item.dart';
import '../../widgets/transaction/compact_summary.dart';
import 'transaction_detail_screen.dart';

/// Màn hình chi tiết giao dịch theo tháng
class TransactionMonthDetailScreen extends StatelessWidget {
  final DateTime selectedMonth; // Use any date within the month
  final List<model.Transaction> transactions;
  final NumberFormat currencyFormat;

  const TransactionMonthDetailScreen({
    super.key,
    required this.selectedMonth,
    required this.transactions,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate month totals (income - expense)
    final totalIncome = transactions
        .where((t) => t.type == model.TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final totalExpense = transactions
        .where((t) => t.type == model.TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount);

    final monthBalance = totalIncome - totalExpense;

    // Format month header: "Tháng MM/yyyy"
    final monthStr = 'Tháng ${DateFormat('MM/yyyy').format(selectedMonth)}';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Tổng hợp giao dịch theo tháng',
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
            // Month header with balance
            Container(
              color: AppTheme.primaryTeal,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Month label
                  Text(
                    monthStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary using CompactSummaryWidget
                  CompactSummaryWidget(
                    totalBalance: monthBalance,
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    currencyFormat: currencyFormat,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Transactions list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  const SizedBox(height: 12),
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
                              const SizedBox(height: 8),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
