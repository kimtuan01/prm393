import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/budget.dart';
import '../../services/data/budget_service.dart';
import '../../models/wallet.dart';
import '../../services/data/wallet_service.dart';
import '../../services/auth/auth_service.dart';
import '../../services/data/category_group_service.dart';
import '../../models/category_group.dart';
import '../../widgets/category/category_picker_bottom_sheet.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/notification_helper.dart';
import 'package:uuid/uuid.dart';

class EditBudgetScreen extends StatefulWidget {
  final Budget budget;

  const EditBudgetScreen({super.key, required this.budget});

  @override
  State<EditBudgetScreen> createState() => _EditBudgetScreenState();
}

class _EditBudgetScreenState extends State<EditBudgetScreen> {
  late String _selectedCategory;
  late double _amount;
  late String _note;
  late DateTime _periodStart;
  late DateTime _periodEnd;
  late BudgetPeriodType _periodType;

  List<CategoryGroup> _categories = [];

  List<Wallet> _wallets = [];
  String? _selectedWalletId;

  // UI: persistent controller for the note field to preserve cursor and text across rebuilds
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    // Pre-fill với dữ liệu budget hiện tại
    _selectedCategory = widget.budget.category;
    _amount = widget.budget.limit;
    _note = widget.budget.note ?? '';
    _periodStart = widget.budget.startDate;
    _periodEnd = widget.budget.endDate;
    _periodType = widget.budget.periodType;

    // Initialize the note controller once to avoid recreating it on each build
    _noteController = TextEditingController(text: _note);

    _loadCategories();
    _loadWallets();
  }

  Future<void> _loadCategories() async {
    final service = CategoryGroupService();
    final cats = await service.getAll(type: CategoryType.expense);
    if (!mounted) return;
    setState(() {
      _categories = cats;
      // Keep existing budget category even if not present in seed; user can switch to seeded groups
    });
  }

  Future<void> _loadWallets() async {
    final service = WalletService();
    await service.init();

    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.id ?? '';

    if (userId.isNotEmpty) {
      await service.seedDefaultWallets(userId);
    }

    final wallets = await service.getAll(
      userId: userId.isNotEmpty ? userId : null,
    );
    if (!mounted) return;

    setState(() {
      _wallets = wallets;
      // Keep selection if it still exists; otherwise require the user to select explicitly
      if (_wallets.any((w) => w.id == widget.budget.walletId)) {
        _selectedWalletId = widget.budget.walletId;
      } else {
        _selectedWalletId = null;
      }
    });
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
      return CategoryIconMapper.fromKey(match.iconKey);
    }
    return CategoryIconMapper.fromKey('other');
  }

  IconData _getSelectedWalletIcon() {
    if (_selectedWalletId == null || _wallets.isEmpty)
      return Icons.account_balance_wallet;

    final w = _wallets.firstWhere(
      (x) => x.id == _selectedWalletId,
      orElse: () => Wallet(
        id: 'unknown',
        userId: '',
        name: 'Ví',
        type: WalletType.cash,
        balance: 0,
        isDefault: false,
        createdAt: DateTime.now(),
      ),
    );

    switch (w.type) {
      case WalletType.bank:
        return Icons.account_balance;
      case WalletType.ewallet:
        return Icons.account_balance_wallet;
      case WalletType.saving:
        return Icons.savings;
      case WalletType.investment:
        return Icons.trending_up;
      case WalletType.cash:
        return Icons.account_balance_wallet;
    }
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
                        setState(() => _selectedCategory = group.name);
                        // CategoryPickerBottomSheet handles pop itself
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

    int qIndex = ((now.month - 1) ~/ 3);
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
    // Resolve selected wallet safely for display purposes
    final Wallet? selectedWallet = (() {
      if (_selectedWalletId == null) return null;
      try {
        return _wallets.firstWhere((w) => w.id == _selectedWalletId);
      } catch (_) {
        return null;
      }
    })();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Chỉnh sửa ngân sách',
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
                      title: const Text('Chọn nhóm'),
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
                              initialValue: NumberFormat(
                                '#,##0',
                              ).format(_amount),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0',
                              ),
                              style: const TextStyle(
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

                    // Period
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
                        selectedWallet == null
                            ? 'Chưa chọn ví'
                            : '${selectedWallet.name} • ${NumberFormat('#,##0', 'vi_VN').format(selectedWallet.balance)} ₫',
                        style: TextStyle(
                          color: selectedWallet == null
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
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  cursorColor: AppTheme.primaryTeal,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    hintText: 'Nhập ghi chú...',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppTheme.primaryTeal,
                        width: 2,
                      ),
                    ),
                    hintStyle: TextStyle(color: AppTheme.textSecondary),
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

                    // Require explicit wallet selection
                    if (_selectedWalletId == null ||
                        _selectedWalletId!.isEmpty) {
                      AppNotification.showError(context, 'Vui lòng chọn ví');
                      return;
                    }

                    // Check for overlapping budgets (excluding current budget)
                    final service = BudgetService();
                    await service.init();
                    final auth = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final userId = auth.currentUser?.id ?? '';

                    // Check if there's another budget with same category, wallet and overlapping time
                    final allBudgets = service.getAllBudgets(userId: userId);
                    final hasOverlap = allBudgets.any(
                      (b) =>
                          b.id != widget.budget.id && // Exclude current budget
                          b.category == _selectedCategory &&
                          b.walletId == _selectedWalletId &&
                          b.overlaps(_periodStart, _periodEnd),
                    );

                    if (hasOverlap) {
                      if (!context.mounted) return;
                      AppNotification.showError(
                        context,
                        'Đã có ngân sách cho danh mục này trong ví và khoảng thời gian trùng lặp. Vui lòng chọn ví khác hoặc thời gian khác',
                      );
                      return;
                    }

                    final updatedBudget = Budget(
                      id: widget.budget.id, // Giữ nguyên ID
                      category: _selectedCategory,
                      limit: _amount,
                      startDate: _periodStart,
                      endDate: _periodEnd,
                      periodType: _periodType,
                      note: _note.isEmpty ? null : _note,
                      walletId: _selectedWalletId,
                    );

                    try {
                      // Ensure category exists in admin categories
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
                        } catch (_) {}
                      }

                      await service.updateBudget(updatedBudget, userId: userId);
                      if (!context.mounted) return;
                      AppNotification.showSuccess(
                        context,
                        'Đã cập nhật ngân sách',
                      );
                      Navigator.pop(
                        context,
                        true,
                      ); // Return true to signal refresh
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
