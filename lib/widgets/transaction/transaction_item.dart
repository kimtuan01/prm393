import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../utils/category_helper.dart';

/// Widget hiển thị một transaction item
class TransactionItemWidget extends StatelessWidget {
  final model.Transaction transaction;
  final NumberFormat currencyFormat;
  final VoidCallback? onTap;

  const TransactionItemWidget({
    super.key,
    required this.transaction,
    required this.currencyFormat,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryHelper.getCategoryColor(transaction.category);
    final categoryIcon = CategoryHelper.getCategoryIcon(transaction.category);

    final amountText = transaction.type == model.TransactionType.income
        ? '+${currencyFormat.format(transaction.amount)}'
        : '-${currencyFormat.format(transaction.amount)}';

    final amountColor = transaction.type == model.TransactionType.income
        ? Colors.green
        : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.03 * 255).round()),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Category icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: categoryColor.withAlpha((0.1 * 255).round()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(categoryIcon, color: categoryColor, size: 24),
              ),
            ),
            SizedBox(width: 12),

            // Category name and optional note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  if (transaction.note != null && transaction.note!.isNotEmpty)
                    Text(
                      transaction.note!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            SizedBox(width: 8),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '₫',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
