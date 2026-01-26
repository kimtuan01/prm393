import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../models/transaction.dart' as model;
import '../../services/debug/hive_debug_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  List<User> _users = [];
  List<model.Transaction> _transactions = [];
  Map<String, dynamic> _sessionData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load users
      final userBox = await Hive.openBox<User>('users');
      _users = userBox.values.toList();

      // Load transactions
      final transactionBox = await Hive.openBox<model.Transaction>(
        'transactions',
      );
      _transactions = transactionBox.values.toList();

      // Load session data
      final sessionBox = await Hive.openBox('session');
      _sessionData = {};
      for (var key in sessionBox.keys) {
        _sessionData[key.toString()] = sessionBox.get(key);
      }
    } catch (e) {
      print('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        title: Text(
          'Debug - Hive Database',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('👥 Users (${_users.length})'),
                  _buildUsersSection(),

                  SizedBox(height: 24),

                  _buildSectionHeader(
                    '💰 Transactions (${_transactions.length})',
                  ),
                  _buildTransactionsSection(),

                  SizedBox(height: 24),

                  _buildSectionHeader('🔐 Session Data'),
                  _buildSessionSection(),

                  SizedBox(height: 24),

                  _buildActionsSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryTeal.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryTeal,
        ),
      ),
    );
  }

  Widget _buildUsersSection() {
    if (_users.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Chưa có tài khoản nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _users.map((user) {
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryTeal,
              child: Text(
                user.fullName[0].toUpperCase(),
                style: TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              user.fullName,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${user.email}'),
                Text('ID: ${user.id}'),
                Text('Verified: ${user.isVerified ? "✓" : "✗"}'),
              ],
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteUser(user),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsSection() {
    if (_transactions.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Chưa có giao dịch nào',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        ..._transactions.take(5).map((transaction) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              dense: true,
              title: Text(transaction.category),
              subtitle: Text(transaction.note ?? ''),
              trailing: Text(
                '${transaction.amount.toStringAsFixed(0)} ₫',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: transaction.type == model.TransactionType.expense
                      ? Colors.red
                      : Colors.green,
                ),
              ),
            ),
          );
        }),
        if (_transactions.length > 5)
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              '... và ${_transactions.length - 5} giao dịch khác',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSessionSection() {
    if (_sessionData.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Chưa có session data',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _sessionData.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${entry.key}: ${entry.value}',
                style: TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Column(
      children: [
        // 🗑️ XÓA TOÀN BỘ DATA
        ElevatedButton.icon(
          onPressed: _deleteAllData,
          icon: Icon(Icons.delete_forever, size: 28),
          label: Text(
            '🗑️ XÓA TOÀN BỘ DATA (RESET APP)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            minimumSize: Size(double.infinity, 60),
          ),
        ),
        SizedBox(height: 16),

        // Divider
        Divider(thickness: 2),
        SizedBox(height: 8),

        ElevatedButton.icon(
          onPressed: _clearAllUsers,
          icon: Icon(Icons.person_remove),
          label: Text('Xóa tất cả Users'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _clearAllTransactions,
          icon: Icon(Icons.delete_sweep),
          label: Text('Xóa tất cả Transactions'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _clearSession,
          icon: Icon(Icons.logout),
          label: Text('Xóa Session'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text('Bạn có chắc muốn xóa tài khoản ${user.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm == true) {
      final userBox = await Hive.openBox<User>('users');
      await userBox.delete(user.id);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa tài khoản ${user.fullName}')),
        );
      }
    }
  }

  Future<void> _clearAllUsers() async {
    final confirm = await _showConfirmDialog(
      'Xóa tất cả ${_users.length} tài khoản?',
    );
    if (!mounted) return;
    if (confirm) {
      final userBox = await Hive.openBox<User>('users');
      await userBox.clear();
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xóa tất cả tài khoản')));
      }
    }
  }

  Future<void> _clearAllTransactions() async {
    final confirm = await _showConfirmDialog(
      'Xóa tất cả ${_transactions.length} giao dịch?',
    );
    if (!mounted) return;
    if (confirm) {
      final transactionBox = await Hive.openBox<model.Transaction>(
        'transactions',
      );
      await transactionBox.clear();
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xóa tất cả giao dịch')));
      }
    }
  }

  /// 🗑️ XÓA TOÀN BỘ DATA (RESET APP)
  Future<void> _deleteAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('⚠️ CẢNH BÁO!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn XÓA TOÀN BỘ DATA?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 12),
            Text('✅ Sẽ xóa:'),
            Text('  • ${_users.length} tài khoản'),
            Text('  • ${_transactions.length} giao dịch'),
            Text('  • Tất cả wallets, budgets, categories'),
            Text('  • Session data'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📝 Lưu ý:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Chỉ xóa LOCAL data (Hive).\nFirebase cloud data KHÔNG bị xóa.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('HỦY BỎ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('XÓA TẤT CẢ'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang xóa data...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Delete all local data
      await HiveDebugService.deleteAllLocalData();

      // Reload UI
      await _loadData();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Đã xóa TOÀN BỘ local data! App đã reset.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi khi xóa data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearSession() async {
    final confirm = await _showConfirmDialog('Xóa session data?');
    if (!mounted) return;
    if (confirm) {
      final sessionBox = await Hive.openBox('session');
      await sessionBox.clear();
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã xóa session')));
      }
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xác nhận', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
