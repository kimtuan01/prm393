import 'package:expense_tracker_app/models/category_group.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/budget.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../widgets/user_avatar.dart';
import '../../services/auth/auth_service.dart';
import '../../services/data/budget_service.dart';
import '../../services/data/transaction_service.dart';
import '../../services/data/transaction_notifier.dart';
import '../../services/data/category_group_service.dart';
import '../../services/data/wallet_service.dart';
import '../auth/login_screen.dart';
import '../../services/core/budget_progress.dart';
import '../../utils/category_icon_mapper.dart';
import '_progress_bar.dart';
import 'create_budget_screen.dart';
import 'budget_detail_screen.dart';
import 'completed_budgets_screen.dart';

enum BudgetSortOption { startDateAsc, endDateAsc, limitDesc }

class BudgetScreen extends StatefulWidget {
  final bool embedded;

  const BudgetScreen({super.key, this.embedded = false});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  int _selectedNavIndex = 3; // Budget tab
  late DateTime _periodStart;
  late DateTime _periodEnd;
  final Set<BudgetPeriodType> _visiblePeriods = {};
  final BudgetService _budgetService = BudgetService();
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();
  BudgetSortOption _sort = BudgetSortOption.startDateAsc;

  // Cached category groups for display (expense groups)
  List<CategoryGroup> _categories = [];

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedNavIndex = index;
    });

    if (index != 3) {
      Navigator.pop(context);
    }
  }

  // Cached notifier for safe listener handling
  TransactionNotifier? _transactionNotifier;

  @override
  void initState() {
    super.initState();
    _initializeBudgetService();
    final now = DateTime.now();
    _periodStart = DateTime(now.year, now.month, 1);
    _periodEnd = DateTime(now.year, now.month + 1, 0);
    _refreshVisiblePeriods();
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
    // Refresh budgets when transactions change
    _refreshVisiblePeriods();
  }

  Future<void> _initializeBudgetService() async {
    await _budgetService.init();
    // Preload categories used by budget UI
    final catService = CategoryGroupService();
    _categories = await catService.getAll(type: CategoryType.expense);
    _refreshVisiblePeriods();
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: _onNavItemTapped,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.cardColor,
      selectedItemColor: AppTheme.primaryTeal,
      unselectedItemColor: AppTheme.textSecondary,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Trang chủ',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.sync_alt), label: 'Giao dịch'),
        BottomNavigationBarItem(icon: SizedBox.shrink(), label: ''),
        BottomNavigationBarItem(
          icon: Icon(Icons.pie_chart_outline),
          activeIcon: Icon(Icons.pie_chart),
          label: 'Ngân sách',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Tài khoản',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Verify user is logged in
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userName = currentUser.fullName;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 60,
        leadingWidth: 64,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: UserAvatar(radius: 20),
        ),
        title: const Text(
          'Ngân sách',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateBudgetScreen()),
              );
              if (result == true && mounted) {
                _markPeriodsWithNewBudget();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppTheme.cardColor,
            onSelected: (value) {
              if (value == 'completed') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CompletedBudgetsScreen(),
                  ),
                ).then((_) {
                  setState(() {});
                });
              } else if (value == 'sort_start') {
                setState(() => _sort = BudgetSortOption.startDateAsc);
              } else if (value == 'sort_end') {
                setState(() => _sort = BudgetSortOption.endDateAsc);
              } else if (value == 'sort_limit') {
                setState(() => _sort = BudgetSortOption.limitDesc);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'completed',
                child: Text('Xem ngân sách đã kết thúc'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sort_start',
                child: Text('Sắp xếp: Ngày bắt đầu ↑'),
              ),
              const PopupMenuItem<String>(
                value: 'sort_end',
                child: Text('Sắp xếp: Ngày kết thúc ↑'),
              ),
              const PopupMenuItem<String>(
                value: 'sort_limit',
                child: Text('Sắp xếp: Giới hạn ↓'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _visiblePeriods.isNotEmpty
            ? _buildBudgetsList(userName)
            : _buildEmptyState(userName),
      ),
      bottomNavigationBar: widget.embedded ? null : _buildBottomNavBar(),
    );
  }

  Widget _buildEmptyState(String userName) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 100,
              color: AppTheme.textSecondary.withOpacity(0.3),
            ),
            SizedBox(height: AppConstants.paddingLarge),
            Text(
              'Bạn chưa có ngân sách nào',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.paddingSmall),
            Text(
              'Hãy tạo ngân sách để kiểm soát chi tiêu hiệu quả hơn',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppConstants.paddingLarge * 1.2),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateBudgetScreen()),
                );
                if (result == true && mounted) {
                  _markPeriodsWithNewBudget();
                  // TODO: load budgets from storage when available and set visible periods accordingly
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tạo ngân sách'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge,
                  vertical: AppConstants.paddingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  Widget _buildBudgetsList(String userName) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;

    // Filter budgets overlapping the selected period range and not completed
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    var budgets = _budgetService
        .getBudgetsOverlapping(_periodStart, _periodEnd)
        .where((b) {
          final endDate = DateTime(
            b.endDate.year,
            b.endDate.month,
            b.endDate.day,
          );
          return !endDate.isBefore(today); // Chỉ lấy ngân sách chưa kết thúc
        })
        .toList();

    budgets.sort((a, b) {
      switch (_sort) {
        case BudgetSortOption.startDateAsc:
          return a.startDate.compareTo(b.startDate);
        case BudgetSortOption.endDateAsc:
          return a.endDate.compareTo(b.endDate);
        case BudgetSortOption.limitDesc:
          return b.limit.compareTo(a.limit);
      }
    });

    Future<void> _onRefresh() async {
      await _budgetService.init();
      setState(() {});
    }

    if (budgets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.primaryTeal,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(AppConstants.paddingMedium),
          children: const [SizedBox.shrink()],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppTheme.primaryTeal,
      child: ListView.separated(
        padding: EdgeInsets.all(AppConstants.paddingMedium),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: budgets.length,
        itemBuilder: (context, index) {
          final b = budgets[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BudgetDetailScreen(budget: b, walletId: b.walletId),
                ),
              ).then((_) {
                // Refresh list after returning from detail
                setState(() {});
              });
            },
            child: Container(
              padding: EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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
                  final timePercent = BudgetProgress.computeTimeProgressPercent(
                    b.startDate,
                    b.endDate,
                    DateTime.now(),
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Category Icon + Name & Limit
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primaryTeal
                                      .withOpacity(0.12),
                                  child: Icon(
                                    _getCategoryIcon(b.category),
                                    color: AppTheme.primaryTeal,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        b.category,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      FutureBuilder<String>(
                                        future: _getWalletName(b.walletId),
                                        builder: (context, snapshot) {
                                          final walletName =
                                              snapshot.data ?? 'Đang tải...';
                                          return Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .account_balance_wallet_outlined,
                                                size: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  walletName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppTheme
                                                            .textSecondary,
                                                      ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${NumberFormat('#,##0').format(b.limit)} VND',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Date range
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
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Spent & Remaining
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Đã chi: ${NumberFormat('#,##0').format(spent)}',
                            style: Theme.of(context).textTheme.bodySmall,
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
    );
  }

  // NOTE: _setPeriod removed — unused in current UI. Leave logic in history if needed later.

  void _markPeriodsWithNewBudget() {
    _refreshVisiblePeriods();
    final now = DateTime.now();
    setState(() {
      _periodStart = DateTime(now.year, now.month, 1);
      _periodEnd = DateTime(now.year, now.month + 1, 0);
    });
  }

  void _refreshVisiblePeriods() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    final qIndex = ((now.month - 1) ~/ 3);
    final qStartMonth = qIndex * 3 + 1;
    final qEndMonth = qStartMonth + 2;
    final quarterStart = DateTime(now.year, qStartMonth, 1);
    final quarterEnd = DateTime(now.year, qEndMonth + 1, 0);

    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);

    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.id;
    final budgets = _budgetService.getAllBudgets(userId: userId);
    final visible = <BudgetPeriodType>{};
    if (budgets.any((b) => b.overlaps(monthStart, monthEnd))) {
      visible.add(BudgetPeriodType.month);
    }
    if (budgets.any((b) => b.overlaps(quarterStart, quarterEnd))) {
      visible.add(BudgetPeriodType.quarter);
    }
    if (budgets.any((b) => b.overlaps(yearStart, yearEnd))) {
      visible.add(BudgetPeriodType.year);
    }
    // custom is added only when user selects a custom range and there are budgets overlapping it
    setState(() {
      _visiblePeriods
        ..clear()
        ..addAll(visible);
    });
  }

  Future<String> _getWalletName(String? walletId) async {
    if (walletId == null || walletId.isEmpty) {
      return 'Chưa chọn ví';
    }
    final wallet = await _walletService.getById(walletId);
    return wallet?.name ?? 'Ví không tìm thấy';
  }
}

// Using BudgetPeriodType from models/budget.dart
