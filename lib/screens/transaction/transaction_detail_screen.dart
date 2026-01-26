import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../utils/category_helper.dart';
import '../../services/data/transaction_notifier.dart';
import '../../services/data/wallet_service.dart';
import '../../utils/notification_helper.dart';
import 'edit_transaction_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final model.Transaction transaction;
  final NumberFormat currencyFormat;

  const TransactionDetailScreen({
    super.key,
    required this.transaction,
    required this.currencyFormat,
  });

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isDeleting = false;
  String _walletName = '';

  @override
  void initState() {
    super.initState();
    _loadWalletName();
  }

  Future<void> _loadWalletName() async {
    final wid = widget.transaction.walletId;
    if (wid == null || wid.isEmpty) return;
    final service = WalletService();
    await service.init();
    final wallet = await service.getById(wid);
    if (!mounted) return;
    setState(() {
      _walletName = wallet?.name ?? '';
    });
  }

  Future<void> _deleteTransaction() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Xóa giao dịch này?',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: const Text('Không thể hoàn tác sau khi xóa.'),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'KHÔNG',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'ĐỒNG Ý',
              style: TextStyle(
                color: AppTheme.accentGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      final notifier = context.read<TransactionNotifier>();
      await notifier.deleteTransactionAndNotify(widget.transaction.id);
      if (mounted) {
        AppNotification.showSuccess(context, 'Đã xóa giao dịch');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Lỗi: $e');
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _editTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditTransactionScreen(transaction: widget.transaction),
      ),
    );

    // If edit was successful, pop back with result
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = CategoryHelper.getCategoryColor(
      widget.transaction.category,
    );
    final categoryIcon = CategoryHelper.getCategoryIcon(
      widget.transaction.category,
    );
    final isIncome = widget.transaction.type == model.TransactionType.income;
    final amountText =
        (isIncome ? '+' : '-') +
        widget.currencyFormat.format(widget.transaction.amount.abs());
    final dateStr = DateFormat('dd/MM/yyyy').format(widget.transaction.date);
    final timeStr = DateFormat('HH:mm').format(widget.transaction.date);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Chi tiết giao dịch',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => _editTransaction(),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _isDeleting ? null : _deleteTransaction,
          ),
        ],
      ),
      body: _isDeleting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and amount
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.05 * 255).round()),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: categoryColor.withAlpha(
                            (0.12 * 255).round(),
                          ),
                          child: Icon(categoryIcon, color: categoryColor),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.transaction.category,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$dateStr · $timeStr',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              amountText,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isIncome
                                    ? AppTheme.accentGreen
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isIncome ? 'Thu nhập' : 'Chi tiêu',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Details
                  Text(
                    'Chi tiết',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Wallet
                  if (_walletName.isNotEmpty) ...[
                    _buildDetailRow(
                      icon: Icons.account_balance_wallet,
                      label: 'Ví',
                      value: _walletName,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Note
                  if (widget.transaction.note != null &&
                      widget.transaction.note!.isNotEmpty) ...[
                    _buildDetailRow(
                      icon: Icons.note,
                      label: 'Ghi chú',
                      value: widget.transaction.note ?? '',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Date created
                  _buildDetailRow(
                    icon: Icons.schedule,
                    label: 'Ngày tạo',
                    value: DateFormat(
                      'dd/MM/yyyy · HH:mm',
                    ).format(widget.transaction.createdAt),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
