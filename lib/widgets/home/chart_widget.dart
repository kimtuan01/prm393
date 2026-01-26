import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ChartWidget extends StatelessWidget {
  final Map<int, double> monthlyData;

  const ChartWidget({super.key, required this.monthlyData});

  String _getMonthName(int month) {
    const monthNames = [
      '',
      'T1',
      'T2',
      'T3',
      'T4',
      'T5',
      'T6',
      'T7',
      'T8',
      'T9',
      'T10',
      'T11',
      'T12',
    ];
    return monthNames[month];
  }

  @override
  Widget build(BuildContext context) {
    // Get last 6 months data
    final now = DateTime.now();
    final List<Map<String, dynamic>> chartData = [];

    for (int i = 5; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year;

      // Handle previous year months
      final adjustedMonth = month <= 0 ? month + 12 : month;
      final adjustedYear = month <= 0 ? year - 1 : year;

      final monthName = _getMonthName(adjustedMonth);
      final amount = monthlyData[adjustedMonth] ?? 0;

      chartData.add({
        'month': monthName,
        'amount': amount,
        'isCurrentMonth':
            adjustedMonth == now.month && adjustedYear == now.year,
      });
    }

    // Find max value for scaling
    final amounts = chartData.map((e) => e['amount'] as double).toList();
    final maxValue = amounts.isEmpty
        ? 0.0
        : amounts.reduce((a, b) => a > b ? a : b);
    final effectiveMaxValue = maxValue > 0
        ? maxValue
        : 1000000; // Default scale if no data

    return Container(
      height: 200,
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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: chartData.map((data) {
          final amount = data['amount'] as double;
          final barHeight = amount > 0
              ? (amount / effectiveMaxValue) * 120
              : 5; // Minimum height for empty bars
          final isCurrentMonth = data['isCurrentMonth'] as bool;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Amount label (show if > 0)
                  if (amount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${(amount / 1000).toStringAsFixed(0)}K',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),

                  // Bar
                  Container(
                    width: double.infinity,
                    height: barHeight.toDouble(),
                    decoration: BoxDecoration(
                      gradient: isCurrentMonth
                          ? LinearGradient(
                              colors: [
                                AppTheme.primaryTeal,
                                AppTheme.primaryTeal.withAlpha(
                                  (0.6 * 255).round(),
                                ),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: isCurrentMonth
                          ? null
                          : AppTheme.textSecondary.withAlpha(
                              (0.3 * 255).round(),
                            ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Month label
                  Text(
                    data['month'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isCurrentMonth
                          ? AppTheme.primaryTeal
                          : AppTheme.textSecondary,
                      fontWeight: isCurrentMonth
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
