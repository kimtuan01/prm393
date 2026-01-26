import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart' as model;
import '../../services/data/transaction_grouping_service.dart';
import '../../config/theme.dart';

class TransactionCalendarView extends StatelessWidget {
  final Map<String, List<model.Transaction>> groupedTransactions;
  final NumberFormat currencyFormat;
  final bool isLoading;

  const TransactionCalendarView({
    super.key,
    required this.groupedTransactions,
    required this.currencyFormat,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (groupedTransactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Chưa có giao dịch nào')),
      );
    }

    final entries = groupedTransactions.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: entries.map((entry) {
          final incomeTotal = TransactionGroupingService.sumByType(
            entry.value,
            model.TransactionType.income,
          );
          final expenseTotal = TransactionGroupingService.sumByType(
            entry.value,
            model.TransactionType.expense,
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            color: AppTheme.cardColor,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          _buildChip(
                            label: '+${currencyFormat.format(incomeTotal)}',
                            color: AppTheme.accentGreen,
                          ),
                          const SizedBox(width: 8),
                          _buildChip(
                            label:
                                '-${currencyFormat.format(expenseTotal.abs())}',
                            color: Colors.red,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: entry.value.take(4).map((tx) {
                      final isIncome = tx.type == model.TransactionType.income;
                      final amountText =
                          (isIncome ? '+' : '-') +
                          currencyFormat.format(tx.amount.abs());
                      final timeStr = DateFormat('HH:mm').format(tx.date);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isIncome
                              ? AppTheme.accentGreen.withAlpha(
                                  (0.12 * 255).round(),
                                )
                              : Colors.red.withAlpha((0.12 * 255).round()),
                          child: Icon(
                            isIncome
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isIncome ? AppTheme.accentGreen : Colors.red,
                          ),
                        ),
                        title: Text(
                          tx.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(timeStr),
                        trailing: Text(
                          amountText,
                          style: TextStyle(
                            color: isIncome ? AppTheme.accentGreen : Colors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (entry.value.length > 4) ...[
                    const SizedBox(height: 8),
                    Text(
                      '+${entry.value.length - 4} giao dịch nữa',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.12 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
