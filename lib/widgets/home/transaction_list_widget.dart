import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction.dart' as model;
import '../../services/data/transaction_service.dart';

class TransactionListWidget extends StatefulWidget {
  const TransactionListWidget({super.key});

  @override
  State<TransactionListWidget> createState() => _TransactionListWidgetState();
}

class _TransactionListWidgetState extends State<TransactionListWidget> {
  final TransactionService _transactionService = TransactionService();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<model.Transaction>>(
      future: _transactionService.getCurrentMonthTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Có lỗi xảy ra: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                SizedBox(height: 16),
                Text(
                  'Chưa có giao dịch nào',
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
              ],
            ),
          );
        }

        // Sort by date (newest first)
        transactions.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(transaction);
          },
        );
      },
    );
  }

  Widget _buildTransactionItem(model.Transaction transaction) {

    Color amountColor;
    String prefix;

    switch (transaction.type) {

      case model.TransactionType.expense:
        amountColor = Colors.red;
        prefix = '-';
        break;

      case model.TransactionType.income:
        amountColor = Colors.green;
        prefix = '+';
        break;

      case model.TransactionType.loanOut:
        amountColor = Colors.orange;
        prefix = '-';
        break;

      case model.TransactionType.loanIn:
        amountColor = Colors.blue;
        prefix = '+';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),

        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: amountColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForType(transaction.type),
            color: amountColor,
          ),
        ),

        title: Text(
          transaction.category,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              transaction.note?.isNotEmpty == true
                  ? transaction.note!
                  : 'Không có ghi chú',
            ),

            const SizedBox(height: 4),

            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(transaction.date),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),

        trailing: Text(
          '$prefix${_currencyFormat.format(transaction.amount)} ₫',
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(model.TransactionType type) {
    switch (type) {
      case model.TransactionType.expense:
        return Icons.arrow_downward;

      case model.TransactionType.income:
        return Icons.arrow_upward;

      case model.TransactionType.loanOut:
        return Icons.call_made; // tiền đi ra

      case model.TransactionType.loanIn:
        return Icons.call_received; // tiền đi vào
    }
  }
}
