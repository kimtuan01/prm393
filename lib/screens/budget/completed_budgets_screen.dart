import 'package:expense_tracker_app/models/category_group.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../services/data/category_group_service.dart';
import '../../services/data/transaction_notifier.dart';
import '../../utils/category_icon_mapper.dart';
import '../../config/theme.dart';
import '../../models/budget.dart';
import '../../services/auth/auth_service.dart';
import '../../services/data/budget_service.dart';
import '../../services/data/transaction_service.dart';
import '../../services/core/budget_progress.dart';
import 'budget_detail_screen.dart';
import '_progress_bar.dart';

class CompletedBudgetsScreen extends StatefulWidget {
  const CompletedBudgetsScreen({super.key});

  @override
  State<CompletedBudgetsScreen> createState() => _CompletedBudgetsScreenState();
}

class _CompletedBudgetsScreenState extends State<CompletedBudgetsScreen> {
  final BudgetService _budgetService = BudgetService();
  final TransactionService _transactionService = TransactionService();

  // cached categories
  List<CategoryGroup> _categories = [];

  // Cached notifier for safe listener management
  TransactionNotifier? _transactionNotifier;

  @override
  void initState() {
    super.initState();
    _budgetService.init();
    // preload categories
    CategoryGroupService().getAll(type: CategoryType.expense).then((cats) {
      _categories = cats;
      if (mounted) setState(() {});
    });
  }

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

  @override
  void dispose() {
    _transactionNotifier?.removeListener(_onTransactionChanged);
    super.dispose();
  }

  void _onTransactionChanged() {
    // Refresh completed budgets when transactions change
    if (mounted) setState(() {});
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

  List<Budget> _getCompletedBudgets() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.id ?? '';

    return _budgetService.getAllBudgets(userId: userId).where((b) {
      final endDate = DateTime(b.endDate.year, b.endDate.month, b.endDate.day);
      return endDate.isBefore(today);
    }).toList()..sort(
      (a, b) => b.endDate.compareTo(a.endDate),
    ); // Mới nhất trước
  }

  Future<void> _onRefresh() async {
    await _budgetService.init();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    final completedBudgets = _getCompletedBudgets();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 60,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ngân sách đã kết thúc',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: completedBudgets.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppTheme.primaryTeal,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: completedBudgets.length,
                itemBuilder: (context, index) {
                  final b = completedBudgets[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BudgetDetailScreen(budget: b),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    child: Container(
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
                      child: FutureBuilder<double>(
                        future: _budgetService.computeTotalSpentForBudget(
                          budget: b,
                          transactionService: _transactionService,
                          userId: userId,
                        ),
                        builder: (context, snapshot) {
                          final spent = snapshot.data ?? 0;
                          final remaining = (b.limit - spent).clamp(
                            -double.infinity,
                            double.infinity,
                          );
                          final percent = b.limit > 0
                              ? (spent / b.limit).clamp(0, 10)
                              : 0.0;
                          Color barColor;
                          if (percent >= 1.0) {
                            barColor = Colors.red;
                          } else if (percent >= 0.8) {
                            barColor = Colors.orange;
                          } else {
                            barColor = AppTheme.primaryTeal;
                          }

                          final dateFormat = DateFormat('dd/MM/yyyy');
                          final startStr = dateFormat.format(b.startDate);
                          final endStr = dateFormat.format(b.endDate);
                          final timePercent =
                              BudgetProgress.computeTimeProgressPercent(
                                b.startDate,
                                b.endDate,
                                DateTime.now(),
                              );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: Category Icon + Name & Limit
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Colors.grey
                                              .withOpacity(0.12),
                                          child: Icon(
                                            _getCategoryIcon(b.category),
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            b.category,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat('#,##0').format(b.limit)} VND',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Date range + Completed badge
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$startStr → $endStr',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Đã kết thúc',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Spent & Remaining
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Đã chi: ${NumberFormat('#,##0').format(spent)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  Text(
                                    'Còn lại: ${NumberFormat('#,##0').format(remaining)}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: remaining < 0
                                              ? Colors.red
                                              : AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              BudgetProgressBar(
                                spendingPercent: (spent / b.limit),
                                timePercent: timePercent,
                                barColor: barColor,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primaryTeal,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.check_circle_outline,
            size: 100,
            color: AppTheme.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          Text(
            'Danh sách ngân sách đã kết thúc trống',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Các ngân sách đã kết thúc sẽ xuất hiện tại đây',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
