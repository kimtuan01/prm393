import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/constants.dart';
import '../../../../config/theme.dart';
import '../../utils/category_icon_mapper.dart';

class RecentTransactionsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const RecentTransactionsWidget({super.key, required this.transactions});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0', 'vi_VN');
    final sign = amount > 0 ? '+' : '';
    return '$sign${formatter.format(amount)} ${AppConstants.currencySymbol}';
  }

  // Prefer asset iconPath when available; otherwise use CategoryIconMapper by iconKey
  Widget _buildIcon(String? iconPath, String? iconKey) {
    if (iconPath != null && iconPath.isNotEmpty) {
      return Image.asset(
        iconPath,
        width: AppConstants.iconMedium,
        height: AppConstants.iconMedium,
        errorBuilder: (context, error, stackTrace) {
          // fallback to key if asset fails
          if (iconKey != null && iconKey.isNotEmpty) {
            return Icon(
              CategoryIconMapper.fromKey(iconKey),
              color: Colors.white,
              size: AppConstants.iconMedium,
            );
          }
          return Icon(
            Icons.receipt,
            color: Colors.white,
            size: AppConstants.iconMedium,
          );
        },
      );
    }

    if (iconKey != null && iconKey.isNotEmpty) {
      return Icon(
        CategoryIconMapper.fromKey(iconKey),
        color: Colors.white,
        size: AppConstants.iconMedium,
      );
    }

    return Icon(
      Icons.receipt,
      color: Colors.white,
      size: AppConstants.iconMedium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Giao dịch gần đây',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to all transactions
              },
              child: Text(
                'Xem tất cả',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryTeal,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: AppConstants.paddingSmall),

        // Transaction List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return _buildTransactionItem(context, transaction);
          },
        ),
      ],
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) {
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: AppConstants.paddingSmall),
      padding: EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryTeal.withAlpha((0.8 * 255).round()),
            AppTheme.primaryTeal,
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withAlpha((0.3 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).round()),
            ),
            child: _buildIcon(
              transaction['iconPath'] as String?,
              transaction['iconKey'] as String?,
            ),
          ),

          SizedBox(width: AppConstants.paddingMedium),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction['title'] as String,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction['subtitle'] as String,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withAlpha((0.8 * 255).round()),
                  ),
                ),
              ],
            ),
          ),

          // Amount & Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(amount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                transaction['date'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withAlpha((0.8 * 255).round()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
