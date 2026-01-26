import 'package:flutter/material.dart';
import '../../config/theme.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spendingPercent; // 0..inf
  final double timePercent; // 0..1
  final Color barColor;

  const BudgetProgressBar({
    super.key,
    required this.spendingPercent,
    required this.timePercent,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final clampedSpend = spendingPercent.isNaN
        ? 0.0
        : spendingPercent.clamp(0.0, 1.0);
    final clampedTime = timePercent.isNaN ? 0.0 : timePercent.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final spendWidth = width * clampedSpend;
            final markerLeft = width * clampedTime;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Background bar
                Container(
                  width: width,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Spending fill
                Container(
                  width: spendWidth,
                  height: 8,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                // Today marker line
                Positioned(
                  left: markerLeft - 1,
                  top: -2,
                  child: Container(
                    width: 2,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        // Today label below the bar, horizontally aligned to marker
        LayoutBuilder(
          builder: (context, constraints) {
            final alignX = -1 + 2 * clampedTime; // map [0,1] -> [-1,1]
            return Align(
              alignment: Alignment(alignX, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Hôm nay',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
