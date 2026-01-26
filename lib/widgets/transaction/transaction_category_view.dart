import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart' as model;
import '../../config/theme.dart';
import '../../utils/category_helper.dart';

class TransactionCategoryView extends StatelessWidget {
  final Map<String, List<model.Transaction>> groupedByCategory;
  final NumberFormat currencyFormat;
  final bool isLoading;

  const TransactionCategoryView({
    super.key,
    required this.groupedByCategory,
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

    if (groupedByCategory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text('Chưa có giao dịch nào')),
      );
    }

    final entries = groupedByCategory.entries.toList()
      ..sort((a, b) => _totalAmount(b.value).compareTo(_totalAmount(a.value)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: entries.map((entry) {
          final txs = entry.value;
          final total = _totalAmount(txs);
          final isPositive = total >= 0;
          final totalText =
              (isPositive ? '+' : '-') + currencyFormat.format(total.abs());
          final subtitle = '${txs.length} giao dịch';

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
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: CategoryHelper.getCategoryColor(
                              entry.key,
                            ).withAlpha((0.12 * 255).round()),
                            child: Icon(
                              CategoryHelper.getCategoryIcon(entry.key),
                              color: CategoryHelper.getCategoryColor(entry.key),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Text(
                        totalText,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isPositive ? AppTheme.accentGreen : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: txs.take(4).map((tx) {
                      final isIncome = tx.type == model.TransactionType.income;
                      final amountText =
                          (isIncome ? '+' : '-') +
                          currencyFormat.format(tx.amount.abs());
                      final dateLabel = _dateLabel(tx.date);

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade200,
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        title: Text(
                          dateLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_timeLabel(tx.date)),
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
                  if (txs.length > 4) ...[
                    const SizedBox(height: 8),
                    Text(
                      '+${txs.length - 4} giao dịch nữa',
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

  static double _totalAmount(List<model.Transaction> txs) {
    return txs.fold<double>(0, (sum, tx) {
      final sign = tx.type == model.TransactionType.income ? 1 : -1;
      return sum + sign * tx.amount;
    });
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'Hôm nay';
    if (target == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return DateFormat('dd MMM yyyy', 'vi_VN').format(date);
  }

  String _timeLabel(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }
}
