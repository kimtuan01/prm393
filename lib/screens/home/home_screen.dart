import 'package:provider/provider.dart';
import '../../services/data/notification_service.dart';
import '../notification/notification_center_screen.dart';
import '../../widgets/user_avatar.dart';
import 'package:expense_tracker_app/widgets/home/balance_card_widget.dart';
import 'package:expense_tracker_app/widgets/home/chart_widget.dart';
import 'package:expense_tracker_app/widgets/home/recent_transactions_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../services/data/wallet_service.dart';
import '../../config/theme.dart';
import 'package:hive/hive.dart';
import '../../services/auth/auth_service.dart';
import '../../services/data/transaction_service.dart';
import '../../services/data/transaction_notifier.dart';
import '../../models/transaction.dart' as model;
import '../../models/category_group.dart';
import '../../utils/category_icon_mapper.dart';
import '../transaction/add_transaction_screen.dart';
import '../transaction/transactions_screen.dart';
import '../budget/budget_screen.dart';
import '../profile/profile_screen.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _selectedYear = DateTime.now().year;

  final TransactionService _transactionService = TransactionService();

  // Data from database
  double _totalBalance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  List<model.Transaction> _allTransactions = [];
  List<Map<String, dynamic>> _recentTransactions = [];
  final Map<int, double> _monthlyExpenses = {}; // For chart

  bool _isLoading = true;

  // Cached notifier for safe listener handling
  TransactionNotifier? _transactionNotifier;

  @override
  void initState() {
    super.initState();

    // Defer loading to after first frame but avoid using context in dispose later
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
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
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id;

      if (userId == null || userId.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      // Load transactions
      _allTransactions =
      await _transactionService.getAllTransactions(userId: userId);

      // Reset totals
      _totalIncome = 0;
      _totalExpense = 0;

      for (final t in _allTransactions) {
        switch (t.type) {
          case model.TransactionType.income:
            _totalIncome += t.amount;
            break;

          case model.TransactionType.expense:
            _totalExpense += t.amount;
            break;

          case model.TransactionType.loanIn:
          // không tính vào income
            break;

          case model.TransactionType.loanOut:
          // không tính vào expense
            break;
        }
      }

      // ✅ CHUẨN PRODUCTION: balance lấy từ wallets
      final walletService = WalletService();
      final wallets = await walletService.getByUser(userId);

      _totalBalance = wallets.fold(
        0.0,
            (sum, wallet) => sum + wallet.balance,
      );

      // Recent transactions
      final recentList = _allTransactions.toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final categoryBox = Hive.box<CategoryGroup>('category_groups');

      _recentTransactions = recentList.take(5).map((t) {
        CategoryGroup? group;

        if (t.categoryId != null && t.categoryId!.isNotEmpty) {
          group = categoryBox.get(t.categoryId);
        }

        group ??= categoryBox.values.firstWhere(
              (g) => g.name.toLowerCase() == t.category.toLowerCase(),
          orElse: () => CategoryGroup(
            id: '',
            name: t.category,
            type: CategoryType.expense,
            iconKey: 'other',
            colorValue: 0xFF9E9E9E,
            createdAt: DateTime.now(),
          ),
        );

        return {
          'id': t.id,
          'title': t.category,
          'subtitle': DateFormat('dd/MM/yyyy').format(t.date),
          'amount': (t.type == model.TransactionType.expense ||
              t.type == model.TransactionType.loanOut)
              ? -t.amount
              : t.amount,
          'date': DateFormat('dd/MM/yyyy').format(t.date),
          'iconPath': CategoryIconMapper.assetForKey(group.iconKey),
          'iconKey': group.iconKey,
          'color': Color(group.colorValue),
        };
      }).toList();

      _calculateMonthlyExpenses();
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateMonthlyExpenses() {
    _monthlyExpenses.clear();

    // Initialize all months with 0
    for (int i = 1; i <= 12; i++) {
      _monthlyExpenses[i] = 0;
    }

    // Calculate expenses for each month in selected year
    for (var transaction in _allTransactions) {
      if (transaction.date.year == _selectedYear &&
          transaction.type == model.TransactionType.expense) {
        final month = transaction.date.month;
        _monthlyExpenses[month] =
            (_monthlyExpenses[month] ?? 0) + transaction.amount;
      }
    }
  }

  // YearPicker
  Future<void> _showYearPicker(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Chọn năm'),
          contentPadding: const EdgeInsets.all(0),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
              selectedDate: DateTime(_selectedYear),
              onChanged: (DateTime dateTime) {
                setState(() {
                  _selectedYear = dateTime.year;
                  _calculateMonthlyExpenses(); // Recalculate for new year
                });
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );

    if (!mounted) return;
  }

  void _onItemTapped(int index) {
    // Middle slot reserved for the FAB; open add flow instead of switching
    if (index == 2) {
      _openAddTransaction();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🔒 CRITICAL: Verify user is still logged in on every build
    final authService = context.watch<AuthService>();
    final currentUser = authService.currentUser;

    // If no user logged in, redirect to login
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360 || screenHeight < 700;
    final padding = isSmallScreen ? 12.0 : AppConstants.paddingMedium;
    final spacing = isSmallScreen ? 12.0 : AppConstants.paddingLarge;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildHomeTab(padding, spacing),
          const TransactionsScreen(),
          const SizedBox.shrink(), // placeholder for FAB slot
          const BudgetScreen(embedded: true),
          const ProfileScreen(),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: _buildBottomNavBar(),

      // Floating Action Button (Add button)
      // Keep FAB visible on Home, Transactions, Budget, and Accounts tabs
      floatingActionButton:
          (_selectedIndex == 0 ||
              _selectedIndex == 1 ||
              _selectedIndex == 3 ||
              _selectedIndex == 4)
          ? FloatingActionButton(
              onPressed: _openAddTransaction,
              backgroundColor: AppTheme.primaryTeal,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 32, color: Colors.white),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildHeader() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userName = authService.currentUser?.fullName ?? 'User';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar
        const UserAvatar(radius: 24),

        // Name
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Xin chào,',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        // Notification Icon with unread badge
        Consumer<NotificationService>(
          builder: (context, notif, _) {
            final unread = notif.unreadCount;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  color: AppTheme.primaryTeal,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationCenterScreen(),
                      ),
                    );
                  },
                ),
                if (unread > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Thống kê',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            // ✅ Year filter button - Clickable
            InkWell(
              onTap: () => _showYearPicker(context), // Call year picker
              borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                ),
                child: Row(
                  children: [
                    Text(
                      'Year - $_selectedYear', // ✅ Hiển thị năm được chọn
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: AppTheme.primaryTeal,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: AppConstants.paddingMedium),

        // Chart Widget with real data
        ChartWidget(monthlyData: _monthlyExpenses),
      ],
    );
  }

  // Home tab content wrapped so it can live inside IndexedStack
  Widget _buildHomeTab(double padding, double spacing) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryTeal),
      );
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar, name, notification
                _buildHeader(),

                SizedBox(height: spacing),

                // Balance Card with real data
                BalanceCardWidget(balance: _totalBalance),

                SizedBox(height: padding),

                // Income & Expense Summary
                _buildSummaryCards(),

                SizedBox(height: spacing),

                // Chart Section
                _buildChartSection(),

                SizedBox(height: spacing),

                // Recent Transactions
                _recentTransactions.isEmpty
                    ? Center(child: _buildEmptyState())
                    : RecentTransactionsWidget(
                        transactions: _recentTransactions,
                        onViewAll: () {
                          setState(() {
                            _selectedIndex = 1;
                          });
                        },
                      ),

                const SizedBox(height: 80), // Space for FAB
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
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
        BottomNavigationBarItem(
          icon: SizedBox.shrink(), // Placeholder for FAB
          label: '',
        ),
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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        // Income Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(
                color: Colors.green.withAlpha((0.3 * 255).round()),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Thu nhập',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  NumberFormat('#,##0').format(_totalIncome),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  AppConstants.currencySymbol,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.withAlpha((0.7 * 255).round()),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: AppConstants.paddingMedium),
        // Expense Card
        Expanded(
          child: Container(
            padding: EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha((0.1 * 255).round()),
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(
                color: Colors.red.withAlpha((0.3 * 255).round()),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Chi tiêu',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  NumberFormat('#,##0').format(_totalExpense),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                Text(
                  AppConstants.currencySymbol,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.withAlpha((0.7 * 255).round()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(AppConstants.paddingLarge * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: AppTheme.textSecondary.withAlpha((0.5 * 255).round()),
          ),
          SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Chưa có giao dịch',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppConstants.paddingSmall),
          Text(
            'Nhấn nút + để thêm giao dịch đầu tiên',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddTransactionScreen()),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }
}
