import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget hiển thị summary gọn gàng (Số dư, Tiền vào, Tiền ra)
class CompactSummaryWidget extends StatelessWidget {
  final double totalBalance;
  final double totalIncome;
  final double totalExpense;
  final NumberFormat currencyFormat;

  const CompactSummaryWidget({
    super.key,
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpense,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Balance at top
          Text(
            'Số dư',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          SizedBox(height: 4),
          Text(
            '${currencyFormat.format(totalBalance)} ₫',
            style: TextStyle(
              color: totalBalance >= 0 ? Colors.green : Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Income and Expense side by side
          Row(
            children: [
              Expanded(
                child: _buildCompactItem(
                  'Tiền vào',
                  totalIncome,
                  Colors.green,
                  currencyFormat,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildCompactItem(
                  'Tiền ra',
                  totalExpense,
                  Colors.red,
                  currencyFormat,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactItem(
    String label,
    double amount,
    Color color,
    NumberFormat format,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        SizedBox(height: 4),
        Row(
          children: [
            Text(
              amount >= 0 ? '' : '-',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: Text(
                format.format(amount.abs()),
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
