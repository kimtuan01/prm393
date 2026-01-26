import 'package:expense_tracker_app/models/category_group.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/budget.dart';
import '../../models/wallet.dart';
import '../../config/constants.dart';
import '../../services/data/category_group_service.dart';
import '../../services/data/wallet_service.dart';
import '../../services/data/transaction_notifier.dart';
import '../../utils/category_icon_mapper.dart';
import '../../config/theme.dart';
import '../../services/auth/auth_service.dart';
import '../../services/data/budget_service.dart';
import '../../services/data/transaction_service.dart';
import '../../services/core/budget_progress.dart';
import '../../models/transaction.dart' as model;
import '../budget/_progress_bar.dart';
import 'edit_budget_screen.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;
  final String? walletId; // Optional wallet filter

  const BudgetDetailScreen({super.key, required this.budget, this.walletId});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  final BudgetService _budgetService = BudgetService();
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();
  bool _showTransactions = false;
  List<model.Transaction> _transactions = [];
  double _totalSpent = 0;
  late Budget _currentBudget;
  Wallet? _wallet;

  @override
  void initState() {
    super.initState();
    _currentBudget = widget.budget;
    _loadData();
  }

  @override
  void dispose() {
    _transactionNotifier?.removeListener(_onTransactionChanged);
    super.dispose();
  }

  void _onTransactionChanged() {
    _loadData();
  }

  // Cached groups for rendering
  List<CategoryGroup> _categories = [];

  // Cached reference to the TransactionNotifier to manage listeners safely
  TransactionNotifier? _transactionNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final notifier = context.read<TransactionNotifier>();
    if (_transactionNotifier != notifier) {
      _transactionNotifier?.removeListener(_onTransactionChanged);
      _transactionNotifier = notifier;
      _transactionNotifier!.addListener(_onTransactionChanged);
    }
  }

  Future<void> _loadData() async {
    // Reload budget object from service
    await _budgetService.init();
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.id;

    final budgets = _budgetService.getAllBudgets(userId: userId);
    final updatedBudget = budgets.firstWhere(
      (b) => b.id == widget.budget.id,
      orElse: () => widget.budget,
    );

    // Abort if widget was disposed while awaiting data
    if (!mounted) return;

    final txs = await _transactionService.getTransactionsByDateRange(
      updatedBudget.startDate,
      updatedBudget.endDate,
      userId: userId,
    );

    final filtered = txs
        .where((t) => t.type == model.TransactionType.expense)
        .where((t) => t.category == updatedBudget.category)
        .where(
          (t) =>
              updatedBudget.walletId == null ||
              t.walletId == updatedBudget.walletId,
        ) // Filter by wallet from updated budget
        .toList();

    final spent = filtered.fold<double>(0, (sum, t) => sum + t.amount);

    // load categories for icon lookup
    final catService = CategoryGroupService();
    _categories = await catService.getAll();

    // Load wallet from updated budget's walletId
    Wallet? wallet;
    if (updatedBudget.walletId != null) {
      wallet = await _walletService.getById(updatedBudget.walletId!);
    }

    if (mounted) {
      setState(() {
        _currentBudget = updatedBudget;
        _transactions = filtered;
        _totalSpent = spent;
        _wallet = wallet;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  IconData _getCategoryIcon(String categoryName) {
    final match = _categories.firstWhere(
      (c) => c.name == categoryName,
      orElse: () => CategoryGroup(
        id: '',
        name: '',
        type: CategoryType.expense,
        iconKey: 'other',
        colorValue: 0xFF9E9E9E,
        createdAt: DateTime.now(),
      ),
    );

    return CategoryIconMapper.fromKey(match.iconKey);
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        title: Text(
          'Xóa ngân sách',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa ngân sách này không?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppTheme.textPrimary),
            child: const Text(
              'KHÔNG',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthService>(context, listen: false);
              final userId = auth.currentUser?.id ?? '';
              await _budgetService.deleteBudget(
                _currentBudget.id,
                userId: userId,
              );
              if (!mounted) return;
              Navigator.pop(context); // Close dialog
              Navigator.pop(
                context,
                true,
              ); // Return to list with refresh signal
            },

            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              'XÓA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  int _getDaysRemaining() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(
      _currentBudget.endDate.year,
      _currentBudget.endDate.month,
      _currentBudget.endDate.day,
    );

    if (today.isAfter(end)) return 0;
    return end.difference(today).inDays + 1;
  }

  Widget _buildChart() {
    // Group transactions by date and sum amounts
    final Map<DateTime, double> dailySpending = {};
    for (var tx in _transactions) {
      final date = DateTime(tx.date.year, tx.date.month, tx.date.day);
      dailySpending[date] = (dailySpending[date] ?? 0) + tx.amount;
    }

    // Generate all dates in budget range
    final start = DateTime(
      _currentBudget.startDate.year,
      _currentBudget.startDate.month,
      _currentBudget.startDate.day,
    );
    final end = DateTime(
      _currentBudget.endDate.year,
      _currentBudget.endDate.month,
      _currentBudget.endDate.day,
    );
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final totalDays = end.difference(start).inDays + 1;

    // Điều chỉnh trục tung: nếu vượt hạn mức thì lấy chi tiêu làm điểm cao nhất,
    // nếu chưa vượt thì lấy hạn mức làm điểm cao nhất
    final maxY = _totalSpent >= _currentBudget.limit
        ? _totalSpent *
              1.1 // Vượt mức: chi tiêu + 10% để có khoảng trống
        : _currentBudget.limit * 1.2; // Chưa vượt: hạn mức + 20%

    // Check if budget is completed
    final isBudgetCompleted = end.isBefore(today);

    // Find today's index for marker (only if budget not completed)
    final todayIndex = today.isAfter(end)
        ? totalDays - 1
        : (today.isBefore(start) ? 0 : today.difference(start).inDays);

    // Only render the line up to today for active budgets, or to end for completed budgets
    final endIndexForLine = isBudgetCompleted
        ? totalDays - 1
        : todayIndex.clamp(0, totalDays - 1);

    // Create line chart data points (cumulative spending) up to endIndexForLine
    final List<FlSpot> spots = [];
    double cumulative = 0;
    for (int i = 0; i <= endIndexForLine; i++) {
      final date = start.add(Duration(days: i));
      final dailyAmount = dailySpending[date] ?? 0;
      cumulative += dailyAmount;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          maxY: maxY,
          minY: 0,
          minX: 0,
          maxX: (totalDays - 1).toDouble(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = start.add(Duration(days: spot.x.toInt()));
                  return LineTooltipItem(
                    '${DateFormat('dd/MM').format(date)}\n${NumberFormat('#,##0').format(spot.y)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= totalDays)
                    return const SizedBox.shrink();

                  final date = start.add(Duration(days: index));
                  // Show labels for start, today, end, and some intermediate points
                  final showLabel =
                      date == start ||
                      date == end ||
                      date == today ||
                      (totalDays > 10 && index % (totalDays ~/ 5 + 1) == 0);

                  if (showLabel) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: TextStyle(
                          fontSize: 9,
                          color: date == today
                              ? AppTheme.primaryTeal
                              : AppTheme.textSecondary,
                          fontWeight: date == today
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            verticalInterval: totalDays > 10 ? (totalDays / 5) : 1,
            getDrawingVerticalLine: (value) {
              final index = value.toInt();
              final date = start.add(Duration(days: index));
              if (!isBudgetCompleted && date == today) {
                return FlLine(
                  color: AppTheme.primaryTeal.withOpacity(0.5),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                );
              }
              return FlLine(color: Colors.grey.shade300, strokeWidth: 0.5);
            },
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              if ((value - _currentBudget.limit).abs() < maxY * 0.01) {
                return FlLine(
                  color: Colors.red,
                  strokeWidth: 2,
                  dashArray: [8, 4],
                );
              }
              return FlLine(color: Colors.grey.shade300, strokeWidth: 0.5);
            },
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.grey.shade400),
              bottom: BorderSide(color: Colors.grey.shade400),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppTheme.primaryTeal,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  if (!isBudgetCompleted && index == todayIndex) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: AppTheme.primaryTeal,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  }
                  return FlDotCirclePainter(
                    radius: 2,
                    color: AppTheme.primaryTeal,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryTeal.withOpacity(0.1),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: _currentBudget.limit,
                color: Colors.red.withOpacity(0.8),
                strokeWidth: 2,
                dashArray: [8, 4],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  labelResolver: (line) => 'Hạn mức',
                ),
              ),
            ],
            verticalLines: [
              if (!isBudgetCompleted &&
                  todayIndex >= 0 &&
                  todayIndex < totalDays)
                VerticalLine(
                  x: todayIndex.toDouble(),
                  color: AppTheme.primaryTeal.withOpacity(0.3),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: VerticalLineLabel(
                    show: true,
                    alignment: Alignment.topCenter,
                    padding: const EdgeInsets.only(bottom: 5),
                    style: TextStyle(
                      color: AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                    labelResolver: (line) => 'Hôm nay',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final remaining = (_currentBudget.limit - _totalSpent).clamp(
      -double.infinity,
      double.infinity,
    );
    final percent = _currentBudget.limit > 0
        ? (_totalSpent / _currentBudget.limit).clamp(0, 10)
        : 0.0;

    Color barColor;
    if (percent >= 1.0) {
      barColor = Colors.red;
    } else if (percent >= 0.8) {
      barColor = Colors.orange;
    } else {
      barColor = AppTheme.primaryTeal;
    }

    final timePercent = BudgetProgress.computeTimeProgressPercent(
      _currentBudget.startDate,
      _currentBudget.endDate,
      DateTime.now(),
    );

    final daysRemaining = _getDaysRemaining();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Chi tiết ngân sách',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditBudgetScreen(budget: _currentBudget),
                ),
              );
              if (result == true && mounted) {
                // Reload data after edit
                _loadData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: _showDeleteConfirmation,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header card
              Container(
                margin: const EdgeInsets.all(AppConstants.paddingMedium),
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Category icon and name
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.primaryTeal.withOpacity(
                            0.12,
                          ),
                          child: Icon(
                            _getCategoryIcon(_currentBudget.category),
                            color: AppTheme.primaryTeal,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentBudget.category,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Totals summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đã chi',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        Text(
                          NumberFormat('#,##0').format(_totalSpent),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Còn lại',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        Text(
                          NumberFormat('#,##0').format(remaining),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: remaining < 0
                                    ? Colors.red
                                    : AppTheme.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hạn mức',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        Text(
                          '${NumberFormat('#,##0').format(_currentBudget.limit)} VND',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryTeal,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Progress bar
                    BudgetProgressBar(
                      spendingPercent: _totalSpent / _currentBudget.limit,
                      timePercent: timePercent,
                      barColor: barColor,
                    ),
                  ],
                ),
              ),

              // Date and days remaining
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                ),
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${dateFormat.format(_currentBudget.startDate)} - ${dateFormat.format(_currentBudget.endDate)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          daysRemaining > 0
                              ? 'Còn $daysRemaining ngày'
                              : 'Đã kết thúc',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: daysRemaining > 0
                                    ? AppTheme.textPrimary
                                    : Colors.red,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Wallet type
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                ),
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 20,
                      color: AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: 12),
                    Text(_wallet?.name ?? 'Tất cả ví'),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Chart
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Text(
                        'Biểu đồ chi tiêu',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _buildChart(),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingMedium),

              // Transaction list button
              Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showTransactions = !_showTransactions;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.paddingMedium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Danh sách giao dịch'),
                      const SizedBox(width: 8),
                      Icon(
                        _showTransactions
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction list
              if (_showTransactions)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppConstants.paddingMedium,
                    0,
                    AppConstants.paddingMedium,
                    AppConstants.paddingMedium,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusMedium,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _transactions.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(
                            AppConstants.paddingLarge,
                          ),
                          child: Center(
                            child: Text(
                              'Chưa có giao dịch nào',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transactions.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.red.shade50,
                                child: Icon(
                                  _getCategoryIcon(tx.category),
                                  color: Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                tx.category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('dd/MM/yyyy').format(tx.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              trailing: Text(
                                '-${NumberFormat('#,##0').format(tx.amount)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              // Extra padding at bottom for scrolling
              const SizedBox(height: AppConstants.paddingLarge),
            ],
          ),
        ),
      ),
    );
  }
}
