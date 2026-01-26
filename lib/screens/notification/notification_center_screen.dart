import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../services/data/transaction_service.dart';
import '../../services/data/budget_service.dart';
import '../transaction/transaction_detail_screen.dart';
import '../budget/budget_detail_screen.dart';
import '../../models/app_notification.dart';
import '../../services/data/notification_service.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notif = context.watch<NotificationService>();
    final items = notif.getAll();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          if (items.any((e) => !e.isRead))
            TextButton(
              onPressed: notif.markAllRead,
              child: const Text(
                'Đánh dấu đã đọc',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.white,
      body: items.isEmpty
          ? _buildEmpty()
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) =>
                  _NotificationTile(item: items[index]),
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemCount: items.length,
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'Chưa có thông báo',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final AppNotification item;

  Color _levelColor(NotificationLevel level) {
    switch (level) {
      case NotificationLevel.success:
        return Colors.green;
      case NotificationLevel.warning:
        return Colors.orange;
      case NotificationLevel.error:
        return Colors.red;
      case NotificationLevel.info:
        return AppTheme.primaryTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<NotificationService>();
    final icon = iconForNotification(item.type);
    final color = _levelColor(item.level);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: _buildSwipeBg(context, alignEnd: false),
      secondaryBackground: _buildSwipeBg(context, alignEnd: true),
      onDismissed: (_) async {
        await service.delete(item.id);
      },
      child: InkWell(
        onTap: () async {
          await service.markRead(item.id, read: true);
          // Deep-link based on route
          if (item.route == 'transaction_detail') {
            final txId = item.params?['transactionId'] as String?;
            if (txId != null) {
              final txService = TransactionService();
              final tx = await txService.getById(txId);
              if (tx != null) {
                final nf = NumberFormat('#,###', 'vi_VN');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailScreen(
                      transaction: tx,
                      currencyFormat: nf,
                    ),
                  ),
                );
              }
            }
          } else if (item.route == 'budget_detail') {
            final budgetId = item.params?['budgetId'] as String?;
            if (budgetId != null) {
              final bService = BudgetService();
              await bService.init();
              final budget = bService.getById(budgetId);
              if (budget != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BudgetDetailScreen(budget: budget),
                  ),
                );
              }
            }
          }
        },
        onLongPress: () async {
          await service.delete(item.id);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(item.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeBg(BuildContext context, {required bool alignEnd}) {
    return Container(
      alignment: Alignment.center,
      color: Colors.red,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.delete, color: Colors.white),
          SizedBox(height: 4),
          Text(
            'Xóa',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}
