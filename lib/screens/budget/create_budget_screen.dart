import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/budget.dart';
import '../../services/data/budget_service.dart';
import '../../services/data/category_group_service.dart';
import '../../models/category_group.dart';
import '../../widgets/category/category_picker_bottom_sheet.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/notification_helper.dart';
import 'package:uuid/uuid.dart';

import 'package:provider/provider.dart';

import '../../models/wallet.dart';
import '../../services/data/wallet_service.dart';
import '../../services/auth/auth_service.dart';

class CreateBudgetScreen extends StatefulWidget {
  const CreateBudgetScreen({super.key});

  @override
  State<CreateBudgetScreen> createState() => _CreateBudgetScreenState();
}

class _CreateBudgetScreenState extends State<CreateBudgetScreen> {
  String _selectedCategory = 'Ăn uống';
  double _amount = 0.0;
  String _note = '';
  bool _repeatBudget = false;
  DateTime _periodStart = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _periodEnd = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );
  BudgetPeriodType _periodType = BudgetPeriodType.month;

  List<CategoryGroup> _categories = [];

  List<Wallet> _wallets = [];
  String? _selectedWalletId;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadWallets();
  }

  Future<void> _loadCategories() async {
    final service = CategoryGroupService();
    final catsRaw = await service.getAll(type: CategoryType.expense);
    // Khử trùng lặp theo (type, name)
    final seen = <String>{};
    var cats = catsRaw
        .where(
          (c) => seen.add('${c.type.index}-${c.name.trim().toLowerCase()}'),
        )
        .toList();

    // Sắp xếp alphabetical, "Khác" ở cuối
    cats.sort((a, b) {
      final aIsOther = a.name.contains('Khác');
      final bIsOther = b.name.contains('Khác');
      if (aIsOther && !bIsOther) return 1;
      if (!aIsOther && bIsOther) return -1;
      return a.name.compareTo(b.name);
    });

    if (!mounted) return;
    setState(() {
      _categories = cats;
      if (_categories.isNotEmpty &&
          !_categories.any((c) => c.name == _selectedCategory)) {
        _selectedCategory = _categories.first.name;
      }
    });
  }

  Future<void> _loadWallets() async {
    final ws = WalletService();
    await ws.init();

    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.id ?? '';

    // seed default wallets for this user (idempotent)
    await ws.seedDefaultWallets(userId);

    final wallets = await ws.getAll(userId: userId);
    if (!mounted) return;
    setState(() {
      _wallets = wallets;
      // Do not auto-select a wallet — require explicit user selection.
      if (_selectedWalletId != null &&
          !_wallets.any((w) => w.id == _selectedWalletId)) {
        _selectedWalletId = null;
      }
    });
  }

  IconData _getSelectedCategoryIcon() {
    final match = _categories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => CategoryGroup(
        id: '',
        name: '',
        type: CategoryType.expense,
        iconKey: '',
        colorValue: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (match.id.isNotEmpty) {
      final asset = CategoryIconMapper.assetForKey(match.iconKey);
      if (asset != null) {
        // Using Icon fallback for small view - keep consistent with other pickers
        return CategoryIconMapper.fromKey(match.iconKey);
      }
      return CategoryIconMapper.fromKey(match.iconKey);
    }

    return CategoryIconMapper.fromKey('other');
  }

  IconData walletIcon(WalletType type) {
    switch (type) {
      case WalletType.cash:
        return Icons.money;
      case WalletType.bank:
        return Icons.account_balance;
      case WalletType.ewallet:
        return Icons.account_balance_wallet;
      case WalletType.saving:
        return Icons.savings;
      case WalletType.investment:
        return Icons.trending_up;
    }
  }

  IconData _getSelectedWalletIcon() {
    if (_selectedWalletId == null || _wallets.isEmpty)
      return Icons.account_balance_wallet;
    final w = _wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => _wallets.first,
    );
    return walletIcon(w.type);
  }

  void _showCategoryPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.8,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Chọn nhóm',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Expanded(
                    child: CategoryPickerBottomSheet(
                      type: CategoryType.expense,
                      onSelected: (group) {
                        // Chỉ cập nhật giá trị, bottom sheet tự đóng bên trong widget
                        setState(() => _selectedCategory = group.name);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showWalletPicker() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.6,
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Chọn ví',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = _wallets[index];
                        final isSelected = wallet.id == _selectedWalletId;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryTeal.withOpacity(
                              0.12,
                            ),
                            child: Icon(
                              // show wallet-specific icon
                              (() {
                                switch (wallet.type) {
                                  case WalletType.bank:
                                    return Icons.account_balance;
                                  case WalletType.ewallet:
                                    return Icons.account_balance_wallet;
                                  case WalletType.saving:
                                    return Icons.savings;
                                  case WalletType.investment:
                                    return Icons.trending_up;
                                  case WalletType.cash:
                                    return Icons.money;
                                }
                              })(),
                              color: isSelected
                                  ? AppTheme.primaryTeal
                                  : Colors.green,
                            ),
                          ),
                          title: Text(
                            wallet.name,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.primaryTeal
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            '${NumberFormat('#,##0', 'vi_VN').format(wallet.balance)} ₫',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() => _selectedWalletId = wallet.id);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPeriodPicker() async {
    final now = DateTime.now();
    BudgetPeriodType tempType = _periodType;

    DateTime monthStart = DateTime(now.year, now.month, 1);
    DateTime monthEnd = DateTime(now.year, now.month + 1, 0);

    int qIndex = ((now.month - 1) ~/ 3); // 0..3
    int qStartMonth = qIndex * 3 + 1;
    int qEndMonth = qStartMonth + 2;
    DateTime quarterStart = DateTime(now.year, qStartMonth, 1);
    DateTime quarterEnd = DateTime(now.year, qEndMonth + 1, 0);

    DateTime yearStart = DateTime(now.year, 1, 1);
    DateTime yearEnd = DateTime(now.year, 12, 31);

    String rangeLabel(DateTime s, DateTime e) {
      final df = DateFormat('dd/MM');
      return '(${df.format(s)} - ${df.format(e)})';
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Khoảng thời gian',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),

                    RadioListTile<BudgetPeriodType>(
                      value: BudgetPeriodType.month,
                      groupValue: tempType,
                      onChanged: (val) => setModalState(() => tempType = val!),
                      activeColor: AppTheme.primaryTeal,
                      title: Text(
                        'Tháng này ${rangeLabel(monthStart, monthEnd)}',
                      ),
                    ),

                    RadioListTile<BudgetPeriodType>(
                      value: BudgetPeriodType.quarter,
                      groupValue: tempType,
                      onChanged: (val) => setModalState(() => tempType = val!),
                      activeColor: AppTheme.primaryTeal,
                      title: Text(
                        'Quý này ${rangeLabel(quarterStart, quarterEnd)}',
                      ),
                    ),

                    RadioListTile<BudgetPeriodType>(
                      value: BudgetPeriodType.year,
                      groupValue: tempType,
                      onChanged: (val) => setModalState(() => tempType = val!),
                      activeColor: AppTheme.primaryTeal,
                      title: Text('Năm nay ${rangeLabel(yearStart, yearEnd)}'),
                    ),

                    RadioListTile<BudgetPeriodType>(
                      value: BudgetPeriodType.custom,
                      groupValue: tempType,
                      onChanged: (val) => setModalState(() => tempType = val!),
                      activeColor: AppTheme.primaryTeal,
                      title: const Text('Tùy chỉnh'),
                    ),

                    const SizedBox(height: AppConstants.paddingMedium),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            if (tempType == BudgetPeriodType.custom) {
                              final initialRange = DateTimeRange(
                                start: _periodStart,
                                end: _periodEnd,
                              );
                              final picked = await showDateRangePicker(
                                context: context,
                                initialDateRange: initialRange,
                                firstDate: DateTime(now.year - 5, 1, 1),
                                lastDate: DateTime(now.year + 5, 12, 31),
                                helpText: 'Chọn khoảng thời gian',
                                builder: (context, child) {
                                  final scheme = Theme.of(context).colorScheme;
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: scheme.copyWith(
                                        primary: AppTheme.primaryTeal,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: AppTheme.textPrimary,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppTheme.primaryTeal,
                                        ),
                                      ),
                                    ),
                                    child: child ?? const SizedBox.shrink(),
                                  );
                                },
                              );
                              if (!context.mounted) return;
                              if (picked != null) {
                                setState(() {
                                  _periodType = tempType;
                                  _periodStart = picked.start;
                                  _periodEnd = picked.end;
                                });
                              }
                              Navigator.pop(context);
                              return;
                            }

                            setState(() {
                              _periodType = tempType;
                              if (tempType == BudgetPeriodType.month) {
                                _periodStart = monthStart;
                                _periodEnd = monthEnd;
                              } else if (tempType == BudgetPeriodType.quarter) {
                                _periodStart = quarterStart;
                                _periodEnd = quarterEnd;
                              } else if (tempType == BudgetPeriodType.year) {
                                _periodStart = yearStart;
                                _periodEnd = yearEnd;
                              }
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Lưu'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _periodLabel() {
    final df = DateFormat('dd/MM');
    final range = '(${df.format(_periodStart)} - ${df.format(_periodEnd)})';
    switch (_periodType) {
      case BudgetPeriodType.month:
        return 'Tháng này $range';
      case BudgetPeriodType.quarter:
        return 'Quý này $range';
      case BudgetPeriodType.year:
        return 'Năm nay $range';
      case BudgetPeriodType.custom:
        return 'Tùy chỉnh $range';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Thêm ngân sách',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
              // Card-like container for fields
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Category (Chọn nhóm)
                    ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                        child: Icon(
                          _getSelectedCategoryIcon(),
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                      title: Text('Chọn nhóm'),
                      subtitle: Text(
                        _selectedCategory,
                        style: TextStyle(color: AppTheme.primaryTeal),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondary,
                      ),
                      onTap: _showCategoryPicker,
                    ),
                    const Divider(height: 1),

                    // Amount (Số tiền)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                        vertical: AppConstants.paddingMedium,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('VND'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: _amount == 0
                                  ? ''
                                  : NumberFormat('#,##0').format(_amount),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                              ),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                              onChanged: (value) {
                                final clean = value
                                    .replaceAll('.', '')
                                    .replaceAll(',', '');
                                setState(
                                  () => _amount = double.tryParse(clean) ?? 0.0,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Period (Tháng này)
                    ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: AppTheme.textSecondary,
                      ),
                      title: Text(_periodLabel()),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondary,
                      ),
                      onTap: _showPeriodPicker,
                    ),
                    const Divider(height: 1),

                    // Wallet (Tổng cộng)
                    ListTile(
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryTeal.withOpacity(0.12),
                        child: Icon(
                          _getSelectedWalletIcon(),
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                      title: const Text('Chọn ví'),
                      subtitle: Text(
                        // show wallet name + balance if present; otherwise show explicit placeholder
                        _selectedWalletId == null
                            ? 'Chưa chọn ví'
                            : '${_wallets.firstWhere(
                                (w) => w.id == _selectedWalletId,
                                orElse: () => Wallet(id: 'unknown', userId: '', name: 'Ví không xác định', type: WalletType.cash, balance: 0, isDefault: false, createdAt: DateTime.now()),
                              ).name} • ${NumberFormat('#,##0', 'vi_VN').format(_wallets.firstWhere(
                                (w) => w.id == _selectedWalletId,
                                orElse: () => Wallet(id: 'unknown', userId: '', name: 'Ví không xác định', type: WalletType.cash, balance: 0, isDefault: false, createdAt: DateTime.now()),
                              ).balance)} ₫',
                        style: TextStyle(
                          color: _selectedWalletId == null
                              ? AppTheme.primaryTeal
                              : AppTheme.textSecondary,
                        ),
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        color: AppTheme.textSecondary,
                      ),
                      onTap: _showWalletPicker,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Repeat budget checkbox
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingMedium,
                  vertical: AppConstants.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _repeatBudget,
                      onChanged: (val) =>
                          setState(() => _repeatBudget = val ?? false),
                      activeColor: AppTheme.primaryTeal,
                      checkColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Lặp lại ngân sách này'),
                          SizedBox(height: 4),
                          Text(
                            'Ngân sách được tự động lặp lại ở kỳ hạn tiếp theo.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Optional note
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  maxLines: 3,
                  cursorColor: AppTheme.primaryTeal,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryTeal,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: AppTheme.primaryTeal.withOpacity(0.9),
                    ),
                  ),
                  onChanged: (v) => setState(() => _note = v.trim()),
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge * 1.5),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_amount <= 0) {
                      AppNotification.showError(
                        context,
                        'Vui lòng nhập số tiền hợp lệ',
                      );
                      return;
                    }
                    if (_periodStart.isAfter(_periodEnd)) {
                      AppNotification.showError(
                        context,
                        'Ngày bắt đầu phải nhỏ hơn hoặc bằng ngày kết thúc',
                      );
                      return;
                    }
                    // Reject budgets with end date in the past (date-only comparison)
                    final today = DateTime.now();
                    final todayDate = DateTime(
                      today.year,
                      today.month,
                      today.day,
                    );
                    final endDateOnly = DateTime(
                      _periodEnd.year,
                      _periodEnd.month,
                      _periodEnd.day,
                    );
                    if (endDateOnly.isBefore(todayDate)) {
                      AppNotification.showError(
                        context,
                        'Ngày kết thúc ngân sách không được trong quá khứ',
                      );
                      return;
                    }
                    // Ensure category exists in admin categories (create non-system group if needed)
                    final catService = CategoryGroupService();
                    final cats = await catService.getAll(
                      type: CategoryType.expense,
                    );
                    if (!cats.any((c) => c.name == _selectedCategory)) {
                      final newGroup = CategoryGroup(
                        id: const Uuid().v4(),
                        name: _selectedCategory,
                        type: CategoryType.expense,
                        iconKey: 'other',
                        colorValue: 0xFF9E9E9E,
                        isSystem: false,
                        createdAt: DateTime.now(),
                      );
                      try {
                        await catService.add(newGroup);
                        await _loadCategories();
                      } catch (_) {
                        // ignore - duplicate handling done in service
                      }
                    }

                    final service = BudgetService();
                    await service.init(); // Ensure Hive is initialized
                    if (!context.mounted) return;
                    final auth = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final userId = auth.currentUser?.id ?? '';

                    final exists = service.existsOverlappingBudget(
                      category: _selectedCategory,
                      start: _periodStart,
                      end: _periodEnd,
                      userId: userId,
                      walletId: _selectedWalletId,
                    );
                    if (exists) {
                      if (!context.mounted) return;
                      AppNotification.showError(
                        context,
                        'Đã có ngân sách cho danh mục này trong ví và khoảng thời gian trùng lặp',
                      );
                      return;
                    }

                    // Ensure wallet was selected explicitly
                    if (_selectedWalletId == null ||
                        _selectedWalletId!.isEmpty) {
                      AppNotification.showError(context, 'Vui lòng chọn ví');
                      return;
                    }

                    final newBudget = Budget(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      category: _selectedCategory,
                      limit: _amount,
                      startDate: _periodStart,
                      endDate: _periodEnd,
                      periodType: _periodType,
                      note: _note.isEmpty ? null : _note,
                      walletId: _selectedWalletId,
                      userId: userId,
                    );
                    try {
                      await service.addBudget(newBudget, userId: userId);
                      if (!context.mounted) return;
                      AppNotification.showSuccess(
                        context,
                        '\u0110ã lưu ngân sách',
                      );
                      Navigator.pop(context, true);
                    } catch (e) {
                      if (!context.mounted) return;
                      AppNotification.showError(context, e.toString());
                    }
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
                  child: const Text('Lưu'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
