import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/theme.dart';
import '../../models/transaction.dart' as model;
import '../../services/data/transaction_notifier.dart';
import '../../services/ocr/ocr_service.dart';
import '../../models/receipt_data.dart';
import '../../services/auth/auth_service.dart';
import '../../models/category_group.dart';
import '../../utils/category_icon_mapper.dart';
import '../../utils/notification_helper.dart';

import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/wallet.dart';
import '../../services/data/wallet_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  int _selectedTab = 0; // 0: Khoản chi, 1: Khoản thu, 2: Vay/Nợ
  String _selectedCategory = '';
  String _amount = '0';
  final FocusNode _amountFocusNode = FocusNode();
  final TextEditingController _amountController = TextEditingController(
    text: '0',
  );
  DateTime _selectedDate = DateTime.now();

  // Wallets
  List<Wallet> _wallets = [];
  String? _selectedWalletId;

  final TextEditingController _noteController = TextEditingController();
  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();

  /// 🔹 DANH MỤC TỪ HIVE
  List<CategoryGroup> _categories = [];

  // Payment method removed – wallet now represents the source of funds.

  @override
  void initState() {
    super.initState();
    _initializeOCR();
    _loadCategoriesFromHive();
    _loadWallets();
    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus && _amountController.text == '0') {
        _setAmount('');
      }
    });
  }

  Future<void> _loadWallets() async {
    final service = WalletService();
    await service.init();

    // Load wallets scoped to the current user to avoid showing wallets from other accounts.
    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.id ?? '';

    // Ensure default wallets exist for this user (seed only if user present).
    if (userId.isNotEmpty) {
      await service.seedDefaultWallets(userId);
    }

    final ws = await service.getAll(userId: userId.isNotEmpty ? userId : null);

    if (ws.isNotEmpty) {
      // Prefer selecting an existing default wallet for convenience
      Wallet? preferred;
      try {
        preferred = ws.firstWhere((w) => w.isDefault);
      } catch (_) {
        preferred = ws.first;
      }

      setState(() {
        _wallets = ws;
        // If previous selection is invalid or missing, pick preferred wallet or require user to choose.
        if (_selectedWalletId == null ||
            !_wallets.any((w) => w.id == _selectedWalletId)) {
          _selectedWalletId = preferred?.id;
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

    // Khử trùng lặp theo (type, name) để tránh lặp danh mục hiển thị
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
      if (aIsOther && !bIsOther) return 1; // a (Khác) xuống cuối
      if (!aIsOther && bIsOther) return -1; // b (Khác) xuống cuối
      return a.name.compareTo(
        b.name,
      ); // Cả hai Khác hoặc không Khác: sort alphabetical
    });

    setState(() {
      _categories = items;
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first.name;
      }
    });
  }

  Future<void> _initializeOCR() async {
    try {
      await _ocrService.initialize();
    } catch (_) {}
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Thêm giao dịch',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt_outlined, color: AppTheme.textPrimary),
            onPressed: _showScanOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tab selector
              _buildTabSelector(),
              const SizedBox(height: 20),

              // Category button
              Center(child: _buildCategorySelector()),
              const SizedBox(height: 24),

              // Amount input field (system numeric keyboard)
              _buildAmountInput(),
              const SizedBox(height: 20),

              // Wallet selector
              _buildWalletSelectorCompact(),
              const SizedBox(height: 16),

              // Note display
              _buildNoteDisplay(),
              const SizedBox(height: 16),

              // Date picker
              _buildDatePickerCompact(),
              const SizedBox(height: 32),

              // Save button
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        children: [
          // Animated selector background (inset pill)
          AnimatedAlign(
            alignment: _getTabAlignment(),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 1 / 3,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ),
          // Tab buttons (on top)
          Row(
            children: [
              _buildTab('Khoản chi', 0),
              _buildTab('Khoản thu', 1),
              _buildTab('Vay/Nợ', 2),
            ],
          ),
        ],
      ),
    );
  }

  Alignment _getTabAlignment() {
    switch (_selectedTab) {
      case 0:
        return Alignment.centerLeft;
      case 1:
        return Alignment.center;
      case 2:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  Widget _buildTab(String title, int index) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedTab = index;
            _loadCategoriesFromHive();
          });
        },
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
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
          borderRadius: BorderRadius.circular(26),
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
            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }

  // ================= AMOUNT INPUT (SYSTEM NUMERIC KEYBOARD) =================

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số tiền',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Theme(
          data: Theme.of(context).copyWith(
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: AppTheme.primaryTeal,
              selectionColor: AppTheme.primaryTeal.withOpacity(0.25),
              selectionHandleColor: AppTheme.primaryTeal,
            ),
          ),
          child: TextField(
            focusNode: _amountFocusNode,
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            cursorColor: AppTheme.primaryTeal,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              prefixText: 'VND ',
              prefixStyle: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.w500,
              ),
              suffix: Text(
                '₫',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryTeal, width: 2),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 0,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _amount = value.isEmpty ? '0' : value;
              });
            },
          ),
        ),
      ],
    );
  }

  // ================= WALLET SELECTOR (COMPACT) =================

  Widget _buildWalletSelectorCompact() {
    final hasSelection =
        _selectedWalletId != null &&
        _wallets.any((w) => w.id == _selectedWalletId);

    final selected = hasSelection
        ? _wallets.firstWhere((w) => w.id == _selectedWalletId)
        : null;

    final icon = selected == null
        ? Icons.wallet_outlined
        : selected.type == WalletType.cash
        ? Icons.wallet_outlined
        : selected.type == WalletType.bank
        ? Icons.account_balance_outlined
        : Icons.credit_card_outlined;

    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).unfocus();
        final chosen = await showModalBottomSheet<Wallet>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (sheetContext) {
            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.6,
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                      const Text(
                        'Chọn ví',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _wallets.length,
                          itemBuilder: (context, index) {
                            final w = _wallets[index];
                            return ListTile(
                              title: Text(w.name),
                              subtitle: Text('${w.balance} VND'),
                              trailing: w.id == _selectedWalletId
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                Navigator.pop(sheetContext, w);
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

        if (chosen != null) setState(() => _selectedWalletId = chosen.id);
      },
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryTeal, size: 20),
          const SizedBox(width: 10),
          Text(
            selected?.name ?? 'Chọn ví',
            style: TextStyle(
              fontSize: 14,
              color: selected == null ? Colors.grey : AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ================= NOTE DISPLAY (COMPACT) =================

  Widget _buildNoteDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ghi chú',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 4,
          minLines: 3,
          cursorColor: AppTheme.primaryTeal,
          style: TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: '', // no placeholder text
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryTeal),
            ),
            isDense: true,
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  // ================= DATE PICKER (COMPACT) =================

  Widget _buildDatePickerCompact() {
    // Format date in Vietnamese
    final dateStr =
        '${_getDayOfWeek(_selectedDate)} ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';

    return GestureDetector(
      onTap: () async {
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
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: AppTheme.primaryTeal,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.primaryTeal,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 18),
        ],
      ),
    );
  }

  String _getDayOfWeek(DateTime date) {
    final days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'];
    return days[date.weekday - 1];
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
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        onPressed: _saveTransaction,
        child: const Text(
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

  Future<void> _saveTransaction() async {
    final amountValue = double.parse(_amount.replaceAll(',', ''));

    final type = _selectedTab == 0
        ? model.TransactionType.expense
        : _selectedTab == 1
        ? model.TransactionType.income
        : model.TransactionType.loan;

    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.id ?? '';

    // Require explicit wallet selection — do not auto-assign
    if (_selectedWalletId == null || _selectedWalletId!.isEmpty) {
      AppNotification.showError(context, 'Vui lòng chọn ví');
      return;
    }

    final tx = model.Transaction(
      id: const Uuid().v4(),
      amount: amountValue,
      category: _selectedCategory,
      note: _noteController.text,
      date: _selectedDate,
      type: type,
      createdAt: DateTime.now(),
      userId: userId,
      walletId: _selectedWalletId,
    );

    final notifier = context.read<TransactionNotifier>();
    try {
      await notifier.addTransactionAndNotify(tx);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      AppNotification.showError(context, e.toString());
    }
  }

  String _formatNumber(String number) {
    if (number.isEmpty) return '0';

    // Remove all commas first
    number = number.replaceAll(',', '');

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

  /// Show options to scan from camera or gallery
  void _showScanOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quét hóa đơn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: AppTheme.primaryTeal),
                ),
                title: Text('Chụp ảnh'),
                subtitle: Text(
                  'Quét hóa đơn với camera',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: _scanFromCamera,
              ),
              SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withAlpha((0.1 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.photo_library, color: AppTheme.primaryTeal),
                ),
                title: Text('Chọn từ thư viện'),
                subtitle: Text(
                  'Chọn ảnh hóa đơn từ thư viện',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: _pickFromGallery,
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ========== OCR METHODS ==========

  Future<void> _scanFromCamera() async {
    try {
      Navigator.pop(context); // Close the scan options dialog

      // Request camera permission
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        _showErrorDialog('Ứng dụng cần quyền truy cập camera');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        _showLoadingDialog('Đang xử lý hóa đơn...');

        final result = await _ocrService.scanReceipt(File(image.path));

        Navigator.pop(context); // Close loading dialog

        if (result != null) {
          _processReceiptData(result);
        } else {
          _showErrorDialog('Không thể nhận diện hóa đơn');
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorDialog('Lỗi khi chụp ảnh: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      Navigator.pop(context); // Close the scan options dialog

      // Request photos permission
      final photosStatus = await Permission.photos.request();
      if (!photosStatus.isGranted) {
        _showErrorDialog('Ứng dụng cần quyền truy cập thư viện ảnh');
        return;
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        _showLoadingDialog('Đang xử lý hóa đơn...');

        final result = await _ocrService.scanReceipt(File(image.path));

        Navigator.pop(context); // Close loading dialog

        if (result != null) {
          _processReceiptData(result);
        } else {
          _showErrorDialog('Không thể nhận diện hóa đơn');
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if open
      _showErrorDialog('Lỗi khi chọn ảnh: $e');
    }
  }

  void _processReceiptData(ReceiptData data) {
    setState(() {
      // Update amount
      if (data.amount > 0) {
        // Round and format with separators
        _setAmount(_formatNumber(data.amount.round().toString()));
      }

      // Update date
      _selectedDate = data.date;

      // Update category - map from standard to Vietnamese
      final categoryMapping = {
        'Food & Drink': 'Ăn uống',
        'Transport': 'Xăng xe',
        'Shopping': 'Shopping',
        'Entertainment': 'Giải trí',
        'Healthcare': 'Y tế',
        'Education': 'Giáo dục',
        'Bills': 'Hóa đơn',
        'Other': 'Khác',
      };

      final vietnameseCategory =
          categoryMapping[data.category] ?? data.category;
      // _categories is a flat list of CategoryGroup; check by name
      if (_categories.any((cat) => cat.name == vietnameseCategory)) {
        _selectedCategory = vietnameseCategory;
      } else if (_categories.isNotEmpty && _selectedCategory.isEmpty) {
        _selectedCategory = _categories.first.name;
      }

      // Build note from merchant and items
      String noteText = '';
      if (data.merchant != 'Unknown' && data.merchant.isNotEmpty) {
        noteText += 'Cửa hàng: ${data.merchant}\n';
      }
      if (data.items.isNotEmpty) {
        noteText += 'Món: ${data.items.join(", ")}\n';
      }
      if (data.notes != null && data.notes!.isNotEmpty) {
        noteText += data.notes!;
      }

      if (noteText.isNotEmpty) {
        _noteController.text = noteText.trim();
      }
    });

    // Show success message with confidence
    final confidencePercent = (data.confidence * 100).toStringAsFixed(0);
    final confidenceEmoji = data.confidence >= 0.7 ? '✅' : '⚠️';

    final message = data.confidence >= 0.7
        ? '$confidenceEmoji Đã quét hóa đơn thành công'
        : '$confidenceEmoji Đã quét hóa đơn (Độ tin cậy: $confidencePercent%)';

    if (data.confidence >= 0.7) {
      AppNotification.showSuccess(
        context,
        message,
        duration: const Duration(seconds: 3),
      );
    } else {
      AppNotification.showWarning(
        context,
        message,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryTeal),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _setAmount(String value) {
    _amount = value.isEmpty ? '0' : value;
    _amountController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }
}
