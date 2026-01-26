import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../services/data/transaction_service.dart';
import '../../services/data/transaction_notifier.dart';
import '../../services/auth/auth_service.dart';
import '../../models/category_group.dart';
import '../../utils/category_icon_mapper.dart';
import '../../models/wallet.dart';
import '../../services/data/wallet_service.dart';
import '../../utils/notification_helper.dart';

class EditTransactionScreen extends StatefulWidget {
  final model.Transaction transaction;

  const EditTransactionScreen({super.key, required this.transaction});

  @override
  State<EditTransactionScreen> createState() => _EditTransactionScreenState();
}

class _EditTransactionScreenState extends State<EditTransactionScreen> {
  int _selectedTab = 0; // 0: Khoản chi, 1: Khoản thu, 2: Vay/Nợ
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();

  // Wallets
  List<Wallet> _wallets = [];
  String? _selectedWalletId;

  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TransactionService _transactionService = TransactionService();

  /// DANH MỤC TỪ HIVE
  List<CategoryGroup> _categories = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeFromTransaction();
    _loadWallets();
  }

  void _initializeFromTransaction() {
    final tx = widget.transaction;

    // Set tab based on transaction type (handle loan as separate tab)
    if (tx.type == model.TransactionType.loan) {
      _selectedTab = 2;
    } else if (tx.type == model.TransactionType.income) {
      _selectedTab = 1;
    } else {
      _selectedTab = 0;
    }

    // Set category
    _selectedCategory = tx.category;

    // Set amount (as positive number for display)
    final amountValue = tx.amount.abs().round();
    _amountController.text = _formatNumber(amountValue.toString());

    // Set date
    _selectedDate = tx.date;

    // Set note
    _noteController.text = tx.note ?? '';

    // Set wallet
    _selectedWalletId = tx.walletId;

    // Load categories for current type
    _loadCategoriesFromHive();
  }

  Future<void> _loadWallets() async {
    final service = WalletService();
    await service.init();

    // Load wallets for the transaction's user only
    final userId = widget.transaction.userId;
    final ws = await service.getAll(userId: userId.isNotEmpty ? userId : null);

    if (ws.isNotEmpty) {
      setState(() {
        _wallets = ws;
        // Keep selected wallet if valid; otherwise require explicit selection
        if (_selectedWalletId != null &&
            !_wallets.any((w) => w.id == _selectedWalletId)) {
          _selectedWalletId = null;
        }
      });
    } else {
      setState(() {
        _wallets = [];
        _selectedWalletId = null;
      });
    }
  }

  void _loadCategoriesFromHive() {
    final box = Hive.box<CategoryGroup>('category_groups');

    final type = _selectedTab == 0
        ? CategoryType.expense
        : _selectedTab == 1
        ? CategoryType.income
        : CategoryType.loan;

    // Khử trùng lặp theo (type, name)
    final seen = <String>{};
    var items = box.values
        .where((c) => c.type == type)
        .where(
          (c) => seen.add('${c.type.index}-${c.name.trim().toLowerCase()}'),
        )
        .toList();

    // Sắp xếp alphabetical, "Khác" ở cuối
    items.sort((a, b) {
      final aIsOther = a.name.contains('Khác');
      final bIsOther = b.name.contains('Khác');
      if (aIsOther && !bIsOther) return 1;
      if (!aIsOther && bIsOther) return -1;
      return a.name.compareTo(b.name);
    });

    setState(() {
      _categories = items;
      // If current category is not in the new list, select first
      if (!_categories.any((c) => c.name == _selectedCategory)) {
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first.name;
        }
      }
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chỉnh sửa giao dịch',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Transaction type indicator (readonly)
            _buildTransactionTypeIndicator(),
            const SizedBox(height: 20),
            _buildCategorySelector(),
            const SizedBox(height: 20),
            _buildAmountDisplay(),
            const SizedBox(height: 16),
            _buildWalletSelector(),
            const SizedBox(height: 16),
            _buildNoteField(),
            const SizedBox(height: 16),
            _buildDatePicker(),
            const SizedBox(height: 20),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  // ================= TRANSACTION TYPE =================

  Widget _buildTransactionTypeIndicator() {
    final isIncome = _selectedTab == 1;
    final isLoan = _selectedTab == 2;

    final bgColor = isIncome
        ? AppTheme.accentGreen.withAlpha((0.1 * 255).round())
        : isLoan
        ? AppTheme.primaryTeal.withAlpha((0.08 * 255).round())
        : Colors.red.withAlpha((0.1 * 255).round());

    final borderColor = isIncome
        ? AppTheme.accentGreen
        : isLoan
        ? AppTheme.primaryTeal
        : Colors.red;

    final iconData = isIncome
        ? Icons.add_circle_outline
        : isLoan
        ? Icons.swap_horiz
        : Icons.remove_circle_outline;

    final label = isIncome
        ? 'Khoản thu'
        : isLoan
        ? 'Vay/Nợ'
        : 'Khoản chi';

    final labelColor = borderColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData, color: labelColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ================= CATEGORY =================

  Widget _buildCategorySelector() {
    if (_categories.isEmpty) {
      return const Text('Chưa có danh mục');
    }

    final category = _categories.firstWhere(
      (e) => e.name == _selectedCategory,
      orElse: () => _categories.first,
    );

    return GestureDetector(
      onTap: _showCategoryPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.white.withAlpha((0.15 * 255).round()),
              child: Builder(
                builder: (context) {
                  final asset = CategoryIconMapper.assetForKey(
                    category.iconKey,
                  );
                  if (asset != null) {
                    return ClipOval(
                      child: Image.asset(
                        asset,
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                  return Icon(
                    CategoryIconMapper.fromKey(category.iconKey),
                    color: Colors.white,
                    size: 18,
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Số tiền',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '0',
            suffixIcon: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                '₫',
                style: TextStyle(fontSize: 20, color: AppTheme.textPrimary),
              ),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 10,
            ),
          ),
          onChanged: (value) {
            // Auto-format with commas
            if (value.isNotEmpty) {
              final cleanValue = value.replaceAll(',', '');
              if (cleanValue.isNotEmpty) {
                final formatted = _formatNumber(cleanValue);
                if (formatted != value) {
                  _amountController.value = TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                }
              }
            }
          },
        ),
      ],
    );
  }

  String _formatNumber(String number) {
    if (number.isEmpty) return '0';

    // Remove all non-digits
    number = number.replaceAll(RegExp(r'[^0-9]'), '');

    if (number.isEmpty) return '0';

    // Parse to int and format with commas
    try {
      final value = int.parse(number);
      return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return number;
    }
  }

  // ================= WALLET =================

  Widget _buildWalletSelector() {
    if (_wallets.isEmpty) {
      return const Text('Chưa có ví');
    }

    final selected = _wallets.firstWhere(
      (w) => w.id == _selectedWalletId,
      orElse: () => _wallets.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ví', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _showWalletPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppTheme.primaryTeal,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      selected.name,
                      style: TextStyle(color: AppTheme.textPrimary),
                    ),
                  ],
                ),
                const Icon(Icons.keyboard_arrow_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteController,
      maxLines: 3,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.note, size: 20),
        hintText: 'Ghi chú',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildDatePicker() {
    return OutlinedButton.icon(
      onPressed: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() => _selectedDate = picked);
        }
      },
      icon: Icon(Icons.calendar_today, color: AppTheme.primaryTeal),
      label: Text(
        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
        style: TextStyle(color: AppTheme.primaryTeal),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.grey.shade300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ================= SAVE =================

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryTeal,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isSaving ? null : _saveTransaction,
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Lưu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemCount: _categories.length,
            itemBuilder: (_, index) {
              final c = _categories[index];
              return InkWell(
                onTap: () {
                  setState(() => _selectedCategory = c.name);
                  Navigator.pop(sheetContext);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(c.colorValue),
                      child: Builder(
                        builder: (_) {
                          final asset = CategoryIconMapper.assetForKey(
                            c.iconKey,
                          );
                          if (asset != null) {
                            return ClipOval(
                              child: Image.asset(
                                asset,
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                              ),
                            );
                          }
                          return Icon(
                            CategoryIconMapper.fromKey(c.iconKey),
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(c.name, textAlign: TextAlign.center),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showWalletPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Chọn ví',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ..._wallets.map((w) {
                final isSelected = w.id == _selectedWalletId;
                return ListTile(
                  leading: Icon(
                    Icons.account_balance_wallet,
                    color: isSelected ? AppTheme.primaryTeal : Colors.grey,
                  ),
                  title: Text(w.name),
                  trailing: isSelected
                      ? Icon(Icons.check, color: AppTheme.primaryTeal)
                      : null,
                  onTap: () {
                    setState(() => _selectedWalletId = w.id);
                    Navigator.pop(sheetContext);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTransaction() async {
    if (_isSaving) return;

    final amountText = _amountController.text.replaceAll(',', '').trim();
    final amount = int.tryParse(amountText) ?? 0;

    if (amount <= 0) {
      AppNotification.showError(context, 'Vui lòng nhập số tiền hợp lệ');
      return;
    }

    if (_selectedCategory.isEmpty) {
      AppNotification.showError(context, 'Vui lòng chọn danh mục');
      return;
    }

    if (_selectedWalletId == null || _selectedWalletId!.isEmpty) {
      AppNotification.showError(context, 'Vui lòng chọn ví');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.id ?? '';

      final txType = _selectedTab == 0
          ? model.TransactionType.expense
          : _selectedTab == 1
          ? model.TransactionType.income
          : model.TransactionType.loan;

      // Create updated transaction (keep original ID and createdAt)
      final updatedTransaction = model.Transaction(
        id: widget.transaction.id,
        userId: userId,
        type: txType,
        category: _selectedCategory,
        // Store amount as positive; wallet balance logic uses type to apply sign
        amount: amount.toDouble(),
        date: _selectedDate,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        walletId: _selectedWalletId,
        createdAt: widget.transaction.createdAt, // Keep original creation date
      );

      await _transactionService.updateTransaction(updatedTransaction);

      final notifier = context.read<TransactionNotifier>();
      notifier.notifyTransactionChanged();

      if (mounted) {
        AppNotification.showSuccess(context, 'Đã cập nhật giao dịch');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        AppNotification.showError(context, 'Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
