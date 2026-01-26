import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/wallet.dart';
import '../../services/data/wallet_service.dart';
import '../../services/auth/auth_service.dart';
import '../../utils/notification_helper.dart';

// ============================================================================
// MY WALLET SCREEN - Manage user wallets and accounts
// ============================================================================

class MyWalletScreen extends StatefulWidget {
  const MyWalletScreen({super.key});

  @override
  State<MyWalletScreen> createState() => _MyWalletScreenState();
}

class _MyWalletScreenState extends State<MyWalletScreen> {
  final WalletService _walletService = WalletService();
  List<Wallet> _wallets = [];
  bool _isProtected(Wallet w) {
    final id = w.id;
    const prefixes = [
      'wallet_cash',
      'wallet_bank',
      'wallet_ewallet',
      'wallet_saving',
      'wallet_investment',
    ];
    for (final p in prefixes) {
      if (id == p || id.startsWith('${p}_')) return true;
    }
    return false;
  }

  final _currencyFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'VND',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    await _walletService.init();
    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.id ?? '';

    // seed defaults if needed (idempotent)
    await _walletService.seedDefaultWallets(userId);

    final w = await _walletService.getAll(userId: userId);
    if (mounted) setState(() => _wallets = w);
  }

  String _formatBalance(double amount) {
    try {
      return _currencyFormatter.format(amount);
    } catch (_) {
      return '${amount.toStringAsFixed(0)} VND';
    }
  }

  IconData _iconForType(WalletType type) {
    switch (type) {
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
  }

  Future<void> _showAddEditDialog({Wallet? wallet}) async {
    final nameCtrl = TextEditingController(text: wallet?.name ?? '');
    WalletType type = wallet?.type ?? WalletType.cash;

    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(wallet == null ? 'Thêm ví' : 'Chỉnh sửa ví'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên ví'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<WalletType>(
                    value: type,
                    isExpanded: true,
                    items: WalletType.values.map((wt) {
                      final label = wt.toString().split('.').last;
                      return DropdownMenuItem(
                        value: wt,
                        child: Text(
                          label[0].toUpperCase() + label.substring(1),
                        ),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setState(() => type = v ?? WalletType.cash),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    nameCtrl.dispose();
                    Navigator.pop(context, null);
                  },
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    // Quick in-memory duplicate check to avoid disk IO and UI freeze
                    final auth = Provider.of<AuthService>(
                      context,
                      listen: false,
                    );
                    final userId = auth.currentUser?.id ?? '';
                    final dup = _wallets.any(
                      (w2) =>
                          w2.userId == userId &&
                          w2.name.trim().toLowerCase() == name.toLowerCase() &&
                          w2.id != wallet?.id,
                    );
                    if (dup) {
                      AppNotification.showError(context, 'Tên ví đã tồn tại');
                      return;
                    }

                    final payload = {
                      'name': name,
                      'type': type,
                      'id': wallet?.id,
                    };
                    nameCtrl.dispose();
                    Navigator.pop(context, payload);
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      // show non-blocking progress indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        final auth = Provider.of<AuthService>(context, listen: false);
        final userId = auth.currentUser?.id ?? '';

        final name = result['name'] as String;
        final type = result['type'] as WalletType;
        final id = result['id'] as String?;

        // Give UI a moment to render the progress indicator before heavy IO
        await Future.delayed(const Duration(milliseconds: 100));

        // Check duplicates
        final existing = await _walletService.getByName(name, userId: userId);
        if (existing != null && existing.id != id) {
          Navigator.pop(context);
          AppNotification.showError(context, 'Tên ví đã tồn tại');
          return;
        }

        final opStart = DateTime.now();
        if (id == null) {
          final newW = _walletService.createNew(
            name: name,
            type: type,
            userId: userId,
          );
          await _walletService.add(newW);
        } else {
          final w = await _walletService.getById(id);
          if (w == null) throw StateError('Wallet không tồn tại');
          w.name = name;
          w.type = type;
          await _walletService.update(w);
        }
        final opMs = DateTime.now().difference(opStart).inMilliseconds;
        if (opMs > 2000) {
          debugPrint('⚠️ Wallet save took ${opMs}ms for user $userId');
        }

        Navigator.pop(context);
        AppNotification.showSuccess(context, 'Lưu ví thành công');

        // Refresh wallets without blocking UI
        _loadWallets();
      } catch (e) {
        Navigator.pop(context);
        AppNotification.showError(context, 'Lỗi khi lưu ví: $e');
      }
    }
  }

  Future<void> _confirmDelete(Wallet w) async {
    if (w.isDefault) {
      AppNotification.showError(context, 'Không thể xóa ví mặc định');
      return;
    }

    final auth = Provider.of<AuthService>(context, listen: false);
    final userId = auth.currentUser?.id ?? '';

    final count = (await _walletService.getAll(userId: userId)).length;
    if (count <= 1) {
      AppNotification.showError(context, 'Phải có ít nhất 1 ví');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa ví'),
        content: Text('Bạn có chắc muốn xóa ví "${w.name}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _walletService.deleteWallet(w.id);
      await _loadWallets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _wallets.fold<double>(0.0, (s, w) => s + w.balance);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Ví của tôi'),
        backgroundColor: AppTheme.cardColor,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadWallets,
        child: _wallets.isEmpty
            ? ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn chưa có ví. Thêm ví để bắt đầu quản lý số dư và giao dịch.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _wallets.length + 1,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Card(
                      color: AppTheme.cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tính vào tổng',
                              style: TextStyle(color: Colors.black54),
                            ),
                            Text(
                              _formatBalance(total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final w = _wallets[index - 1];
                  final isProtected = _isProtected(w);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade50,
                      child: Icon(_iconForType(w.type), color: Colors.green),
                    ),
                    title: Text(
                      w.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(_formatBalance(w.balance)),
                    trailing: isProtected
                        ? const SizedBox.shrink()
                        : PopupMenuButton<String>(
                            onSelected: (v) async {
                              if (v == 'edit') {
                                await _showAddEditDialog(wallet: w);
                              } else if (v == 'delete') {
                                await _confirmDelete(w);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('Chỉnh sửa'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Xóa',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppTheme.primaryTeal,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
