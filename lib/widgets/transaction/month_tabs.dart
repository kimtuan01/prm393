import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Widget hiển thị thanh cuộn ngang để chọn tháng hoặc khoảng thời gian khác
class MonthTabsWidget extends StatelessWidget {
  final List<DateTime> availableMonths;
  final DateTime selectedMonth;
  final Function(DateTime) onMonthSelected;
  final ScrollController scrollController;
  final String timeRangeType; // 'Ngày', 'Tuần', 'Tháng', 'Quý', 'Năm'

  const MonthTabsWidget({
    super.key,
    required this.availableMonths,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.scrollController,
    this.timeRangeType = 'Tháng',
  });

  String _getLabel(DateTime period, DateTime currentPeriod) {
    final now = DateTime.now();

    switch (timeRangeType) {
      case 'Ngày':
        final isToday =
            period.year == now.year &&
            period.month == now.month &&
            period.day == now.day;
        if (isToday) {
          return 'HÔM NAY';
        }
        return '${period.day}/${period.month}';
      case 'Tháng':
        final isCurrentMonth =
            period.year == now.year && period.month == now.month;
        String label;
        if (isCurrentMonth) {
          label = 'THÁNG NAY';
        } else {
          label = 'Tháng ${period.month}';
        }
        if (period.year != now.year) {
          label += '/${period.year}';
        }
        return label;
      case 'Quý':
        final quarter = ((period.month - 1) ~/ 3) + 1;
        final isCurrentQuarter =
            period.year == now.year && ((now.month - 1) ~/ 3) + 1 == quarter;
        String label = 'Q$quarter';
        if (period.year != now.year) {
          label += '/${period.year}';
        }
        if (isCurrentQuarter) {
          label = 'QUÝ NAY';
        }
        return label;
      case 'Năm':
        final isCurrentYear = period.year == now.year;
        if (isCurrentYear) {
          return 'NĂM NAY';
        }
        return 'Năm ${period.year}';
      default:
        return 'Tháng ${period.month}/${period.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: availableMonths.map((period) {
          bool isSelected;

          switch (timeRangeType) {
            case 'Ngày':
              isSelected =
                  period.year == selectedMonth.year &&
                  period.month == selectedMonth.month &&
                  period.day == selectedMonth.day;
              break;

            case 'Quý':
              isSelected =
                  period.year == selectedMonth.year &&
                  ((period.month - 1) ~/ 3) == ((selectedMonth.month - 1) ~/ 3);
              break;
            case 'Năm':
              isSelected = period.year == selectedMonth.year;
              break;
            default: // Tháng
              isSelected =
                  period.year == selectedMonth.year &&
                  period.month == selectedMonth.month;
          }

          final label = _getLabel(period, selectedMonth);

          return GestureDetector(
            onTap: () => onMonthSelected(period),
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryTeal : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryTeal : Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
